package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,ex_mem_pc_plus4 = 2'b10
	 ,fetch_offset = 2'b11
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit [3:0] {
    rs2_out = 4'b0000
    ,i_imm = 4'b0001
	 ,ex_mem_u_imm_2 = 4'b0010
	 ,ex_mem_br_en_2 = 4'b0011
	 ,ex_mem_pc_plus_4_2 = 4'b0100
	 ,ex_mem_alu_out_2 = 4'b0101
	 ,mem_wb_u_imm_2 = 4'b0110
	 ,mem_wb_br_en_2 = 4'b0111
	 ,mem_wb_pc_plus_4_2 = 4'b1000
	 ,mem_wb_alu_out_2 = 4'b1001
	 ,mem_wb_read_data_2 = 4'b1010 
} cmpmux2_sel_t;

typedef enum bit [3:0] {
    rs1_out = 4'b0001
	 ,ex_mem_u_imm_1 = 4'b0010
	 ,ex_mem_br_en_1 = 4'b0011
	 ,ex_mem_pc_plus_4_1 = 4'b0100
	 ,ex_mem_alu_out_1 = 4'b0101
	 ,mem_wb_u_imm_1 = 4'b0110
	 ,mem_wb_br_en_1 = 4'b0111
	 ,mem_wb_pc_plus_4_1 = 4'b1000
	 ,mem_wb_alu_out_1 = 4'b1001
	 ,mem_wb_read_data_1 = 4'b1010 
} cmpmux1_sel_t;
endpackage

package alumux;
typedef enum bit [3:0]{
    rs1_out = 4'b0000
    ,pc_out = 4'b0001
	 ,ex_mem_u_imm_1 = 4'b0010
	 ,ex_mem_br_en_1 = 4'b0011
	 ,ex_mem_pc_plus_4_1 = 4'b0100
	 ,ex_mem_alu_out_1 = 4'b0101
	 ,mem_wb_u_imm_1 = 4'b0110
	 ,mem_wb_br_en_1 = 4'b0111
	 ,mem_wb_pc_plus_4_1 = 4'b1000
	 ,mem_wb_alu_out_1 = 4'b1001
	 ,mem_wb_read_data_1 = 4'b1010 
} alumux1_sel_t;

typedef enum bit [3:0] {
    i_imm    = 4'b0000
    ,u_imm   = 4'b0001
    ,b_imm   = 4'b0010
    ,s_imm   = 4'b0011
    ,j_imm   = 4'b0100
    ,rs2_out = 4'b0101
	 ,ex_mem_u_imm_2 = 4'b0110
	 ,ex_mem_br_en_2 = 4'b0111
	 ,ex_mem_pc_plus_4_2 = 4'b1000
	 ,ex_mem_alu_out_2 = 4'b1001
	 ,mem_wb_u_imm_2 = 4'b1010
	 ,mem_wb_br_en_2 = 4'b1011
	 ,mem_wb_pc_plus_4_2 = 4'b1100
	 ,mem_wb_alu_out_2 = 4'b1101
	 ,mem_wb_read_data_2 = 4'b1110 
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage

package decodemux;
typedef enum bit [2:0] {
	mem_wb_u_imm = 3'b000
	,mem_wb_br_en = 3'b001
	,mem_wb_pc_plus_4 = 3'b010
	,mem_wb_alu_out = 3'b011
	,mem_wb_read_data = 3'b100
	,register_data = 3'b101
} decodemux_sel_t;
endpackage

package memmux;
typedef enum bit [2:0] {
	mem_wb_u_imm_2 = 3'b000
	,mem_wb_br_en_2 = 3'b001
	,mem_wb_pc_plus_4_2 = 3'b010
	,mem_wb_alu_out_2 = 3'b011
	,mem_wb_read_data_2 = 3'b100
	,ex_mem_rs2_data = 3'b101
}memmux2_sel_t;

typedef enum bit [3:0] {
	mem_wb_u_imm_1 = 4'b0000
	,mem_wb_br_en_1 = 4'b0001
	,mem_wb_pc_plus_4_1 = 4'b0010
	,mem_wb_alu_out_1 = 4'b0011
	,mem_wb_read_data_1 = 4'b0100
	,id_ex_rs2_data = 4'b0101
	,ex_mem_u_imm_1 = 4'b0110
	,ex_mem_br_en_1 = 4'b0111
	,ex_mem_pc_plus_4_1 = 4'b1000
	,ex_mem_alu_out_1 = 4'b1001
}memmux1_sel_t;
endpackage
