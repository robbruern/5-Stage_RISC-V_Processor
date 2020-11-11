import rv32i_types::*;
module mem_wb_register(
	input logic clk,
	input logic rst,
	input logic load,
	
	input rv32i_word address_in,
	input rv32i_word read_data_in,
	
	input logic br_en_in,
	input rv32i_word alu_data_in,
	input rv32i_word u_imm_in,
	
	input logic [4:0] rd_in,
	
	//Ctrl signals 
	// WB Control
	input logic reg_write_in,
	input regfilemux::regfilemux_sel_t reg_sel_in,
	
	// WB Control
	output logic reg_write_out,
	output regfilemux::regfilemux_sel_t reg_sel_out,
	
	output rv32i_word address_out,
	output rv32i_word read_data_out,

	output logic br_en_out,
	output rv32i_word alu_data_out,
	output rv32i_word u_imm_out,
	
	output logic [4:0] rd_out
);

rv32i_word u_imm;

rv32i_word read_data;

rv32i_word alu_data;
logic br_en;

	// WB Control
	logic reg_write;
	regfilemux::regfilemux_sel_t reg_sel;	

rv32i_word address;

logic [4:0] rd;

always_comb
	begin

		  u_imm_out = u_imm;

		  read_data_out = read_data;
		  
		  address_out = address;
		  
		  // WB Control
		  reg_write_out = reg_write;
		  reg_sel_out = reg_sel;
		  
		  rd_out = rd;
		  
		  alu_data_out = alu_data;
		  br_en_out = br_en;
	end



always_ff @(posedge clk)
begin
    if (rst)
    begin

		  u_imm <= '0;

		  read_data <= '0;
		  
		  address <= '0;
		  
		   // WB Control
		  reg_write <= '0;
		  reg_sel <= regfilemux::alu_out;
		  
		  rd <= '0;
		  
		  alu_data <= '0;
		  br_en <= '0;
		  
    end
    else if (load == 1)
    begin

		  u_imm <= u_imm_in;

		  read_data <= read_data_in;
		  
		  address <= address_in;
		  
		  // WB Control
		  reg_write <= reg_write_in;
		  reg_sel <= reg_sel_in;
		  
		  rd <= rd_in;
	 
		  alu_data <= alu_data_in;
		  br_en <= br_en_in;
    end
    else
    begin
	 
		  u_imm <= u_imm;
		  
		  address <= address;

		  rd <= rd;

		  // WB Control
		  reg_write <= reg_write;
		  reg_sel <= reg_sel;
		  
		  read_data <= read_data;
		  
		  alu_data <= alu_data;
		  br_en <= br_en;
		  
    end
end


endmodule: mem_wb_register