

import rv32i_types::*;

module if_id_register(
	input logic clk,
	input logic rst,
	input logic load,
	input rv32i_word instruction,
	input rv32i_word address_in,
	
	output logic [4:0] rs1,
	output logic [4:0] rs2,
	output logic [4:0] rd,
	
	output rv32i_word address_out,
	output rv32i_opcode opcode,
	output logic [2:0] funct3,
	output logic [6:0] funct7,
	
	 output rv32i_word i_imm,
    output rv32i_word s_imm,
    output rv32i_word b_imm,
    output rv32i_word u_imm,
    output rv32i_word j_imm,
	 
	 input logic g_p_outcome_in,
	 input logic l_p_outcome_in, 
	 input logic [9:0] l_p_idx_in, 
	 input logic [9:0] g_p_idx_in, 
	 input logic [9:0] p_idx_in,
	 input logic p_outcome_in,
		 
	 output logic if_id_g_p_outcome,// goes into if_id_reg
	 output logic if_id_l_p_outcome, //goes into if_id_reg
	 output logic [9:0] if_id_l_p_idx, //goes into if_id_reg
	 output logic [9:0] if_id_g_p_idx, //goes into if_id_reg
	 output logic [9:0] if_id_p_idx,
	 output logic if_id_p_outcome
	 );
	 
	 
logic [31:0] data;
logic [31:0] address;

logic g_p_outcome;// goes into if_id_reg
logic l_p_outcome; //goes into if_id_reg
logic [9:0] l_p_idx; //goes into if_id_reg
logic [9:0] g_p_idx; //goes into if_id_reg
logic [9:0] p_idx;
logic p_outcome;


assign if_id_g_p_outcome = g_p_outcome;
assign if_id_l_p_outcome = l_p_outcome;
assign if_id_l_p_idx = l_p_idx; 
assign if_id_g_p_idx = g_p_idx; 
assign if_id_p_idx = p_idx;
assign if_id_p_outcome = p_outcome;

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]};
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];

assign address_out = address;


always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
		  address <= '0;
		  
        g_p_outcome <= '0; 
        l_p_outcome <= '0;
        l_p_idx <= '0; 
		  g_p_idx <= '0; 
		  p_idx <= '0;
		  p_outcome <= '0;
    end
    else if (load == 1)
    begin
        data <= instruction;
		  address <= address_in;
		  
        g_p_outcome <= g_p_outcome_in; 
        l_p_outcome <= l_p_outcome_in;
        l_p_idx <= l_p_idx_in; 
		  g_p_idx <= g_p_idx_in; 
		  p_idx <= p_idx_in;
		  p_outcome <= p_outcome_in;
    end
    else
    begin
        data <= data;
		  address <= address;
		  
        g_p_outcome <= g_p_outcome; 
        l_p_outcome <= l_p_outcome;
        l_p_idx <= l_p_idx; 
		  g_p_idx <= g_p_idx; 
		  p_idx <= p_idx;
		  p_outcome <= p_outcome;
    end
end

endmodule : if_id_register
