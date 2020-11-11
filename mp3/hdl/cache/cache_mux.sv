module cache_mux #(parameter width = 32)
(
	input sel,
	input [width-1:0] a, b,
	output logic [width-1:0] f
);
	assign  f = (sel) ? b : a;
endmodule : cache_mux