module global_predictor(
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
	
logic [9:0] global_shift_reg;
logic [9:0] global_shift_reg_out;


always_comb
	begin
		global_shift_reg_out = global_shift_reg;
	end
	
always_ff @(posedge clk)
	begin
		if(rst)
			global_shift_reg <= '0;
		else
			begin
			if(write)
				global_shift_reg <= {global_shift_reg[8:0], actual_outcome};
			else
				global_shift_reg <= global_shift_reg;
			end
	end
	
	
predictor_table predictor_table(
	.clk(clk),
	.rst(rst),
	.idx(idx ^ global_shift_reg_out),
	.read(read),
	.predicted_outcome(predicted_outcome),
	.actual_outcome(actual_outcome),
	.actual_outcome_idx(actual_outcome_idx),
	.write(write)
);

assign predicted_outcome_idx = idx ^ global_shift_reg_out;

	
	
	endmodule: global_predictor