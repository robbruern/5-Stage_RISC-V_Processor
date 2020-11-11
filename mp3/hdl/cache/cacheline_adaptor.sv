module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [63:0] burst_in;
logic [255:0] line_in;

assign address_o = address_i;

enum int unsigned {
    idle, read0, read1, read2, read3, write0, write1, write2, write3, send_resp
} state, next_state;

function void set_defaults();
	read_o = 1'b0;
	write_o = 1'b0;
	resp_o = 1'b0;
	burst_in = burst_o;
	line_in = line_o;
endfunction

always_comb
begin : state_actions
	set_defaults();
	unique case (state)
		idle: ;
		read0: begin			
			read_o = 1'b1;
			if (resp_i)
				line_in[0 +: 64] = burst_i;
		end
		read1: begin
			read_o = 1'b1;
			if (resp_i)			
				line_in[64 +: 64] = burst_i;
		end
		read2: begin
			read_o = 1'b1;
			if (resp_i)
				line_in[128 +: 64] = burst_i;
		end
		read3: begin
			read_o = 1'b1;
			if (resp_i)
				line_in[192 +: 64] = burst_i;
		end
		write0: begin
			write_o = 1'b1;
			if (resp_i)
				burst_in = line_i[0 +: 64];
		end
		write1: begin
			write_o = 1'b1;
			if (resp_i)
				burst_in = line_i[64 +: 64];
		end
		write2: begin
			write_o = 1'b1;
			if (resp_i)
				burst_in = line_i[128 +: 64];
		end
		write3: begin
			write_o = 1'b1;
			if (resp_i)
				burst_in = line_i[192 +: 64];
		end
		send_resp: resp_o = 1'b1;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	unique case (state)
		idle: begin
			case ({read_i, write_i})
				2'b10: next_state = read0;
				2'b01: next_state = write0;
				default: next_state = idle;
			endcase
		end
		read0: begin
			if (resp_i)
				next_state = read1;
		end
		read1: begin
			if (resp_i)
				next_state = read2;
		end
		read2: begin
			if (resp_i)
				next_state = read3;
		end
		read3: begin
			if (resp_i)
				next_state = send_resp;
		end
		write0: begin
			if (resp_i)
				next_state = write1;
		end
		write1: begin
			if (resp_i)
				next_state = write2;
		end
		write2: begin
			if (resp_i)
				next_state = write3;
		end
		write3: begin
			if (resp_i)
				next_state = send_resp;
		end
		send_resp: next_state = idle;
	endcase
end

always_ff @(posedge clk, negedge reset_n)
begin : next_state_assignment
    if (~reset_n) begin
		state <= idle;
		burst_o <= 64'b0;
		line_o <= 256'b0;
	end    
    /* Assignment of next state on clock edge */
    else begin
		state <= next_state;
		burst_o <= burst_in;
		line_o <= line_in;
	end
end

endmodule : cacheline_adaptor