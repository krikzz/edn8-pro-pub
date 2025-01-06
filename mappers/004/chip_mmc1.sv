
module chip_mmc1(
	
	//regular mapper io
	input  [14:13]cpu_addr,
	input  cpu_d7,
	input  cpu_d0,
	input  cpu_m2,
	input  cpu_ce_n,
	input  cpu_rw,
	input  [12:10]ppu_addr,
	
	output wram_ce,
	output prg_ce_n,
	output ciram_a10,
	output [17:14]prg_addr,
	output [16:12]chr_addr,
	
	//extra stuff
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);
	
	assign sst_di = 
	sst.addr[7:0] == 0 	? reg_8x :
	sst.addr[7:0] == 1 	? reg_ax :
	sst.addr[7:0] == 2 	? reg_cx :
	sst.addr[7:0] == 3 	? reg_ex :
	sst.addr[7:0] == 4 	? sreg :
	sst.addr[7:0] == 5 	? bit_ctr :
	8'hff;
	
	
	assign wram_ce		= cpu_ce_n == 1 & cpu_addr[14:13] == 2'b11 & reg_ex[4] == 0;
	assign prg_ce_n	= !(cpu_ce_n == 0 & cpu_rw == 1);
	
	assign ciram_a10 	= 
	reg_8x[1] == 0 	? reg_8x[0] :
	reg_8x[0] == 0 	? ppu_addr[10] : ppu_addr[11];
	
		
	assign prg_addr 	= 
	reg_8x[3] == 0 	? {reg_ex[3:1], cpu_addr[14]} :
	reg_8x[2] == 0 	? (cpu_addr[14] == 0 ? 4'h0 : reg_ex[3:0]) :
							  (cpu_addr[14] == 1 ? 4'hf : reg_ex[3:0]);
	
	assign chr_addr 	=
	reg_8x[4] == 0 	? {reg_ax[4:1], ppu_addr[12]} : 
	ppu_addr[12] == 0 ? reg_ax[4:0] :
							  reg_cx[4:0];
	
	wire [4:0]shift_next	= {cpu_d0, sreg[4:1]};
	
	reg[4:0]reg_8x;//control
	reg[4:0]reg_ax;//chr bank 0
	reg[4:0]reg_cx;//chr bank 1
	reg[4:0]reg_ex;//prg bank
	
	reg [2:0]bit_ctr;
	reg [4:0]sreg;
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)reg_8x 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)reg_ax 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)reg_cx 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)reg_ex 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)sreg 		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 5)bit_ctr	<= sst.dato;
	end
		else
	if(rst)
	begin
		reg_8x		<= 5'b11111;
		reg_ex[4]	<= 0;//enable ram by defaukt
	end
		else
	if(!cpu_ce_n & !cpu_rw)
	begin
		
		
		if(cpu_d7 == 1)
		begin
			bit_ctr 		<= 0;
			reg_8x[3:2] <= 2'b11;
		end
			else
		if(cpu_d7 == 0 & cpu_rw_st == 1)
		begin
			bit_ctr 		<= bit_ctr == 4 ? 0 : bit_ctr + 1;
			sreg[4:0] 	<= shift_next;
		end
		
		
		if(cpu_d7 == 0 & cpu_rw_st == 1 & bit_ctr == 4)
		case(cpu_addr[14:13])
			0:reg_8x <= shift_next;
			1:reg_ax <= shift_next;
			2:reg_cx <= shift_next;
			3:reg_ex <= shift_next;
		endcase
		
		
	end
	
	reg cpu_rw_st;
	
	always @(negedge cpu_m2)
	begin
		cpu_rw_st <= cpu_rw;
	end
	
endmodule
