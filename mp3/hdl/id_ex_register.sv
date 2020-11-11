import rv32i_types::*;
module id_ex_register(
	input logic clk,
	input logic rst,
	input logic load,

	input rv32i_word address_in,
	input rv32i_word rs1_data_in,
	input rv32i_word rs2_data_in,
	
	
	input rv32i_word i_imm_in,
   input rv32i_word s_imm_in,
   input rv32i_word b_imm_in,
   input rv32i_word u_imm_in,
   input rv32i_word j_imm_in,
	
	input logic [4:0] rs1_in,
	input logic [4:0] rs2_in,
	input logic [4:0] rd_in,
	
	input logic [2:0] funct3_in,
	
	
	//Ctrl signals 
	// WB Control
	input logic reg_write_in,
	input regfilemux::regfilemux_sel_t reg_sel_in,
//	input logic pcmux_sel_in,
	// EX Control
	input alumux::alumux1_sel_t ALU_sel_1_in,
	input alumux::alumux2_sel_t ALU_sel_2_in,
	input alu_ops ALU_op_in,
	input branch_funct3_t CMP_op_in,
	input cmpmux::cmpmux2_sel_t cmpmux_sel_in,
	input pcmux::pcmux_sel_t pcmux_sel_in,
	// MEM Control
	input logic mem_write_in,
	input logic mem_read_in,
	input rv32i_mem_wmask mask_in,
	input logic mem_in,
	input logic br_in,
	
	// WB Control
//	output logic pcmux_sel_out,
	output logic reg_write_out,
	output regfilemux::regfilemux_sel_t reg_sel_out,
	// EX Control
	output alumux::alumux1_sel_t ALU_sel_1_out,
	output alumux::alumux2_sel_t ALU_sel_2_out,
	output alu_ops ALU_op_out,
	output branch_funct3_t CMP_op_out,
	output cmpmux::cmpmux2_sel_t cmpmux_sel_out,
	output pcmux::pcmux_sel_t pcmux_sel_out,
	// MEM Control
	output logic mem_write_out,
	output logic mem_read_out,
	output rv32i_mem_wmask mask_out,
	output logic mem_out,
	output logic br_out,
	
	output rv32i_word i_imm_out,
   output rv32i_word s_imm_out,
   output rv32i_word b_imm_out,
   output rv32i_word u_imm_out,
   output rv32i_word j_imm_out,
	
	output rv32i_word address_out,
	output rv32i_word rs1_data_out,
	output rv32i_word rs2_data_out,
	
	output logic [4:0] rs1_out,
	output logic [4:0] rs2_out,
	output logic [4:0] rd_out,
	
	output logic [2:0] funct3_out,
	
	input logic using_rs1_in,
	input logic using_rs2_in,
	
	output logic using_rs1_out,
	output logic using_rs2_out,
	
	 input logic if_id_g_p_outcome,// goes into if_id_reg
	 input logic if_id_l_p_outcome, //goes into if_id_reg
	 input logic [9:0] if_id_l_p_idx, //goes into if_id_reg
	 input logic [9:0] if_id_g_p_idx, //goes into if_id_reg
	 input logic [9:0] if_id_p_idx,
	 input logic if_id_p_outcome,
		 
	 output logic id_ex_g_p_outcome,// goes into if_id_reg
	 output logic id_ex_l_p_outcome, //goes into if_id_reg
	 output logic [9:0] id_ex_l_p_idx, //goes into if_id_reg
	 output logic [9:0] id_ex_g_p_idx, //goes into if_id_reg
	 output logic [9:0] id_ex_p_idx,
	 output logic id_ex_p_outcome,
	 
	 input logic jumpin,
	 output logic jumpout
);

rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;

rv32i_word rs1_data;
rv32i_word rs2_data;

rv32i_word address;

logic using_rs1;
logic using_rs2;

logic [2:0] funct3;

logic jump;

	// WB Control
	//logic pcmux_sel;
	logic reg_write;
	regfilemux::regfilemux_sel_t reg_sel;
	// EX Control
	alumux::alumux1_sel_t ALU_sel_1;
	alumux::alumux2_sel_t ALU_sel_2;
	alu_ops ALU_op;
	branch_funct3_t CMP_op;
	pcmux::pcmux_sel_t pcmux_sel;
	cmpmux::cmpmux2_sel_t cmpmux_sel;
	// MEM Control
	logic mem_write;
	logic mem_read;
	rv32i_mem_wmask mask;
	logic mem;
	logic br;

logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;

logic g_p_outcome;// goes into if_id_reg
logic l_p_outcome; //goes into if_id_reg
logic [9:0] l_p_idx; //goes into if_id_reg
logic [9:0] g_p_idx; //goes into if_id_reg
logic [9:0] p_idx;
logic p_outcome;

assign jumpout = jump;
assign id_ex_g_p_outcome = g_p_outcome;
assign id_ex_l_p_outcome = l_p_outcome;
assign id_ex_l_p_idx = l_p_idx; 
assign id_ex_g_p_idx = g_p_idx; 
assign id_ex_p_idx = p_idx;
assign id_ex_p_outcome = p_outcome;

always_comb
	begin
		  i_imm_out = i_imm;
		  s_imm_out = s_imm;
		  b_imm_out = b_imm;
		  u_imm_out = u_imm;
		  j_imm_out = j_imm;
		  
		  address_out = address;
		  
		  using_rs1_out = using_rs1;
		  using_rs2_out = using_rs2;
		  
		  funct3_out = funct3;
		  
		  // WB Control
		  reg_write_out = reg_write;
		  reg_sel_out = reg_sel;
		//  pcmux_sel_out = pcmux_sel;
	     // EX Control
	     ALU_sel_1_out = ALU_sel_1;
	     ALU_sel_2_out = ALU_sel_2;
	     ALU_op_out = ALU_op;
	     CMP_op_out = CMP_op;
		  cmpmux_sel_out = cmpmux_sel;
		  pcmux_sel_out = pcmux_sel;
	     // MEM Control
	     mem_write_out = mem_write;
	     mem_read_out = mem_read;
	     mask_out = mask;
		  mem_out = mem;
		  br_out = br;
		  
		  rs1_out = rs1;
		  rs2_out = rs2;
		  rd_out = rd;
		  
		  rs1_data_out = rs1_data;
		  rs2_data_out = rs2_data;
	end



always_ff @(posedge clk)
begin
    if (rst)
    begin
        i_imm <= '0;
		  s_imm <= '0;
		  b_imm <= '0;
		  u_imm <= '0;
		  j_imm <= '0;
		  
		  address <= '0;
		  
		  using_rs1 <= '0;
		  using_rs2 <= '0;
		  
		  funct3 <= '0;
		  
		  // WB Control
		  reg_write <= '0;
		  reg_sel <= regfilemux::alu_out;
		//  pcmux_sel <= pcmux::pc_plus4;
	     // EX Control
	     ALU_sel_1 <= alumux::rs1_out;
	     ALU_sel_2 <= alumux::i_imm;
	     ALU_op <= alu_add;
	     CMP_op <= beq;
		  cmpmux_sel <= cmpmux::rs2_out;
		  pcmux_sel <= pcmux::pc_plus4;
	     // MEM Control
	     mem_write <= '0;
	     mem_read <= '0;
	     mask <= '0;
		  mem <= '0;
		  br <= '0;
		  
		  rs1 <= '0;
		  rs2 <= '0;
		  rd <= '0;
		  
		  rs1_data <= '0;
		  rs2_data <= '0;
		  
        g_p_outcome <= '0; 
        l_p_outcome <= '0;
        l_p_idx <= '0; 
		  g_p_idx <= '0; 
		  p_idx <= '0;
		  p_outcome <= '0;
		  
		  jump <= '0;
    end
    else if (load == 1)
    begin

	     i_imm <= i_imm_in;
		  s_imm <= s_imm_in;
		  b_imm <= b_imm_in;
		  u_imm <= u_imm_in;
		  j_imm <= j_imm_in;
		  
		  address <= address_in;
		  
		  using_rs1 <= using_rs1_in;
		  using_rs2 <= using_rs2_in;
		  
		  funct3 <= funct3_in;
		  
		  // WB Control
		  reg_write <= reg_write_in;
		  reg_sel <= reg_sel_in;
	//	  pcmux_sel <= pcmux_sel_in;
	     // EX Control
	     ALU_sel_1 <= ALU_sel_1_in;
	     ALU_sel_2 <= ALU_sel_2_in;
	     ALU_op <= ALU_op_in;
	     CMP_op <= CMP_op_in;
		  cmpmux_sel <= cmpmux_sel_in;
		  pcmux_sel <= pcmux_sel_in;
	     // MEM Control
	     mem_write <= mem_write_in;
	     mem_read <= mem_read_in;
	     mask <= mask_in;
		  mem <= mem_in;
		  br <= br_in;
		  
		  rs1 <= rs1_in;
		  rs2 <= rs2_in;
		  rd <= rd_in;
		  
		  rs1_data <= rs1_data_in;
		  rs2_data <= rs2_data_in;
		  
        g_p_outcome <= if_id_g_p_outcome; 
        l_p_outcome <= if_id_l_p_outcome;
        l_p_idx <= if_id_l_p_idx; 
		  g_p_idx <= if_id_g_p_idx; 
		  p_idx <= if_id_p_idx;
		  p_outcome <= if_id_p_outcome;
		  
		  jump <= jumpin;
	 
    end
    else
    begin
	 
	     i_imm <= i_imm;
		  s_imm <= s_imm;
		  b_imm <= b_imm;
		  u_imm <= u_imm;
		  j_imm <= j_imm;
		  
		  address <= address;
		  
		  using_rs1 <= using_rs1;
		  using_rs2 <= using_rs2;
		  
		  funct3 <= funct3;
		  
		  rs1 <= rs1;
		  rs2 <= rs2;
		  rd <= rd;
		  
		  // WB Conrol
		  reg_write <= reg_write;
		  reg_sel <= reg_sel;
		//  pcmux_sel <= pcmux_sel;
	     // EX Control
	     ALU_sel_1 <= ALU_sel_1;
	     ALU_sel_2 <= ALU_sel_2;
	     ALU_op <= ALU_op;
	     CMP_op <= CMP_op;
		  cmpmux_sel <= cmpmux_sel;
		  pcmux_sel <= pcmux_sel;
	     // MEM Control
	     mem_write <= mem_write;
	     mem_read <= mem_read;
	     mask <= mask;
		  mem <= mem;
		  br <= br;
		  
		  rs1_data <= rs1_data;
		  rs2_data <= rs2_data;
		  
        g_p_outcome <= g_p_outcome; 
        l_p_outcome <= l_p_outcome;
        l_p_idx <= l_p_idx; 
		  g_p_idx <= g_p_idx; 
		  p_idx <= p_idx;
		  p_outcome <= p_outcome;
		  
		  jump <= jump;
    end
end


endmodule: id_ex_register