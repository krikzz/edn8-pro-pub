
module map_004_s1(//MMC6

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
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] = 
	sst.addr[7:0] == 32	? r8000 :
	sst.addr[7:0] == 33	? rA001 :
	sst.addr[7:0] <  127	? sst_di :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;	
//************************************************************* mapper-controlled pins
	assign srm.ce				= ram_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= ram_we;
	assign srm.addr[9:0]		= cpu.addr[9:0];
	
	assign prg.ce				= !prg_ce_n;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[12:0]	= cpu.addr[12:0];
	assign prg.addr[20:13]	= prg_addr[20:13];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[9:0]		= ppu.addr[9:0];
	//assign chr.addr[17:10]		= cfg.chr_ram ? chr_addr[14:10] : chr_addr[17:10];//ines 2.0 requires 32k ram support
	assign chr.addr[17:10]		= chr_addr[17:10];
	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= !irq_n;
	assign int_cpu_oe			= zero_oe;
	assign int_ppu_data		= 0;
//************************************************************* mapper implementation below

	wire irq_n;
	wire ciram_a10;
	wire prg_ce_n;
	wire [20:13]prg_addr;
	wire [17:10]chr_addr;
	
	wire [7:0]sst_di;
	
	chip_mmc3 mmc3_inst(
	
		.cpu_data(cpu.data[7:0]),
		.cpu_a14(cpu.addr[14]),
		.cpu_a13(cpu.addr[13]),
		.cpu_a0(cpu.addr[0]),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.cpu_m2(cpu.m2),
		.ppu_addr(ppu.addr[12:10]),
		
		.irq_n(irq_n),
		.ciram_a10(ciram_a10),
		//.ram_ce(ram_ce),
		//.ram_ce_n(ram_ce_n),
		//.ram_we_n(ram_we_n),	
		.prg_ce_n(prg_ce_n),
		.prg_addr(prg_addr),
		.chr_addr(chr_addr),
		
		.clk(mai.clk),
		.rst(mai.map_rst),
		.map_sub(0),
		.mir_h(cfg.mir_h),
		.cpu_m3(cpu.m3),
		
		.sst(sst),
		.sst_di(sst_di)
	);
	
//************************************************************* mmc6 ram control	
	wire ram_ce				= ram_ce_0 | ram_ce_1;
	wire ram_we				= ram_we_0 | ram_we_1;
	
	wire ram_area			= {cpu.addr[15:12], 12'd0} == 16'h7000;
	wire ram_we_0			= ram_area & cpu.addr[9] == 0 & rA001[4] == 1 & cpu.rw == 0;
	wire ram_ce_0			= ram_area & cpu.addr[9] == 0 & rA001[5] == 1;
	wire ram_we_1			= ram_area & cpu.addr[9] == 1 & rA001[6] == 1 & cpu.rw == 0;
	wire ram_ce_1			= ram_area & cpu.addr[9] == 1 & rA001[7] == 1;
	
	wire ram_oe_on			= rA001[5] | rA001[7];
	wire zero_oe			= ram_area & cpu.rw & !ram_ce;
	
	wire [3:0]reg_addr	= {cpu.addr[15:13], cpu.addr[0]};
	
	reg [7:0]r8000;
	reg [7:0]rA001;
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 32)r8000 <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 33)rA001 <= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		r8000	<= 0;
		rA001	<= 0;
	end
		else
	begin
		
		
		if(!cpu.rw & reg_addr == 'h8)
		begin
			r8000[7:0]	<= cpu.data[7:0];
		end
		
		
		if(r8000[5] == 0)//ram off
		begin
			rA001[7:0]	<= 8'h00;
		end
			else
		if(!cpu.rw & reg_addr == 'hB)
		begin
			rA001[7:0]	<= cpu.data[7:0];
		end
		
	end	
	
endmodule
