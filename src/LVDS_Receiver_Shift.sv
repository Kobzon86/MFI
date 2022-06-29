module LVDS_Receiver_Shift #(
	
	parameter COLOR_MODE = "_SPWG" //"JEIDA", "_SPWG"
	
)(
	
	input         reset        ,
	
	input         serial_clock ,
	input   [7:0] serial_data  ,
	
	output        even_clock   ,
	output        even_hsync_n ,
	output        even_vsync_n ,
	output        even_de      ,
	output [23:0] even_data    ,
	output        even_locked  ,
	
	output        odd_clock    ,
	output        odd_hsync_n  ,
	output        odd_vsync_n  ,
	output        odd_de       ,
	output [23:0] odd_data     ,
	output        odd_locked   
	
);



logic PLL_RefClk;

logic Fast_Clock;
logic Slow_Clock;

logic [6:0] LatchData_D[7:0];

logic PLL_Locked   ;
logic Align_e      ;
logic PLL_PhaseDone;

assign even_clock = Slow_Clock;
assign odd_clock  = Slow_Clock;



cyclonev_clkena #(
	.clock_type        ( "Auto"            ),
	.ena_register_mode ( "falling edge"    ),
	.lpm_type          ( "cyclonev_clkena" )
) LVDS_ClkCtrl ( 
	.ena               ( 1'b1              ),
	.enaout            (                   ),
	.inclk             ( serial_clock      ),
	.outclk            ( PLL_RefClk        )
);



LvdsInputSdrPll i_LvdsInputSdrPll (
	.refclk    (PLL_RefClk   ),
	.rst       (reset        ),
	.outclk_0  (Fast_Clock   ),
	.outclk_1  (Slow_Clock   ),
	.locked    (PLL_Locked   ),
	.phase_en  (Align_e      ),
	.scanclk   (PLL_RefClk   ),
	.updn      (1'b1         ),
	.cntsel    (5'b00001     ),
	.phase_done(PLL_PhaseDone)
);



SerDes SerDes_e (
	.Fast_Clock_i( Fast_Clock       ),
	.Slow_Clock_i( Slow_Clock       ),
	.Data_i      ( serial_data[3:0] ),
	.Data_o      ( LatchData_D[3:0] )
);

SerDes SerDes_o (
	.Fast_Clock_i( Fast_Clock       ),
	.Slow_Clock_i( Slow_Clock       ),
	.Data_i      ( serial_data[7:4] ),
	.Data_o      ( LatchData_D[7:4] )
);



LVDS_Align #(
	.SYN_LENGTH(22)
)LVDS_Align_e (
	.clk_i   ( Slow_Clock   ),
	.reset_i ( reset        ),
	.HSync   ( even_hsync_n ),
	.Align_o ( Align_e      ),
	.Locked_o( even_locked  )
);

LVDS_Align #(
	.SYN_LENGTH(22)
) LVDS_Align_o (
	.clk_i   ( Slow_Clock  ),
	.reset_i ( reset       ),
	.HSync   ( odd_hsync_n ),
	.Locked_o( odd_locked  )
);



generate

if (COLOR_MODE == "JEIDA") begin
	always_ff @(posedge Slow_Clock) begin
		even_hsync_n <= LatchData_D[2][4];
		even_vsync_n <= LatchData_D[2][5];
		even_de      <= LatchData_D[2][6];
		even_data    <= { LatchData_D[0][5:0], LatchData_D[3][1:0], LatchData_D[1][4:0], LatchData_D[0][6], LatchData_D[3][3:2], LatchData_D[2][3:0], LatchData_D[1][6:5], LatchData_D[3][5:4] };
		odd_hsync_n  <= LatchData_D[6][4];
		odd_vsync_n  <= LatchData_D[6][5];
		odd_de       <= LatchData_D[6][6];
		odd_data     <= { LatchData_D[4][5:0], LatchData_D[7][1:0], LatchData_D[5][4:0], LatchData_D[4][6], LatchData_D[7][3:2], LatchData_D[6][3:0], LatchData_D[5][6:5], LatchData_D[7][5:4] };
	end
end

if (COLOR_MODE == "_SPWG") begin
	always_ff @(posedge Slow_Clock) begin
		even_hsync_n <= LatchData_D[2][4];
		even_vsync_n <= LatchData_D[2][5];
		even_de      <= LatchData_D[2][6];
		even_data    <= { LatchData_D[3][1:0], LatchData_D[0][5:0], LatchData_D[3][3:2], LatchData_D[1][4:0], LatchData_D[0][6], LatchData_D[3][5:4], LatchData_D[2][3:0], LatchData_D[1][6:5] };
		odd_hsync_n  <= LatchData_D[6][4];
		odd_vsync_n  <= LatchData_D[6][5];
		odd_de       <= LatchData_D[6][6];
		odd_data     <= { LatchData_D[7][1:0], LatchData_D[4][5:0], LatchData_D[7][3:2], LatchData_D[5][4:0], LatchData_D[4][6], LatchData_D[7][5:4], LatchData_D[6][3:0], LatchData_D[5][6:5] };
	end
end

endgenerate



endmodule



module SerDes (
	input              Fast_Clock_i,
	input              Slow_Clock_i,
	input        [3:0] Data_i      ,
	output logic [6:0] Data_o[3:0]
);

	logic [3:0] Data_r;
	logic [6:0] Des_Data[3:0];

	altddio_in #(
		.intended_device_family ( "Cyclone V"  ),
		.invert_input_clocks    ( "OFF"        ),
		.lpm_hint               ( "UNUSED"     ),
		.lpm_type               ( "altddio_in" ),
		.power_up_high          ( "OFF"        ),
		.width                  ( 4            )
	) ALTDDIO_IN_component (
		.datain   ( Data_i       ),
		.inclock  ( Fast_Clock_i ),
		.dataout_h( Data_r       ),
		.aclr     ( 1'b0         ),
		.aset     ( 1'b0         ),
		.inclocken( 1'b1         ),
		.sclr     ( 1'b0         ),
		.sset     ( 1'b0         )
	);

	always_ff @(posedge Fast_Clock_i) begin
		for (int i = 0; i < 4; i++) begin
			Des_Data[i]   <= {Des_Data[i][5:0], Data_r[i]};
		end
	end

	always_ff @(posedge Slow_Clock_i) begin
		Data_o <= Des_Data;
	end

endmodule



module LVDS_Align #(parameter SYN_LENGTH = 128) (
	input        clk_i   ,
	input        reset_i ,
	input        HSync   ,
	output logic Align_o ,
	output logic Locked_o
);

	localparam DEVIATION    = SYN_LENGTH >> 3;
	localparam IDLE_TIMEOUT = 2048                ;
	localparam DELAY_TO     = 192                 ;

	enum logic [3:0] {
		STATE_IDLE,
		STATE_BLANK,
		STATE_SHIFT,
		STATE_WAIT,
		STATE_RESET
	} Phase_State;

	logic [                10:0] Timeout    ;
	logic [                 9:0] SyncCounter;
	logic [$clog2(DELAY_TO)-1:0] Delay      ;

	always_ff @(posedge clk_i or posedge reset_i) begin
		if(reset_i) begin
			Align_o     <= '0;
			SyncCounter <= '0;
			Timeout     <= '0;
			Locked_o    <= '0;
			Phase_State <= STATE_RESET;
		end else begin
			case (Phase_State)
				STATE_IDLE : begin
					if (Timeout < (IDLE_TIMEOUT - 1)) begin
						if (~HSync)
							Phase_State <= STATE_BLANK;
						Timeout <= Timeout + 1'b1;
					end else
					Phase_State <= STATE_SHIFT;
				end

				STATE_BLANK : begin
					if (Timeout < (IDLE_TIMEOUT - 1)) begin
						if (~HSync) begin
							SyncCounter <= SyncCounter + 1'b1;
							Timeout     <= Timeout + 1'b1;
						end else begin
							if (SyncCounter < (SYN_LENGTH - DEVIATION) || SyncCounter > (SYN_LENGTH + DEVIATION))
								Phase_State <= STATE_SHIFT;
							else begin
								Timeout     <= '0;
								Phase_State <= STATE_RESET;
								Locked_o    <= 1'b1;
							end
						end
					end else
					Phase_State <= STATE_SHIFT;
				end

				STATE_SHIFT : begin
					Locked_o    <= 1'b0;
					Align_o     <= '1;
					Phase_State <= STATE_WAIT;
				end

				STATE_WAIT : begin
					if (Delay < DELAY_TO)
						Delay <= Delay + 1'b1;
					else
						Phase_State <= STATE_RESET;
				end

				default : begin
					Delay       <= '0;
					Align_o     <= '0;
					SyncCounter <= '0;
					Timeout     <= '0;
					Phase_State <= STATE_IDLE;
				end
			endcase
		end
	end

endmodule
