
module lvds_deser (
	input	[7:0]  rx_channel_data_align,
	input	[7:0]  rx_in,
	input	  rx_inclock,
	output	  rx_locked,
	output	logic [55:0]  rx_out,
	output	  rx_outclock
);

  logic       [1:0]fast_clock;
  logic       slow_clock;
  assign rx_outclock = slow_clock;
 

  logic [9:0] source;
  altsource_probe #(
    .sld_auto_instance_index ( "YES"  ),
    .sld_instance_index      ( 0      ),
    .instance_id             ( "fasa"  ),
    .probe_width             ( 0      ),
    .source_width            ( 10     ),
    .source_initial_value    ( "0"    ),
    .enable_metastability    ( "NO"   )
  ) altsource_probe_i (
    .source                  ( source ),
    .source_ena              ( 1'b1   )
  );
  
logic [7:0] data_align_cntr [7:0]; 
wire slow_phase = data_align_cntr[0][7]|data_align_cntr[4][7];  
pllll pllll_i
		(
			.refclk   (rx_inclock),
			.rst      (source[9]),
			.outclk_0 (fast_clock[0]),
			.outclk_1 (fast_clock[1]),
			.outclk_2 (slow_clock),
			.locked   (rx_locked),
			.phase_en(source[8] ? source[7] : (data_align_cntr[2][3]|data_align_cntr[6][3])),   //   phase_en.phase_en slow_phase|
			.scanclk(slow_clock),    //    scanclk.scanclk
			.updn(source[6]),       //       updn.updn
			.cntsel( source[8]?source[4:0]:{4'd0,(!data_align_cntr[0][3])} ),     //     cntsel.cntsel
			.phase_done()  // phase_done.phase_done
		);
		

//(* altera_attribute = "-name FAST_INPUT_REGISTER on" *) logic [7:0] in_bufer ;//
(* altera_attribute = "-name FAST_INPUT_REGISTER on" *)logic [7:0][13:0] data ;
logic [7:0][13:0] data_lat ;
logic [7:0][13:0] data_latch ;

always_ff @(posedge fast_clock[0] ) 
	begin		 
		 	for (int i = 0; i < 4; i++) begin
//				in_bufer[i] <= rx_in[i];
		 	 	data[i] <= {data[i][12:0],rx_in[i]};
		 	 	data_latch[i] <= data[i];
//		 	 	data_latch[i] <= data_lat[i];
		 	 end 
	end
always_ff @(posedge fast_clock[1] ) 
	begin		 
		 	for (int i = 4; i < 8; i++) begin
//				in_bufer[i] <= rx_in[i];
		 	 	data[i] <= {data[i][12:0],rx_in[i]};
		 	 	data_latch[i] <= data[i];
//		 	 	data_latch[i] <= data_lat[i];
		 	 end 
	end
	
	
logic [7:0][13:0] data_slow ;
logic [7:0][13:0] data_lat_slow ;
logic [7:0][13:0] data_latch_slow ;
logic [7:0] data_align_sig = 0;
always_ff @(posedge slow_clock ) 
	begin
		 for (int i = 0; i < 8; i++) begin
		  	data_slow[i] <= data_latch[i];
		  	data_lat_slow[i] <= data_slow[i];
		  	data_latch_slow[i] <= data_lat_slow[i]>>data_align_cntr[i][2:0];

		  	if( (!data_align_sig[i]) & rx_channel_data_align[i]) 
		  		data_align_cntr[i] <= data_align_cntr[i] + 3'd1;
				
			if( (|rx_channel_data_align) && data_align_cntr[i][3] )
				data_align_cntr[i]<='0;		   
		 end 

		 data_align_sig <= rx_channel_data_align;
		 
		 rx_out[6:0] <= data_latch_slow[0];
		 rx_out[13:7] <= data_latch_slow[1];
		 rx_out[20:14] <= data_latch_slow[2];
		 rx_out[27:21] <= data_latch_slow[3];
		 rx_out[34:28] <= data_latch_slow[4];
		 rx_out[41:35] <= data_latch_slow[5];
		 rx_out[48:42] <= data_latch_slow[6];
		 rx_out[55:49] <= data_latch_slow[7];
	end	

	
endmodule