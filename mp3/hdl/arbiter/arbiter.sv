`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

module arbiter(
	input clk,
	input rst,
	input logic [31:0] data_addr,
	input logic [31:0] inst_addr,
	input logic data_read,
	input logic data_write,
	input logic inst_read,
	input logic inst_write,
	input logic l2_resp,
	input logic [255:0] data_wdata,
	input logic [255:0] inst_wdata,
	input logic [255:0] l2_rdata,

	output logic [31:0] l2_addr,
	output logic l2_data_resp,
	output logic l2_inst_resp,
	output logic l2_write,
	output logic l2_read,
	output logic [255:0] l2_wdata,
	output logic [255:0] d_rdata,
	output logic [255:0] i_rdata

);
enum int unsigned{
	idle, data, instruction
} state, next_state;	

function void set_arbiter_defaults();
	l2_wdata = '0;
	d_rdata = 'X;
	i_rdata = 'X;
	l2_read = '0;
	l2_write = '0;
	l2_inst_resp = '0;
	l2_data_resp = '0;
	l2_addr = '0;
endfunction

always_comb begin
	next_state = state;
	case(state)
		idle: begin
			if(data_read || data_write) next_state = data;
			if(inst_read || inst_write) next_state  = instruction;
		end
		
		data: begin
			if(l2_resp) begin
				if(inst_read || inst_write) next_state = instruction;
				else next_state = idle;
			end
		end
		
		instruction: begin
			if(l2_resp) begin
				if(data_read || data_write) next_state = data;
				else next_state = idle;
			end
		end
		
		default:;
	
	endcase
end

always_comb begin
	set_arbiter_defaults();
	
	case(state)
	
		idle:;
		
		data: begin
			if(l2_resp) begin
				l2_data_resp = l2_resp;
				d_rdata = l2_rdata;
			end
			l2_addr = data_addr;
			l2_wdata = data_wdata;
			l2_read = data_read;
			l2_write = data_write;
		end
		
		instruction: begin
			if(l2_resp) begin
				l2_inst_resp = l2_resp;
				i_rdata = l2_rdata;
			end
			l2_addr = inst_addr;
			l2_wdata = inst_wdata;
			l2_read = inst_read;
			l2_write = inst_write;
		end
		
		default:;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	if(rst) state <= idle;
	 else state <= next_state;
end
endmodule : arbiter
