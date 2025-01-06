
module chip_vrc4(

	input  cpu_m2,
	input  cpu_rw,
	input  cpu_a0,
	input  cpu_a1,
	input  cpu_a12,
	input  cpu_a13,
	input  cpu_a14,
	input  cpu_ce_n,
	input  [7:0]cpu_data,
	input  [13:10]ppu_addr,
	input  ppu_oe_n,//what is this for?
	
	output irq_n, 
	output ciram_a10,
	output chr_ce_n,
	output prg_ce_n, 
	output wram_ce_n,
	output wr9003_n,
	output [18:10]chr_addr,
	output [20:13]prg_addr,
	
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);
//************************************************************* sst
	assign sst_di[7:0] = 
	{sst.addr[7:3], 3'd0} == 0 ? chr_reg[sst.addr[2:0]][7:0] :
	{sst.addr[7:3], 3'd0} == 8 ? chr_reg[sst.addr[2:0]][8] :
	sst.addr[7:0] == 16 ? prg_reg[0][7:0] :
	sst.addr[7:0] == 17 ? prg_reg[1][7:0] :
	sst.addr[7:0] == 18 ? {ram_on, swp_mode, mir_mode[1:0]} :
	sst.addr[7:0] == 32 ? irq_ss :
	sst.addr[7:0] == 33 ? irq_ss :
	sst.addr[7:0] == 34 ? irq_ss :
	sst.addr[7:0] == 35 ? irq_ss :
	sst.addr[7:0] == 36 ? irq_ss :
	8'hff;
//*************************************************************
	assign irq_n				= !irq_pend;
	assign ciram_a10			= mir_mode[1] ? mir_mode[0] : !mir_mode[0] ? ppu_addr[10] : ppu_addr[11];
	assign chr_ce_n 			= ppu_addr[13];
	assign prg_ce_n			= !cpu_addr[15];
	assign wram_ce_n			= !({cpu_addr[15:13], 13'd0} == 16'h6000);// & ram_on);
	assign wr9003_n			= !(cpu_addr[15:0] == 16'h9003 & !cpu_rw);
	
	assign chr_addr[18:10]	= chr_reg[ppu_addr[12:10]][8:0];
	
	assign prg_addr[20:13]	=
	{cpu_addr[15:13], 13'd0} == 16'h8000 & swp_mode == 0 ? prg_reg[0][7:0] : 
	{cpu_addr[15:13], 13'd0} == 16'h8000 & swp_mode == 1 ? 8'hFE : 
	{cpu_addr[15:13], 13'd0} == 16'hA000 					  ? prg_reg[1][7:0] : 
	{cpu_addr[15:13], 13'd0} == 16'hC000 & swp_mode == 0 ? 8'hFE : 
	{cpu_addr[15:13], 13'd0} == 16'hC000 & swp_mode == 1 ? prg_reg[0][7:0] : 
	8'hFF; 
	
	
	wire [15:0]cpu_addr		= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a12, 10'd0, cpu_a1, cpu_a0};
	
	
	reg [8:0]chr_reg[8];
	reg [7:0]prg_reg[2];
	reg swp_mode;
	reg ram_on;
	reg [1:0]mir_mode;
	
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 0)chr_reg[sst.addr[2:0]][7:0] 	<= sst.dato;
		if(sst.we_reg & {sst.addr[7:3], 3'd0} == 8)chr_reg[sst.addr[2:0]][8] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 16)prg_reg[0][7:0] 							<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 17)prg_reg[1][7:0] 							<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 18){ram_on, swp_mode, mir_mode[1:0]} 	<= sst.dato;
	end
		else
	if(rst)
	begin
		prg_reg[1] 	<= 1;
		prg_reg[0] 	<= 0;
		swp_mode 	<= 0;
		mir_mode 	<= 3;
		ram_on		<= 1;
	end
		else
	if(!cpu_rw)
	begin
	
		if(cpu_addr[15:0] == 16'h9000)mir_mode <= cpu_data[1:0];
		if(cpu_addr[15:0] == 16'h9002)ram_on	<= cpu_data[0];
		if(cpu_addr[15:0] == 16'h9002)swp_mode <= cpu_data[1];
		
		if({cpu_addr[15:2],2'b0} == 16'h8000)prg_reg[0][7:0] <= cpu_data[7:0];
		if({cpu_addr[15:2],2'b0} == 16'hA000)prg_reg[1][7:0] <= cpu_data[7:0];
		
		if(cpu_addr[15:0] == 16'hB000)chr_reg[0][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hB001)chr_reg[0][8:4] <= cpu_data[4:0];
		if(cpu_addr[15:0] == 16'hB002)chr_reg[1][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hB003)chr_reg[1][8:4] <= cpu_data[4:0];
		
		if(cpu_addr[15:0] == 16'hC000)chr_reg[2][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hC001)chr_reg[2][8:4] <= cpu_data[4:0];
		if(cpu_addr[15:0] == 16'hC002)chr_reg[3][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hC003)chr_reg[3][8:4] <= cpu_data[4:0];
		
		if(cpu_addr[15:0] == 16'hD000)chr_reg[4][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hD001)chr_reg[4][8:4] <= cpu_data[4:0];
		if(cpu_addr[15:0] == 16'hD002)chr_reg[5][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hD003)chr_reg[5][8:4] <= cpu_data[4:0];
		
		if(cpu_addr[15:0] == 16'hE000)chr_reg[6][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hE001)chr_reg[6][8:4] <= cpu_data[4:0];
		if(cpu_addr[15:0] == 16'hE002)chr_reg[7][3:0] <= cpu_data[3:0];
		if(cpu_addr[15:0] == 16'hE003)chr_reg[7][8:4] <= cpu_data[4:0];
		
	end
	
//************************************************************* irq	
	wire irq_pend;
	wire [7:0]irq_ss;
	
	irq_vrc irq_vrc_inst(
		
		.cpu_data(cpu_data[7:0]),
		.cpu_m2(cpu_m2),
		.cpu_rw(cpu_rw),
		.map_rst(rst),
		.ce_latl(cpu_addr == 16'hF000),
		.ce_lath(cpu_addr == 16'hF001),
		.ce_ctrl(cpu_addr == 16'hF002),
		.ce_ackn(cpu_addr == 16'hF003),
		
		.irq(irq_pend),
		
		.sst(sst),
		.sst_di(irq_ss)
	);
	
endmodule
