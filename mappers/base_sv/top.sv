
`include "defs.sv"

module top(

	inout  [7:0]cpu_dat,
	input  [14:0]cpu_addr,
	input  cpu_ce, cpu_rw, m2,
	output cpu_irq,
	output cpu_dir, cpu_ex,
	
	inout  [7:0]ppu_dat,
	input  [13:0]ppu_addr,
	input  ppu_oe, ppu_we, ppu_a13n,
	output ppu_ciram_ce, ppu_ciram_a10,
	output ppu_dir, ppu_ex,
	
	inout  [7:0]prg_dat,
	output [21:0]prg_addr,
	output prg_ce, prg_oe, prg_we, prg_ub, prg_lb,
	
	inout  [7:0]chr_dat,
	output [21:0]chr_addr,
	output chr_ce, chr_oe, chr_we, chr_ub, chr_lb,

	output srm_ce, srm_oe, srm_we,
	
	output spi_miso,
	input  spi_mosi, spi_clk, spi_ss,
	
	input  mcu_busy,
	output fifo_rxf,
	
	input  clk, fds_sw,
	output led, pwm, boot_on,
	inout  [3:0]gpio,
	inout  [9:0]exp_io,
	output [2:0]xio,
	input  rx,
	output tx,
	
	output m2n
);
//**************************************************************************************** assigments
	assign exp_io[9:0] 	= 'hzzz;
	assign xio[2:0] 		= 'bzzz;
	
	assign cpu_dat 		= cpu_dir == 0	? 8'hzz : cpu_dati;
	assign ppu_dat 		= ppu_dir == 0	? 8'hzz : ppu_dati;
	
	assign prg_dat 		= (!prg_oe & !prg_ce) | (!srm_oe & srm_ce) ? 8'hzz : srm_ce ? srm_dati : prg_dati;
	assign prg_addr		= srm_ce ? srm_addr_int[17:0] : prg_addr_int[21:0];
	assign prg_ce			= !prg_ce_int;
	assign prg_oe			= !prg_oe_int;
	assign prg_we			= !prg_we_int;
	assign prg_ub 			= !prg_addr_int[22];
	assign prg_lb 			= !prg_ub;
	
	assign chr_dat 		= !chr_oe & !chr_ce	? 8'hzz : chr_dati;
	assign chr_addr		= chr_addr_int[21:0];
	assign chr_ce			= !chr_ce_int;
	assign chr_oe			= !chr_oe_int;
	assign chr_we			= !chr_we_int;
	assign chr_ub 			= !chr_addr_int[22];
	assign chr_lb 			= !chr_ub;
	
	assign srm_ce			= srm_ce_int;//(sram chip select is not inverted)
	assign srm_oe			= !srm_oe_int;
	assign srm_we			= !srm_we_int;
//**************************************************************************************** everdrive core
	wire [7:0]cpu_dati;
	wire [7:0]ppu_dati;
	
	wire [7:0]prg_dati;
	wire [22:0]prg_addr_int;
	wire prg_ce_int, prg_oe_int, prg_we_int;
	
	wire [7:0]chr_dati;
	wire [22:0]chr_addr_int;
	wire chr_ce_int, chr_oe_int, chr_we_int;
	
	wire [7:0]srm_dati;
	wire [17:0]srm_addr_int;
	wire srm_ce_int, srm_oe_int, srm_we_int;
	
	
	everdrive everdrive_inst(

		.cpu_dati(cpu_dati),
		.cpu_dato(cpu_dat),
		.cpu_addr(cpu_addr),
		.cpu_ce(cpu_ce),
		.cpu_rw(cpu_rw),
		.m2(m2),
		.cpu_irq(cpu_irq),
		.cpu_dir(cpu_dir),
		.cpu_ex(cpu_ex),
		
		.ppu_dati(ppu_dati),
		.ppu_dato(ppu_dat),
		.ppu_addr(ppu_addr),
		.ppu_oe(ppu_oe),
		.ppu_we(ppu_we),
		.ppu_a13n(ppu_a13n),
		.ppu_ciram_ce(ppu_ciram_ce),
		.ppu_ciram_a10(ppu_ciram_a10),
		.ppu_dir(ppu_dir),
		.ppu_ex(ppu_ex),
		
		.prg_dati(prg_dati),
		.prg_dato(prg_dat),
		.prg_addr(prg_addr_int),
		.prg_ce(prg_ce_int),
		.prg_oe(prg_oe_int),
		.prg_we(prg_we_int),
		
		.chr_dati(chr_dati),
		.chr_dato(chr_dat),
		.chr_addr(chr_addr_int),
		.chr_ce(chr_ce_int),
		.chr_oe(chr_oe_int),
		.chr_we(chr_we_int),
		
		.srm_dati(srm_dati),
		.srm_dato(prg_dat),
		.srm_addr(srm_addr_int),
		.srm_ce(srm_ce_int),
		.srm_oe(srm_oe_int),
		.srm_we(srm_we_int),
		
		.spi_miso(spi_miso),
		.spi_mosi(spi_mosi),
		.spi_clk(spi_clk),
		.spi_ss(spi_ss),
		
		.mcu_busy(mcu_busy),
		.fifo_rxf(fifo_rxf),
		
		.clk(clk),
		.fds_sw(fds_sw),
		.led(led),
		.pwm(pwm),
		.boot_on(boot_on)
		
	);

endmodule
