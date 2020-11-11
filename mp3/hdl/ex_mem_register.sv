import rv32i_types::*;
module ex_mem_register(
	input logic clk,
	input logic rst,
	input logic load,
	input logic stall,

	input rv32i_word address_in,
	input rv32i_word alu_data_in,
	input logic br_en_in,
	
	input rv32i_word i_imm_in,
   input rv32i_word s_imm_in,
   input rv32i_word b_imm_in,
   input rv32i_word u_imm_in,
   input rv32i_word j_imm_in,
	
	input logic [4:0] rs1_in,
	input logic [4:0] rs2_in,
	input logic [4:0] rd_in,
	
	input logic [2:0] funct3_in,
	
	//Ctrl signals 
	// WB Control
	input logic reg_write_in,
	input regfilemux::regfilemux_sel_t reg_sel_in,
	// MEM Control
	input pcmux::pcmux_sel_t pcmux_sel_in,
	input logic mem_write_in,
	input logic mem_read_in,
	input rv32i_mem_wmask mask_in,
	input logic mem_in,
	input logic br_in,
	input rv32i_word rs2_data_in,
	// WB Control
	output logic reg_write_out,
	output regfilemux::regfilemux_sel_t reg_sel_out,
	// MEM Control
	output logic mem_write_out,
	output logic mem_read_out,
	output rv32i_mem_wmask mask_out,
	output logic mem_out,
	output logic br_out,
	
	output rv32i_word i_imm_out,
   output rv32i_word s_imm_out,
   output rv32i_word b_imm_out,
   output rv32i_word u_imm_out,
   output rv32i_word j_imm_out,
	output pcmux::pcmux_sel_t pcmux_sel_out,
	output rv32i_word rs2_data_out,
	
	output rv32i_word address_out,
	output rv32i_word alu_data_out,
	output logic br_en_out,

	
	output logic [4:0] rs1_out,
	output logic [4:0] rs2_out,
	output logic [4:0] rd_out,
	
	output logic [2:0] funct3_out,
	
	 input logic id_ex_g_p_outcome,// goes into if_id_reg
	 input logic id_ex_l_p_outcome, //goes into if_id_reg
	 input logic [9:0] id_ex_l_p_idx, //goes into if_id_reg
	 input logic [9:0] id_ex_g_p_idx, //goes into if_id_reg
	 input logic [9:0] id_ex_p_idx,
	 input logic id_ex_p_outcome,
		 
	 output logic ex_mem_g_p_outcome,// goes into if_id_reg
	 output logic ex_mem_l_p_outcome, //goes into if_id_reg
	 output logic [9:0] ex_mem_l_p_idx, //goes into if_id_reg
	 output logic [9:0] ex_mem_g_p_idx, //goes into if_id_reg
	 output logic [9:0] ex_mem_p_idx,
	 output logic ex_mem_p_outcome,
	 
	 input logic jumpin,
	 output logic jumpout
);


rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;
rv32i_word rs2_data;
rv32i_word alu_data;
logic br_en;

logic [2:0] funct3;

	// WB Control
	logic reg_write;
	regfilemux::regfilemux_sel_t reg_sel;
	// MEM Control
	logic mem_write;
	logic mem_read;
	logic mem;
	rv32i_mem_wmask mask;
	logic br;
rv32i_word address;
pcmux::pcmux_sel_t pcmux_sel;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;

logic g_p_outcome;// goes into if_id_reg
logic l_p_outcome; //goes into if_id_reg
logic [9:0] l_p_idx; //goes into if_id_reg
logic [9:0] g_p_idx; //goes into if_id_reg
logic [9:0] p_idx;
logic p_outcome;

logic jump;

assign jumpout = jump;
assign ex_mem_g_p_outcome = g_p_outcome;
assign ex_mem_l_p_outcome = l_p_outcome;
assign ex_mem_l_p_idx = l_p_idx; 
assign ex_mem_g_p_idx = g_p_idx; 
assign ex_mem_p_idx = p_idx;
assign ex_mem_p_outcome = p_outcome;

always_comb
	begin
		  i_imm_out = i_imm;
		  s_imm_out = s_imm;
		  b_imm_out = b_imm;
		  u_imm_out = u_imm;
		  j_imm_out = j_imm;
		  
		  address_out = address;
		  
		  funct3_out = funct3;
		  pcmux_sel_out = pcmux_sel;
		  // WB Control
		  reg_write_out = reg_write;
		  reg_sel_out = reg_sel;
	     // MEM Control
	     mem_write_out = mem_write;
	     mem_read_out = mem_read;
	     mask_out = mask;
		  mem_out = mem;
		  br_out = br;
		  
		  rs2_data_out = rs2_data;
		  
		  rs1_out = rs1;
		  rs2_out = rs2;
		  rd_out = rd;
		  
		  alu_data_out = alu_data;
		  br_en_out = br_en;
	end



always_ff @(posedge clk)
begin
    if (rst)
    begin
        i_imm <= '0;
		  s_imm <= '0;
		  b_imm <= '0;
		  u_imm <= '0;
		  j_imm <= '0;
		  
		  address <= '0;
		  
		  funct3 <= '0;
		  
		  rs1 <= '0;
		  rs2 <= '0;
		  rd <= '0;
		  rs2_data <= 32'b0;
		   // WB Control
		  reg_write <= '0;
		  reg_sel <= regfilemux::alu_out;
	     // MEM Control
	     mem_write <= '0;
	     mem_read <= '0;
	     mask <= '0;
		  mem <= '0;
		  br <= '0;
		  pcmux_sel <= pcmux::pc_plus4;
		  alu_data <= '0;
		  br_en <= '0;
		  
        g_p_outcome <='0; 
        l_p_outcome <= '0;
        l_p_idx <= '0; 
		  g_p_idx <= '0; 
		  p_idx <= '0;
		  p_outcome <= '0;
		  
		  jump <= '0;
		  
    end
    else if (load == 1'b1 && stall == 1'b1)
		begin
			i_imm <= '0;
			s_imm <= '0;
			b_imm <= '0;
			u_imm <= '0;
			j_imm <= '0;
			
			address <= '0;
			
			funct3 <= '0;
			
			rs1 <= '0;
			rs2 <= '0;
			rd <= '0;
			rs2_data <= 32'b0;
				// WB Control
			reg_write <= '0;
			reg_sel <= regfilemux::alu_out;
			// MEM Control
			mem_write <= '0;
			mem_read <= '0;
			mask <= '0;
			mem <= '0;
			br <= br;
			pcmux_sel <= pcmux::pc_plus4;
			alu_data <= '0;
			br_en <= '0;
			
        g_p_outcome <= '0; 
        l_p_outcome <= '0;
        l_p_idx <= '0; 
		  g_p_idx <= '0; 
		  p_idx <= '0;
		  p_outcome <= '0;
			
		  jump <= '0;
			end
	 else if(load == 1'b1 && stall == 1'b0)
	 begin
	     i_imm <= i_imm_in;
		  s_imm <= s_imm_in;
		  b_imm <= b_imm_in;
		  u_imm <= u_imm_in;
		  j_imm <= j_imm_in;
		  
		  address <= address_in;
		  
		  funct3 <= funct3_in;
		  
		  // WB Control
		  reg_write <= reg_write_in;
		  reg_sel <= reg_sel_in;
	     // MEM Control
	     mem_write <= mem_write_in;
	     mem_read <= mem_read_in;
	     mask <= mask_in;
		  mem <= mem_in;
		  br <= br_in;
		  pcmux_sel <= pcmux_sel_in;
		  rs2_data <= rs2_data_in;
		  rs1 <= rs1_in;
		  rs2 <= rs2_in;
		  rd <= rd_in;
	 
		  alu_data <= alu_data_in;
		  br_en <= br_en_in;
		  
        g_p_outcome <= id_ex_g_p_outcome; 
        l_p_outcome <= id_ex_l_p_outcome;
        l_p_idx <= id_ex_l_p_idx; 
		  g_p_idx <= id_ex_g_p_idx; 
		  p_idx <= id_ex_p_idx;
		  p_outcome <= id_ex_p_outcome;
		  
		  jump <= jumpin;
    end
   else
   begin
	 
	     i_imm <= i_imm;
		  s_imm <= s_imm;
		  b_imm <= b_imm;
		  u_imm <= u_imm;
		  j_imm <= j_imm;
		  
		  address <= address;
		  
		  funct3 <= funct3;
		  
		  // WB Conrol
		  reg_write <= reg_write;
		  reg_sel <= reg_sel;
	     // MEM Control
	     mem_write <= mem_write;
	     mem_read <= mem_read;
	     mask <= mask;
		  mem <= mem;
		  br <= br;
		  pcmux_sel <= pcmux_sel;
		  rs2_data <= rs2_data;
		  rs1 <= rs1;
		  rs2 <= rs2;
		  rd <= rd;
		  
		  alu_data <= alu_data;
		  br_en <= br_en;
		  
        g_p_outcome <= g_p_outcome; 
        l_p_outcome <= l_p_outcome;
        l_p_idx <= l_p_idx; 
		  g_p_idx <= g_p_idx; 
		  p_idx <= p_idx;
		  p_outcome <= p_outcome;
		  
		  jump <= jump;
		  
    end
end


endmodule: ex_mem_register