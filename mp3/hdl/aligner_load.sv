import rv32i_types::*;
module aligner_load(
	input logic clk,
	input logic rst,
	
	input logic [2:0] funct3,
	input logic [1:0] alignment,
	
	input rv32i_word load_data_in,
	
	output rv32i_word load_data_out
);

always_comb
	begin
		unique case(funct3)
		//lb  
		3'b000:
			begin
				unique case(alignment)
					2'b00: load_data_out = {{24{load_data_in[7]}},load_data_in[7:0]};
					2'b01: load_data_out = {{24{load_data_in[15]}},load_data_in[15:8]};
					2'b10: load_data_out = {{24{load_data_in[23]}},load_data_in[23:16]};
					2'b11: load_data_out = {{24{load_data_in[31]}},load_data_in[31:24]};
					default: load_data_out = 0;
					endcase
			end
			
		//lh  
		3'b001:
			begin
				unique case(alignment)
					2'b00: load_data_out = {{16{load_data_in[15]}},load_data_in[15:0]};
					2'b10: load_data_out = {{16{load_data_in[31]}},load_data_in[31:16]};
				default: load_data_out = 0;
				endcase
			end
			
		//lw  
		3'b010:
			begin
				load_data_out = load_data_in;
			end
			
		//lbu  
		3'b100:
			begin
				unique case(alignment)
					2'b00: load_data_out = {24'h000000,load_data_in[7:0]};
					2'b01: load_data_out = {24'h000000,load_data_in[15:8]};
					2'b10: load_data_out = {24'h000000,load_data_in[23:16]};
					2'b11: load_data_out = {24'h000000,load_data_in[31:24]};
				default: load_data_out = 0;
			endcase	
			end
			
		//lhu 
		3'b101:
			begin
				unique case(alignment)
					2'b00: load_data_out = {16'h0000,load_data_in[15:0]};
					2'b10: load_data_out = {16'h0000,load_data_in[31:16]};
				default: load_data_out = 0;
				endcase
			end
			
		
		default: load_data_out = 0;
		endcase
	end
	
endmodule : aligner_load