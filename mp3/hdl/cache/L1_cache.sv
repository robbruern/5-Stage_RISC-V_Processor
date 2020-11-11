module L1_cache(
	 input clk,
    input rst, 
	 input logic mem_read,
	 input logic mem_write,
	 input logic [3:0] mem_byte_enable,
	 input logic [31:0] mem_address,
	 input logic [31:0] mem_address2,
	 input logic [31:0] mem_wdata,
	 output logic [31:0] mem_rdata,
	 output logic mem_resp,
	 input logic [255:0] pmem_rdata256,
	 output logic [255:0] pmem_wdata,
	 output logic [31:0] address,
	 output logic pmem_read,
	 output logic pmem_write,
	 input logic pmem_resp_cache
);

	 logic [255:0] mem_wdata256, mem_rdata256;  
    logic [255:0] data_out;
	 logic resp_o, read_i, write_i;
    logic tag_read, valid_read, dirty_read, lru_read, tag_load, valid_load, 
			 dirty_load, dirty, hit, data_read, data_sel, addr_sel,
          dirty_out, lru_load;
    logic [31:0] mem_byte_enable256;
	 logic [1:0] data_load;
	 assign pmem_wdata = data_out;



L1_cache_control piped_like_your_mom(
	.clk(clk),
	.rst(rst),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.pmem_resp(pmem_resp_cache),
	.pmem_write(pmem_write),
	.pmem_read(pmem_read),
	.mem_resp(mem_resp),
	.hit(hit),
	.dirty(dirty),
	.dirty_out(dirty_out),
	.addr_sel(addr_sel),
	.data_sel(data_sel),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.lru_read(lru_read),
	.lru_load(lru_load),
	.data_read(data_read),
	.data_load(data_load)
);


L1_cache_datapath pipe_it_up(
	.clk(clk),
	.rst(rst),
	.mem_address(mem_address),
	.mem_address2(mem_address2),
	.mem_byte_enable256(mem_byte_enable256),
	.mem_wdata256(mem_wdata256),
	.pmem_rdata(pmem_rdata256),
	.data_out(data_out),
	.address(address),
	.data_read(data_read),
	.data_load(data_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.dirty_in(dirty_out),
	.lru_read(lru_read),
	.lru_load(lru_load),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load),
	.addr_sel(addr_sel),
	.data_sel(data_sel),
	.hit(hit),
	.dirty(dirty)
);
bus_adapter bus_adapter(
    .mem_wdata256       (mem_wdata256),
    .mem_rdata256       (data_out),
    .mem_wdata          (mem_wdata),
    .mem_rdata          (mem_rdata),
    .mem_byte_enable    (mem_byte_enable),
    .mem_byte_enable256 (mem_byte_enable256),
    .address            (mem_address2)
);

endmodule: L1_cache