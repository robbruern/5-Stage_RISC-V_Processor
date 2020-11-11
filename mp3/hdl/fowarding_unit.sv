import rv32i_types::*;

module forwarding_unit(
	input clk,
	input rst,
	
	input logic using_rs1,
	input logic using_rs2,
	
	input rv32i_reg if_id_rs1,
	input rv32i_reg if_id_rs2,
	input rv32i_reg if_id_rd,
	
	input rv32i_reg id_ex_rs1,
	input rv32i_reg id_ex_rs2,
	input rv32i_reg id_ex_rd,
	
	input rv32i_reg ex_mem_rs1,
	input rv32i_reg ex_mem_rs2,
	input rv32i_reg ex_mem_rd,
	
	input rv32i_reg mem_wb_rd,
	
	input regfilemux::regfilemux_sel_t ex_mem_reg_sel,
								  input logic ex_mem_reg_write,
	input regfilemux::regfilemux_sel_t mem_wb_reg_sel,
								  input logic mem_wb_reg_write,
	
	output cmpmux::cmpmux1_sel_t cmpmux1_sel,
	output cmpmux::cmpmux2_sel_t cmpmux2_sel,
   output alumux::alumux1_sel_t alumux1_sel,
   output alumux::alumux2_sel_t alumux2_sel,
	output memmux::memmux1_sel_t memmux1_sel,
	output memmux::memmux2_sel_t memmux2_sel,
	output decodemux::decodemux_sel_t decodemux1_sel,
	output decodemux::decodemux_sel_t decodemux2_sel,
	
	output logic alumux1_forward,
	output logic alumux2_forward,
	output logic cmpmux2_forward
);

function void set_defaults();
alumux1_forward = 1'b0;
alumux2_forward = 1'b0;
cmpmux2_forward = 1'b0;

cmpmux1_sel = cmpmux::rs1_out;
cmpmux2_sel = cmpmux::ex_mem_u_imm_2;
alumux1_sel = alumux::ex_mem_u_imm_1;
alumux2_sel = alumux::ex_mem_u_imm_2;
memmux1_sel = memmux::id_ex_rs2_data;
memmux2_sel = memmux::ex_mem_rs2_data;
decodemux1_sel = decodemux::register_data;
decodemux2_sel = decodemux::register_data;
endfunction

//double check, might be missing a forwarding path
always_comb begin
	set_defaults();
	//forwarding to alu
	//forwarding rs1
		if(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1) && using_rs1)
			begin
				alumux1_forward = 1'b1;
				unique case(ex_mem_reg_sel)
					regfilemux::alu_out: alumux1_sel = alumux::ex_mem_alu_out_1;
					regfilemux::br_en: alumux1_sel = alumux::ex_mem_br_en_1;
					regfilemux::u_imm: alumux1_sel = alumux::ex_mem_u_imm_1;
					regfilemux::pc_plus4: alumux1_sel = alumux::ex_mem_pc_plus_4_1;
					default:;
				endcase
			end
		else if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1) && using_rs1)
			begin
				alumux1_forward = 1'b1;
				unique case(mem_wb_reg_sel)
					regfilemux::alu_out: alumux1_sel = alumux::mem_wb_alu_out_1;
					regfilemux::br_en: alumux1_sel = alumux::mem_wb_br_en_1;
					regfilemux::u_imm: alumux1_sel = alumux::mem_wb_u_imm_1;
					regfilemux::pc_plus4: alumux1_sel = alumux::mem_wb_pc_plus_4_1;
					regfilemux::lw: alumux1_sel = alumux::mem_wb_read_data_1;
					default:;
				endcase
			end
		//forwarding rs2
		if(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2) && using_rs2)
			begin
				alumux2_forward = 1'b1;
				unique case(ex_mem_reg_sel)
					regfilemux::alu_out: alumux2_sel = alumux::ex_mem_alu_out_2;
					regfilemux::br_en: alumux2_sel = alumux::ex_mem_br_en_2;
					regfilemux::u_imm: alumux2_sel = alumux::ex_mem_u_imm_2;
					regfilemux::pc_plus4: alumux2_sel = alumux::ex_mem_pc_plus_4_2;
					default:;
				endcase
			end
		else if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2) && using_rs2)
			begin
				alumux2_forward = 1'b1;
				unique case(mem_wb_reg_sel)
					regfilemux::alu_out: alumux2_sel = alumux::mem_wb_alu_out_2;
					regfilemux::br_en: alumux2_sel = alumux::mem_wb_br_en_2;
					regfilemux::u_imm: alumux2_sel = alumux::mem_wb_u_imm_2;
					regfilemux::pc_plus4: alumux2_sel = alumux::mem_wb_pc_plus_4_2;
					regfilemux::lw: alumux2_sel = alumux::mem_wb_read_data_2;
					default:;
				endcase
			end
		
	
	//fowarding to cmp
		if(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
			begin
				unique case(ex_mem_reg_sel)
					regfilemux::alu_out: cmpmux1_sel = cmpmux::ex_mem_alu_out_1;
					regfilemux::br_en: cmpmux1_sel = cmpmux::ex_mem_br_en_1;
					regfilemux::u_imm: cmpmux1_sel = cmpmux::ex_mem_u_imm_1;
					regfilemux::pc_plus4: cmpmux1_sel = cmpmux::ex_mem_pc_plus_4_1;
					default:;
				endcase
			end
		else if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1))
			begin
				unique case(mem_wb_reg_sel)
					regfilemux::alu_out: cmpmux1_sel = cmpmux::mem_wb_alu_out_1;
					regfilemux::br_en: cmpmux1_sel = cmpmux::mem_wb_br_en_1;
					regfilemux::u_imm: cmpmux1_sel = cmpmux::mem_wb_u_imm_1;
					regfilemux::pc_plus4: cmpmux1_sel = cmpmux::mem_wb_pc_plus_4_1;
					regfilemux::lw: cmpmux1_sel = cmpmux::mem_wb_read_data_1;
					default:;
				endcase
			end
		//forwarding rs2
		if(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2) && using_rs2)
			begin
				cmpmux2_forward = 1'b1;
				unique case(ex_mem_reg_sel)
					regfilemux::alu_out: cmpmux2_sel = cmpmux::ex_mem_alu_out_2;
					regfilemux::br_en: cmpmux2_sel = cmpmux::ex_mem_br_en_2;
					regfilemux::u_imm: cmpmux2_sel = cmpmux::ex_mem_u_imm_2;
					regfilemux::pc_plus4: cmpmux2_sel = cmpmux::ex_mem_pc_plus_4_2;
					default:;
				endcase
			end
		else if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2) && using_rs2)
			begin
				cmpmux2_forward = 1'b1;
				unique case(mem_wb_reg_sel)
					regfilemux::alu_out: cmpmux2_sel = cmpmux::mem_wb_alu_out_2;
					regfilemux::br_en: cmpmux2_sel = cmpmux::mem_wb_br_en_2;
					regfilemux::u_imm: cmpmux2_sel = cmpmux::mem_wb_u_imm_2;
					regfilemux::pc_plus4: cmpmux2_sel = cmpmux::mem_wb_pc_plus_4_2;
					regfilemux::lw: cmpmux2_sel = cmpmux::mem_wb_read_data_2;
					default:;
				endcase
			end
		
	
	//forwarding in decode stage 
		//from mem_wb to 	decode
		if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == if_id_rs1))
			begin
			unique case(mem_wb_reg_sel)
				regfilemux::alu_out: decodemux1_sel = decodemux::mem_wb_alu_out;
				regfilemux::br_en: decodemux1_sel = decodemux::mem_wb_br_en;
				regfilemux::u_imm: decodemux1_sel = decodemux::mem_wb_u_imm;
				regfilemux::pc_plus4: decodemux1_sel = decodemux::mem_wb_pc_plus_4;
				regfilemux::lw: decodemux1_sel = decodemux::mem_wb_read_data;
				default:;
			endcase
			end
			
		if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == if_id_rs2))
			begin
			unique case(mem_wb_reg_sel)
				regfilemux::alu_out: decodemux2_sel = decodemux::mem_wb_alu_out;
				regfilemux::br_en: decodemux2_sel = decodemux::mem_wb_br_en;
				regfilemux::u_imm: decodemux2_sel = decodemux::mem_wb_u_imm;
				regfilemux::pc_plus4: decodemux2_sel = decodemux::mem_wb_pc_plus_4;
				regfilemux::lw: decodemux2_sel = decodemux::mem_wb_read_data;
				default:;
			endcase
		end
			
	
	//forwarding for a load follwed by a store
		//from mem_wb to dcache
		if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == ex_mem_rs2))
		begin
			unique case(mem_wb_reg_sel)
				regfilemux::alu_out: memmux2_sel = memmux::mem_wb_alu_out_2;
				regfilemux::br_en: memmux2_sel = memmux::mem_wb_br_en_2;
				regfilemux::u_imm: memmux2_sel = memmux::mem_wb_u_imm_2;
				regfilemux::pc_plus4: memmux2_sel = memmux::mem_wb_pc_plus_4_2;
				regfilemux::lw: memmux2_sel = memmux::mem_wb_read_data_2;
				default:;
			endcase
		end
			
		//from mem_wb to rs2 into ex_mem
		if(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))
		begin
			unique case(ex_mem_reg_sel)
				regfilemux::alu_out: memmux1_sel = memmux::mem_wb_alu_out_1;
				regfilemux::br_en: memmux1_sel = memmux::mem_wb_br_en_1;
				regfilemux::u_imm: memmux1_sel = memmux::mem_wb_u_imm_1;
				regfilemux::pc_plus4: memmux1_sel = memmux::mem_wb_pc_plus_4_1;
				default:;
			endcase
		end
		else if(mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2))
			begin
			unique case(mem_wb_reg_sel)
				regfilemux::alu_out: memmux1_sel = memmux::mem_wb_alu_out_1;
				regfilemux::br_en: memmux1_sel = memmux::mem_wb_br_en_1;
				regfilemux::u_imm: memmux1_sel = memmux::mem_wb_u_imm_1;
				regfilemux::pc_plus4: memmux1_sel = memmux::mem_wb_pc_plus_4_1;
				regfilemux::lw: memmux1_sel = memmux::mem_wb_read_data_1;
				default:;
			endcase
			end
	end


endmodule: forwarding_unit