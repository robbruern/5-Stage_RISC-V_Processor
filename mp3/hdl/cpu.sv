import rv32i_types::*;

module cpu
(
    input clk,
    input rst,
    input data_resp,
	 input inst_resp,
    //input rv32i_word mem_rdata,
	 input logic [31:0] inst_rdata,
	 input logic [31:0] data_rdata,
    output logic inst_read,    //We can get rid of these when we inplement our caches
    output logic data_write,   //
	 output logic data_read,    //
    //output logic [3:0] mem_byte_enable,
    //output rv32i_word mem_address,
	 output rv32i_mem_wmask data_mbe, 
	 output logic [31:0] inst_addr,
	 output logic [31:0] data_addr,
	 output logic [31:0] data_wdata
    //output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_regfile;
logic load_reg;

logic using_rs1;
logic using_rs2;

logic [3:0] mem_byte_enable;

rv32i_word mem_wdata; //Think we need a line adapter again

logic br_en;

logic [1:0] twoBmask;
rv32i_word offset;
rv32i_opcode opcode;

logic [2:0] funct3;
logic [6:0] funct7;

logic [4:0] if_id_rs1;
logic [4:0] if_id_rs2;
logic [4:0] if_id_rd;

logic [1:0] if_id_alignment;

logic branch_read;

logic jump;
logic ex_mem_jump;
logic jump_wrong;

//I cache


//D-Cache
logic c_data_read;
logic c_data_write;
//br
logic br_out;
logic br_in;

//mem
logic mem_out;
logic mem_in;

logic branch_wrong;

logic stall;

logic branch_update;
logic predicted_outcome;
logic ex_mem_predicted_outcome;
/*****************************************************************************/

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
cmpmux::cmpmux2_sel_t cmpmux_sel;
alu_ops aluop;
branch_funct3_t cmpop;
/*****************************************************************************/

/* Instantiate MP 1 top level blocks here */


// Keep control named `control` for RVFI Monitor
control control(
    .clk(clk),
    .rst(rst),
	 
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .br_en(br_en),
	 
    .if_id_rs1(if_id_rs1),
    .if_id_rs2(if_id_rs2),
	 .if_id_rd(if_id_rd),
	 .if_id_alignment(if_id_alignment),
	 
	 .br_out(br_out),
	 .br_in(br_in),
	 
    .pcmux_sel(pcmux_sel),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .cmpmux_sel(cmpmux_sel),
	 
    .aluop(aluop),
	 .cmpop(cmpop),
	 
    .load_pc(load_pc),
    .load_reg(load_reg),
    .load_regfile(load_regfile),
	 
	 .data_resp(data_resp),
	 .inst_resp(inst_resp),
	 .inst_read(inst_read),
	 .data_read(c_data_read),
	 .data_write(c_data_write),
	 

	 .mem_byte_enable(mem_byte_enable),
	 .mem_out(mem_out),
	 .mem_in(mem_in),
	 
	 .using_rs1(using_rs1),
	 .using_rs2(using_rs2),
	 
	 .branch_wrong(branch_wrong),
	 .stall(stall),
	 .branch_update(branch_update),
	 .predicted_outcome(predicted_outcome),
	 .ex_mem_predicted_outcome(ex_mem_predicted_outcome),
	 .branch_read(branch_read),
	 .jump(jump),
	 .ex_mem_jump(ex_mem_jump),
	 .jump_wrong(jump_wrong)
);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(
	 .clk(clk),
    .rst(rst),
   
	 //signals to load registers
	 .load_pc(load_pc),
    .load_reg(load_reg),
    .load_regfile(load_regfile),
	 
	 //I-Cache Data
    .instruction(inst_rdata),
    .instruction_address(inst_addr),
 	 
	 //D-Cache
	 .data_address(data_addr),
	 .c_data_read(c_data_read),
	 .c_data_write(c_data_write),
	 .data_read(data_read),
	 .data_write(data_write),
	 .write_data(data_wdata),
	 .read_data(data_rdata),
	 //mem
	 .mem_out(mem_in),
	 .mem_in(mem_out),

	 //br
	 .br_out1(br_in),
	 .br_in1(br_out),
	 
	 //Mask
	 .mem_wmask(data_mbe),
	 .mem_byte_enable(mem_byte_enable),
	 
	 //muxes responsible for using data
	 .pcmux_sel(pcmux_sel),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .cmpmux_sel(cmpmux_sel),
    
	 //ALU and CMP control
	 .aluop(aluop),
	 .cmpop(cmpop),
	 
	 //Things used in control for decoding and branching
	 .cmp_out(br_en),
	 .opcode(opcode),
	 .funct3(funct3),
	 .funct7(funct7),
	 
	 //some registers needed later in forwarding
	 .if_id_rs1_out(if_id_rs1),
    .if_id_rs2_out(if_id_rs2),
	 .if_id_rd_out(if_id_rd),
	 .if_id_alignment(if_id_alignment),
	 
	 .using_rs1(using_rs1),
	 .using_rs2(using_rs2),
	 
	 .branch_wrong(branch_wrong),
	 .stall_out(stall),
	 .branch_update(branch_update),
	 .predicted_outcome_out(predicted_outcome),
	 .ex_mem_predicted_outcome(ex_mem_predicted_outcome),
	 .branch_read_out(branch_read),
	 .jump(jump),
	 .ex_mem_jump(ex_mem_jump),
	 .jump_wrong(jump_wrong)
);

endmodule : cpu
