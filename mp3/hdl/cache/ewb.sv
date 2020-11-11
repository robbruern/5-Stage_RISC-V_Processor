module ewb(
	input clk,
	input rst,
	input logic ewb_read,
	input logic ewb_write,
	input logic [31:0] ewb_addr,
	output logic [255:0] ewb_rdata,
	input logic [255:0] ewb_wdata,
	output logic ewb_resp,
	
	input logic [255:0] line_o,
	output logic [255:0] line_i,
	input logic resp_o,
	output logic [31:0] address_i,
	output logic read_i,
	output logic write_i
);
//7445 speed without ewb
logic reg_load, data_sel, addr_sel, hit;

ewb_datapath ewb_datapath(.*);

ewb_control ewb_control(.*);

endmodule : ewb