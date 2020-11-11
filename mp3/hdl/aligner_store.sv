import rv32i_types::*;
module aligner_store(
input logic clk,
input logic rst,

input logic [2:0] funct3,
input rv32i_word store_data_in,
input logic [3:0] mem_byte_enable,

output rv32i_word store_data_out
);

always_comb
	begin
		unique case(funct3)
		3'b000: store_data_out = {{8{mem_byte_enable[3]}} & store_data_in[7:0],
										{8{mem_byte_enable[2]}} & store_data_in[7:0],
										{8{mem_byte_enable[1]}} & store_data_in[7:0],
										{8{mem_byte_enable[0]}} & store_data_in[7:0]};
		3'b001: store_data_out = {{16{mem_byte_enable[3]}} & store_data_in[15:0],
										{16{mem_byte_enable[1]}} & store_data_in[15:0]};
		3'b010: store_data_out = store_data_in;
		default: store_data_out = 0;
		endcase
		
	end

endmodule: aligner_store