

module map_hub(
	input  MapIn mai,
	output MapOut mao
);

	
	assign mao = 
	mai.cfg.map_idx == 1		? map_out_001 :
	mai.cfg.map_idx == 4   	& mai.cfg.map_sub == 1 ? map_out_004_s1 :
	mai.cfg.map_idx == 4   	& mai.cfg.map_sub == 3 ? map_out_004_s3 :
	mai.cfg.map_idx == 4		? map_out_004 :
	mai.cfg.map_idx == 9		? map_out_009 :
	mai.cfg.map_idx == 10	? map_out_009 :
	mai.cfg.map_idx == 155	? map_out_001 : 
	map_out_nom;
	
	MapOut map_out_nom;
	map_nom mnom(mai, map_out_nom);

	
	MapOut map_out_001;
	map_001 m001(mai, map_out_001);
	
	MapOut map_out_004;
	map_004 m004(mai, map_out_004);
	
	MapOut map_out_004_s1;
	map_004_s1 m004_s1(mai, map_out_004_s1);
	
	MapOut map_out_004_s3;
	map_004_s3 m004_s3(mai, map_out_004_s3);
	
	MapOut map_out_009;
	map_009 m009(mai, map_out_009);
	
endmodule
