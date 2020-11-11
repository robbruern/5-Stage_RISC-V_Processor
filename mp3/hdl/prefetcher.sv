module prefetcher(
	 input clk,
    input rst, 
	 input logic l2_mem_read_in,
	 input logic l2_mem_write_in,
	 input logic [31:0] mem_address,
	 input logic [255:0] l2_mem_wdata,
	 output logic [255:0] mem_rdata,
	 output logic l2_mem_resp,
	 input logic [255:0] pmem_rdata256,
	 output logic [255:0] pmem_wdata,
	 output logic [31:0] address,
	 output logic pmem_read,
	 output logic pmem_write, //Done
	 input logic pmem_resp

);
logic last_address_load;
logic address_picker; //0 for address in, 1 for address + 32
logic mem_picker; //0 for data from pmem, 1 for data from prefetcher
logic load_prefetch; //1 if prefetch data loaded
logic [31:0] prefetcher_address; //Address of data line currently in prefetcher
logic [255:0] prefetcher_mem_rdata256;  //Data line currently stored in prefetcher
logic [31:0] last_address_read;


always_comb begin
	if (mem_picker == 1 && address_picker == 1)begin
	mem_rdata = prefetcher_mem_rdata256;
	address = prefetcher_address;
	end
	else if (mem_picker == 0 && address_picker == 1)begin
	mem_rdata = pmem_rdata256;
	address = prefetcher_address;
	end
	else if (address_picker == 0 && mem_picker == 1 )begin
	address = mem_address;
	mem_rdata = prefetcher_mem_rdata256;
	end
	else begin
	mem_rdata = pmem_rdata256;
	address = mem_address;
	end
end
register #(32) last_address_reg(
		.clk(clk),
		.rst(rst),
		.load(last_address_load),
		.in(mem_address),
		.out(last_address_read)
	);
	
register #(32) prefetcher_address_reg(
		.clk(clk),
		.rst(rst),
		.load(load_prefetch),
		.in(last_address_read + 32),
		.out(prefetcher_address)
	);
	
register #(256) prefetch_mem_reg(
		.clk(clk),
		.rst(rst),
		.load(load_prefetch),
		.in(pmem_rdata256),
		.out(prefetcher_mem_rdata256)
	);


assign pmem_wdata = l2_mem_wdata;  //Pmem w data should never be affected by prefetching

enum int unsigned{
	read, buffer, prefetch, write
} state, next_state;	

function void set_prefetcher_defaults();
	pmem_read = 0;
	pmem_write = 0;
	l2_mem_resp = 0;
	load_prefetch = 0;
	address_picker = 0;
	mem_picker = 0;
	last_address_load = 0;
endfunction

always_comb begin
	next_state = state;
	case(state)
		read: begin
			if(l2_mem_read_in && pmem_resp) next_state = buffer;
			else if(l2_mem_write_in && ~l2_mem_read_in) next_state  = write;
			else next_state = read;
		end
		buffer: begin
		next_state = prefetch;
		end
		
		prefetch: begin
			if(pmem_resp && l2_mem_write_in) next_state = write;
			else if (pmem_resp) next_state = read;
			else next_state = prefetch;
		end
		
		write: begin
			if(pmem_resp) next_state = read;
			else next_state = write;
		end
		
		default:;
	
	endcase
end

always_comb begin
	set_prefetcher_defaults();
	
	case(state)
	
		read: begin
		if(mem_address == prefetcher_address && prefetcher_address != 0) begin
		mem_picker = 1;
		pmem_read = 0;
		l2_mem_resp = 1;
		end
		else if (mem_address != prefetcher_address) begin
		pmem_read = l2_mem_read_in;
		pmem_write = 0;
		l2_mem_resp = pmem_resp;
		mem_picker = 0;
		last_address_load = 1;
		end
		end
		buffer: begin
		load_prefetch = 1;
		address_picker = 1;
		end
		prefetch: begin
			l2_mem_resp = 0;
			pmem_read = 1;
			address_picker = 1;
			pmem_write = 0;
			load_prefetch = 1;
		end
		
		write: begin
			pmem_read = 0;
			pmem_write = 1;
			l2_mem_resp = pmem_resp;
			address_picker = 0;
		end
		
		default:;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	if(rst) state <= read;
	 else state <= next_state;
end
endmodule
	
		