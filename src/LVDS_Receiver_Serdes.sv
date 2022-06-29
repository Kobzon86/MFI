module LVDS_Receiver_Serdes (

	input         reset       ,
	
	input         serial_clock,
	input   [7:0] serial_data ,
	
	output        even_clock  ,
	output        even_hsync_n,
	output        even_vsync_n,
	output        even_de     ,
	output [23:0] even_data   ,
	output        even_locked ,
	
	output        odd_clock   ,
	output        odd_hsync_n ,
	output        odd_vsync_n ,
	output        odd_de      ,
	output [23:0] odd_data    ,
	output        odd_locked
	
);

	LVDS_RX_Single i_LVDS_RX0_Single (
		.reset       (reset           ),
		.serial_clock(serial_clock    ),
		.serial_data (serial_data[3:0]),
		.clock       (even_clock      ),
		.hsync_n     (even_hsync_n    ),
		.vsync_n     (even_vsync_n    ),
		.de          (even_de         ),
		.data        (even_data       ),
		.locked      (even_locked     )
	);

	LVDS_RX_Single i_LVDS_RX1_Single (
		.reset       (reset           ),
		.serial_clock(serial_clock    ),
		.serial_data (serial_data[7:4]),
		.clock       (odd_clock       ),
		.hsync_n     (odd_hsync_n     ),
		.vsync_n     (odd_vsync_n     ),
		.de          (odd_de          ),
		.data        (odd_data        ),
		.locked      (odd_locked      )
	);

endmodule

module LVDS_RX_Single (
	input               reset       ,
	input               serial_clock,
	input        [ 3:0] serial_data ,
	output              clock       ,
	output logic        hsync_n     ,
	output logic        vsync_n     ,
	output logic        de          ,
	output logic [23:0] data        ,
	output logic        locked
);

	logic video_clock;

	logic        align  ;
	logic [27:0] bus_out;

	logic [2:0] ctrl_delay;

	assign clock = video_clock;

	always_ff @(posedge video_clock) begin
		ctrl_delay <= bus_out[20:18];
		hsync_n    <= ctrl_delay[0];
		vsync_n    <= ctrl_delay[1];
		de         <= ctrl_delay[2];
		data       <= {bus_out[22:21], bus_out[5 :0], bus_out[24:23], bus_out[11:6], bus_out[26:25], bus_out[17:12]};
	end

	LVDS_RX LVDS_RX_inst (
		.rx_channel_data_align({4{align}}  ),
		.rx_inclock           (serial_clock),
		.rx_in                (serial_data ),
		.rx_out               (bus_out     ),
		.rx_outclock          (video_clock )
	);

	LVDS_Shifter #(.SYN_LENGTH(22)) i_LVDS_Shifter (
		.Parallel_Clock(video_clock),
		.reset         (reset      ),
		.HSync         (hsync_n    ),
		.align         (align      ),
		.locked        (locked     )
	);


endmodule

module LVDS_Shifter #(parameter SYN_LENGTH = 22) (
	input        Parallel_Clock,
	input        reset         ,
	input        HSync         ,
	output logic align         ,
	output logic locked
);

	localparam DEVIATION    = SYN_LENGTH >> 3;
	localparam IDLE_TIMEOUT = 2048           ;
	localparam DELAY_TO     = 192            ;

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

	always_ff @(posedge Parallel_Clock or posedge reset) begin
		if (reset) begin
			SyncCounter <= '0;
			Timeout     <= '0;
			Phase_State <= STATE_RESET;
		end
		else begin
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
							if (SyncCounter == 22 || SyncCounter == 68)
								Phase_State <= STATE_SHIFT;
							else begin
								Timeout     <= '0;
								Phase_State <= STATE_RESET;
								locked      <= 1'b1;
							end
						end
					end else
					Phase_State <= STATE_SHIFT;
				end

				STATE_SHIFT : begin
					locked      <= 1'b0;
					align       <= '1;
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
					align       <= '0;
					SyncCounter <= '0;
					Timeout     <= '0;
					Phase_State <= STATE_IDLE;
				end
			endcase
		end
	end

endmodule 