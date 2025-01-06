

typedef struct{
	
	bit [7:0]dati;
	bit [22:0]addr;
	bit ce, oe, we;
	bit async_io;//if prg/srm controlled not by cpu 
	
}MemCtrl;

//********

typedef struct{

	bit [7:0]data;
	bit [15:0]addr;
	bit rw;
	bit m2;
	bit m3;
	
}CpuBus;

//********

typedef struct{

	bit [7:0]data;
	bit [13:0]addr;
	bit oe;
	bit we;

}PpuBus;

//********

typedef struct {
	
	bit clk;		//50Mhz master clock
	bit fds_sw;	//cart button
	bit sys_rst;//cpu reset
	bit map_rst;//mapper reset
	
	bit [7:0]prg_do;//prg rom data out
	bit [7:0]chr_do;//chr rom data out
	bit [7:0]srm_do;//bram data out
	
	SysCfg cfg;//mapper and sys config
	SSTBus sst;//save state control
	CpuBus cpu;
	PpuBus ppu;
	
}MapIn;

//********

typedef struct {

	bit prg_mask_off; 
	bit chr_mask_off;
	bit srm_mask_off;
	bit mir_4sc;
	bit bus_cf;
	
	bit ciram_a10;
	bit ciram_ce;
	bit irq;
	bit chr_xram_ce;//for mapper with chr ram+rom
	bit led;
	bit [15:0]snd;
	
	
	bit map_cpu_oe;
	bit map_ppu_oe;
	bit [7:0]map_cpu_do;
	bit [7:0]map_ppu_do;
	
	bit [7:0]sst_di;
	
	MemCtrl prg;//prg rom
	MemCtrl chr;//chr rom
	MemCtrl srm;//bram
	
}MapOut;

//********

typedef struct{
	
	
	bit ce_prg;
	bit ce_chr;
	bit ce_srm;
	bit ce_sys;
	
	//all below located in ce_sys area
	bit ce_cfg;
	bit ce_cc;
	
	bit ce_sst;
	
	bit ce_fifo;
		
}PiMap;

//********

typedef struct{

	bit [7:0]dato;
	bit [31:0]addr;
	bit we;//write mode
	bit oe;//read mode
	bit act;//memory read or write during act=1 pulse
	PiMap map;

}PiBus;

//********

typedef struct{
	
	MemCtrl mem;
	
	bit [7:0]pi_di;
	bit req_prg, req_chr, req_srm;
	bit mem_req;
	
}DmaBus;

//********

typedef struct{
	
	bit [11:0]map_idx;
	
	bit [9:0]prg_msk;
	bit [9:0]chr_msk;
	bit [10:0]srm_msk;
	bit [1:0]fds_msk;
	bit [7:0]master_vol;
	bit [7:0]ss_key_save;
	bit [7:0]ss_key_load;
	bit [7:0]ss_key_menu;
	
	
	bit ct_rst_delay;
	bit ct_ss_on;
	bit ct_gg_on;
	bit ct_ss_btn;
	bit ct_fami;
	bit ct_unlock;
	
	bit mir_h;
	bit mir_v;
	bit mir_4;
	bit mir_1;
	bit chr_ram;
	bit prg_ram_off;
	bit [3:0]map_sub;
	
	bit[7:0]jumper;
	
	bit [18:0]srm_size;
	
}SysCfg;


//save state stuff
typedef struct{

	bit [12:0]addr;
	bit act;
	bit act_mc;//for blocks driven by master clock
	bit we;
	
	bit we_reg;
	bit we_mem;
	
	bit [7:0]dato;
	
}SSTBus;

