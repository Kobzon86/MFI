
/*
 * LVDS Display Interface receiver
 */

module ldi_basic_reciever #(  
 
  parameter pixels_in_parallel  = 2
  
) (
  
  input                              reset_n,
  
  input     [pixels_in_parallel-1:0] ldi_clock,
  input   [4*pixels_in_parallel-1:0] ldi_data,
  
  output logic    [pixels_in_parallel-1:0] clock,
  output logic    [pixels_in_parallel-1:0] hsync_n,
  output logic    [pixels_in_parallel-1:0] vsync_n,
  output logic    [pixels_in_parallel-1:0] de,
  output logic [24*pixels_in_parallel-1:0] data,
  output logic    [pixels_in_parallel-1:0] locked
  
);
  
  localparam FREQ = 74_250_000;
  

  logic       pll_reset;
  logic [4:0] pll_clk;
  logic       pll_locked;
  
  logic       pll_phase_step;
  logic       pll_phase_dir;
  logic [4:0] pll_phase_cntsel;
  logic       pll_phase_done;
  
  logic [4:0] fast_cntsel;
  logic [4:0] slow_cntsel;
 
 
  logic [9:0] source;
  altsource_probe #(
    .sld_auto_instance_index ( "YES"  ),
    .sld_instance_index      ( 0      ),
    .instance_id             ( "LDI"  ),
    .probe_width             ( 0      ),
    .source_width            ( 10     ),
    .source_initial_value    ( "0"    ),
    .enable_metastability    ( "NO"   )
  ) altsource_probe_i (
    .source                  ( source ),
    .source_ena              ( 1'b1   )
  );
  
  (* noprune *) logic [55:0] pix_data;
   (* noprune *) logic rx_locked_sig; 
  logic [1:0] align_bits;
		wire [7:0] data_align = source[7] ? 
              {source[1],source[1],source[1],source[1],source[0],source[0],source[0],source[0]} :
              {align_bits[1],align_bits[1],align_bits[1],align_bits[1],align_bits[0],align_bits[0],align_bits[0],align_bits[0]};

	
				  
	
logic slow_clock;				  
  lvds_deser	lvds_rx_inst (
	.rx_channel_data_align ( data_align ),
	.rx_in ( ldi_data ),
	.rx_inclock ( ldi_clock ),
	.rx_locked ( rx_locked_sig ),
	.rx_out ( pix_data ),
	.rx_outclock ( slow_clock )
	);
assign clock = {slow_clock,slow_clock};
  
wire [27:0]pix[1:0];
assign pix[0] = pix_data[27:0];
assign pix[1] = pix_data[55:28];
  
wire [7:0] pixel1_red = {pix[0][22:21],pix[0][5:0]};
wire [7:0] pixel1_grn = {pix[0][24:23],pix[0][11:6]};
wire [7:0] pixel1_blu = {pix[0][26:25],pix[0][17:12]};

wire [7:0] pixel2_red = {pix[1][22:21],pix[1][5:0]};
wire [7:0] pixel2_grn = {pix[1][24:23],pix[1][11:6]};
wire [7:0] pixel2_blu = {pix[1][26:25],pix[1][17:12]};


wire [23:0]data_t[1:0];
assign data_t[1] = {pixel2_red,pixel2_grn,pixel2_blu};
assign data_t[0] = {pixel1_red,pixel1_grn,pixel1_blu};
wire [1:0]hsync_n_t = {pix[1][18], pix[0][18]};
wire [1:0]vsync_n_t = {pix[1][19], pix[0][19]};
wire [1:0]de_t = {pix[1][20], pix[0][20]};


always_ff @(posedge slow_clock )begin
		 data <= {data_t[1], data_t[0]};
		 hsync_n <= {hsync_n_t[1], hsync_n_t[0]};
		 vsync_n <= {vsync_n_t[1], vsync_n_t[0]};
		 de <= {de_t[1], de_t[0]};
	locked<={(|locked_t),(|locked_t)};
//	case(locked_t)
//
//		2'b01:begin
//		 data <= {data_t[0], data_t[0]};
//		 hsync_n <= {hsync_n_t[0], hsync_n_t[0]};
//		 vsync_n <= {vsync_n_t[0], vsync_n_t[0]};
//		 de <= {de_t[0], de_t[0]};
//		end
//		2'b10:begin
//		 data <= {data_t[1], data_t[1]};
//		 hsync_n <= {hsync_n_t[1], hsync_n_t[1]};
//		 vsync_n <= {vsync_n_t[1], vsync_n_t[1]};
//		 de <= {de_t[1], de_t[1]};
//		end
//		default:begin
//		 data <= {data_t[1], data_t[0]};
//		 hsync_n <= {hsync_n_t[1], hsync_n_t[0]};
//		 vsync_n <= {vsync_n_t[1], vsync_n_t[0]};
//		 de <= {de_t[1], de_t[0]};
//		end
//	endcase
end

logic [11:0] de_buf [1:0][4:0];
logic [1:0] de_sig; 

logic [11:0] h_buf [1:0][4:0];
logic [1:0] h_sig; 

logic [11:0] v_buf [1:0];
logic [1:0] v_sig; 

logic [23:0]data_half [1:0];
assign data_half[0] = data[23:0]; 
assign data_half[1] = data[47:24];
logic [7:0] notde[1:0];
logic [7:0] notde_latch[1:0];
always_ff @(posedge slow_clock or negedge reset_n)
  if(~reset_n) begin
     de_sig <= '0;
     for (int i = 0; i < 5; i++) begin
      de_buf[0][i] <= '0;
      de_buf[1][i] <= '0;
		h_buf[0][i] <= '0;
      h_buf[1][i] <= '0;
     end
  end else begin
    de_sig <= de_t;
	 h_sig <= hsync_n_t;
    for (int i = 0; i < pixels_in_parallel; i++) begin
    ///////de 
	  if(de_t[i]) begin 
        de_buf[i][0] <= de_buf[i][0] + 1'b1;
      end
      else begin 
        if(de_sig[i])begin
          de_buf[i][1] <=  de_buf[i][0];
          de_buf[i][2] <=  de_buf[i][1];
          de_buf[i][3] <=  de_buf[i][2];
          de_buf[i][4] <=  de_buf[i][3];
        end
        de_buf[i][0] <= '0;
      end

		//////////
		////h
		if(!hsync_n_t[i]) begin 
          h_buf[i][0] <= h_buf[i][0] + 1'b1;
		    notde[i] <= notde[i] + (data_t[i] == 24'h101010  );
		end
      else begin 
        if(!h_sig[i])begin
          h_buf[i][1] <=  h_buf[i][0];
          h_buf[i][2] <=  h_buf[i][1];
          h_buf[i][3] <=  h_buf[i][2];
			 notde_latch[i] <= notde[i];		 
        end
        h_buf[i][0] <= '0; 
			notde[i] <='0;
      end		
		
    end 
  end

logic [27:0] timer;
localparam PERIOD = FREQ/10/4;
wire timer_event = timer == PERIOD;
reg [1:0] not_zero; 

reg [1:0] h_not_zero; 
reg [1:0]locked_t;
always_ff @(posedge slow_clock or negedge reset_n) 
  if(~reset_n) begin
     locked_t<= '0;
     timer <= '0;
     align_bits <= '0;
  end else begin
    timer <= (timer_event)? 0 : (timer + 1);
    align_bits <= '0;
    if(rx_locked_sig && timer_event)
      for (int i = 0; i < pixels_in_parallel; i++) begin
        if( (de_buf[i][1][11:1] == de_buf[i][2][11:1]) &&
		      ( de_buf[i][2] > (640/2-10) ) &&
				( de_buf[i][2] < (1920/2+10) ) &&
				( notde_latch[i] == h_buf[i][3] )		)//
          locked_t[i] <= 1'b1;
        else begin
          locked_t[i] <= 1'b0;  
			 align_bits[i] <= 1'b1; 			 
        end		  
		  
		end     		
		
  end
  
endmodule
