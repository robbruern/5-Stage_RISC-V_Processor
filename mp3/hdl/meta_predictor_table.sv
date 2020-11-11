module meta_predictor_table(
	input clk,
	input rst,
	
	//All used to read state of table
	input logic [9:0] idx, //index into predictor table
	input logic read, //valid if a read into the table is valid
	
	output logic predicted_outcome,
	
	//Used to update state of table
	input logic global_outcome,
	input logic local_outcome,
	input logic [9:0] actual_outcome_idx,
	input logic write
);
//reads are output continously
//writes happen on a clk cycle, CAN ONLY WRITE ONCE PER BRANCH!!
//Initally set every state to 01, weak not taken

logic [1:0] ptable [1024];
logic [1:0] read_state;
logic [1:0] write_state;



always_comb 
	begin
	write_state = 2'b00;
	read_state = 2'b00;
	predicted_outcome = '0;
	if(read)
		begin
			read_state = ptable[idx];
			predicted_outcome = read_state[1];
		end
	
	if(write)
			write_state = ptable[actual_outcome_idx];
			if((write_state == 2'b11) && (global_outcome == 1'b1))
				write_state = 2'b11;
			else if((write_state == 2'b11) && (global_outcome == 1'b0) && (local_outcome == 1'b1))
				write_state = 2'b10;
			else if((write_state == 2'b10) && (global_outcome == 1'b1) && (local_outcome == 1'b0))
				write_state = 2'b11;
			else if((write_state == 2'b10) && (global_outcome == 1'b0) && (local_outcome == 1'b1))
				write_state = 2'b01;
			else if((write_state == 2'b01) && (global_outcome == 1'b1) && (local_outcome == 1'b0))
				write_state = 2'b10;
			else if((write_state == 2'b01) && (global_outcome == 1'b0) && (local_outcome == 1'b1))
				write_state = 2'b00;
			else if((write_state == 2'b00) && (global_outcome == 1'b1) && (local_outcome == 1'b0))
				write_state = 2'b01;
			else if((write_state == 2'b00) && (local_outcome == 1'b1))
				write_state = 2'b00;		
			end

always_ff @(posedge clk)
begin
	 if (rst)
    begin
        for (int i=0; i<1024; i=i+1) begin
            ptable[i] <= 2'b01;
        end
    end
	 else
		if(write)
			ptable[actual_outcome_idx] <= write_state;
end

endmodule: meta_predictor_table