module split_caches
(
	input clk,
	input rst,
	input logic [31:0] i_mem_addr,
	input logic [31:0] d_mem_addr,
	input logic [31:0] d_wdata,
	input logic [3:0] mem_byte_enable,
	input logic d_read_in,
	input logic d_write_in,
	input logic i_read_in,
	input logic l2_resp,
	input logic [255:0] l2_rdata,
	output logic i_resp_out,
	output logic d_resp_out,
	output logic [31:0] i_rdata,
	output logic [31:0] d_rdata,
	output logic [31:0] l2_addr,
	output logic l2_write,
	output logic l2_read,
	output logic [255:0] l2_wdata
);

	logic [31:0] i_address, i_addr1, i_addr2, d_address, d_addr1, d_addr2, d_wdata_out;
	logic d_mem_read, d_mem_write, i_mem_read, i_pmem_write, i_pmem_read, d_pmem_read, d_pmem_write, i_pmem_resp, d_pmem_resp;
	logic [3:0] mbe;
	logic [255:0] i_pmem_rdata256, d_pmem_rdata256, i_pmem_wdata, d_pmem_wdata;
	logic resp_match;
	
	L1_cache instruction_cache(	
		 .clk(clk),
		 .rst(rst), 
		 .mem_read(i_read_in),
		 .mem_write(1'b0),
		 .mem_byte_enable(4'b1111),
		 .mem_address(i_mem_addr),
		 .mem_address2(i_mem_addr),
		 .mem_wdata(32'b0),
		 .mem_rdata(i_rdata),
		 .mem_resp(i_resp_out),
		 .pmem_rdata256(i_pmem_rdata256),
		 .pmem_wdata(i_pmem_wdata),
		 .address(i_address),
		 .pmem_read(i_pmem_read),
		 .pmem_write(i_pmem_write),
		 .pmem_resp_cache(i_pmem_resp)
	);

	L1_cache data_cache(
		 .clk(clk),
		 .rst(rst), 
		 .mem_read(d_read_in),
		 .mem_write(d_write_in),
		 .mem_byte_enable(mem_byte_enable),
		 .mem_address(d_mem_addr),
		 .mem_address2(d_mem_addr),
		 .mem_wdata(d_wdata),
		 .mem_rdata(d_rdata),
		 .mem_resp(d_resp_out),
		 .pmem_rdata256(d_pmem_rdata256),
		 .pmem_wdata(d_pmem_wdata),
		 .address(d_address),
		 .pmem_read(d_pmem_read),
		 .pmem_write(d_pmem_write),
		 .pmem_resp_cache(d_pmem_resp)
	);

	arbiter arbiter(
		.clk(clk),
		.rst(rst),
		.data_addr(d_address),
		.inst_addr(i_address),
		.data_read(d_pmem_read),
		.data_write(d_pmem_write),
		.inst_read(i_pmem_read),
		.inst_write(i_pmem_write),
		.l2_resp(l2_resp),
		.data_wdata(d_pmem_wdata),
		.inst_wdata(i_pmem_wdata),
		.l2_rdata(l2_rdata),
		.l2_addr(l2_addr),
		.l2_data_resp(d_pmem_resp),
		.l2_inst_resp(i_pmem_resp),
		.l2_write(l2_write),
		.l2_read(l2_read),
		.l2_wdata(l2_wdata),
		.d_rdata(d_pmem_rdata256),
		.i_rdata(i_pmem_rdata256)
	);

	register #(32) i_addr2_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(i_mem_addr),
		.out(i_addr2)
	);

	register #(32) d_addr2_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(d_mem_addr),
		.out(d_addr2)
	);

	register #(1) i_mem_read_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(i_read_in),
		.out(i_mem_read)
	);

	register #(1) d_mem_read_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(d_read_in),
		.out(d_mem_read)
	);

	register #(32) d_wdata_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(d_wdata),
		.out(d_wdata_out)
	);

	register #(1) d_mem_write_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(d_write_in),
		.out(d_mem_write)
	);

	register #(4) data_mbe_reg(
		.clk(clk),
		.rst(rst),
		.load(resp_match),
		.in(mem_byte_enable),
		.out(mbe)
	);

	always_comb begin
		resp_match = d_resp_out & i_resp_out;
	end

	always_comb begin
		i_addr1 = 32'b0;
		d_addr1 = 32'b0;
		
		unique case(resp_match) 
			1'b0: begin
				i_addr1 = i_addr2;
				d_addr1 = d_addr2;
			end
			1'b1: begin
				i_addr1 = i_mem_addr;
				d_addr1 = d_mem_addr;
			end
			default:;
		endcase
	end

endmodule: split_caches