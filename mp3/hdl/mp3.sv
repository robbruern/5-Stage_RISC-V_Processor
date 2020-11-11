import rv32i_types::*;

module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

	logic [31:0] l2_addr, i_mem_addr, d_mem_addr, d_wdata, i_rdata, d_rdata, l2_addr_out, address_i, ewb_addr;
	logic [3:0] data_mbe;
	logic d_resp_out, i_resp_out, d_read, i_read, d_write, write_i, ewb_read, ewb_write, ewb_resp, read_i, resp_o, l2_resp, l2_read, l2_write, l2_mem_read_in, l2_mem_write_in, l2_mem_resp;
	logic [255:0] line_i, line_o, ewb_rdata, ewb_wdata;
	logic [255:0] l2_wdata, l2_rdata, l2_mem_rdata, l2_mem_wdata;

	
	
	cpu cpu(
		.clk(clk),
		.rst(rst),
		.data_resp(d_resp_out),
		.inst_resp(i_resp_out),
			 //input rv32i_word mem_rdata,
		.inst_rdata(i_rdata),
		.data_rdata(d_rdata),
		.inst_read(i_read),    //We can get rid of these when we inplement our caches
		.data_write(d_write),   //
		.data_read(d_read),    //
			 //output logic [3:0] mem_byte_enable,
			 //output rv32i_word mem_address,
		.data_mbe(data_mbe), 
		.inst_addr(i_mem_addr),
		.data_addr(d_mem_addr),
		.data_wdata(d_wdata)
			 //output rv32i_word mem_wdata
	);
	
	split_caches I_D_cache(
	.clk(clk),
	.rst(rst),
	.i_mem_addr(i_mem_addr),
	.d_mem_addr(d_mem_addr),
	.d_wdata(d_wdata),
	.mem_byte_enable(data_mbe),
	.d_read_in(d_read),
	.d_write_in(d_write),
	.i_read_in(i_read),
	.l2_rdata(l2_rdata),
	.l2_resp(l2_resp),
	
	.d_resp_out(d_resp_out),
	.i_resp_out(i_resp_out),
	.i_rdata(i_rdata),
	.d_rdata(d_rdata),
	.l2_addr(l2_addr),
	.l2_read(l2_read),
	.l2_write(l2_write),
	.l2_wdata(l2_wdata)
	);
	

	L2_cache L2_cache(
	 .clk(clk),
    .rst(rst), 
	 .mem_read(l2_read),
	 .mem_write(l2_write),
	 .mem_address(l2_addr),
	 .mem_address2(l2_addr),
	 .mem_wdata(l2_wdata),
	 .mem_rdata(l2_rdata),
	 .mem_resp(l2_resp),
	 .pmem_rdata256(l2_mem_rdata),
	 .pmem_wdata(l2_mem_wdata),
	 .address(l2_addr_out),
	 .pmem_read(l2_mem_read_in),
	 .pmem_write(l2_mem_write_in),
	 .pmem_resp_cache(l2_mem_resp)
	);
prefetcher	prefetcher(
	 .clk(clk),
    .rst(rst), 
	 .l2_mem_read_in(l2_mem_read_in),
	 .l2_mem_write_in(l2_mem_write_in),
	 .mem_address(l2_addr_out),
	 .l2_mem_wdata(l2_mem_wdata),
	 .mem_rdata(l2_mem_rdata),
	 .l2_mem_resp(l2_mem_resp),
	 .pmem_rdata256(ewb_rdata),
	 .pmem_wdata(ewb_wdata),
	 .address(ewb_addr),
	 .pmem_read(ewb_read),
	 .pmem_write(ewb_write),
	 .pmem_resp(ewb_resp)
	);

	
	ewb ewb(
		.clk(clk),
		.rst(rst),
		.ewb_read(ewb_read),
		.ewb_write(ewb_write),
		.ewb_addr(ewb_addr),
		.ewb_rdata(ewb_rdata),
		.ewb_wdata(ewb_wdata),
		.ewb_resp(ewb_resp),
	
	.line_o(line_o),
	.line_i(line_i),
	.resp_o(resp_o),
	.address_i(address_i),
	.read_i(read_i),
	.write_i(write_i)
	);

	cacheline_adaptor gayass64bit(
		.clk(clk),
		.reset_n(~rst),

		// Port to LLC (Lowest Level Cache)
		.line_i(line_i),
		.line_o(line_o),
		.address_i(address_i),
		.read_i(read_i),
		.write_i(write_i),
		.resp_o(resp_o),

		// Port to memory
		.burst_i(pmem_rdata),
		.burst_o(pmem_wdata),
		.address_o(pmem_address),
		.read_o(pmem_read),
		.write_o(pmem_write),
		.resp_i(pmem_resp)
	);

endmodule : mp3