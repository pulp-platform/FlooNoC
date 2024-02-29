
// a simple one-hot encoded multiplexer
module floo_mux
#(
  parameter int unsigned SOURCE_COUNT = 2,
  parameter int unsigned DATA_WIDTH = 1
)
(
  input logic[SOURCE_COUNT-1:0] sel_i,
  input logic[SOURCE_COUNT-1:0][DATA_WIDTH-1:0] data_i,
  output logic[DATA_WIDTH-1:0] data_o
);

  logic[DATA_WIDTH-1:0][SOURCE_COUNT-1:0] transposed_data;
  logic[DATA_WIDTH-1:0][SOURCE_COUNT-1:0] select_mat;

  generate
    for(genvar i = 0 ; i < DATA_WIDTH; i++) begin
      for(genvar j = 0 ; j < SOURCE_COUNT; j++) begin
        assign transposed_data[i][j] = data_i[j][i];
      end
    end
  endgenerate
  
  generate
    for(genvar i = 0; i < DATA_WIDTH; i++) begin
      assign data_o[i] = |(transposed_data[i] & sel_i);
    end
  endgenerate

endmodule