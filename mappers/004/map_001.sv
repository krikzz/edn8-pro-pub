
module map_001(//MMC1

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] 	= 
	sst.addr[7:0]  < 127 ? sst_di_mmc :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= wram_ce | ram_ce_155;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	assign srm.addr[14:13]	= cfg.chr_ram ? chr_addr[15:14] : 2'b00;
	
	assign prg.ce				= !prg_ce_n;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[14] 		= cfg.map_sub == 5 ? cpu.addr[14] : prg_addr[14];
	assign prg.addr[18:15] 	= {chr_addr[16], prg_addr[17:15]};
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[11:0]	= ppu.addr[11:0];
	assign chr.addr[16:12]	= cfg.chr_ram  ? {4'b0000, chr_addr[12]} : chr_addr[16:12];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
//************************************************************* mapper implementation below
	wire ram_ce_155			= {cpu.addr[15:13], 13'd0} == 16'h6000 & cfg.map_idx == 155;
	
	wire ciram_a10;
	wire wram_ce;
	wire prg_ce_n;
	wire [17:14]prg_addr;
	wire [16:12]chr_addr;
	wire [7:0]sst_di_mmc;
	
	chip_mmc1 mmc1_inst(
		
		.cpu_addr(cpu.addr[14:13]),
		.cpu_d7(cpu.data[7]),
		.cpu_d0(cpu.data[0]),
		.cpu_m2(cpu.m2),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.ppu_addr(ppu.addr[12:10]),
		
		.wram_ce(wram_ce),
		.prg_ce_n(prg_ce_n),
		.ciram_a10(ciram_a10),
		.prg_addr(prg_addr[17:14]),
		.chr_addr(chr_addr[16:12]),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di_mmc)
	);
		
endmodule

