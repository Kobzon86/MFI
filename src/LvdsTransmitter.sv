module LvdsTransmitter (
	input              reset_n    ,
	input              color_mode ,
	input              Video_Clock,
	input              Video_HSync,
	input              Video_VSync,
	input              Video_Blank,
	input        [7:0] Video_Red  ,
	input        [7:0] Video_Green,
	input        [7:0] Video_Blue ,
	output logic       LVDS_Clock ,
	output logic [3:0] LVDS_Data
);

	logic pll_reset;
	logic pll_locked;

	logic Serial_Clock  ;
	logic Parallel_Clock;

	logic       HSync_D, HSync_Q;
	logic       VSync_D, VSync_Q;
	logic       Blank_D, Blank_Q;
	logic [7:0] Red_D,   Red_Q;
	logic [7:0] Green_D, Green_Q;
	logic [7:0] Blue_D,  Blue_Q;

	logic[6:0] encoded_data[3:0];

	logic [3:0] ser_data;
	logic       ser_clk ;
	logic [2:0] cnt     ;

	LvdsOutputSdrPll LvdsOutputSdrPll_0 (
		.rst     (pll_reset     ),
		.refclk  (Video_Clock   ),
		.outclk_0(Serial_Clock  ),
		.outclk_1(Parallel_Clock),
		.locked  (pll_locked    )
	);


	always_ff @(posedge Parallel_Clock)
		begin
			HSync_D <= Video_HSync;
			VSync_D <= Video_VSync;
			Blank_D <= Video_Blank;
			Red_D   <= Video_Red  ;
			Green_D <= Video_Green;
			Blue_D  <= Video_Blue ;

			HSync_Q <= HSync_D;
			VSync_Q <= VSync_D;
			Blank_Q <= Blank_D;
			Red_Q   <= Red_D  ;
			Green_Q <= Green_D;
			Blue_Q  <= Blue_D ;
		end

	logic [1:0] source;

	altsource_probe #(
	  .sld_auto_instance_index ( "YES"  ),
	  .sld_instance_index      ( 0      ),
	  .instance_id             ( "LVDS" ),
	  .probe_width             ( 0      ),
	  .source_width            ( 2      ),
	  .source_initial_value    ( "0"    ),
	  .enable_metastability    ( "NO"   )
	) altsource_probe_i (
	  .source                  ( source ),
	  //.probe                   (        ),
	  .source_ena              ( 1'b1   )
	);

	logic color_mode_l;

	assign color_mode_l = (source[1]) ? source[0] : color_mode;

	always_ff @(posedge Parallel_Clock)
		begin
			if (color_mode_l)
				begin
					encoded_data[3] <= {'0, Blue_Q[1:0], Green_Q[1:0], Red_Q[1:0]};
					encoded_data[2] <= {Blank_Q, VSync_Q, HSync_Q, Blue_Q[7:4]};
					encoded_data[1] <= {Blue_Q[3:2], Green_Q[7:3]};
					encoded_data[0] <= {Green_Q[2], Red_Q[7:2]};
				end
			else
				begin
					encoded_data[3] <= {'0, Blue_Q[7:6], Green_Q[7:6], Red_Q[7:6]};
					encoded_data[2] <= {Blank_Q, VSync_Q, HSync_Q, Blue_Q[5:2]};
					encoded_data[1] <= {Blue_Q[1:0], Green_Q[5:1]};
					encoded_data[0] <= {Green_Q[0], Red_Q[5:0]};
				end
		end

		(* dont_merge *) logic [3:0] upd_en;
		
		generate
			genvar i;

			for (i = 0; i < 4; i++)
				begin: shift_reg_gen
					lvds_tx_shiftreg lvds_tx_shiftreg_inst (
						.Serial_Clock(Serial_Clock   ),
						.data        (encoded_data[i]),
						.Serial_data (ser_data[i]    ),
						.upd_en      (upd_en[i]      )
					);
				end

		endgenerate

		lvds_tx_shiftreg lvds_tx_shiftreg_clk (
			.Serial_Clock(Serial_Clock),
			.data        (7'b1100011  ),
			.Serial_data (ser_clk     ),
			.upd_en      (upd_en[0]   )
		);

		always_ff @(posedge Serial_Clock)
			begin
				LVDS_Data  <= ser_data;
				LVDS_Clock <= ser_clk;
				if (cnt < 6)
					begin
						cnt    <= cnt + 1'b1;
						upd_en <= '1;
					end
				else
					begin
						upd_en <= '0;
						cnt    <= '0;
					end
			end


endmodule

module lvds_tx_shiftreg (
	input        Serial_Clock,
	input        upd_en      ,
	input  [6:0] data        ,
	output       Serial_data
);

	logic [6:0] shift_reg;

	assign Serial_data = shift_reg[6];

	always_ff @(posedge Serial_Clock)
		begin
			if (upd_en)
				shift_reg <= {shift_reg[5:0], 1'b0};
			else
				shift_reg <= data;
		end


endmodule