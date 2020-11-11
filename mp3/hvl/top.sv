import rv32i_types::*;
module mp3_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
/****************************** End do not touch *****************************/

/**** RVFI signals to pipe / WB *****/

logic [31:0] rvfi_inst;
logic [4:0] rvfi_rs1_addr;
logic [4:0] rvfi_rs2_addr;
logic [31:0] rvfi_rs1_rdata;
logic [31:0] rvfi_rs2_rdata;
logic [4:0] rvfi_rd_addr;
logic [31:0] rvfi_rd_wdata;
logic [31:0] buf_rvfi_rd_wdata;
logic [31:0] rvfi_pc_rdata;
logic [31:0] rvfi_pc_wdata;
logic [31:0] rvfi_mem_addr; 
logic [3:0] rvfi_mem_rmask; 
logic [3:0] rvfi_mem_wmask; 
logic [31:0] rvfi_mem_rdata; 
logic [31:0] rvfi_mem_wdata; 
logic rvfi_branch_wrong;
rv32i_opcode rvfi_opcode;

logic rvfi_halt;
logic rvfi_commit;
logic rvfi_load_pc;
logic rvfi_load_reg;

/* Fetch */
logic [31:0] fet_inst;

/* Decode */
logic [31:0] dec_inst;
rv32i_opcode dec_opcode;
logic [4:0] dec_rs1_addr;
logic [4:0] dec_rs2_addr;
logic [3:0] dec_rmask, dec_wmask;
logic [31:0] dec_pc_rdata;
logic [31:0] dec_pc_wdata;
logic [31:0] dec_rs1_rdata;
logic [31:0] dec_rs2_rdata;

/*Execute */
logic [31:0] exe_inst;
rv32i_opcode exe_opcode;
logic [4:0] exe_rs1_addr;
logic [4:0] exe_rs2_addr;
logic [31:0] exe_rs1_rdata;
logic [31:0] exe_rs2_rdata;
logic [3:0] exe_rmask, exe_wmask;
logic [31:0] exe_pc_rdata;
logic [31:0] exe_pc_wdata;

/*MEM*/
rv32i_opcode mem_opcode;
logic [31:0] mem_inst;
logic [4:0] mem_rs1_addr;
logic [4:0] mem_rs2_addr;
logic [31:0] mem_rs1_rdata;
logic [31:0] mem_rs2_rdata;
logic [31:0] mem_pc_rdata;
logic [31:0] mem_pc_wdata;
logic [31:0] mem_addr; 
logic [3:0] mem_rmask; 
logic [3:0] mem_wmask; 
logic [31:0] mem_rdata; 
logic [31:0] mem_wdata; 
logic mem_load_pc;

logic stall_flag;
logic [31:0] rvfi_save_pc;
logic [31:0] stall_mem_addr; 


/************************ Signals necessary for monitor **********************/
// This section not required until CP3
logic commit;
assign commit = dut.cpu.load_pc;
logic [0:7] prefetch_hit_counter; 

// Shadow mem assignments
assign itf.inst_read = dut.i_read;
assign itf.inst_addr = dut.i_mem_addr;
assign itf.inst_rdata = dut.i_rdata;
assign itf.inst_resp = dut.i_resp_out;

assign itf.data_write = dut.d_write;
assign itf.data_read = dut.d_read;
assign itf.data_addr = dut.d_mem_addr;
assign itf.data_rdata = dut.d_rdata;
assign itf.data_resp = dut.d_resp_out;
assign itf.data_wdata = dut.d_wdata;
assign itf.data_mbe = dut.data_mbe;


    assign rvfi.inst = rvfi_inst; //Piped from Fetch stage
    assign rvfi.trap = '0; //Doesn't really matter
    assign rvfi.rs1_addr = rvfi_rs1_addr;  //Piped from Decode stage
    assign rvfi.rs2_addr = rvfi_rs2_addr;  //Piped from decode stage
    assign rvfi.rs1_rdata = rvfi_rs1_rdata; //Piped from Decode Stage
    assign rvfi.rs2_rdata = rvfi_rs2_rdata; //Piped from Decode stage
    assign rvfi.load_regfile = rvfi_load_reg; //Piped from Decode stage (WB)
    assign rvfi.rd_addr = rvfi_rd_addr; //Determined during commit (WB)
//	 always_comb
//	 begin
//	 if(rvfi_rd_addr)
//	 rvfi_rd_wdata = dut.cpu.datapath.regfilemux_out; 
//	 else
//	 rvfi_rd_wdata = '0;
//	 end
	// always_comb begin
	// if(dut.cpu.datapath.MEM_WB_REGISTER.br_en == 1 && dut.cpu.control.opcode == op_br && dut.cpu.control.all_done == 1)
	//	br_rvfi_pc_wdata = dut.cpu.datapath.MEM_WB_REGISTER.alu_data_out;
	// else
	//	br_rvfi_pc_wdata = buf_rvfi_pc_wdata;
	// end

	 assign rvfi.rd_wdata = rvfi_rd_wdata;

 //assign rvfi.rd_wdata = dut.cpu.datapath.regfilemux_out; //Determined during commit (WB)
    assign rvfi.pc_rdata = rvfi_pc_rdata; //Piped from fet stage 
    assign rvfi.pc_wdata = rvfi_pc_wdata; // Piped from fet stage
    assign rvfi.mem_addr =  rvfi_mem_addr;//Piped from MEM stage
    assign rvfi.mem_rmask = rvfi_mem_rmask; //Piped from MEM stage
    assign rvfi.mem_wmask = rvfi_mem_wmask; //Piped from MEM stage
    assign rvfi.mem_rdata = rvfi_mem_rdata; // Piped from MEM stage
    assign rvfi.mem_wdata = rvfi_mem_wdata; // Piped from MEM stage
	
	 always_ff @(posedge itf.clk)begin
		if (itf.rst ) begin
		rvfi_inst <= '0;
		rvfi_rs1_addr <= '0;
		rvfi_rs2_addr <= '0;
		rvfi_rs1_rdata <= '0;
		rvfi_rs2_rdata <= '0;
		rvfi_rd_addr <= '0;
		rvfi_pc_rdata <= '0;
		rvfi_pc_wdata <= '0;
		rvfi_load_pc <= '0;
		rvfi_mem_addr <= '0; 
		rvfi_mem_rmask <= '0;
		rvfi_mem_wmask <= '0;
		rvfi_mem_rdata <= '0;
		rvfi_mem_wdata <=  '0;
		rvfi_load_reg <= '0;
		rvfi_commit <= '0;
		rvfi_rd_wdata <= '0;
		rvfi_opcode <= op_imm;
		rvfi_save_pc <= '0;
		stall_flag <= 0;
		stall_mem_addr <= '0;
		end
		else if(dut.cpu.control.done == 1 && dut.cpu.control.stall)begin
		if (rvfi.commit)
					rvfi_save_pc <= rvfi_pc_wdata;
					
		stall_flag <= 1;			
	rvfi_inst <= mem_inst;
		rvfi_rs1_addr <= mem_rs1_addr;
	rvfi_rs2_addr <= mem_rs2_addr;
		rvfi_rs1_rdata <= mem_rs1_rdata;
		rvfi_rs2_rdata <= mem_rs2_rdata;
		rvfi_rd_addr <= dut.cpu.datapath.mem_wb_rd;
		rvfi_pc_rdata <= mem_pc_rdata;

		rvfi_pc_wdata <= mem_pc_wdata;
		rvfi_load_pc <= mem_load_pc;
		//rvfi_mem_addr <= mem_addr; 
		rvfi_mem_rmask <= mem_rmask;
		rvfi_mem_wmask <= mem_wmask;
		rvfi_mem_rdata <= mem_rdata;
		rvfi_mem_wdata <=  mem_wdata;
		rvfi_load_reg <= dut.cpu.datapath.mem_wb_reg_write_out;
		if(dut.cpu.datapath.mem_wb_rd != 0 )
			rvfi_rd_wdata <= dut.cpu.datapath.regfilemux_out;
			else
         rvfi_rd_wdata <= '0;
			if(mem_inst != 8'h00000013 && mem_inst != 8'h00000000 )
			rvfi_commit <= (mem_load_pc || dut.cpu.datapath.mem_wb_reg_write_out) ;
			else
      rvfi_commit <= 0;
		rvfi_branch_wrong <= dut.cpu.control.branch_wrong;
		rvfi_opcode <= mem_opcode;
		
		//IDEA
		mem_inst <= exe_inst;
		mem_rs1_addr <= exe_rs1_addr;
		mem_rs2_addr <= exe_rs2_addr;
		mem_rs1_rdata <= exe_rs1_rdata;
		mem_rs2_rdata <= dut.cpu.datapath.memmux2_out;
		mem_pc_rdata <= exe_pc_rdata;
			if(dut.cpu.datapath.EX_MEM_REGISTER.br_out == 1 && dut.cpu.datapath.EX_MEM_REGISTER.br == 1 && dut.cpu.datapath.EX_MEM_REGISTER.br_en == 1 )
			mem_pc_wdata <= dut.cpu.datapath.EX_MEM_REGISTER.alu_data_out;
			else
			mem_pc_wdata <= exe_pc_wdata;
		mem_addr <= dut.cpu.datapath.data_address;
		mem_rmask <= exe_rmask;
		mem_wmask <= exe_wmask;
		mem_rdata <= dut.cpu.datapath.MEM_WB_REGISTER.read_data;
		mem_wdata <= dut.cpu.datapath.memmux2_out;
		mem_load_pc <= dut.cpu.datapath.load_pc;
		mem_opcode <= exe_opcode;
		
		stall_mem_addr <= dut.cpu.datapath.data_address;
		
		
		end
		
		else if(dut.cpu.control.done == 1 && ~dut.cpu.control.stall)begin
					if (rvfi.commit)
					rvfi_save_pc <= rvfi_pc_wdata;
		// WB to commit
		stall_flag <= 0;	
		rvfi_inst <= mem_inst;
		rvfi_rs1_addr <= mem_rs1_addr;
		rvfi_rs2_addr <= mem_rs2_addr;
		rvfi_rs1_rdata <= mem_rs1_rdata;
		rvfi_rs2_rdata <= mem_rs2_rdata;
		rvfi_rd_addr <= dut.cpu.datapath.mem_wb_rd;
		rvfi_pc_rdata <= mem_pc_rdata;

		rvfi_pc_wdata <= mem_pc_wdata;
		rvfi_load_pc <= mem_load_pc;
		rvfi_mem_addr <= mem_addr; 
		rvfi_mem_rmask <= mem_rmask;
		rvfi_mem_wmask <= mem_wmask;
		rvfi_mem_rdata <= dut.cpu.datapath.MEM_WB_REGISTER.read_data;
		rvfi_mem_wdata <=  mem_wdata;
		rvfi_load_reg <= dut.cpu.datapath.mem_wb_reg_write_out;
			if(dut.cpu.datapath.mem_wb_rd != 0 )
			rvfi_rd_wdata <= dut.cpu.datapath.regfilemux_out;
			else
			rvfi_rd_wdata <= '0;
			if(mem_inst != 8'h00000013 && mem_inst != 8'h00000000 )
			rvfi_commit <= (mem_load_pc || dut.cpu.datapath.mem_wb_reg_write_out) ;
			else
			rvfi_commit <= 0;
		rvfi_branch_wrong <= dut.cpu.control.branch_wrong;
		rvfi_opcode <= mem_opcode;
		// MEM to WB
		if(stall_flag) begin
		mem_inst <= mem_inst;
		mem_rs1_addr <= mem_rs1_addr;
		mem_rs2_addr <= mem_rs2_addr;
		mem_rs1_rdata <= mem_rs1_rdata;
		mem_rs2_rdata <= mem_rs2_rdata;
		mem_pc_rdata <= mem_pc_rdata;
		mem_pc_wdata <= mem_pc_wdata;
		mem_addr <= mem_addr;
		mem_rmask <= mem_rmask;
		mem_wmask <= mem_wmask;
		mem_rdata <= mem_rdata;
		mem_wdata <= mem_wdata;
		mem_load_pc <= mem_load_pc;
		mem_opcode <= mem_opcode;
		end
		else begin
		mem_inst <= exe_inst;
		mem_rs1_addr <= exe_rs1_addr;
		mem_rs2_addr <= exe_rs2_addr;
		mem_rs1_rdata <= exe_rs1_rdata;
		mem_rs2_rdata <= dut.cpu.datapath.memmux2_out;
		mem_pc_rdata <= exe_pc_rdata;
			if(dut.cpu.datapath.EX_MEM_REGISTER.br_out == 1 && dut.cpu.datapath.EX_MEM_REGISTER.br == 1 && dut.cpu.datapath.EX_MEM_REGISTER.br_en == 1 )
			mem_pc_wdata <= dut.cpu.datapath.EX_MEM_REGISTER.alu_data_out;
			else
			mem_pc_wdata <= exe_pc_wdata;
			if(stall_flag)
			mem_addr <= stall_mem_addr;
			else
			mem_addr <= dut.cpu.datapath.data_address;
		mem_rmask <= exe_rmask;
		mem_wmask <= exe_wmask;
		mem_rdata <= dut.cpu.datapath.MEM_WB_REGISTER.read_data;
		mem_wdata <= dut.cpu.datapath.write_data;
		mem_load_pc <= dut.cpu.datapath.load_pc;
		mem_opcode <= exe_opcode;
		end
		
		if (~dut.cpu.control.stall) begin 
		//EXE to MEM
		exe_inst <= dec_inst;
		exe_rs1_addr <= dec_rs1_addr;
		exe_rs2_addr <= dec_rs2_addr; 
		exe_rs1_rdata <= dut.cpu.datapath.cmpmux_out1;
			
		exe_rs2_rdata <= dec_rs2_rdata;

		
		exe_rmask <= dec_rmask;
		exe_wmask <= dec_wmask;
		exe_pc_rdata <= dec_pc_rdata;
		exe_pc_wdata <= dec_pc_wdata;
		exe_opcode <= dec_opcode;
		//DEC to EXE
		dec_inst <= dut.cpu.datapath.instruction;
		dec_rs1_addr <= dut.cpu.datapath.if_id_rs1;
		dec_rs2_addr <= dut.cpu.datapath.if_id_rs2;
		dec_rmask <= dut.cpu.control.rmask;
		dec_wmask <= dut.cpu.control.wmask;
		dec_pc_rdata <= dut.cpu.datapath.pc_out;
		dec_pc_wdata <= dut.cpu.datapath.pcmux_out;
		dec_opcode <= dut.cpu.control.opcode;
		dec_rs1_rdata <= dut.cpu.datapath.rs1_data;
		dec_rs2_rdata <= dut.cpu.datapath.rs2_data;
			end
		end
		else begin
		rvfi_inst <= rvfi_inst;
		rvfi_rs1_addr <= rvfi_rs1_addr;
		rvfi_rs2_addr <= rvfi_rs2_addr;
		rvfi_rs1_rdata <= rvfi_rs1_rdata;
		rvfi_rs2_rdata <= rvfi_rs2_rdata;
		rvfi_rd_addr <= rvfi_rd_addr;
		rvfi_pc_rdata <= rvfi_pc_rdata;
		rvfi_pc_wdata <= rvfi_pc_wdata;
		rvfi_load_pc <= rvfi_load_pc;
		rvfi_load_reg <= rvfi_load_reg;
		rvfi_rd_wdata <= rvfi_rd_wdata;
		rvfi_branch_wrong <= rvfi_branch_wrong;
		rvfi_opcode <= rvfi_opcode;
		rvfi_save_pc <= rvfi_save_pc;
		end
	 end

    //logic [15:0] rvfi.errcode;
assign rvfi.commit = rvfi_commit && dut.cpu.control.done && ((rvfi_save_pc == rvfi_pc_rdata || rvfi_save_pc == '0)) ; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = (rvfi_pc_rdata == rvfi_pc_wdata) && rvfi_inst == op_br;//(dut.datapath.pcmux_sel == pcmux::alu_out) && (dut.datapath.ex_mem_alu_data_out == dut.datapath.ex_mem_pc_out) && (dut.datapath.br_out1 == 1);   // Set high when you detect an infinite loop
initial begin
rvfi.order = 0;
prefetch_hit_counter = 0;
end
always @(posedge itf.clk iff dut.prefetcher.mem_picker == 1 && dut.L2_cache.mem_resp) prefetch_hit_counter <= prefetch_hit_counter +1 ;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO
/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
//assign itf.registers = '{default: '0};
assign itf.registers = dut.cpu.datapath.REGFILE.data;
/*********************** Instantiate your design here ************************/
mp3 dut( .clk(itf.clk),
			.rst(itf.rst),
		   //.data_resp(itf.data_resp),
			//.inst_resp(itf.inst_resp),
			//.inst_read(itf.inst_read),
			//.inst_rdata(itf.inst_rdata),
			//.data_rdata(itf.data_rdata),
			//.data_write(itf.data_write),
			//.data_mbe(itf.data_mbe),
			//.data_read(itf.data_read),
			//.inst_addr(itf.inst_addr),
			//.data_addr(itf.data_addr),
			//.data_wdata(itf.data_wdata)
				.pmem_resp(itf.mem_resp),
				.pmem_rdata(itf.mem_rdata),
				.pmem_read(itf.mem_read),
				.pmem_write(itf.mem_write),
				.pmem_address(itf.mem_addr),
				.pmem_wdata(itf.mem_wdata));


/***************************** End Instantiation *****************************/

endmodule