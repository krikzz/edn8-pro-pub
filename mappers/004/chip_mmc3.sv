
module chip_mmc3(
	
	//regular mapper io
	input  [7:0]cpu_data,
	input	 cpu_a14,
	input	 cpu_a13,
	input	 cpu_a0,
	input  cpu_ce_n,
	input  cpu_rw,
	input  cpu_m2,
	input  [12:10]ppu_addr,
	
	output irq_n,
	output ciram_a10,
	output ram_ce,
	output ram_ce_n,
	output ram_we_n,	
	output prg_ce_n,
	output [20:13]prg_addr,
	output [17:10]chr_addr,
	
	//extra stuff
	input  clk,
	input  rst,
	input  [3:0]map_sub,
	input  mir_h,//default mirroring mode in case if not controlled by mapper
	input  cpu_m3,
	
	input  SSTBus sst,
	output [7:0]sst_di
);
	
	assign sst_di[7:0] 	=
	sst.addr[7:3] == 0   ? r8001[sst.addr[2:0]]:
	sst.addr[7:0] == 8   ? r8000 : 
	sst.addr[7:0] == 9   ? rA000 : 
	sst.addr[7:0] == 10  ? rA001 : 
	sst.addr[7:0] >= 16  ? sst_di_irq :
	8'hff;
	
	
	assign irq_n			= !irq_pend;
	
	assign ciram_a10 		= !mir_mod ? ppu_addr[10] : ppu_addr[11];
	
	assign ram_ce			= {cpu_ce_n, cpu_a14, cpu_a13} == 3'b111 & ram_ce_on;
	assign ram_ce_n		= !ram_ce;
	assign ram_we_n		= !(!cpu_rw & !ram_we_off);
	
	assign prg_ce_n		= !(!cpu_ce_n & cpu_rw);
	
	assign prg_addr[20:13]	= 
	{cpu_a14, cpu_a13} == 0 ? (prg_mod == 0 ? r8001[6][7:0] : 8'b11111110) :
	{cpu_a14, cpu_a13} == 1 ? r8001[7][7:0] :
	{cpu_a14, cpu_a13} == 2 ? (prg_mod == 1 ? r8001[6][7:0] : 8'b11111110) :
	8'b11111111;
	
	assign chr_addr[17:10] 	= 
	ppu_addr[12:11] == {chr_mod, 1'b0} ? {r8001[0][7:1], ppu_addr[10]} :
	ppu_addr[12:11] == {chr_mod, 1'b1} ? {r8001[1][7:1], ppu_addr[10]} :
	ppu_addr[11:10] == 0 ? r8001[2][7:0] :
	ppu_addr[11:10] == 1 ? r8001[3][7:0] :
	ppu_addr[11:10] == 2 ? r8001[4][7:0] :
   r8001[5][7:0];
	
	wire [3:0]reg_addr	= {!cpu_ce_n, cpu_a14, cpu_a13, cpu_a0};
	
	wire prg_mod 			= r8000[6];
	wire chr_mod 			= r8000[7];
	wire mir_mod 			= rA000[0];
	wire ram_we_off 		= rA001[6];
	wire ram_ce_on 		= rA001[7];
	
	reg [7:0]r8000;
	reg [7:0]r8001[8];
	reg [7:0]rA000;
	reg [7:0]rA001;
	
	
	always @(negedge cpu_m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:3] == 0)r8001[sst.addr[2:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)r8000 						<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9)rA000 						<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)rA001						<= sst.dato;
	end
		else
	if(rst)
	begin
		r8000[7:0] 		<= 0;
	
		rA000[0] 		<= mir_h;
		rA001[7:0] 		<= 0;
	
		r8001[0][7:0]	<= 0;
		r8001[1][7:0] 	<= 2;
		r8001[2][7:0] 	<= 4;
		r8001[3][7:0] 	<= 5;
		r8001[4][7:0] 	<= 6;
		r8001[5][7:0] 	<= 7;
		r8001[6][7:0] 	<= 0;
		r8001[7][7:0] 	<= 1;
	end
		else
	if(!cpu_rw)
	case(reg_addr[3:0])
		4'h8:r8000[7:0] 					<= cpu_data[7:0];
		4'h9:r8001[r8000[2:0]][7:0]	<= cpu_data[7:0];
		4'hA:rA000[7:0] 					<= cpu_data[7:0];
		4'hB:rA001[7:0] 					<= cpu_data[7:0];
	endcase
	
//************************************************************* irq
	wire irq_pend;
	wire [7:0]sst_di_irq;
	
	irq_mmc3 irq_mmc_inst(
		
		.clk(clk),
		.cpu_m3(cpu_m3),
		.cpu_m2(cpu_m2),
		.cpu_rw(cpu_rw),
		.cpu_data(cpu_data),
		.reg_addr(reg_addr),
		.ppu_a12(ppu_addr[12]),
		.map_rst(rst),
		.mmc3a(map_sub == 4),
		.irq(irq_pend),
		
		.sst(sst),
		.sst_di(sst_di_irq)
	);

endmodule