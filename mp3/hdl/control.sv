
/* Import types defined in rv32i_types.sv */
import rv32i_types::*; 
module control
(
    input clk,
    input rst,
	 
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
	 
    input logic [4:0] if_id_rs1,
    input logic [4:0] if_id_rs2,
	 input logic [4:0] if_id_rd,
	 
	 
	 
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output cmpmux::cmpmux2_sel_t cmpmux_sel,
	 
    output alu_ops aluop,
	 output branch_funct3_t cmpop,
	 
    output logic load_pc,
    output logic load_reg,
    output logic load_regfile,
	 
	 input logic data_resp,
	 input logic inst_resp, //Think we might need a mem response for Icache and Dcache seperate
	 
	 output logic inst_read,
	 output logic data_read,
	 output logic data_write,

	 output logic br_out,
	 input logic br_in,

	 output logic [3:0] mem_byte_enable,
	 
	 output logic mem_out,
	 input logic mem_in,
	 
	 input logic [1:0] if_id_alignment,
	 
	 output logic using_rs1,
	 output logic using_rs2,
	 
	 output logic branch_wrong,
	 input logic stall,
	 output logic branch_update,
	 input logic ex_mem_predicted_outcome,
	 input logic predicted_outcome,
	 input logic branch_read,
	 
	 output logic jump,
	 input logic ex_mem_jump,
	 output logic jump_wrong


);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr, rd_addr;
logic [3:0] rmask, wmask;


branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

logic done;// moves all fives stages back to start
logic fetch_done;// done dependdent on mem_resp from icache is high
logic decode_done;// done dependent on when decode is fully figure out
logic execute_done;// done dependent on when alu_output is done, so basically one clock cycle
logic memory_done;// done dependent on mem_resp from d_cache is high
logic writeback_done;// done dependent on when regfilemux_out is valid, so basically one clock cycle
logic all_done;// used to signal that all states are done

logic i_mem_resp;//signals both need to come from the respective cache, figure this out plz (done)
logic d_mem_resp;

int total_branches;
int branches_wrong;
int branches_right;

assign branches_right = total_branches - branches_wrong;
//logic mem;//driven in decode, going to store in datapath, then comes back in memory stage

assign all_done = fetch_done && decode_done && execute_done && memory_done && writeback_done;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = if_id_rs1;
assign rs2_addr = if_id_rs2;
assign rd_addr = if_id_rd;


always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_reg, op_jal, op_jalr:;
			
		  op_imm: begin
		  trap = 0;
		  end
        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: 
					 begin
						unique case(if_id_alignment)
						2'b00: rmask = 4'b0011;
						2'b10: rmask = 4'b1100;
						default: rmask = 0;
						endcase
					 end
                lb, lbu:
					 begin
						unique case(if_id_alignment)
						2'b00: rmask = 4'b0001;
						2'b01: rmask = 4'b0010;
						2'b10: rmask = 4'b0100;
						2'b11: rmask = 4'b1000;
						default: rmask = 0;
						endcase
					 end
                
						default: rmask = 0;
						endcase
					 end
     

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
					 sh: 
					 begin
						unique case(if_id_alignment)
						2'b00: wmask = 4'b0011;
						2'b10: wmask = 4'b1100;

						default: wmask = 0;
						endcase
					 end
                sb: 
					 begin
						unique case(if_id_alignment)
						2'b00: wmask = 4'b0001;
						2'b01: wmask = 4'b0010;
						2'b10: wmask = 4'b0100;
						2'b11: wmask = 4'b1000;
						default: wmask = 0;
						endcase
					 end
                
						default: wmask = 0;
						endcase
					 end
          

        default: trap = 1;
    endcase
end
/*****************************************************************************/
/*
enum int unsigned {
    8
	 fetch1,fetch2,decode, 
	 imm, lui, auipc, br, regop, load, store,
	 calc_addrlw, calc_addrlb, calc_addrlh, calc_addrlbu, 
	 calc_addrlhu, calc_addrsw, calc_addrsb, calc_addrsh, 
	 lw1,lw2, lb1, lb2, lh1, lh2, lbu1, lbu2, lhu1, lhu2,
	 sw1,sw2, sh1, sh2, sb1, sb2,
	 saddi,sslti,ssltui,sxori, sori,sandi,sslli,ssrli,ssrai,//states for register - imm
	 sadd,ssub,ssll,sslt,ssltu,saxor,ssrl,ssra,saor,saand,//state for reg-reg
	 sbeq, sbne, sblt, sbge, sbltu, sbgeu,
	 jal, jalr
} state, next_state;
*/

//list of fetch states
enum int unsigned {
	fetch1, fetch2, fetch_done_state
} fetch_state, fetch_next_state;

//list of decode states
enum int unsigned{
	decode, 
	imm, lui, auipc, br, regop, load, store,
	saddi,sslti,ssltui,sxori, sori,sandi,sslli,ssrli,ssrai,//states for register - imm
	sadd,ssub,ssll,sslt,ssltu,saxor,ssrl,ssra,saor,saand,//state for reg-reg
	jal, jalr,
	sbeq, sbne, sblt, sbge, sbltu, sbgeu,
	lw1,sw1,  lb1, lbu1, sb1, lh1, lhu1, sh1,
	nop
}	decode_state, decode_next_state;

//list of execute state, might need to add more states for when we do forwarding
enum int unsigned{
	execute1, execute_done_state
} execute_state, execute_next_state;

//list of memory state
enum int unsigned{
	start, 
	done1,
	data_fetch, done2
} memory_state, memory_next_state;

//list of writeback states
enum int unsigned{
	writeback1, writeback_done_state
} writeback_state, writeback_next_state;

enum int unsigned{
	Wait, Done
} all_done_state, all_done_next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
//fetch state
fetch_done = 1'b0;

//decode state
load_pc = 1'b0;
load_regfile = 1'b0;
load_reg = 1'b0;

inst_read = 1'b0;
data_read = 1'b0;
data_write = 1'b0;

mem_out = 1'b0;
decode_done = 1'b1;

br_out = 1'b0;

pcmux_sel = pcmux::pc_plus4;
alumux1_sel = alumux::rs1_out;
alumux2_sel = alumux::i_imm;
regfilemux_sel = regfilemux::alu_out;
cmpmux_sel = cmpmux::rs2_out;

aluop = alu_add;
cmpop = beq;

//execute state
execute_done = 1'b0;

//memory state
memory_done = 1'b0;

//writeback state
writeback_done = 1'b0;

//all done state
load_reg = 1'b0;
done = 1'b0;

mem_byte_enable = 4'b0000;

using_rs1 = 1'b0;
using_rs2 = 1'b0;

branch_wrong = 1'b0;

branch_update = 1'b0;

jump = 1'b0;
jump_wrong = 1'b0;

endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    pcmux_sel = sel;
endfunction



//this function is not done
function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	 load_regfile = 1'b1;
	 regfilemux_sel = sel;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
										 alu_ops op = alu_add);
    /* Student code here */
	 alumux1_sel = sel1;
	 alumux2_sel = sel2;
	 aluop = op;
	 


   /* if (setop)
        aluop = op; // else default value
	*/
endfunction

function automatic void setCMP(cmpmux::cmpmux2_sel_t sel, branch_funct3_t op);
cmpmux_sel = sel;
cmpop = op;
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */
//need tp make six unique case statements to deal with every state machine, ask Ricky if confused
//Cause this logic is responsible for two things
//1) Getting the correct control to datapath
//2) Telling the nexxt_states when they can proceed **this is the more important one**
always_comb
begin : state_actions
    /* Default output assignments */
	 set_defaults();
	 unique case(fetch_state)
	   fetch2: inst_read = 1'b1;
		fetch_done_state: fetch_done = 1'b1;
		default: ;
	 endcase
	 
	 unique case(decode_state)
		lui: 
			begin
			loadRegfile(regfilemux::u_imm);
			end
		nop: ;
		auipc:
			begin
			setALU(alumux::pc_out, alumux::u_imm, alu_add);
			loadRegfile(regfilemux::alu_out);
			end	
	  
	  saddi:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_add);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		sxori:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_xor);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		sori:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_or);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		sandi:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_and);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		sslli:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_sll);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		ssrli:
		begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_srl);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		ssrai:
			begin
				setALU(alumux::rs1_out, 
						alumux::i_imm, 
						alu_sra);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
			end
		
		
		sslti, ssltui :
		begin
		setCMP(cmpmux::i_imm, branch_funct3);
		loadRegfile(regfilemux::br_en);
		end
		
		sadd:
			begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_add);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		ssll:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_sll);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		ssra:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_sra);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		ssub:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_sub);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		saxor:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_xor);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		ssrl:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_srl);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		saor:
		begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_or);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		saand :
			begin
				setALU(alumux::rs1_out, 
						alumux::rs2_out, 
						alu_and);
				loadRegfile(regfilemux::alu_out);
				using_rs1 = 1'b1;
				using_rs2 = 1'b1;
			end
		
		sslt, ssltu: 
		begin
		setCMP(cmpmux::rs2_out, branch_funct3);
		loadRegfile(regfilemux::br_en);
		using_rs2 = 1'b1;
		end
		
		
		sbeq,sbne,sblt,sbge,sbltu,sbgeu:
		begin
		br_out = 1'b1;
		setCMP(cmpmux::rs2_out, branch_funct3);
			setALU(alumux::pc_out, 
					alumux::b_imm);
//		loadPC(pcmux::alu_out);
		using_rs2 = 1'b1;
		using_rs1 = 1'b1;
		
		end
		
		
		jal: 
		begin
		setALU(alumux::pc_out, 
					alumux::j_imm);		
		loadRegfile(regfilemux::pc_plus4);
		jump = 1'b1;
		end
		
		jalr: 
		begin		
		setALU(alumux::rs1_out, 
					alumux::i_imm);
		loadRegfile(regfilemux::pc_plus4);
		using_rs1 = 1'b1;
		jump = 1'b1;
		end
		
		lw1:
		begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			data_read = 1'b1;
			loadRegfile(regfilemux::lw);
			mem_out = 1'b1;
			using_rs1 = 1'b1;
		end
		
		lb1:
		begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			data_read = 1'b1;
			loadRegfile(regfilemux::lw);
			mem_out = 1'b1;
			using_rs1 = 1'b1;
		end
		
		lbu1:
		begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			data_read = 1'b1;
			loadRegfile(regfilemux::lw);
			mem_out = 1'b1;
			using_rs1 = 1'b1;
		end
		
		lh1:
		begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			data_read = 1'b1;
			loadRegfile(regfilemux::lw);
			mem_out = 1'b1;
			using_rs1 = 1'b1;
		end
		
		lhu1:
		begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			data_read = 1'b1;
			loadRegfile(regfilemux::lw);
			mem_out = 1'b1;
			using_rs1 = 1'b1;
		end
		
		sw1:
		begin
			setALU(alumux::rs1_out, alumux::s_imm, alu_add);
			data_write = 1'b1;
			mem_out = 1'b1;
			mem_byte_enable = 4'b1111;
			using_rs1 = 1'b1;
		end
		
		sb1:
		begin
			setALU(alumux::rs1_out, alumux::s_imm, alu_add);
			data_write = 1'b1;
			mem_out = 1'b1;
			mem_byte_enable = wmask;
			using_rs1 = 1'b1;
		end
		
		sh1:
		begin
			setALU(alumux::rs1_out, alumux::s_imm, alu_add);
			data_write = 1'b1;
			mem_out = 1'b1;
			mem_byte_enable = wmask;
			using_rs1 = 1'b1;
		end
		
		default: decode_done = 1'b0;
	  endcase
	  
	 unique case(execute_state)
	 execute_done_state: begin
	 execute_done = 1'b1;

	end
	default: ;
	 endcase
	 
	 unique case(memory_state)
	 done1, done2: memory_done = 1'b1;
		default: ;
	 endcase
	 
	 unique case(writeback_state)
	 writeback_done_state: writeback_done = 1'b1;
		default: ;
	 endcase
	 
	 unique case(all_done_state)
		Wait:
			begin
				load_reg = all_done;
				done = 1'b0;
			end
		Done:
			begin
			if(br_in == 1'b1)
				branch_update = 1'b1;
			if(stall == 1'b1)
				done = 1'b1;
			if ((br_en != ex_mem_predicted_outcome) && br_in == 1'b1)//for mispredicted branches
				begin
				branch_wrong = 1'b1;
				load_pc = 1'b1;
				done = 1'b1;
				if(br_en == 1'b0)
					begin
					loadPC(pcmux::ex_mem_pc_plus4); //need to add more pcmux ssstates
					end
				else if (br_en == 1'b1)
					begin
					loadPC(pcmux::alu_out);
					end
				end
			else if(stall == 1'b1)
				done = 1'b1;
			else
				begin
				load_pc = 1'b1;
				done = 1'b1;
				if(ex_mem_jump == 1'b1)//for the jump
					begin
					loadPC(pcmux::alu_out);		
					jump_wrong = 1'b1;
					end
				else if(branch_read == 1'b1 && (predicted_outcome == 1'b1))
					begin
					loadPC(pcmux::fetch_offset);
					end
				else
					begin
					loadPC(pcmux::pc_plus4);		
					end
				end
			end
		default: ;
	 endcase
    /* Actions for each state */
end

//might need to break this up into multiple always_comb next state blcoks
always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  
	  unique case(fetch_state)
			fetch1: fetch_next_state = fetch2;
			fetch2:
				begin
					if(inst_resp == 1'b0)
						fetch_next_state = fetch2;
					else
						fetch_next_state = fetch_done_state;
				end
			fetch_done_state: 
				begin
					if(done == 1'b0)
						fetch_next_state = fetch_done_state;
					else
						fetch_next_state = fetch1;
				end
			default: fetch_next_state = fetch1;
	  endcase
	  
	  unique case(decode_state)
	  		decode:
			begin
			unique case(opcode)
				op_lui:   decode_next_state = lui;
				op_auipc: decode_next_state = auipc;
				op_jal: decode_next_state = jal;
				op_jalr: decode_next_state = jalr;
				op_br: decode_next_state = br;
				op_load: decode_next_state = load;
				op_store: decode_next_state = store;
				op_imm: decode_next_state = imm;
				op_reg: decode_next_state = regop;
				default: decode_next_state = nop;
			endcase
			end
			
			load:
			begin
			unique case(load_funct3)
				lw:   decode_next_state = lw1;
				default: decode_next_state = lw1;
			endcase
			end
			
			store:
			begin
			unique case(store_funct3)
				sw:   decode_next_state = sw1;
				default: decode_next_state = sw1;
			endcase
			end
			
			br: 
			begin
				unique case(branch_funct3)
					beq: decode_next_state = sbeq;
					bne: decode_next_state = sbne;
					2: decode_next_state = decode;
					3: decode_next_state = decode;
					blt: decode_next_state = sblt;
					bge: decode_next_state = sbge;
					bltu: decode_next_state = sbltu;
					bgeu: decode_next_state = sbgeu;
				endcase
			end
			
			imm:
			begin
						unique case(arith_funct3)
							add: decode_next_state = saddi;		
							sll: decode_next_state = sslli;
							slt: decode_next_state = sslti;
							sltu: decode_next_state = ssltui;
							axor: decode_next_state = sxori;
							sr: 
								begin
									if(funct7[5] == 1)begin
										decode_next_state = ssrai;
										end
									else begin
										decode_next_state = ssrli;
									end
										
								end
							aor: decode_next_state = sori;
							aand: decode_next_state = sandi;
							default: decode_next_state = decode;
						endcase
					end
			
			regop:
			begin
						unique case(arith_funct3)
							add: 
								begin
									if(funct7[5] == 1)begin
										decode_next_state = ssub;
										end
									else begin
										decode_next_state = sadd;
									end	
								end	
							sll: decode_next_state = ssll;
							slt: decode_next_state = sslt;
							sltu: decode_next_state = ssltu;
							axor: decode_next_state = saxor;
							sr: 
								begin
									if(funct7[5] == 1)begin
										decode_next_state = ssra;
										end
									else begin
										decode_next_state = ssrl;
									end	
								end
							aor: decode_next_state = saor;
							aand: decode_next_state = saand;
							default: decode_next_state = decode;
						endcase
					end
			
			sbeq,sbne,sblt, sbge, sbltu,sbgeu:
			begin
				if(done == 1'b1)
					decode_next_state = decode;
				else
					decode_next_state = decode_state;
			end
			
			sadd, ssub, ssll, sslt, ssltu, saxor, ssrl, ssra, saor, saand,
			saddi, sslti, ssltui, sxori, sslli, ssrli, ssrai, sori, sandi,
			jal, jalr,
			lw1, sw1,  lb1, lbu1, sb1, lh1, lhu1, sh1,
			lui, auipc, nop:
				begin
					if(done == 1'b0)
						decode_next_state = decode_state;
					else
						decode_next_state = decode;
				end
			
			
			default: decode_next_state = decode;
	  endcase
	  
	  unique case(execute_state)
			execute1: execute_next_state = execute_done_state;
			execute_done_state:
				begin
					if(done == 1'b0)
						execute_next_state = execute_done_state;
					else
						execute_next_state = execute1;
				end
			default: execute_next_state = execute1;
	  endcase
	  
	  unique case(memory_state)
			start: 
				begin
					if(mem_in == 1'b0)
						memory_next_state = done1;
					else
						memory_next_state = data_fetch;
				end
			done1: 
				begin
					if(done == 1'b0)
						memory_next_state = done1;
					else
						memory_next_state = start;
				end
			data_fetch:
				begin
					if(data_resp == 1'b0)
						memory_next_state = data_fetch;
					else
						memory_next_state = done2;
				end
			done2:
				begin
					if(done == 1'b0)
						memory_next_state = done2;
					else
						memory_next_state = start;
				end
				
			default: memory_next_state = start;
	  endcase
	  
	  unique case(writeback_state)
			writeback1: writeback_next_state = writeback_done_state;
			writeback_done_state:
				begin
					if(done == 1'b0)
						writeback_next_state = writeback_done_state;
					else
						writeback_next_state = writeback1;
				end
			default: writeback_next_state = writeback1;
	  endcase
	  
	  unique case(all_done_state)
			Wait:
				begin
					if(all_done == 1'b0)
						all_done_next_state = Wait;
					else
						all_done_next_state = Done;						
				end
			Done: all_done_next_state = Wait;
			default: all_done_next_state = Wait;
	  endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 if(rst == 1)begin
		fetch_state = fetch1;
		decode_state = decode;
		execute_state = execute1;
		memory_state = start;
		writeback_state = writeback1;
		all_done_state = Wait;
	 end
	 else
	 begin
		fetch_state = fetch_next_state;
		decode_state = decode_next_state;
		execute_state = execute_next_state;
		memory_state = memory_next_state;
		writeback_state = writeback_next_state;
		all_done_state = all_done_next_state;
		if(branch_update)
			total_branches = total_branches + 1;
		if(branch_wrong)
			branches_wrong = branches_wrong + 1;
	 end
end




endmodule : control


