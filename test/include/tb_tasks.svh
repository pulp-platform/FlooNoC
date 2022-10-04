// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Thomas Benz <tbenz@ethz.ch>

// write a byte to the AXI-attached memory
task write_byte_dma_mem (
    input byte_t byte_i,
    input addr_t addr_i
);
    i_axi_dma_sim_mem.mem[addr_i] = byte_i;
endtask

task write_byte_axi_in_mem (
    input byte_t byte_i,
    input addr_t addr_i
);
    i_axi_in_sim_mem.mem[addr_i] = byte_i;
endtask

task automatic init_mem (
    ref tb_dma_job_t now_r
);
    addr_t now;
    byte_t to_write;
    now = 0;
    while (now < now_r.length) begin
        // to_write = $urandom();
        to_write = now_r.src_addr + now;
        // model.write_byte   (to_write, now_r.src_addr + now);
        write_byte_dma_mem (to_write, now_r.src_addr + now);
        write_byte_axi_in_mem (to_write, now_r.src_addr + now);
        now++;
    end
endtask

// read jobs from the job file
task automatic read_jobs (
    input string       filename,
    ref   tb_dma_job_t jobs [$]
);

    // job file
    integer job_file;

    // parsed fields
    int unsigned            num_errors;
    string                  is_read, error_handling;
    addr_t                  err_addr;
    tb_dma_job_t            now;
    idma_pkg::idma_eh_req_t eh;

    // open file
    job_file = $fopen(filename, "r");

    // check if file exist
    if (job_file == 0)
        $fatal(1, "File not found!");

    // until not end of file
    while (! $feof(job_file)) begin
        now = new();
        void'($fscanf(job_file, "%d\n", now.length));
        void'($fscanf(job_file, "0x%x\n", now.src_addr));
        void'($fscanf(job_file, "0x%x\n", now.dst_addr));
        void'($fscanf(job_file, "%d\n", now.max_src_len));
        void'($fscanf(job_file, "%d\n", now.max_dst_len));
        void'($fscanf(job_file, "%b\n", now.aw_decoupled));
        void'($fscanf(job_file, "%b\n", now.rw_decoupled));
        if (now.IsND) begin
            for (int d = 0; d < now.NumDim-1; d++) begin
                void'($fscanf(job_file, "%d\n", now.n_dims[d].reps));
                void'($fscanf(job_file, "0x%x\n", now.n_dims[d].src_strides));
                void'($fscanf(job_file, "0x%x\n", now.n_dims[d].dst_strides));
            end
        end
        void'($fscanf(job_file, "%d\n", num_errors));
        for (int i = 0; i < num_errors; i++) begin
            void'($fscanf(job_file, "%c%c0x%h\n", is_read, error_handling, err_addr));
            // parse error handling option
            eh = '0;
            case (error_handling)
                "c" : eh = idma_pkg::CONTINUE;
                "a" : eh = idma_pkg::ABORT;
                default:;
            endcase
            now.err_action.push_back(eh);

            // parse read flag
            if (is_read == "r") begin
                now.err_is_read.push_back(1);
            end else begin
                now.err_is_read.push_back(0);
            end

            // error address
            now.err_addr.push_back(err_addr);
        end
        if (now.length == 0) continue;
        jobs.push_back(now);
    end

    // close job file
    $fclose(job_file);

endtask

// print a job summary (# jobs and total length)
task automatic print_summary (
    ref   tb_dma_job_t jobs [$]
);
    int unsigned data_size;
    int unsigned num_transfers;
    data_size     = '0;
    num_transfers = jobs.size();
    // go through queue
    for (int i = 0; i < num_transfers; i++) begin
        data_size = data_size + jobs[i].length;
    end
    $display("[DMA%0d] Launching %d jobs copying a total of %d B (%d kiB - %d MiB)",
                JobId + 1,
                num_transfers,
                data_size,
                data_size / 1024,
                data_size / 1024 / 1024
            );
endtask
