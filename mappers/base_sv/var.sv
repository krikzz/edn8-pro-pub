

//********************************************************************************* system reset detection
module sys_rst_ctrl(

	input  clk,
	input  m2,
	output rst
);
	
	assign rst = ctr[6];
	
	reg [1:0]m2_st;
	reg [6:0]ctr;
	
	always @(posedge clk)
	begin
		
		m2_st[1:0] <= {m2_st[0], m2};
		
		if(m2_st[0] != m2_st[1])
		begin
			ctr <= 0;
		end
			else
		if(!rst)
		begin
			ctr <= ctr + 1;
		end
	
	end
	
endmodule
//********************************************************************************* mapper reset
module map_rst_ctrl(

	input clk,
	input sys_rst, 
	input rst_ack, 
	input rst_delay,
	
	output reg rst_req
);	
	parameter DELAY_SIZE = 25;
	
	reg rst_st;
	reg rst_ack_st;
	reg [DELAY_SIZE:0]delay;
	
	wire rst_act = rst_st & (delay[DELAY_SIZE:DELAY_SIZE-1] == 2'b11 | !rst_delay);
	
	always @(posedge clk)
	begin
	
		rst_ack_st 	<= rst_ack;
		rst_st 		<= sys_rst;
		
		if(rst_act)
		begin
			rst_req 	<= 1;
		end
			else
		if(rst_ack_st)
		begin
			rst_req 	<= 0;
		end
		
		
		if(rst_st == 0)
		begin
			delay 	<= 0;
		end
			else
		if(rst_st == 1 & !rst_act)
		begin
			delay 	<= delay + 1;
		end
		
	end
	
endmodule
//********************************************************************************* 4-screen mirroring vram
module ppu_vram_ctrl(

	input  clk,
	input  CpuBus cpu,
	input  PpuBus ppu,
	input  map_ciram_a10,
	input  map_ciram_ce,
	input  mir_4s,
	
	output ppu_ciram_a10,
	output ppu_ciram_ce,
	output ppu_iram_oe,
	output [7:0]ppu_iram_do
);

	//wire mir_4sc_act = cfg.mc_mir_4 & mir_4sc;
	
	assign ppu_ciram_a10 = !mir_4s ? map_ciram_a10 : ppu.addr[10];
	assign ppu_ciram_ce =  !mir_4s ? map_ciram_ce  : !(!map_ciram_ce & ppu.addr[11] == 0);
	
	assign ppu_iram_oe = ppu_iram_ce & !ppu.oe;
	
	wire ppu_iram_ce = mir_4s & !map_ciram_ce & ppu.addr[11] == 1;
	
	ppu_ram ppu_ram_inst(

		.clk(clk),
		.din(ppu.data),
		.addr(ppu.addr[10:0]),
		.ce(ppu_iram_ce),
		.oe(!ppu.oe),
		.we(!ppu.we),
		.dout(ppu_iram_do)
	);
	
endmodule


module ppu_ram(

	input  clk,
	input  [7:0]din,
	input  [11:0]addr,
	input  ce, oe, we,

	output reg [7:0]dout
	
);
	
	reg [7:0]ram[4096];
	wire we_act = we & ce & !oe;
	
	
	always @(posedge clk)
	begin
		
		if(we_act)
		begin
			ram[addr][7:0] <= din[7:0];
		end
			else
		begin
			dout[7:0] 		<= ram[addr][7:0];
		end
		
	end

endmodule

//********************************************************************************* audio dac

module dac_ds(

	input  clk, 
	input  m2,
	input  [DEPTH-1:0]vol,
	input  [7:0]master_vol,
	output reg snd
);
	
	parameter DEPTH = 16;
	

	wire [DEPTH+1:0]delta;
	wire [DEPTH+1:0]sigma;
	

	reg [DEPTH+1:0] sigma_st;	
	reg [DEPTH-1:0] vol_mul;

	assign	delta[DEPTH+1:0] = {2'b0, vol_mul[DEPTH-1:0]} + {sigma_st[DEPTH+1], sigma_st[DEPTH+1], {(DEPTH){1'b0}}};
	assign	sigma[DEPTH+1:0] = delta[DEPTH+1:0] + sigma_st[DEPTH+1:0];

	
	reg mclk;
	always @(negedge m2)
	begin
		mclk <= !mclk;
	end
	
	always @(posedge mclk)
	begin
		vol_mul[DEPTH-1:0] 	<= (vol[DEPTH-1:0] * master_vol) / 128;
	end
	
	
	always @(posedge clk) 
	begin
		sigma_st[DEPTH+1:0] 	<= sigma[DEPTH+1:0];
		snd	<= !sigma_st[DEPTH+1];//inverted
	end
	
endmodule 
