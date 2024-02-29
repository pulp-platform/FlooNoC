
// one hot & id encoded round robin arbiter
module floo_rr_arbiter #(
  parameter N_INPUT = 2,
  localparam int unsigned N_INPUT_WIDTH = N_INPUT > 1 ? $clog2(N_INPUT) : 1,
) (
  input   logic [N_INPUT-1:0] req_i,
  input   logic               update_i, //only update arbiter when told to
  output  logic [N_INPUT-1:0] grant_o,
  output  logic [N_INPUT_WIDTH-1:0] grant_id_o,
  input   logic               rst_ni, clk_i
); 
  genvar i, j;
  generate
    if(N_INPUT == 1) begin: 
    
      assign grant_o     = req_i;
      assign grant_id_o = 0;
    end else begin: 

      logic [N_INPUT-1:0] reodered_req, reordered_selected_req;
      logic [N_INPUT*2-1:0] left_rotate_helper, right_rotate_helper;
      logic [N_INPUT-1:0] dereordered_selected_req;
      logic [N_INPUT_WIDTH-1:0] round_ptr_q, round_ptr_d;
      logic [N_INPUT_WIDTH-1:0] round_ptr_q_comp;
      logic [N_INPUT_WIDTH-1:0] selected_req_id;

      logic [N_INPUT_WIDTH-1:0][N_INPUT-1:0] id_mask;   

      // rotade left
      assign left_rotate_helper = {req_i, req_i} << round_ptr_q;
      assign reodered_req = left_rotate_helper[N_INPUT*2-1-:N_INPUT];
          
      //isolate rightmost 1 bit: reodered_req & (-reodered_req)
      assign reordered_selected_req = reodered_req & (~reodered_req + 1'b1);

      //rotate back: circular rotate by N_INPUT - round_ptr_q
      assign round_ptr_q_comp = N_INPUT - round_ptr_q;
      assign right_rotate_helper = {reordered_selected_req, reordered_selected_req} << round_ptr_q_comp;
      assign dereordered_selected_req = right_rotate_helper[N_INPUT*2-1-:N_INPUT];

      //extract id from onehot: create id mask
      for(i = 0; i < N_INPUT_WIDTH; i++) begin
        for(j = 0; j < N_INPUT; j++) begin 
          assign id_mask[i][j] = (j/(2**i)) % 2;
        end
      end
      //mask looks like this: N_Input = 3: (0,0) is first bit
      // 0 0 0  // 1 0 0  // 0 1 0  // 1 1 0  // 0 0 1  // 1 0 1  // 0 1 1  // 1 1 1  
      // use mask to get req_id
      for(i = 0; i < N_INPUT_WIDTH; i++) begin
        assign selected_req_id[i] = |(dereordered_selected_req & id_mask[i]);
      end

      // ff for round ptr
      assign round_ptr_d =  (selected_req_id == '0)          ? N_INPUT-1 :
                            (selected_req_id == (N_INPUT-1)) ? '0        : (N_INPUT-1) - selected_req_id;

      always_ff @(posedge clk or negedge rst_n) begin
        if (~rstn) begin
          round_ptr_q <= '0;
        end else begin
          if (update_i) begin
            round_ptr_q <= round_ptr_d;
          end
        end
      end

      assign grant_o     = dereordered_selected_req;
      assign grant_id_o  = selected_req_id;

    end
  endgenerate
endmodule
