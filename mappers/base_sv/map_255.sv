

//this mapper used by the cart menu
module map_255(

	input  MapIn  mai,
	output MapOut mao
);

//************************************************************* standard mapper header
	CpuBus cpu;
	PpuBus ppu;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;
	
	
	assign mao.srm_mask_off = 1;
	assign mao.chr_mask_off = 1;
	assign mao.prg_mask_off = 1;
	assign mao.mir_4sc		= 1;//enable support for 4-screen mirroring. for activation should be ensabled in cfg also
	
	assign prg.oe 				= cpu.rw;
	assign srm.oe 				= cpu.rw;
	assign chr.oe 				= !ppu.oe;
	
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
	//************************************************************* mapper implementation below
	parameter REG_VRAM_CTRL	= 0;//4registers
	parameter REG_TIMER		= 4;//2 registers
	parameter REG_APP_BANK	= 6;
	
	
	assign prg.ce = rom_area | ram_area | app_area;
	assign prg.we = (ram_area | app_area) & !cpu.rw;
	
	assign prg.addr[22:17] 	= 6'h3F;//system rom mapped to 0x7E0000
	assign prg.addr[16:0] 	= 
	ram_area ? {5'd0, cpu.addr[11:0]} :
	app_area ? {app_bank[3:0], cpu.addr[12:0]} : 
	{2'b11, cpu.addr[14:0]};
	
	
	assign chr.ce 				= !ppu.addr[13];
	assign chr.we 				= !ppu.we & ppu_off;

	assign chr.addr[11:0]  	= ppu.addr[11:0];
	assign chr.addr[13:12] 	= ppu_off ? {1'b0, ppu.addr[12]} : atr_do[3:2];
	assign chr.addr[22:17] 	= ppu_off ? 6'h20 : 6'h3F;
	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ppu.addr[10];
	assign mao.ciram_ce 		= ppu_off & !int_vram_tst ? !ppu.addr[13] : !int_vram_ce;//ppu_off ? !ppu_addr[13] : 1;
	
	assign int_cpu_oe			= !cpu.m2 ? 0 : regs_oe;
	assign int_ppu_oe 		= vram_oe_ppu & !ppu_off;
	
	assign int_cpu_data[7:0] = 
	bnk_ce 		? app_bank[3:0] : 
	timer_ce 	? timer_do[7:0] : 
	vram_ce_cpu ? vram_do_cpu[7:0] : 
	8'h00;

	
	wire reg_area 			= {cpu.addr[15:8], 8'h00}  == 16'h4100;
	wire ram_area 			= {cpu.addr[15:12], 12'd0} == 16'h5000;
	wire app_area 			= {cpu.addr[15:13], 13'd0} == 16'h6000;
	wire rom_area 			= cpu.addr[15];
	

	wire [7:0]reg_addr	= cpu.addr[7:0];
	wire regs_ce 			= reg_area;// & !mai.sys_rst & mai.os_act;
	wire regs_oe 			= regs_ce & cpu.rw == 1;
	wire regs_we 			= regs_ce & cpu.rw == 0;
	

	wire bnk_ce 			= regs_ce & reg_addr == REG_APP_BANK;
	wire timer_ce 			= regs_ce & {reg_addr[7:1], 1'b0} == REG_TIMER;
	
	
	reg [3:0]app_bank;
	reg ppu_off;//required for save state vram access. if ppu off int vram on and first 8k chr bank mapped
	
	always @(negedge cpu.m2)
	begin
	
		if(regs_we & bnk_ce)
		begin
			app_bank[3:0] 	<= cpu.data[3:0];
		end
		
		if(!cpu.rw & cpu.addr[15:0] == 16'h2001)
		begin
			ppu_off 			<= !cpu.data[3];
		end
		
	end
	
	
	
	wire [7:0]timer_do;
	
	timer timer_inst(
	
		.clk(mai.clk),
		.cpu(cpu),
		.timer_ce(timer_ce),
		.timer_do(timer_do)
	);

//****************************************************************************************************************** VRAM

	wire vram_ce_cpu = regs_ce & {reg_addr[7:2], 2'b00} == REG_VRAM_CTRL;//4 registers
	wire vram_oe_ppu, int_vram_ce, int_vram_tst;
	wire [7:0]vram_do_cpu;
	wire [3:0]atr_do;
	
	//tricky vram module for menu rendering
	vram vram_inst(
	
		.clk(mai.clk),
		.cpu(cpu),
		.ppu(ppu),
		.cpu_do(vram_do_cpu),
		.ppu_do(int_ppu_data), 
		.vram_ce(vram_ce_cpu), 
		.vram_oe_ppu(vram_oe_ppu), 
		.atr_do(atr_do),
		.int_vram_ce(int_vram_ce),
		.int_vram_tst(int_vram_tst)
	);
	

	endmodule

//********************************************************************************* VRAM
module vram(

	input clk,
	input CpuBus cpu,
	input PpuBus ppu,
	input vram_ce,
	
	output [7:0]cpu_do, ppu_do,
	output vram_oe_ppu, int_vram_ce, int_vram_tst,
	output [3:0]atr_do
);

	parameter REG_VRM_ADDR_LO	= 0;
	parameter REG_VRM_ADDR_HI	= 1;
	parameter REG_VRM_DATA 		= 2;
	parameter REG_VRM_ATTR		= 3;
	
	parameter VRAM_MODE_STD		= 0;
	parameter VRAM_MODE_SAF		= 1;
	parameter VRAM_MODE_TST		= 2;
	
	assign ppu_do[7:0] = ppu_atr_ce ? atr_val[7:0] : vram_do_ppu[7:0];
	
	assign cpu_do[7:0] = 
	ce_addr_lo 	? vram_addr_cpu[7:0] : 
	ce_addr_hi 	? vram_addr_cpu[15:8] : 
	ce_data 		? vram_do_cpu[7:0] : atr_do_cpu[3:0];//for screenshots
	//8'h00;
	
	wire [10:0]ppu_atr_addr;
	wire ppu_atr_ce;

	atr_ctrl atr_inst(
	
		.clk(clk), 
		.ppu_addr({ppu.addr[13:12], ppu.addr[10], ppu.addr[11], ppu.addr[9:0]}), 
		.ppu_oe(ppu.oe), 
		.ppu_atr_addr(ppu_atr_addr),
		.ppu_atr_ce(ppu_atr_ce)
	);
	
	wire vram_ce_ppu 		= ppu.addr[13];
	assign vram_oe_ppu 	= vram_ce_ppu & !ppu.oe & vram_mode == VRAM_MODE_STD;
	wire vram_we_ppu 		= 0;//vram_ce_ppu & !ppu_we;
	
	assign int_vram_ce 	= vram_ce_ppu & vram_mode == VRAM_MODE_SAF;
	assign int_vram_tst 	= vram_mode == VRAM_MODE_TST;
	
	wire vram_oe_cpu 		= ce_data & cpu.rw;
	wire vram_we_cpu 		= ce_data & !cpu.rw & cpu.m2 & vram_addr_cpu[15] == 0;//so attrib can be updated without name table changes
	wire ppu_dat_ce 		= cpu.addr[15:0] == 16'h2007;

	
	
	wire ce_addr_lo 		= vram_ce & cpu.addr[1:0] == REG_VRM_ADDR_LO;
	wire ce_addr_hi 		= vram_ce & cpu.addr[1:0] == REG_VRM_ADDR_HI;
	wire ce_data 			= vram_ce & cpu.addr[1:0] == REG_VRM_DATA;
	wire ce_attr 			= vram_ce & cpu.addr[1:0] == REG_VRM_ATTR;
	
	always @(negedge cpu.m2)
	begin
	
		if(cpu.rw == 0 & ce_addr_lo)
		begin
			vram_addr_cpu[7:0] 	<= cpu.data[7:0];
		end
		
		if(cpu.rw == 0 & ce_addr_hi)
		begin
			vram_addr_cpu[15:8] 	<= cpu.data[7:0];
		end
		
		if(cpu.rw == 0 & (ce_data | ppu_dat_ce))
		begin
			vram_addr_cpu[15:0] 	<= vram_addr_cpu[15:0] + 1;
		end
		
		if(cpu.rw == 1 & ce_data)
		begin
			cur_atr[3:0] 			<= atr_do_cpu[3:0];//used for back buffer copy
		end
		
		//if(!cpu_rw & ce_attr)vram_mode[2] <= cpu_dat[7];
		if(!cpu.rw & ce_attr & cpu.data[7:4] != 4'ha)
		begin
			cur_atr[3:0] 			<= {cpu.data[5:4], cpu.data[1:0]};
		end
		
		if(!cpu.rw & ce_attr & cpu.data[7:4] == 4'ha)
		begin
			vram_mode[1:0] 		<= cpu.data[1:0];
		end
	end
	
	
	wire vram_a10 = !cpu.rw ? vram_addr_cpu[10] : !vram_addr_cpu[10];
	
	wire [7:0]vram_do_ppu;
	wire [7:0]vram_do_cpu;
	reg [15:0]vram_addr_cpu;
	reg [2:0]vram_mode;
	
	ram_dp ntb_ram(
	
		.clk_a(!cpu.m2),
		.dati_a(cpu.data),
		.addr_a({vram_a10, vram_addr_cpu[9:0]}),
		.we_a(vram_we_cpu),
		.dato_a(vram_do_cpu),
		 
		.clk_b(clk),
		.dati_b(ppu.data),
		.addr_b({ppu.addr[11], ppu.addr[9:0]}),
		.we_b(vram_we_ppu),
		.dato_b(vram_do_ppu)
	);
	
	wire [3:0]atr_do_cpu;
	reg [3:0]cur_atr;
	wire atr_we 		= ce_data & !cpu.rw & cpu.m2;
	wire [7:0]atr_val = {atr_do[1:0], atr_do[1:0], atr_do[1:0], atr_do[1:0]};

	ram_dp atr_ram(
	
		.clk_a(!cpu.m2),
		.dati_a(cur_atr[3:0]),
		.addr_a({vram_a10, vram_addr_cpu[9:0]}),
		.we_a(atr_we),
		.dato_a(atr_do_cpu[3:0]),
		
		.clk_b(clk),
		.addr_b(ppu_atr_addr[10:0]),
		.dato_b(atr_do[3:0])
		
	);
	
endmodule

module atr_ctrl(
	
	input clk,
	input [13:0]ppu_addr,
	input ppu_oe,
	
	output reg[10:0]ppu_atr_addr,
	output ppu_atr_ce
);
	
	assign ppu_atr_ce = ppu_addr[13] == 1 & ppu_addr[9:6] == 4'b1111;
	wire ppu_ntb_ce 	= ppu_addr[13] == 1 & ppu_addr[9:6] != 4'b1111;
	
	//may be change it to the sync implementation
	always @(negedge ppu_oe)
	if(ppu_ntb_ce)
	begin
		ppu_atr_addr[10:0] <= ppu_addr[10:0];
	end
	
endmodule


//********************************************************************************* timer
module timer(

	input  clk,
	input  CpuBus cpu,
	input  timer_ce,
	
	output [7:0]timer_do
);


	//`include "../base/bus_in.v"

	
	assign timer_do[7:0] = cpu.addr[0] == 0 ? timer_ms[7:0] : time_ms_hi[7:0];
	
	reg [15:0]timer_1khz;
	reg tick_1khz;
	
	
	wire timer_ce_lo = timer_ce & cpu.addr[0] == 0;
	wire timer_ce_hi = timer_ce & cpu.addr[0] == 1;
	
	always @(posedge clk)
	if(timer_1khz == 16'd49999)
	begin
		timer_1khz 	<= 0;
		tick_1khz 	<= !tick_1khz;
	end
		else
	begin
		timer_1khz 	<= timer_1khz + 1;
	end
	
	
	reg[15:0]timer_ms;
	reg [7:0]time_ms_hi;
	reg [1:0]tick_1khz_st;
	
	always @(negedge cpu.m2)
	begin
	
		tick_1khz_st[1:0] <= {tick_1khz_st[0], tick_1khz};
		
		if(tick_1khz_st[0] != tick_1khz_st[1])
		begin
			timer_ms 		<= timer_ms + 1;
		end
		
		if(timer_ce & cpu.addr[0] == 0)
		begin
			time_ms_hi[7:0] <= timer_ms[15:8];
		end
		
	end
	
endmodule
 
 




