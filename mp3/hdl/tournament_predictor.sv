module tournament_predictor(
	input clk,
	input rst,
	
	input logic [9:0] idx, //index used for local_predictor
	input logic read, //signal used to read predictor table
	output logic predicted_outcome, //predicts whether to branch or not
	output logic [9:0] predicted_outcome_idx,
	
	input logic [9:0] actual_outcome_idx,
	input logic actual_outcome,
	input logic write,
	
	//records data used to write later
	output logic global_predicted_outcome_out,
	output logic local_predicted_outcome_out,
	output logic [9:0] local_predicted_idx_out,
	output logic [9:0] global_predicted_idx_out,
	
	//used to write to each predictor
	input logic global_predicted_outcome_in,
	input logic local_predicted_outcome_in,
	input logic [9:0] local_actual_idx_in,
	input logic [9:0] global_actual_idx_in
	
	
	);
	
	logic predicted_choice; 
	logic local_predicted_outcome;
	logic global_predicted_outcome;
	
	
	meta_predictor_table meta_predictor_table(
	.clk(clk),
	.rst(rst),
	
	//All used to read state of table
	.idx(idx), //index into predictor table
	.read(read), //valid if a read into the table is valid
	
	.predicted_outcome(predicted_choice),
	
	//Used to update state of table
	.global_outcome(global_predicted_outcome_in == actual_outcome), //was global correct
	.local_outcome(local_predicted_outcome_in == actual_outcome),  //was local correct, need to save the predicted vals of and compare with actual result
	.actual_outcome_idx(actual_outcome_idx),
	.write(write)
);

local_predictor local_predictor(
	.clk(clk),
	.rst(rst),
	
	.idx(idx), //index used for local_predictor
	.read(read), //signal used to read predictor table
	.predicted_outcome(local_predicted_outcome), //predicts whether to branch or not
	.predicted_outcome_idx(local_predicted_idx_out),
	
	.actual_outcome_idx(local_actual_idx_in),
	.actual_outcome(actual_outcome),
	.write(write)
	);
	
global_predictor global_predictor(
	.clk(clk),
	.rst(rst),
	
	.idx(idx), //index used for local_predictor
	.read(read), //signal used to read predictor table
	.predicted_outcome(global_predicted_outcome), //predicts whether to branch or not
	.predicted_outcome_idx(global_predicted_idx_out),
	
	.actual_outcome_idx(global_actual_idx_in),
	.actual_outcome(actual_outcome),
	.write(write)
	);
	
always_comb
	begin
		if(predicted_choice == 1'b1)
			predicted_outcome = global_predicted_outcome;
		else
			predicted_outcome = local_predicted_outcome;
	end
assign global_predicted_outcome_out = global_predicted_outcome;
assign local_predicted_outcome_out = local_predicted_outcome;
assign predicted_outcome_idx = idx;

	endmodule: tournament_predictor