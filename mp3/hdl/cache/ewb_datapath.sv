module ewb_datapath(
	input clk, 
	input rst,
	input logic data_sel,
	input logic addr_sel,
	input logic reg_load,
	input logic [31:0] ewb_addr,
	output logic [255:0] ewb_rdata,
	input logic [255:0] ewb_wdata,
	output logic [31:0] address_i,
	output logic [255:0] line_i,
	input logic [255:0] line_o,
	output logic hit
);

logic [31:0] ewb_addr_out;
logic [255:0] ewb_wdata_out;
logic valid;

assign line_i = ewb_wdata_out;
assign address_i = (addr_sel) ? ewb_addr_out : ewb_addr;
assign hit = (ewb_addr == ewb_addr_out && valid) ? 1'b1 : 1'b0;





register #(.width(256)) ewb_data
(
	.clk(clk),
	.rst(rst),
   .load(reg_load),
   .in(ewb_wdata),
   .out(ewb_wdata_out)
);

register #(.width(32)) ewb_address
(
	.clk(clk),
	.rst(rst),
   .load(reg_load),
   .in(ewb_addr),
   .out(ewb_addr_out)
);

register #(.width(1)) valid_reg
(
	.clk(clk),
	.rst(rst),
	.load(reg_load),
	.in(1'b1),
	.out(valid)
);

cache_mux #(.width(256)) ewb_rdata_mux
(
	.sel(data_sel),
	.a(ewb_wdata_out),
	.b(line_o),
	.f(ewb_rdata)
);
endmodule : ewb_datapath