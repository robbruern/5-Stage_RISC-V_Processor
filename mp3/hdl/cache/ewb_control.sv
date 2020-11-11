module ewb_control(
	input clk,
	input rst,
	output logic ewb_resp,
	input logic ewb_write,
	input logic ewb_read,
	input logic  hit,
	output logic write_i,
	output logic read_i,
	input logic resp_o,
	output logic reg_load,
	output logic addr_sel,
	output logic data_sel
);


function void set_ewb_defaults();
	reg_load = 1'b0;
	ewb_resp = 1'b0;
	read_i = 1'b0;
	write_i = 1'b0;
	data_sel = 1'b1;
	addr_sel = 1'b0;
endfunction 

enum int unsigned{
	idle, hit_state, resp_wait, data_wait
} state, next_state;

always_comb begin
	next_state = state;
	unique case(state)
	idle: begin
		if (ewb_write || (ewb_read && hit)) next_state = hit_state;
		else if (ewb_read && ~hit) next_state = data_wait;
	end
	
	resp_wait: begin
		if(resp_o) next_state = idle;
	end
	
	data_wait: begin
		if(resp_o) next_state = hit_state;
	end
	
	hit_state: begin
		if (ewb_write || ewb_read && hit) next_state = resp_wait;
		else  next_state = idle;
	end
	
	default:;
	endcase
end

always_comb begin
	set_ewb_defaults();
	unique case(state)
	idle: begin
		if (ewb_write) begin
			reg_load = 1'b1;
			ewb_resp = 1'b1;
		end
		else if (ewb_read && hit) begin
			ewb_resp = 1'b1;
			data_sel = 1'b0;
		end
	end
	
	resp_wait: begin
		write_i = 1'b1;
		addr_sel = 1'b1;
	end
	
	data_wait: begin
		read_i = 1'b1;
		if(resp_o) ewb_resp = 1'b1;
	end
	
	hit_state: begin
		if (ewb_read && hit) data_sel = 1'b0;
	end

	default:;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if(rst) state <= idle;
	 else state <= next_state;
end

endmodule: ewb_control