module L1_cache_datapath #(
	parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	 input clk,
    input rst, 
    input logic [31:0] mem_address,
	 input logic [31:0] mem_address2,
    input logic [255:0] mem_wdata256,
    input logic [255:0] pmem_rdata,
	 input logic [31:0] mem_byte_enable256,

    output logic [255:0] data_out,
	 output logic [31:0] address,

    input logic tag_read,
	 input logic valid_read,
	 input logic dirty_read,
	 input logic data_read,
	 input logic lru_read,

	 input logic tag_load,
	 input logic valid_load,
	 input logic dirty_load,
	 input logic [1:0] data_load,
	 input logic lru_load,

	 input logic dirty_in,

	 input logic addr_sel,
	 input logic data_sel,

	 output logic hit,
	 output logic dirty
);

	logic way, hit0, hit1, tag0_load, tag1_load, valid0_load, valid1_load, valid0_out, valid1_out, lru_out,dirty0_load, dirty1_load, dirty0_out, dirty1_out;
	logic [23:0] tag0_out, tag1_out, tag;

	logic [31:0] data0_write, data1_write;
	logic [255:0] data0_out, data1_out, data_in;

	logic [23:0] mem_tag; 
	logic [2:0] index, index2;

	assign index = mem_address[7:5];
	assign index2 = mem_address2[7:5];
	assign mem_tag = mem_address2[31:8];

	//all the arrays
	array #(.width(24)) tag0array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (tag_read),
		 .load    (tag0_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (mem_tag),
		 .dataout (tag0_out)
	);

	array #(.width(24)) tag1array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (tag_read),
		 .load    (tag1_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (mem_tag),
		 .dataout (tag1_out)
	);


	array valid0array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (valid_read),
		 .load    (valid0_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (1'b1),
		 .dataout (valid0_out)
	);

	array valid1array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (valid_read),
		 .load    (valid1_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (1'b1),
		 .dataout (valid1_out)
	);

	array dirty0array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (dirty_read),
		 .load    (dirty0_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (dirty_in),
		 .dataout (dirty0_out)
	);

	array dirty1array(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (dirty_read),
		 .load    (dirty1_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (dirty_in),
		 .dataout (dirty1_out)
	);

	array lruarray(
		 .clk     (clk),
		 .rst     (rst),
		 .read    (lru_read),
		 .load    (lru_load),
		 .rindex  (index),
		 .windex  (index2),
		 .datain  (~way),
		 .dataout (lru_out)
	);

	data_array data1array(
		 .clk      (clk),
		 .rst      (rst),
		 .read     (data_read),
		 .write_en (data1_write),
		 .rindex   (index),
		 .windex   (index2),
		 .datain   (data_in),
		 .dataout  (data1_out)
	);

	data_array data0array(
		 .clk      (clk),
		 .rst      (rst),
		 .read     (data_read),
		 .write_en (data0_write),
		 .rindex   (index),
		 .windex   (index2),
		 .datain   (data_in),
		 .dataout  (data0_out)
	);

	//tag load shit
	always_comb begin
		if(way) begin
			tag0_load = 1'b0;
			tag1_load = tag_load;
		end
		else begin
			tag0_load = tag_load;
			tag1_load = 1'b0;
		end
	end

	//is it valid
	always_comb begin
		if(way) begin
			valid0_load = 1'b0;
			valid1_load = valid_load;
		end
		else begin
			valid0_load = valid_load;
			valid1_load = 1'b0;
		end
	end

	//dirty dirty boy
	always_comb begin
		if(way) begin
			dirty0_load = dirty_load;
			dirty1_load = 1'b0;
			dirty = dirty0_out & valid0_out;
		end
		else begin
			dirty0_load = 1'b0;
			dirty1_load = dirty_load;
			dirty = dirty1_out & valid1_out;
		end
	end
	
	//hit determination
	always_comb begin
		if((mem_tag == tag0_out) && valid0_out)	hit0 = 1'b1;
		else	hit0 = 1'b0;
		if((mem_tag == tag1_out) && valid1_out)	hit1 = 1'b1;
		else	hit1 = 1'b0;
		if(((mem_tag == tag0_out) && valid0_out) || ((mem_tag == tag1_out) && valid1_out))	hit = 1'b1; 
		else	hit = 1'b0;
	end

	always_comb begin
		data0_write = 32'b0;
		data1_write = 32'b0;
		if(way) begin
			case(data_load)
				2'b01: data1_write = mem_byte_enable256;
				2'b10: data1_write = 32'hFFFFFFFF;
				default: ;
				
			endcase
		end
		else begin
			case(data_load)
				2'b01: data0_write = mem_byte_enable256;
				2'b10: data0_write = 32'hFFFFFFFF;
				default: ;
			endcase
		end
	end
	
	//muxes the traditional way because it wasnt working with case statements.
	cache_mux #(1) way_mux(
		.sel(hit),
		.a(lru_out),
		.b(hit1),
		.f(way)
	);

	cache_mux #(24) tag_mux(
		.sel(way),
		.a(tag0_out),
		.b(tag1_out),
		.f(tag)
	);

	cache_mux #(256) data_in_mux(
		.sel(data_sel),
		.a(mem_wdata256),
		.b(pmem_rdata),
		.f(data_in)
	);

	cache_mux #(256) data_out_mux(
		.sel(way),
		.a(data0_out),
		.b(data1_out),
		.f(data_out)
	);

	cache_mux #(32) address_mux(
		.sel(0), // MEH
		.a({mem_tag, index2, 5'b0}),
		.b({tag, index2, 5'b0}),
		.f(address)
	);

	
endmodule : L1_cache_datapath

