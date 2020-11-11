module arbiter_control(
	input clk,
	input rst,
	input logic data_read_in,
	input logic data_write_in,
	input logic inst_read_in,
	input logic inst_write_in,
	
	
	input logic data_resp,
	input logic inst_resp,
	
	output logic data_read_out,
	output logic data_write_out,
	output logic inst_read_out,
	output logic inst_write_out

);


logic data_read, data_write, inst_read, inst_write;

assign data_read_out = data_read;
assign inst_read_out = inst_read;
assign data_write_out = data_write;
assign inst_write_out = inst_write;


function void set_default();
	data_read = data_read_in;
	data_write = data_write_in;
	inst_read = inst_read_in;
	inst_write = inst_write_in;
    
endfunction

enum int unsigned {
    idle, data_read_idle/*1*/, inst_read_idle/*3*/, data_resp_wait /*2*/, inst_resp_wait,/*4*///, data_resp_to_idle, inst_resp_to_idle,
	 data_resp_to_inst, inst_resp_to_data
} state, next_state;
always_comb
	begin :  next_state_logic
	next_state = state;
		
		unique case(state) 
			idle: begin
					if(data_read_in)
					next_state = data_read_idle;
					else if(inst_read_in)
					next_state = inst_read_idle;
					else
					next_state = idle;
					end
//			data_resp_to_idle:
//					next_state = idle;
//			inst_resp_to_idle:
//					next_state = idle;
			data_resp_to_inst:
					next_state = inst_read_idle;
			inst_resp_to_data:
					next_state = data_read_idle;
			data_read_idle: 
					if(inst_read_in == 1 && data_resp == 0)
						next_state = data_resp_wait;
					else if(data_resp == 1)
						begin
						next_state = idle;
						end
					else
						next_state = data_read_idle;
			inst_read_idle:
					if(data_read_in == 1 && inst_resp == 0)
						next_state = inst_resp_wait;
					else if(inst_resp == 1)
						begin
						next_state = idle;
						end
					else
						next_state = inst_read_idle;
			data_resp_wait:
					if(data_resp == 1)
						begin
						next_state = data_resp_to_inst;
						end
					else
						next_state = data_resp_wait;
			inst_resp_wait:
					if(inst_resp == 1)
						begin
						next_state = inst_resp_to_data;
						end
					else
						next_state = inst_resp_wait;
		default: next_state = idle;
		endcase
	end
always_comb
	begin : state_actions
/* Default output assignments */
    set_default();
     unique case(state)
			idle: ;
			data_read_idle:
			begin
			data_read = 1'b1;
			inst_read = 1'b0;
			end
			data_resp_wait:
			begin
			data_read = 1'b1;
			inst_read = 1'b0;
			end
			inst_read_idle:
			begin
			data_read = 1'b0;
			inst_read = 1'b1;
			end
			inst_resp_wait:
			begin
			data_read = 1'b0;
			inst_read = 1'b1;
			end
//			data_resp_to_idle: ;
										
//			inst_resp_to_idle:
//					begin
//					data_read = 1'b0;
//					inst_read = 1'b1;
//					end
			data_resp_to_inst: 
					begin
				data_read = 1'b0;
				inst_read = 1'b0;
					end
			inst_resp_to_data: 
					begin
					data_read = 1'b0;
					inst_read = 1'b0;
					end
			default: ;
		endcase
	end
always_ff @(posedge clk) 
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if(rst)
        state <= idle;
    else    
        state <= next_state;
end

endmodule