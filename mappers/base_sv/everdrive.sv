
module everdrive(

	output [7:0]cpu_dati,
	input  [7:0]cpu_dato,
	input  [14:0]cpu_addr,
	input  cpu_ce, cpu_rw, m2,
	output cpu_irq,
	output cpu_dir, cpu_ex,
	
	output [7:0]ppu_dati,
	input  [7:0]ppu_dato,	
	input  [13:0]ppu_addr,
	input  ppu_oe, ppu_we, ppu_a13n,
	output ppu_ciram_ce, ppu_ciram_a10,
	output ppu_dir, ppu_ex,
	
	output [7:0]prg_dati,
	input  [7:0]prg_dato,
	output [22:0]prg_addr,
	output prg_ce, prg_oe, prg_we,
	
	output [7:0]chr_dati,
	input  [7:0]chr_dato,
	output [22:0]chr_addr,
	output chr_ce, chr_oe, chr_we,

	output [7:0]srm_dati,
	input  [7:0]srm_dato,
	output [17:0]srm_addr,
	output srm_ce, srm_oe, srm_we,
	
	output spi_miso,
	input  spi_mosi, spi_clk, spi_ss,
	
	input  mcu_busy,
	output fifo_rxf,
	
	input  clk, fds_sw,
	output led, pwm, boot_on
);


	assign boot_on 		= 0;

	SysCfg cfg;
	DmaBus dma;
//**************************************************************************************** map in
	MapIn mai;
	CpuBus cpu;
	PpuBus ppu;
	
	assign cpu.data[7:0]		= bus_cf_act ? cpu_data_bcf[7:0] : cpu_dato[7:0];
	assign cpu.addr[15:0]	= {!cpu_ce, cpu_addr[14:0]};
	assign cpu.rw				= cpu_rw;
	assign cpu.m2				= m2;
	assign cpu.m3				= m3;
	
	assign ppu.data[7:0]		= ppu_dato[7:0];
	assign ppu.addr[13:0]	= ppu_addr[13:0];
	assign ppu.oe				= ppu_oe;
	assign ppu.we				= ppu_we;
	
	assign mai.clk 			= clk;//50Mhz clock for stuff which can not be driven by system clock
	assign mai.fds_sw 		= !fds_sw;
	assign mai.map_rst 		= cfg.map_idx == 255 | !cfg.ct_unlock | map_rst_req;
	assign mai.prg_do			= prg_dato;
	assign mai.chr_do			= chr_dato;
	assign mai.srm_do			= srm_dato;
	assign mai.cpu				= cpu;
	assign mai.ppu				= ppu;
	assign mai.cfg				= cfg;
//**************************************************************************************** map out	
	MapOut mao;
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	
	
	assign prg 					= dma.req_prg ? dma.mem : mao.prg;
	assign chr 					= dma.req_chr ? dma.mem : mao.chr;
	assign srm 					= dma.req_srm ? dma.mem : mao.srm;
	
	assign prg_addr[22:0] 	= prg_addr_msk[22:0];
	assign prg_ce 				= prg.ce & !dma.req_srm & (ce_ok | prg.async_io);
	assign prg_oe 				= prg.oe | bus_cf_act;
	assign prg_we 				= prg.we & (we_ok | prg.async_io);
	
	assign chr_addr[22:0] 	= chr_addr_msk[22:0];
	assign chr_ce 				= chr.ce & (chr.oe | chr.we);
	assign chr_oe 				= chr.oe;
	assign chr_we 				= chr.we;
	
	assign srm_addr[17:0] 	= srm_addr_msk[17:0];
	assign srm_ce 				= srm.ce & !dma.req_prg & (ce_ok | srm.async_io) & !srm_off;
	assign srm_oe 				= srm.oe;
	assign srm_we 				= srm.we & (we_ok | srm.async_io);
	
	assign cpu_irq				= !mao.irq;
	
	assign led 					= mao.led | (mai.sys_rst & mai.map_rst & cfg.map_idx != 255);//ss_act
	
	
	wire [22:0]prg_addr_msk = (prg.addr & prg_msk);
	wire [22:0]chr_addr_msk = (chr.addr & chr_msk) | {chr_ram, 22'd0};
	wire [22:0]srm_addr_msk = (srm.addr & srm_msk);
	
	wire [22:0]prg_msk		=  mao.prg_mask_off | dma.req_prg ? 'h7FFFFF : {cfg.prg_msk[9:0], 13'd8191};
	wire [22:0]chr_msk		=  mao.chr_mask_off | dma.req_chr ? 'h7FFFFF : {cfg.chr_msk[9:0], 13'd8191};
	wire [22:0]srm_msk		=  mao.srm_mask_off | dma.req_srm ? 'h03FFFF : {cfg.srm_msk[10:0], 7'd127};
	
	wire chr_ram				= !dma.req_chr & !mai.map_rst & (mao.chr_xram_ce | cfg.chr_ram);//save state engine expects chr ram to be mapped at upper 4M
	wire srm_off				= !dma.req_srm & !mai.map_rst & cfg.prg_ram_off;
//**************************************************************************************** data bus drivers
	wire apu_space				= {!cpu_ce, cpu_addr[14:5], 5'd0} == 16'h4000;
	wire cart_space 			= (!cpu_ce | cpu_addr[14]) & !apu_space;
	
	//cpu data bus
	assign cpu_dati[7:0] 	= 
	bio_ce_cpu		? bio_do[7:0] : 
	sst_ce_cpu		? sst_do[7:0] :
	cc_ce_cpu		? cc_do[7:0]  ://priority was changed
	mao.map_cpu_oe	? mao.map_cpu_do[7:0] : 
	{!cpu_ce, cpu_addr[14:8]};//open bus
	
	assign cpu_dir 			= cart_space & cpu_rw & cpu.m2 ? 1 : 0;// cpu_bus_oe;
	assign cpu_ex  			= 0;
	
	
	//ppu data bus
	assign ppu_dati[7:0] 	= 
	dma.req_chr		? 8'h00 : 
	mao.map_ppu_oe	? mao.map_ppu_do[7:0] :
	ppu_iram_oe 	? ppu_iram_do[7:0] : 
	8'hff;
	
	assign ppu_dir 			= !ppu_oe & ppu_ciram_ce ? 1 : 0;
	assign ppu_ex 				= 0;

	//prg rom data bus
	assign prg_dati[7:0] 	= prg.dati;
	
	//chr mem data bus
	assign chr_dati[7:0] 	= chr.dati;
	
	//prg ram data bus
	assign srm_dati[7:0] 	= srm.dati;
	
	
	//bus conflicts
	wire bus_cf_act			= mao.bus_cf & prg_ce & !cpu_rw;
	wire [7:0]cpu_data_bcf	= cpu_dato[7:0] & prg_dato[7:0];
	
//****************************************************************************************
	wire we_ok					= cpu.m2 & m2_st[7:0] == 'b11111111;//data bus stable
	wire ce_ok					= cpu.m2 & m2_st[1:0] == 'b11;//addr bus stable (cpu_ce comes with little delay)
	wire m3						= m2_st[12:10] == 'b001;//used if block cloced by master clock (clk) instead of m2. (mmc3)
	
	reg [15:0]m2_st;
	
	always @(posedge mai.clk)
	begin
		m2_st[15:0]	<= {m2_st[14:0], cpu.m2};
	end	
//**************************************************************************************** vram driver
	wire ppu_iram_oe;
	wire [7:0]ppu_iram_do;
	
	ppu_vram_ctrl ppu_vram_ctrl_inst(

		.clk(mai.clk),
		.cpu(cpu),
		.ppu(ppu),
		.map_ciram_a10(mao.ciram_a10),
		.map_ciram_ce(mao.ciram_ce),
		.mir_4s(cfg.mir_4 & mao.mir_4sc),
		
		.ppu_ciram_a10(ppu_ciram_a10),
		.ppu_ciram_ce(ppu_ciram_ce),
		.ppu_iram_oe(ppu_iram_oe),
		.ppu_iram_do(ppu_iram_do)
	);
//**************************************************************************************** mappers
	
	assign mao = 
	mai.map_rst | mai.sst.act ? map_out_255 :
	map_out_game;
	
	
	//system mapper
	MapOut map_out_255;
	map_255 m255(mai, map_out_255);
	
	
	
	//game mappers
	MapOut map_out_game;
	map_hub(
		.mai(mai),
		.mao(map_out_game)
	);
	
//**************************************************************************************** peripheral interface	
	PiBus pi;
	
	wire [7:0]pi_di = 
	dma.mem_req 	? dma.pi_di :
	pi.map.ce_fifo ? pi_di_bio :
	pi.map.ce_cfg	? pi_di_cfg :
	pi.map.ce_sst 	? sst_do :
	8'hff;
	
	pi_io pi_io_inst(
	
		.clk(mai.clk),
		.spi_clk(spi_clk),
		.spi_ss(spi_ss),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.dati(pi_di),
		.pi(pi)
	);
//**************************************************************************************** base io
	wire bio_ce_cpu;
	wire [7:0]bio_do;
	wire [7:0]pi_di_bio;	
	
	base_io io_inst(
	
		.clk(mai.clk),
		.pi(pi),
		.cpu(cpu),
		.sys_rst(mai.sys_rst),
		.mcu_busy(mcu_busy),
		.ct_unlock(cfg.ct_unlock),
		
		.dout_pi(pi_di_bio),
		.dout_cp(bio_do),
		.bio_ce_cpu(bio_ce_cpu),
		.fifo_rxf_pi(fifo_rxf)
	);
//****************************************************************************************  sys cfg	
	wire [7:0]pi_di_cfg;
	
	sys_cfg sys_cfg_inst(
	
		.clk(mai.clk),
		.pi(pi),
		.pi_di(pi_di_cfg),
		.cfg(cfg)
	);		
//**************************************************************************************** dma controller
	dma_io dma_io_inst(
			
		.pi(pi),
		.prg_do(prg_dato),
		.chr_do(chr_dato),
		.srm_do(srm_dato),
		.dma(dma)
	);
//**************************************************************************************** reset controls			
	//cpu reset detection
	sys_rst_ctrl sys_rst_inst(
	
		.clk(mai.clk),
		.m2(cpu.m2),
		.rst(mai.sys_rst)
	);

	
	wire map_rst_req;

	//mapper reset control
	map_rst_ctrl map_rst_inst(

		.clk(mai.clk),
		.sys_rst(mai.sys_rst),
		.rst_ack(cfg.map_idx == 255),
		.rst_delay(cfg.ct_rst_delay),
		.rst_req(map_rst_req)
	);	
//**************************************************************************************** cheats	
	wire [7:0]cc_do;
	wire cc_ce_cpu;
	
`ifndef CCO_OFF
	cheats cheats_inst(
	
		.clk(mai.clk),
		.pi(pi),
		.cpu(cpu),
		.cheats_on(cfg.ct_gg_on & !mai.map_rst & !mai.sst.act),
		.prg_do(mai.prg_do[7:0]),
		
		.cc_do(cc_do[7:0]),
		.cc_ce(cc_ce_cpu)
	
	);
`endif	

//**************************************************************************************** save state controller	
	wire sst_ce_cpu;
	wire [7:0]sst_do;
	
`ifndef SST_OFF	
	sst_controller sst_inst(
	
		.clk(mai.clk),
		.pi(pi),
		.cpu(cpu),
		.cfg(cfg),
		.map_rst(mai.map_rst),
		.sys_rst(mai.sys_rst),
		.fds_sw(mai.fds_sw),
		.sst_di(map_out_game.sst_di),
			
		.sst(mai.sst),
		.sst_do(sst_do),
		.sst_ce_cpu(sst_ce_cpu)
	);
`endif
	
//**************************************************************************************** audio dac
`ifndef SND_OFF
		
	dac_ds dac_inst(

		.clk(mai.clk),
		.m2(cpu.m2),
		.vol(mao.snd[15:0]),
		.master_vol(cfg.master_vol),
		.snd(pwm)
	);
`endif
//****************************************************************************************
endmodule
