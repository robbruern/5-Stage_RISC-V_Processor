`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
    input rst,
   
	 //signals to load registers
	 input logic load_pc,
    input logic load_reg,
    input logic load_regfile,
	 
	 //I-Cache Data
    input rv32i_word instruction,
    output rv32i_word instruction_address,
 	 
	 //D-Cache
	 output rv32i_word data_address,
	 
		//From control
	 input logic c_data_write,
	 input logic c_data_read,
		//To D-cache
		output logic data_read,
		output logic data_write,
	
	 output rv32i_word write_data,
	 input rv32i_word read_data,
	 
	 //Mask
	 input rv32i_mem_wmask mem_byte_enable,
	 output rv32i_mem_wmask mem_wmask,
	 
	 //mem
	 output logic mem_out,
	 input logic mem_in,
	 
	 //muxes responsible for using data
	 input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input cmpmux::cmpmux2_sel_t cmpmux_sel,
    
	 //ALU and CMP control
	 input alu_ops aluop,
	 input branch_funct3_t cmpop,
	 
	 input logic br_in1,
	 output logic br_out1,
	 
	 //Things used in control for decoding and branching
	 output logic cmp_out,
	 output rv32i_opcode opcode,
	 output logic [2:0] funct3,
	 output logic [6:0] funct7,
	 
	 output logic [4:0] if_id_rs1_out,
    output logic [4:0] if_id_rs2_out,
	 output logic [4:0] if_id_rd_out,
	 
	 output logic [1:0] if_id_alignment,
	 
	 input logic using_rs1,
	 input logic using_rs2,
	 
	 input logic branch_wrong,
	 output logic stall_out,
	 
	 output logic predicted_outcome_out,
	 output logic ex_mem_predicted_outcome,
	 
	 input logic branch_update,
	 output logic branch_read_out,
	 
	 input logic jump,
	 output logic ex_mem_jump,
	 input logic jump_wrong

);


/******************* Random Outputs I Don't Know What they are for *************************/
logic g_p_outcome;// goes into if_id_reg
logic l_p_outcome; //goes into if_id_reg
logic [9:0] l_p_idx; //goes into if_id_reg
logic [9:0] g_p_idx; //goes into if_id_reg
logic [9:0] p_idx;
logic predicted_outcome;

logic if_id_g_p_outcome;// goes into if_id_reg
logic if_id_l_p_outcome; //goes into if_id_reg
logic [9:0] if_id_l_p_idx; //goes into if_id_reg
logic [9:0] if_id_g_p_idx; //goes into if_id_reg
logic [9:0] if_id_p_idx;
logic if_id_p_outcome;

logic id_ex_g_p_outcome;// goes into if_id_reg
logic id_ex_l_p_outcome; //goes into if_id_reg
logic [9:0] id_ex_l_p_idx; //goes into if_id_reg
logic [9:0] id_ex_g_p_idx; //goes into if_id_reg
logic [9:0] id_ex_p_idx;
logic id_ex_p_outcome;

logic ex_mem_g_p_outcome;// goes into if_id_reg
logic ex_mem_l_p_outcome; //goes into if_id_reg
logic [9:0] ex_mem_l_p_idx; //goes into if_id_reg
logic [9:0] ex_mem_g_p_idx; //goes into if_id_reg
logic [9:0] ex_mem_p_idx;
logic ex_mem_p_outcome;

logic id_ex_jump;





//Mux stuff

pcmux::pcmux_sel_t id_ex_pcmux_sel_out;
pcmux::pcmux_sel_t ex_mem_pcmux_sel_out;

cmpmux::cmpmux1_sel_t cmpmux1_sel;
cmpmux::cmpmux2_sel_t cmpmux2f_sel;
alumux::alumux1_sel_t alumux1f_sel;
alumux::alumux2_sel_t alumux2f_sel;
memmux::memmux1_sel_t memmux1_sel;
memmux::memmux2_sel_t memmux2_sel;
decodemux::decodemux_sel_t decodemux1_sel;
decodemux::decodemux_sel_t decodemux2_sel;

cmpmux::cmpmux2_sel_t cmpmux2final_sel;
alumux::alumux1_sel_t alumux1final_sel;
alumux::alumux2_sel_t alumux2final_sel;

logic alumux1_forward;
logic alumux2_forward;
logic cmpmux2_forward;

logic id_ex_using_rs1;
logic id_ex_using_rs2;

logic stall;

logic branch_read;





//outputs of if_id register, deosnt include funct3, funct7, and opcode
 rv32i_word  if_id_i_imm;
 rv32i_word  if_id_s_imm;
 rv32i_word  if_id_b_imm;
 rv32i_word  if_id_u_imm;
 rv32i_word  if_id_j_imm;
 
 rv32i_reg if_id_rs1;
 rv32i_reg if_id_rs2;
 rv32i_reg if_id_rd;
 
 rv32i_word if_id_pc_out;
 
 
 //outputs of id_ex register
 rv32i_word  id_ex_i_imm;
 rv32i_word  id_ex_s_imm;
 rv32i_word  id_ex_b_imm;
 rv32i_word  id_ex_u_imm;
 rv32i_word  id_ex_j_imm;
 
 rv32i_reg id_ex_rs1;
 rv32i_reg id_ex_rs2;
 rv32i_reg id_ex_rd;
 
 rv32i_word id_ex_pc_out;
 
 rv32i_word id_ex_rs1_data;
 rv32i_word id_ex_rs2_data;
 
	// WB Control
	logic id_ex_reg_write_out;
	regfilemux::regfilemux_sel_t id_ex_reg_sel_out;
	// EX Control
	alumux::alumux1_sel_t id_ex_ALU_sel_1_out;
	alumux::alumux2_sel_t id_ex_ALU_sel_2_out;
	alu_ops id_ex_ALU_op_out;
	branch_funct3_t id_ex_CMP_op_out;
	// MEM Control
	logic id_ex_mem_write_out;
	logic id_ex_mem_out;
	logic id_ex_mem_read_out;
	rv32i_mem_wmask id_ex_mask_out;
 
 
 //outputs of ex_mem regsiter
 rv32i_word  ex_mem_i_imm;
 rv32i_word  ex_mem_s_imm;
 rv32i_word  ex_mem_b_imm;
 rv32i_word  ex_mem_u_imm;
 rv32i_word  ex_mem_j_imm;
 
 rv32i_reg ex_mem_rs1;
 rv32i_reg ex_mem_rs2;
 rv32i_reg ex_mem_rd;
 
 rv32i_word ex_mem_rs2_data;
 
	// WB Control
	logic ex_mem_reg_write_out;
	regfilemux::regfilemux_sel_t ex_mem_reg_sel_out;
	// MEM Control
	logic ex_mem_mem_write_out;
	logic ex_mem_mem_read_out;
	rv32i_mem_wmask ex_mem_mask_out;
 
 
 rv32i_word ex_mem_pc_out;
 
 rv32i_word ex_mem_alu_data_out;
 logic ex_mem_br_en_out;

 
 
 //outputs of mem_wb register
 rv32i_word  mem_wb_u_imm;
 
 rv32i_word mem_wb_alu_data_out;
 logic mem_wb_br_en;

	// WB Control
	logic mem_wb_reg_write_out;
	regfilemux::regfilemux_sel_t mem_wb_reg_sel_out;
 
logic [0:4] mem_wb_rd;
 
 rv32i_word mem_wb_pc_out;
 
 rv32i_word mem_wb_read_data;//from D cache

 //Fetch Stage
 rv32i_word pc_out;//used for output of pc
 
 //Decode Stage
 rv32i_word rs1_data;
 rv32i_word rs2_data;
 
 rv32i_word rs1_data_mux_out;
 rv32i_word rs2_data_mux_out;

 //Execute Stage
 rv32i_word alu_out;
 rv32i_word alumux_out1;
 rv32i_word alumux_out2;
 rv32i_word cmpmux_out1;
 rv32i_word cmpmux_out2;
 logic br_en;
 logic id_ex_br_out;
 //Memory Stage
 rv32i_word pcmux_out;
 rv32i_word read_data_aligned;
 rv32i_word memmux1_out;
 rv32i_word memmux2_out;
 cmpmux::cmpmux2_sel_t id_ex_cmpmux2_sel;
 //Writeback Stage
 rv32i_word regfilemux_out;
 
 //funct3
 logic [2:0] id_ex_funct3;
 logic [2:0] ex_mem_funct3;
 
 logic [2:0] funct3_temp;
 
 

// Outputs to D-cache
assign mem_wmask = ex_mem_mask_out;
assign data_read = ex_mem_mem_read_out;
assign data_write = ex_mem_mem_write_out;
//Random assigns that are needed for output/input of datapath module
assign cmp_out = ex_mem_br_en_out;
assign instruction_address = pc_out;
//assign write_data = ex_mem_rs2;
assign data_address = ex_mem_alu_data_out;

assign if_id_rs1_out = if_id_rs1;
assign if_id_rs2_out = if_id_rs2;
assign if_id_rd_out = if_id_rd;

assign funct3_temp = funct3;

assign if_id_alignment = pc_out[1:0];

assign stall_out = stall;
assign branch_read_out = branch_read;
/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor

pc_register PC(
	    .clk(clk),
		 .rst(rst),
       .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

if_id_register IF_ID_REGISTER(
		 .clk(clk),
		 .rst(rst || branch_wrong || jump_wrong),
		 .load(load_reg && ~branch_wrong && ~stall && ~jump_wrong),
		 .instruction(instruction),
		 .address_in(pc_out),
		 
		 
		 
		 .rs1(if_id_rs1),
		 .rs2(if_id_rs2),
		 .rd(if_id_rd),
		 
		 .address_out(if_id_pc_out),
		 .opcode(opcode),
		 .funct3(funct3),
		 .funct7(funct7),
		 
		 
		 
		 .i_imm(if_id_i_imm),
		 .s_imm(if_id_s_imm),
		 .b_imm(if_id_b_imm),
		 .u_imm(if_id_u_imm),
		 .j_imm(if_id_j_imm),
		 
		 .g_p_outcome_in(g_p_outcome),// goes into if_id_reg
		 .l_p_outcome_in(l_p_outcome), //goes into if_id_reg
	    .l_p_idx_in(l_p_idx), //goes into if_id_reg
		 .g_p_idx_in(g_p_idx), //goes into if_id_reg
		 .p_idx_in(p_idx),
		 .p_outcome_in(predicted_outcome),
		 
		.if_id_g_p_outcome(if_id_g_p_outcome),// goes into if_id_reg
		.if_id_l_p_outcome(if_id_l_p_outcome), //goes into if_id_reg
		.if_id_l_p_idx(if_id_l_p_idx), //goes into if_id_reg
		.if_id_g_p_idx(if_id_g_p_idx), //goes into if_id_reg
		.if_id_p_idx(if_id_p_idx),
		.if_id_p_outcome(if_id_p_outcome)
		 

);

regfile REGFILE(
	    .clk(clk),
		 .rst(rst),
       .load(load_reg && mem_wb_reg_write_out),
		 .in(regfilemux_out),
		 .src_a(if_id_rs1), 
		 .src_b(if_id_rs2), 
		 .dest(mem_wb_rd),
		 .reg_a(rs1_data), 
		 .reg_b(rs2_data)
);

id_ex_register ID_EX_REGISTER(
	.clk(clk),
	.rst(rst || branch_wrong || jump_wrong),
	.load(load_reg && ~branch_wrong && ~stall && ~jump_wrong),

	.address_in(if_id_pc_out),
	.rs1_data_in(rs1_data_mux_out),
	.rs2_data_in(rs2_data_mux_out),
	
	.rs1_in(if_id_rs1),
	.rs2_in(if_id_rs2),
	.rd_in(if_id_rd),
	
	//WB Control
	.reg_write_in(load_regfile),
	.reg_sel_in(regfilemux_sel),
	// EX Control
	.pcmux_sel_in(pcmux_sel),
	.ALU_sel_1_in(alumux1_sel),
	.ALU_sel_2_in(alumux2_sel),
	.ALU_op_in(aluop),
	.CMP_op_in(cmpop),
	.cmpmux_sel_in(cmpmux_sel),
	// MEM Control
	.mem_write_in(c_data_write),
	.mem_read_in(c_data_read),
	.mask_in(mem_byte_enable),
	
	.funct3_in(funct3_temp),
	
	// WB Control
	.reg_write_out(id_ex_reg_write_out),
	.reg_sel_out(id_ex_reg_sel_out),
	// EX Control
	.pcmux_sel_out(id_ex_pcmux_sel_out),
	.ALU_sel_1_out(id_ex_ALU_sel_1_out),
	.ALU_sel_2_out(id_ex_ALU_sel_2_out),
	.ALU_op_out(id_ex_ALU_op_out),
	.CMP_op_out(id_ex_CMP_op_out),
	.cmpmux_sel_out(id_ex_cmpmux2_sel),
	// MEM Control
	.mem_write_out(id_ex_mem_write_out),
	.mem_read_out(id_ex_mem_read_out),
	.mask_out(id_ex_mask_out),
	.mem_in(mem_in),
	.mem_out(id_ex_mem_out),
	.br_in(br_in1),
	.br_out(id_ex_br_out),
	
	
	.i_imm_in(if_id_i_imm),
   .s_imm_in(if_id_s_imm),
   .b_imm_in(if_id_b_imm),
   .u_imm_in(if_id_u_imm),
   .j_imm_in(if_id_j_imm),
	
	.i_imm_out(id_ex_i_imm),
   .s_imm_out(id_ex_s_imm),
   .b_imm_out(id_ex_b_imm),
   .u_imm_out(id_ex_u_imm),
   .j_imm_out(id_ex_j_imm),
	
	.rs1_data_out(id_ex_rs1_data),
	.rs2_data_out(id_ex_rs2_data),
	
	.rs1_out(id_ex_rs1),
	.rs2_out(id_ex_rs2),
	.rd_out(id_ex_rd),
	
	.address_out(id_ex_pc_out),
	
	.funct3_out(id_ex_funct3),
	
	.using_rs1_in(using_rs1),
	.using_rs2_in(using_rs2),
	
	.using_rs1_out(id_ex_using_rs1),
	.using_rs2_out(id_ex_using_rs2),
	
	.if_id_g_p_outcome(if_id_g_p_outcome),// goes into if_id_reg
	.if_id_l_p_outcome(if_id_l_p_outcome), //goes into if_id_reg
	.if_id_l_p_idx(if_id_l_p_idx), //goes into if_id_reg
	.if_id_g_p_idx(if_id_g_p_idx), //goes into if_id_reg
	.if_id_p_idx(if_id_p_idx), 
	.if_id_p_outcome(if_id_p_outcome),
	
	.id_ex_g_p_outcome(id_ex_g_p_outcome),// goes into if_id_reg
	.id_ex_l_p_outcome(id_ex_l_p_outcome), //goes into if_id_reg
	.id_ex_l_p_idx(id_ex_l_p_idx), //goes into if_id_reg
	.id_ex_g_p_idx(id_ex_g_p_idx), //goes into if_id_reg
	.id_ex_p_idx(id_ex_p_idx),
	.id_ex_p_outcome(id_ex_p_outcome),
	
	.jumpin(jump),
	.jumpout(id_ex_jump)
);

ex_mem_register EX_MEM_REGISTER(
	.clk(clk),
	.rst(rst),
	.stall(stall),
	.load(load_reg && ~branch_wrong && ~jump_wrong),

	.address_in(id_ex_pc_out),
	.alu_data_in(alu_out),
	.br_en_in(br_en),
	
	.i_imm_in(id_ex_i_imm),
   .s_imm_in(id_ex_s_imm),
   .b_imm_in(id_ex_b_imm),
   .u_imm_in(id_ex_u_imm),
   .j_imm_in(id_ex_j_imm),
	
	.rs1_in(id_ex_rs1),
	.rs2_in(id_ex_rs2),
	.rd_in(id_ex_rd),
	.rs2_data_in(memmux1_out),
	
	//WB Control
	.reg_write_in(id_ex_reg_write_out),
	.reg_sel_in(id_ex_reg_sel_out),
	// MEM Control
	.pcmux_sel_in(id_ex_pcmux_sel_out),
	.mem_write_in(id_ex_mem_write_out),
	.mem_read_in(id_ex_mem_read_out),
	.mask_in(id_ex_mask_out),
	
	.funct3_in(id_ex_funct3),
	
	// WB Control
	.reg_write_out(ex_mem_reg_write_out),
	.reg_sel_out(ex_mem_reg_sel_out),
	// MEM Control
	.pcmux_sel_out(ex_mem_pcmux_sel_out),
	.mem_write_out(ex_mem_mem_write_out),
	.mem_read_out(ex_mem_mem_read_out),
	.mask_out(ex_mem_mask_out),
	.mem_in(id_ex_mem_out),
	.mem_out(mem_out),
	.br_in(id_ex_br_out),
	.br_out(br_out1),
	
	.i_imm_out(ex_mem_i_imm),
   .s_imm_out(ex_mem_s_imm),
   .b_imm_out(ex_mem_b_imm),
   .u_imm_out(ex_mem_u_imm),
   .j_imm_out(ex_mem_j_imm),
	
	.address_out(ex_mem_pc_out),
	.alu_data_out(ex_mem_alu_data_out),
	.br_en_out(ex_mem_br_en_out),

	.rs2_data_out(ex_mem_rs2_data),
	.rs1_out(ex_mem_rs1),
	.rs2_out(ex_mem_rs2),
	.rd_out(ex_mem_rd),
	
	.funct3_out(ex_mem_funct3),
	
	.id_ex_g_p_outcome(id_ex_g_p_outcome),// goes into if_id_reg
	.id_ex_l_p_outcome(id_ex_l_p_outcome), //goes into if_id_reg
	.id_ex_l_p_idx(id_ex_l_p_idx), //goes into if_id_reg
	.id_ex_g_p_idx(id_ex_g_p_idx), //goes into if_id_reg
	.id_ex_p_idx(id_ex_p_idx),
	.id_ex_p_outcome(id_ex_p_outcome),
	
	.ex_mem_g_p_outcome(ex_mem_g_p_outcome),// goes into if_id_reg
	.ex_mem_l_p_outcome(ex_mem_l_p_outcome), //goes into if_id_reg
	.ex_mem_l_p_idx(ex_mem_l_p_idx), //goes into if_id_reg
	.ex_mem_g_p_idx(ex_mem_g_p_idx), //goes into if_id_reg
	.ex_mem_p_idx(ex_mem_p_idx),
	.ex_mem_p_outcome(ex_mem_predicted_outcome),
	
	.jumpin(id_ex_jump),
	.jumpout(ex_mem_jump)
);


aligner_store ALIGNER_STORE(
 .clk(clk),
 .rst(rst),

.funct3(ex_mem_funct3),
.store_data_in(memmux2_out),
.mem_byte_enable(ex_mem_mask_out),

.store_data_out(write_data)
);


aligner_load ALIGNER_LOAD(
	.clk(clk),
	.rst(rst),
	
	.funct3(ex_mem_funct3),
	.alignment(ex_mem_alu_data_out[1:0]),
	
	.load_data_in(read_data),
	
	.load_data_out(read_data_aligned)
);
//Add rs1, rs2

mem_wb_register MEM_WB_REGISTER(
	.clk(clk),
	.rst(rst),
	.load(load_reg),
	
	.address_in(ex_mem_pc_out),
	.read_data_in(read_data_aligned),
	
	.br_en_in(br_en),
	.alu_data_in(ex_mem_alu_data_out),
	.u_imm_in(ex_mem_u_imm),
	
	.rd_in(ex_mem_rd),
	
	//WB Control
	.reg_write_in(ex_mem_reg_write_out),
	.reg_sel_in(ex_mem_reg_sel_out),
	
	// WB Control
	.reg_write_out(mem_wb_reg_write_out),
	.reg_sel_out(mem_wb_reg_sel_out),
	
	.address_out(mem_wb_pc_out),
	.read_data_out(mem_wb_read_data),

	.br_en_out(mem_wb_br_en),
	.alu_data_out(mem_wb_alu_data_out),
	.u_imm_out(mem_wb_u_imm),
	
	.rd_out(mem_wb_rd)
);




/******************************* ALU and CMP *********************************/

//ALU
alu ALU
(
    .aluop(id_ex_ALU_op_out),
    .a(alumux_out1), 
	 .b(alumux_out2),
    .f(alu_out)
);

//CMP
always_comb begin : CMP
	unique case(id_ex_CMP_op_out)
		beq :br_en = (cmpmux_out1 == cmpmux_out2);
		bne :br_en = (cmpmux_out1 != cmpmux_out2);
		2: br_en = ($signed(cmpmux_out1) < $signed(cmpmux_out2));
		3: br_en = (cmpmux_out1 < cmpmux_out2);
		blt :br_en = ($signed(cmpmux_out1) < $signed(cmpmux_out2));
		bge :br_en = ($signed(cmpmux_out1) >= $signed(cmpmux_out2));
		bltu :br_en = (cmpmux_out1 < cmpmux_out2);
		bgeu :br_en = (cmpmux_out1 >= cmpmux_out2);
		default: br_en = 0;
	endcase
end


/*****************************************************************************/



function void set_defaults2();
	begin
	pcmux_out = '0;
	regfilemux_out = '0;
	alumux_out1 = '0;
	alumux_out2 = '0;
	cmpmux_out1 = '0;
	cmpmux_out2 = '0;
	end
endfunction

/******************************** Muxes **************************************/
always_comb begin : MUXES
	
	 
	 //PCMUX
	 set_defaults2();
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = {ex_mem_alu_data_out[31:2], 2'b00};
		  pcmux::ex_mem_pc_plus4: pcmux_out = ex_mem_pc_out + 4;
		  pcmux::fetch_offset: pcmux_out = pc_out + {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        default: `BAD_MUX_SEL;
    endcase
	 
	 //REGMUX
	 unique case (mem_wb_reg_sel_out)
		  regfilemux::alu_out: regfilemux_out = mem_wb_alu_data_out;
		  regfilemux::br_en: regfilemux_out = {{31{1'b0}}, mem_wb_br_en};
		  regfilemux::u_imm: regfilemux_out = mem_wb_u_imm;
		  regfilemux::lw: regfilemux_out = mem_wb_read_data;
		  regfilemux::pc_plus4: regfilemux_out = mem_wb_pc_out + 4;
        default: `BAD_MUX_SEL;
    endcase
	 
	 
	 //ALUMUX1, again need special control for dis,like alumux2
	 unique case (alumux1final_sel)
        alumux::rs1_out: alumux_out1 = id_ex_rs1_data;
		  alumux::pc_out: alumux_out1 = id_ex_pc_out;
		  
		  alumux::ex_mem_u_imm_1: alumux_out1 = ex_mem_u_imm;
		  alumux::ex_mem_br_en_1: alumux_out1 = ex_mem_br_en_out;
		  alumux::ex_mem_pc_plus_4_1: alumux_out1 = ex_mem_pc_out + 4;
		  alumux::ex_mem_alu_out_1: alumux_out1 = ex_mem_alu_data_out;
		  
		  alumux::mem_wb_u_imm_1: alumux_out1 = mem_wb_u_imm;
		  alumux::mem_wb_br_en_1: alumux_out1 = mem_wb_br_en;
		  alumux::mem_wb_pc_plus_4_1: alumux_out1 = mem_wb_pc_out + 4;
		  alumux::mem_wb_alu_out_1: alumux_out1 = mem_wb_alu_data_out;
		  alumux::mem_wb_read_data_1: alumux_out1 = mem_wb_read_data;
        default: `BAD_MUX_SEL;
    endcase
	 
	 //ALUMUX2, need weird control for this
	 //if(forwarding)-> then use forwarding control
	 unique case (alumux2final_sel)
        alumux::i_imm: alumux_out2 = id_ex_i_imm;
		  alumux::u_imm: alumux_out2 = id_ex_u_imm;
		  alumux::b_imm: alumux_out2 = id_ex_b_imm;
		  alumux::s_imm: alumux_out2 = id_ex_s_imm;
		  alumux::j_imm: alumux_out2 = id_ex_j_imm;
		  alumux::rs2_out: alumux_out2 = id_ex_rs2_data;
		  
		  alumux::ex_mem_u_imm_2: alumux_out2 = ex_mem_u_imm;
		  alumux::ex_mem_br_en_2: alumux_out2 = ex_mem_br_en_out;
		  alumux::ex_mem_pc_plus_4_2: alumux_out2 = ex_mem_pc_out + 4;
		  alumux::ex_mem_alu_out_2: alumux_out2 = ex_mem_alu_data_out;
		  
		  alumux::mem_wb_u_imm_2: alumux_out2 = mem_wb_u_imm;
		  alumux::mem_wb_br_en_2: alumux_out2 = mem_wb_br_en;
		  alumux::mem_wb_pc_plus_4_2: alumux_out2 = mem_wb_pc_out + 4;
		  alumux::mem_wb_alu_out_2: alumux_out2 = mem_wb_alu_data_out;
		  alumux::mem_wb_read_data_2: alumux_out2 = mem_wb_read_data;


        default: alumux_out2 = id_ex_i_imm;
    endcase
	 
	//DEOCODEMUX RS1		
	unique case(decodemux1_sel)
		decodemux::mem_wb_u_imm: rs1_data_mux_out = mem_wb_u_imm;
		decodemux::mem_wb_br_en: rs1_data_mux_out = mem_wb_br_en;
		decodemux::mem_wb_pc_plus_4: rs1_data_mux_out = mem_wb_pc_out + 4;
		decodemux::mem_wb_alu_out: rs1_data_mux_out = mem_wb_alu_data_out;
		decodemux::mem_wb_read_data: rs1_data_mux_out = mem_wb_read_data;
		decodemux::register_data: rs1_data_mux_out = rs1_data;
		default: rs1_data_mux_out = mem_wb_u_imm;
	endcase
		
	//DEOCODEMUX RS2		
	unique case(decodemux2_sel)
		decodemux::mem_wb_u_imm: rs2_data_mux_out = mem_wb_u_imm;
		decodemux::mem_wb_br_en: rs2_data_mux_out = mem_wb_br_en;
		decodemux::mem_wb_pc_plus_4: rs2_data_mux_out = mem_wb_pc_out + 4;
		decodemux::mem_wb_alu_out: rs2_data_mux_out = mem_wb_alu_data_out;
		decodemux::mem_wb_read_data: rs2_data_mux_out = mem_wb_read_data;
		decodemux::register_data: rs2_data_mux_out = rs2_data;
		default: rs2_data_mux_out = mem_wb_u_imm;
	endcase
	
	 //We need 2 cmp muxes because we need to forward data into cmp
	 //CMPMUX1(NEW CMPMUX)
	unique case(cmpmux1_sel)
		  cmpmux::rs1_out: cmpmux_out1 = id_ex_rs1_data;
		  cmpmux::ex_mem_u_imm_1: cmpmux_out1 = ex_mem_u_imm;
		  cmpmux::ex_mem_br_en_1: cmpmux_out1 = ex_mem_br_en_out;
		  cmpmux::ex_mem_pc_plus_4_1: cmpmux_out1 = ex_mem_pc_out + 4;
		  cmpmux::ex_mem_alu_out_1: cmpmux_out1 = ex_mem_alu_data_out;
		  cmpmux::mem_wb_u_imm_1: cmpmux_out1 = mem_wb_u_imm;
		  cmpmux::mem_wb_br_en_1: cmpmux_out1 = mem_wb_br_en;
		  cmpmux::mem_wb_pc_plus_4_1: cmpmux_out1 = mem_wb_pc_out + 4;
		  cmpmux::mem_wb_alu_out_1: cmpmux_out1 = mem_wb_alu_data_out;
		  cmpmux::mem_wb_read_data_1: cmpmux_out1 = mem_wb_read_data;
		default: cmpmux_out1 = id_ex_rs1_data;
	endcase
	 
	 //CMPMUX2(original CMPMUX),
	 unique case (cmpmux2final_sel)
        cmpmux::rs2_out: cmpmux_out2 = id_ex_rs2_data;
		  cmpmux::i_imm: cmpmux_out2 = id_ex_i_imm;
		  
		  cmpmux::ex_mem_u_imm_2: cmpmux_out2 = ex_mem_u_imm;
		  cmpmux::ex_mem_br_en_2: cmpmux_out2 = ex_mem_br_en_out;
		  cmpmux::ex_mem_pc_plus_4_2: cmpmux_out2 = ex_mem_pc_out + 4;
		  cmpmux::ex_mem_alu_out_2: cmpmux_out2 = ex_mem_alu_data_out;
		  
		  cmpmux::mem_wb_u_imm_2: cmpmux_out2 = mem_wb_u_imm;
		  cmpmux::mem_wb_br_en_2: cmpmux_out2 = mem_wb_br_en;
		  cmpmux::mem_wb_pc_plus_4_2: cmpmux_out2 = mem_wb_pc_out + 4;
		  cmpmux::mem_wb_alu_out_2: cmpmux_out2 = mem_wb_alu_data_out;
		  cmpmux::mem_wb_read_data_2: cmpmux_out2 = mem_wb_read_data;
        default: cmpmux_out2 = id_ex_rs2_data;
    endcase
	 
	 //MEMMUX2
	 unique case(memmux2_sel)
		memmux::ex_mem_rs2_data: memmux2_out = 	ex_mem_rs2_data;
		memmux::mem_wb_u_imm_2: memmux2_out = mem_wb_u_imm;
		memmux::mem_wb_br_en_2: memmux2_out = mem_wb_br_en;
		memmux::mem_wb_pc_plus_4_2: memmux2_out = mem_wb_pc_out + 4;
		memmux::mem_wb_alu_out_2: memmux2_out = mem_wb_alu_data_out;
		memmux::mem_wb_read_data_2: memmux2_out = mem_wb_read_data;
		default: memmux2_out = 	ex_mem_rs2_data;
	 endcase
	 
	 //MEMMUX1
	 unique case(memmux1_sel)
		memmux::id_ex_rs2_data: memmux1_out = id_ex_rs2_data;
		memmux::mem_wb_u_imm_1: memmux1_out = mem_wb_u_imm;
		memmux::mem_wb_br_en_1: memmux1_out = mem_wb_br_en;
		memmux::mem_wb_pc_plus_4_1: memmux1_out = mem_wb_pc_out + 4;
		memmux::mem_wb_alu_out_1: memmux1_out = mem_wb_alu_data_out;
		memmux::mem_wb_read_data_1: memmux1_out = mem_wb_read_data;
		memmux::ex_mem_u_imm_1: memmux1_out = ex_mem_u_imm;
		memmux::ex_mem_br_en_1: memmux1_out = ex_mem_br_en_out;
		memmux::ex_mem_pc_plus_4_1: memmux1_out = ex_mem_pc_out + 4;
		memmux::ex_mem_alu_out_1: memmux1_out = ex_mem_alu_data_out;
		default: memmux1_out = id_ex_rs2_data;
	 endcase

end

//Forwarding Unit
forwarding_unit FORWARDING_UNIT(
	.clk(clk),
	.rst(rst),
	
	.if_id_rs1(if_id_rs1),
	.if_id_rs2(if_id_rs2),
	.if_id_rd(if_id_rd),
	
	.id_ex_rs1(id_ex_rs1),
	.id_ex_rs2(id_ex_rs2),
	.id_ex_rd(id_ex_rd),
	
	.ex_mem_rs1(ex_mem_rs1),
	.ex_mem_rs2(ex_mem_rs2),
	.ex_mem_rd(ex_mem_rd),
	
	.mem_wb_rd(mem_wb_rd),
	
	.ex_mem_reg_sel(ex_mem_reg_sel_out),
	.ex_mem_reg_write(ex_mem_reg_write_out),
	.mem_wb_reg_sel(mem_wb_reg_sel_out),
	.mem_wb_reg_write(mem_wb_reg_write_out),
	
	.cmpmux1_sel(cmpmux1_sel),
	.cmpmux2_sel(cmpmux2f_sel),
   .alumux1_sel(alumux1f_sel),
   .alumux2_sel(alumux2f_sel),
	.memmux1_sel(memmux1_sel),
	.memmux2_sel(memmux2_sel),
	.decodemux1_sel(decodemux1_sel),
	.decodemux2_sel(decodemux2_sel),
	
	.alumux1_forward(alumux1_forward),
	.alumux2_forward(alumux2_forward),
	.cmpmux2_forward(cmpmux2_forward),
	
	.using_rs1(id_ex_using_rs1),
	.using_rs2(id_ex_using_rs2)
);

always_comb begin
	cmpmux2final_sel = id_ex_cmpmux2_sel;
	alumux1final_sel = id_ex_ALU_sel_1_out;
	alumux2final_sel = id_ex_ALU_sel_2_out;
	if(alumux1_forward && ~id_ex_br_out )
		alumux1final_sel = alumux1f_sel;
	if(alumux2_forward && ~id_ex_br_out)
		alumux2final_sel = alumux2f_sel;
	if(cmpmux2_forward)
		cmpmux2final_sel = cmpmux2f_sel;
end



//DA Stalling Unit
assign stall = ex_mem_mem_read_out && (((ex_mem_rd == id_ex_rs1) && id_ex_using_rs1 && (ex_mem_rd != 0)) || ((ex_mem_rd == id_ex_rs2) && id_ex_using_rs2 && (ex_mem_rd != 0)));

assign predicted_outcome_out = predicted_outcome;



tournament_predictor tournament_predictor(
	.clk(clk),
	.rst(rst),
	
	.idx(pc_out[11:2]), 
	.read(branch_read), //if opcode == branch in fetch state
	.predicted_outcome(predicted_outcome), //make a new pc option
	.predicted_outcome_idx(p_idx), //put into if_id reg
	
	.actual_outcome_idx(ex_mem_p_idx),//get from ex_mem_reg
	.actual_outcome(ex_mem_br_en_out),//ex_mem_br_en
	.write(branch_update),//can only be high one clk cycle, based on br_in and if branch was wrong
	
	//records data used to write later
	.global_predicted_outcome_out(g_p_outcome),// goes into if_id_reg
	.local_predicted_outcome_out(l_p_outcome), //goes into if_id_reg
	.local_predicted_idx_out(l_p_idx), //goes into if_id_reg
	.global_predicted_idx_out(g_p_idx), //goes into if_id_reg
	
	//used to write to each predictor
	.global_predicted_outcome_in(ex_mem_g_p_outcome),//get from ex_mem_reg
	.local_predicted_outcome_in(ex_mem_l_p_outcome), //get from ex_mem_reg 
	.local_actual_idx_in(ex_mem_l_p_idx), //get from ex_mem_reg
	.global_actual_idx_in(ex_mem_g_p_idx) //get from ex_mem_reg
	);
	
always_comb
	begin
		if(instruction[6:0] == op_br)
			branch_read = 1'b1;
		else
			branch_read = 1'b0;
	end

endmodule: datapath