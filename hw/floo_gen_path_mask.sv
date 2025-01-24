// Chen Wu

// the bit that is set to 0 means that the flit coming from the input port is to be reduced
// the bit that is set to 1 means that the flit coming from the input port is normal
module floo_gen_path_mask import floo_pkg::*;
# (
    parameter int unsigned NumRoutes  = 1,
    parameter type         flit_t     = logic
) (
    input  logic                   clk_i,
    input  logic                   rst_ni,
    input  flit_t [NumRoutes-1:0]  data_i,
    output logic  [NumRoutes-1:0]  mask_o
);

    always_comb begin
        // Initialize mask_o to zero
        mask_o = '0;

        // Iterate over all routes
        for (int i = 0; i < NumRoutes; i++) begin
        // Check if the commtype matches CollectB
            if (data_i[i].hdr.commtype == CollectB) begin
                mask_o[i] = 1'b0;
            end
            else begin
                mask_o[i] = 1'b1;
            end
        end
    end

endmodule