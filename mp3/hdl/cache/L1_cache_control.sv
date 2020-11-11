
module L1_cache_control
(
	input clk,
	input rst,
	input mem_read,
	input mem_write,
	input hit,
	input dirty,
	output logic dirty_out,
	input pmem_resp,
	output logic addr_sel,
	output logic data_sel,
	output logic pmem_write,
	output logic pmem_read,
	output logic mem_resp,
	output logic tag_read,
	output logic tag_load,
	output logic valid_read,
	output logic valid_load,
	output logic dirty_read,
	output logic dirty_load,
	output logic lru_read,
	output logic lru_load,
	output logic data_read,
	output logic [1:0] data_load
);

function void set_cache_defaults();
	mem_resp = 1'b1;
	data_read = 1'b1;
	lru_read = 1'b1;
	tag_read = 1'b1;
	dirty_read = 1'b1;
	valid_read = 1'b1;
	data_load = 2'b00;
	valid_load = 1'b0;
	dirty_load = 1'b0;
	lru_load = 1'b0;
	tag_load = 1'b0;
	addr_sel = 1'b0;
	data_sel = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	dirty_out = 1'b0;
endfunction

enum int unsigned {
	read, miss1, miss2
} state, next_state;

always_comb begin: next_state_logic

	next_state = state;
	
	case(state)
	
		read: begin
			if(mem_read || mem_write) begin
				if(~hit) next_state = miss1;
			end
		end
		
		miss1: begin
			if(~dirty || pmem_resp) next_state = miss2;
		end
		
		miss2: if(pmem_resp) next_state = read;
		
		default: ;
		
	endcase
end

always_comb begin: state_actions
	set_cache_defaults();
	
	case(state)
	
		read: begin
			if(~hit) mem_resp = 1'b0;
			if(mem_read || mem_write) begin
				if(~hit) mem_resp = 1'b0;
			end
			
			if(mem_write) begin
				dirty_out = 1'b1;
				dirty_load = 1'b1;
				data_sel = 1'b0;
			end
			
			if(hit) begin
				lru_load = 1'b1;
				if(mem_write) data_load = 2'b01;
			end
		end
		
		miss1: begin
			mem_resp = 1'b0;
			if(dirty && ~pmem_resp) begin
			pmem_write = 1'b1;
			end
			addr_sel = 1'b1;
		end
		
		miss2: begin
			mem_resp = 1'b0;
			pmem_read = 1'b1;
			tag_load = 1'b1;
			dirty_out = 1'b0;
			dirty_load = 1'b1;
			valid_load = 1'b1;
			data_sel = 1'b1;
			data_load = 2'b10;
		end
		
		default: ;
		
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if(rst) state <= read;
	 else state <= next_state;
end

endmodule: L1_cache_control
