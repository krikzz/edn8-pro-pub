


//chead codes
module cheats(
	
	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  cheats_on,
	input  [7:0]prg_do,
	
	output [7:0]cc_do,
	output cc_ce
	
);

	
	parameter CHEAT_NUM 	= 16;
	
	
	assign cc_ce	= slot_act != 0 & cheats_on & cpu.m2 & cpu.rw;
	
	wire [7:0]cpu_do[CHEAT_NUM];
	wire [15:0]slot_act;
	
	
	int ic;
	
	always_comb for (ic = 0, cc_do = 0; ic < CHEAT_NUM; ic++) begin
	
		if(slot_act[ic])
		begin
			cc_do		= cpu_do[ic];
		end
		
	end
		
	
	genvar ig;
	
	generate
	
		for (ig = 0; ig < CHEAT_NUM; ig++) begin: cc_slot_block 
		
			cc_slot cc_slot_inst(
			
				.slot(ig), 
				.clk(clk), 
				.cpu(cpu), 
				.prg_do(prg_do), 
				.pi(pi), 
				.slot_act(slot_act[ig]),
				.cpu_do(cpu_do[ig])
			);	
			
		end
				
	endgenerate
	

endmodule



module cc_slot(
	
	input  clk,
	input  PiBus pi,
	input  CpuBus cpu,
	input  [5:0]slot,
	input  [7:0]prg_do,
	
	output slot_act,
	output [7:0]cpu_do
);

	assign cpu_do[7:0] 	= slot_act ? val_new[7:0] : 8'h00;
	
	assign slot_act		= cpu.m2 & cpu.rw & rd_ok & code_eq;
	
	wire gg_ce 				= pi.map.ce_cc & pi.addr[7:2] == slot[5:0];
	wire gg_we 				= gg_ce & pi.we & pi.act;
	wire code_eq 			= addr_eq & (data_eq | data_cmp_off);
	wire addr_eq 			= cpu.addr[15:0] == addr[15:0] & addr[15];//0x8000-0xffff area. upper bit turn on/off slot
	wire data_eq 			= val_cmp[7:0] == prg_do[7:0];
	wire data_cmp_off 	= val_cmp[7:0] == val_new[7:0];
	
	reg [15:0]addr;
	reg [7:0]val_cmp;
	reg [7:0]val_new;
	

	always @(posedge clk)
	if(gg_we)
	case(pi.addr[1:0])
		0:addr[7:0]			<= pi.dato[7:0];
		1:addr[15:8]		<= pi.dato[7:0];
		2:val_cmp[7:0]		<= pi.dato[7:0];
		3:val_new[7:0]		<= pi.dato[7:0];
	endcase

	wire rd_act	= cpu.m2 & cpu.rw;
	wire rd_ok 	= rd_delay == 4;//+1 cycle at rd_act_st latch delay
	
	reg rd_act_st;
	reg [3:0]rd_delay;
	reg rd_st;
	
	always @(posedge clk)
	begin
		
		rd_act_st		<= rd_act;
		
		if(!rd_act_st)
		begin
			rd_delay 	<= 0;
		end
			else
		if(!rd_ok)
		begin
			rd_delay		<= rd_delay + 1;
		end
		
	end
	
endmodule

