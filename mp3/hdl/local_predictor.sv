module local_predictor(
	input clk,
	input rst,
	
	input logic [9:0] idx, //index used for local_predictor
	input logic read, //signal used to read predictor table
	output logic predicted_outcome, //predicts whether to branch or not
	output logic [9:0] predicted_outcome_idx,
	
	input logic [9:0] actual_outcome_idx,
	input logic actual_outcome,
	input logic write
	);
	
	
predictor_table predictor_table(
	.clk(clk),
	.rst(rst),
	.idx(idx),
	.read(read),
	.predicted_outcome(predicted_outcome),
	.actual_outcome(actual_outcome),
	.actual_outcome_idx(actual_outcome_idx),
	.write(write)
);

assign predicted_outcome_idx = idx;

	
	
	endmodule: local_predictor
	