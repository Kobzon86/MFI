/*
 * LVDS display interface receiver
 */

module lvds_receiver #(
  
  parameter family     = "Cyclone V",
  parameter clock_rate = "sdr"
  
)(
  
  input         reset_n,
  input         clk,
  
  input         color_mode,
  
  input         serial_clk,
  input   [3:0] serial_data,
  
  output        clock,
  output        hsync_n,
  output        vsync_n,
  output        de,
  output [23:0] data,
  output        locked
  
);

localparam hsync_min_length = 16'd16;
localparam hsync_min_period = 16'd512;
localparam hsync_max_period = 16'd65534;

localparam vsync_min_length = 24'd4096;
localparam vsync_min_period = 24'd1048576;
localparam vsync_max_period = 24'd16777214;

localparam de_min_period    = 16'd800;
localparam de_max_period    = 16'd65534;

localparam locked_c0_steps  = 8'd16;
localparam locked_timeout   = 32'd4000000;



wire [3:0] fast_clock;
wire       slow_clock;
wire       pll_reset;
wire       pll_locked;
wire       pll_phase_en;
wire       pll_phase_updn;
wire [4:0] pll_phase_cntsel;
wire       pll_phase_done;

    altera_pll #(
      .fractional_vco_multiplier ( "false"                    ),
      .reference_clock_frequency ( "74.25 MHz"                ),
      .pll_fractional_cout       ( 32                         ),
      .pll_dsm_out_sel           ( "1st_order"                ),
      .operation_mode            ( "source synchronous"       ),
      .number_of_clocks          ( 5                          ),
      .output_clock_frequency0   ( "519.750000 MHz"           ),
      .phase_shift0              ( "962 ps"                   ),
      .duty_cycle0               ( 50                         ),
      .output_clock_frequency1   ( "519.750000 MHz"           ),
      .phase_shift1              ( "962 ps"                   ),
      .duty_cycle1               ( 50                         ),
      .output_clock_frequency2   ( "519.750000 MHz"           ),
      .phase_shift2              ( "962 ps"                   ),
      .duty_cycle2               ( 50                         ),
      .output_clock_frequency3   ( "519.750000 MHz"           ),
      .phase_shift3              ( "962 ps"                   ),
      .duty_cycle3               ( 50                         ),
      .output_clock_frequency4   ( "74.250000 MHz"            ),
      .phase_shift4              ( "0 ps"                     ),
      .duty_cycle4               ( 50                         ),
      .pll_type                  ( "Cyclone V"                ),
      .pll_subtype               ( "DPS"                      ),
      .m_cnt_hi_div              ( 4                          ),
      .m_cnt_lo_div              ( 3                          ),
      .n_cnt_hi_div              ( 256                        ),
      .n_cnt_lo_div              ( 256                        ),
      .m_cnt_bypass_en           ( "false"                    ),
      .n_cnt_bypass_en           ( "true"                     ),
      .m_cnt_odd_div_duty_en     ( "true"                     ),
      .n_cnt_odd_div_duty_en     ( "false"                    ),
      .c_cnt_hi_div0             ( 256                        ),
      .c_cnt_lo_div0             ( 256                        ),
      .c_cnt_prst0               ( 1                          ),
      .c_cnt_ph_mux_prst0        ( 4                          ),
      .c_cnt_in_src0             ( "ph_mux_clk"               ),
      .c_cnt_bypass_en0          ( "true"                     ),
      .c_cnt_odd_div_duty_en0    ( "false"                    ),
      .c_cnt_hi_div1             ( 256                        ),
      .c_cnt_lo_div1             ( 256                        ),
      .c_cnt_prst1               ( 1                          ),
      .c_cnt_ph_mux_prst1        ( 4                          ),
      .c_cnt_in_src1             ( "ph_mux_clk"               ),
      .c_cnt_bypass_en1          ( "true"                     ),
      .c_cnt_odd_div_duty_en1    ( "false"                    ),
      .c_cnt_hi_div2             ( 256                        ),
      .c_cnt_lo_div2             ( 256                        ),
      .c_cnt_prst2               ( 1                          ),
      .c_cnt_ph_mux_prst2        ( 4                          ),
      .c_cnt_in_src2             ( "ph_mux_clk"               ),
      .c_cnt_bypass_en2          ( "true"                     ),
      .c_cnt_odd_div_duty_en2    ( "false"                    ),
      .c_cnt_hi_div3             ( 256                        ),
      .c_cnt_lo_div3             ( 256                        ),
      .c_cnt_prst3               ( 1                          ),
      .c_cnt_ph_mux_prst3        ( 4                          ),
      .c_cnt_in_src3             ( "ph_mux_clk"               ),
      .c_cnt_bypass_en3          ( "true"                     ),
      .c_cnt_odd_div_duty_en3    ( "false"                    ),
      .c_cnt_hi_div4             ( 4                          ),
      .c_cnt_lo_div4             ( 3                          ),
      .c_cnt_prst4               ( 1                          ),
      .c_cnt_ph_mux_prst4        ( 0                          ),
      .c_cnt_in_src4             ( "ph_mux_clk"               ),
      .c_cnt_bypass_en4          ( "false"                    ),
      .c_cnt_odd_div_duty_en4    ( "true"                     ),
      .pll_vco_div               ( 2                          ),
      .pll_cp_current            ( 20                         ),
      .pll_bwctrl                ( 2000                       ),
      .pll_output_clk_frequency  ( "519.75 MHz"               ),
      .pll_fractional_division   ( "1"                        ),
      .mimic_fbclk_type          ( "gclk"                     ),
      .pll_fbclk_mux_1           ( "glb"                      ),
      .pll_fbclk_mux_2           ( "m_cnt"                    ),
      .pll_m_cnt_in_src          ( "ph_mux_clk"               ),
      .pll_slf_rst               ( "false"                    )
    ) lvds_sdr_cyclone_v_pll_i (
      .rst                       ( pll_reset                  ),
      .refclk                    ( serial_clk                 ),
      .outclk                    ( { slow_clock, fast_clock } ),
      .locked                    ( pll_locked                 ),
      .scanclk                   ( clk                        ),
      .phase_en                  ( pll_phase_en               ),
      .updn                      ( pll_phase_updn             ),
      .cntsel                    ( pll_phase_cntsel           ),
      .phase_done                ( pll_phase_done             ),
      .fbclk                     ( 1'b0                       ),
      .fboutclk                  (                            )
    );


reg reset_n_meta;
reg reset_n_latch;

always @( posedge slow_clock or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    { reset_n_latch, reset_n_meta } <= 2'b00;
    
  end else begin
    
    { reset_n_latch, reset_n_meta } <= { reset_n_meta, 1'b1 };
    
  end
  
end



wire [6:0] data_shift[3:0];
    
    reg [3:0] serial_data_meta;
    reg [3:0] serial_data_latch;
    
	 genvar i;
	 
    generate
      
      for( i = 0; i < 4; i = i + 1 ) 
            begin : serial_data_gen
                  (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) serial_shift_submodule serial_shift_submodule_i (
                        .serial_clock ( fast_clock[0]  ),
                        .serial_data  ( serial_data[i] ),
                        .clock        ( slow_clock     ),
                        .data         ( data_shift[i]  )
                  );
      end
      
    endgenerate
    


reg [27:0] data_meta;
reg [27:0] data_latch;

always @( posedge slow_clock or negedge reset_n_latch ) begin
  
  if( reset_n_latch == 1'b0 ) begin
    
    { data_latch, data_meta } <= 56'h00000000000000;
    
  end else begin
    
    { data_latch, data_meta } <= { data_meta, data_shift[3], data_shift[2], data_shift[1], data_shift[0] };
    
  end
  
end



reg       hsync_clk_meta;
reg [1:0] hsync_clk_latch;
reg       vsync_clk_meta;
reg [1:0] vsync_clk_latch;
reg       de_clk_meta;
reg [1:0] de_clk_latch;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    { hsync_clk_latch, hsync_clk_meta } <= 3'b000;
    { vsync_clk_latch, vsync_clk_meta } <= 3'b000;
    { de_clk_latch,    de_clk_meta    } <= 3'b000;
    
  end else begin
    
    { hsync_clk_latch, hsync_clk_meta } <= { hsync_clk_latch[0], hsync_clk_meta, data_latch[18] };
    { vsync_clk_latch, vsync_clk_meta } <= { vsync_clk_latch[0], vsync_clk_meta, data_latch[19] };
    { de_clk_latch,    de_clk_meta    } <= { de_clk_latch[0],    de_clk_meta,    data_latch[20] };
    
  end
  
end



reg [15:0] hsync_length;
reg [15:0] hsync_period;
reg        hsync_locked;
reg [23:0] vsync_length;
reg [23:0] vsync_period;
reg        vsync_locked;
reg [15:0] de_period;
reg        de_locked;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    hsync_length <= 16'd0;
    hsync_period <= 16'd0;
    hsync_locked <= 1'b0;
    vsync_length <= 24'd0;
    vsync_period <= 24'd0;
    vsync_locked <= 1'b0;
    de_period    <= 16'd0;
    de_locked    <= 1'b0;
    
  end else begin
    
    if( hsync_period > hsync_max_period ) begin
      
      hsync_length <= 16'd0;
      hsync_period <= 16'd0;
      hsync_locked <= 1'b0;
      
    end else if( hsync_clk_latch == 2'b01 ) begin
      
      if( ( hsync_length >= hsync_min_length ) && ( hsync_period >= hsync_min_period ) && ( hsync_period < hsync_max_period ) )
        hsync_locked <= 1'b1;
      else
        hsync_locked <= 1'b0;
      
      hsync_length <= 16'd0;
      hsync_period <= 16'd0;
      
    end else begin
      
      if( hsync_clk_latch[0] == 1'b0 )
        hsync_length <= hsync_length + 16'd1;
      
      hsync_period <= hsync_period + 16'd1;
      
    end
    
    if( vsync_period > vsync_max_period ) begin
      
      vsync_length <= 16'd0;
      vsync_period <= 16'd0;
      vsync_locked <= 1'b0;
      
    end else if( vsync_clk_latch == 2'b01 ) begin
      
      if( ( vsync_length >= vsync_min_length ) && ( vsync_period >= vsync_min_period ) && ( vsync_period < vsync_max_period ) )
        vsync_locked <= 1'b1;
      else
        vsync_locked <= 1'b0;
      
      vsync_length <= 16'd0;
      vsync_period <= 16'd0;
      
    end else begin
      
      if( vsync_clk_latch[0] == 1'b0 )
        vsync_length <= vsync_length + 16'd1;
      
      vsync_period <= vsync_period + 16'd1;
      
    end
    
    if( de_clk_latch == 2'b10 ) begin
      
      if( de_period >= de_min_period )
        de_locked <= 1'b1;
      else
        de_locked <= 1'b0;
      
      de_period <= 16'd0;
      
    end else if( de_period < de_max_period ) begin
      
      de_period <= de_period + 16'd1;
      
    end
    
  end
  
end



reg phase_done_neg_meta;
reg phase_done_neg_latch;

always @( negedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    { phase_done_neg_latch, phase_done_neg_meta } <= 2'b00;
    
  end else begin
    
    { phase_done_neg_latch, phase_done_neg_meta } <= { phase_done_neg_meta, pll_phase_done };
    
  end
  
end



reg phase_done_meta;
reg phase_done_latch;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    { phase_done_latch, phase_done_meta } <= 2'b00;
    
  end else begin
    
    { phase_done_latch, phase_done_meta } <= { phase_done_meta, phase_done_neg_latch };
    
  end
  
end



wire [4:0] phase_cntsel;

generate
  
  if( family == "Cyclone IV" )
    assign phase_cntsel = 4'b00110;
  else
    assign phase_cntsel = 4'b00100;
  
endgenerate



reg        phase_en;
reg        phase_updn;
reg        phase_wait;
reg [31:0] phase_timer;
reg        locked_clk;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    phase_en     <= 1'b0;
    phase_updn   <= 1'b0;
    phase_wait   <= 1'b0;
    phase_timer  <= 32'd0;
    locked_clk   <= 1'b0;
    
  end else begin
    
    if( ( hsync_locked == 1'b1 ) && ( vsync_locked == 1'b1 ) && ( de_locked == 1'b1 ) && ( phase_timer == 32'd0 ) ) begin
      
      phase_en     <= 1'b0;
      phase_updn   <= 1'b0;
      phase_wait   <= 1'b0;
      phase_timer  <= 32'd0;
      locked_clk   <= 1'b1;
      
    end else begin
	   
      if( phase_wait == 1'b0 ) begin
        
        if( phase_timer < ( locked_timeout - 1 ) ) begin
          
          phase_en    <= 1'b0;
          phase_timer <= phase_timer + 32'd1;
          
        end else begin
          
          if( phase_done_latch == 1'b0 )
            phase_wait <= 1'b1;
          
          phase_en <= 1'b1;
          
        end
        
        phase_updn <= 1'b1;
        
      end else begin
        
        if( phase_done_latch == 1'b1 ) begin
          phase_wait  <= 1'b0;
          phase_timer <= 32'd0;
        end
        
        phase_en   <= 1'b0;
        phase_updn <= 1'b0;
        
      end
      
      locked_clk <= 1'b0;
      
    end
    
  end
  
end



reg locked_meta;
reg locked_latch;

always @( posedge slow_clock or negedge reset_n_latch ) begin
  
  if( reset_n_latch == 1'b0 ) begin
    
    { locked_latch, locked_meta } <= 2'b00;
    
  end else begin
    
    { locked_latch, locked_meta } <= { locked_meta, locked_clk };
    
  end
  
end



reg color_mode_meta;
reg color_mode_latch;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
    { color_mode_latch, color_mode_meta } <= 2'b00;
    
  end else begin
    
    { color_mode_latch, color_mode_meta } <= { color_mode_meta, color_mode };
    
  end
  
end



wire [9:0] source;
wire       color_mode_sel;

assign color_mode_sel   = ( source[9] == 1'b1 ) ? source[8]   : color_mode_latch;
assign pll_reset        = ( source[9] == 1'b1 ) ? source[7]   : ~reset_n;
assign pll_phase_en     = ( source[9] == 1'b1 ) ? source[6]   : phase_en;
assign pll_phase_updn   = ( source[9] == 1'b1 ) ? source[5]   : phase_updn;
assign pll_phase_cntsel = ( source[9] == 1'b1 ) ? source[4:0] : phase_cntsel;

altsource_probe #(
  .sld_auto_instance_index ( "YES"  ),
  .sld_instance_index      ( 0      ),
  .instance_id             ( "LVDS" ),
  .probe_width             ( 0      ),
  .source_width            ( 10     ),
  .source_initial_value    ( "0"    ),
  .enable_metastability    ( "NO"   )
) altsource_probe_i (
  .source                  ( source ),
  //.probe                   (        ),
  .source_ena              ( 1'b1   )
);


assign clock   = slow_clock;
assign hsync_n = data_latch[18];
assign vsync_n = data_latch[19];
assign de      = data_latch[20];
assign data    = ( color_mode_sel == 1'b1 ) ? { data_latch[5:0], data_latch[22:21], data_latch[11:6], data_latch[24:23], data_latch[17:12], data_latch[26:25] } :
                                              { data_latch[22:21], data_latch[5:0], data_latch[24:23], data_latch[11:6], data_latch[26:25], data_latch[17:12] } ;
assign locked  = locked_latch;



endmodule



module serial_shift_submodule(
  
  input            serial_clock,
  input            serial_data,
  
  input            clock,
  output reg [6:0] data
  
);
  
  reg serial_data_meta;
  reg serial_data_latch;
  
  always @( posedge serial_clock ) begin
    { serial_data_latch, serial_data_meta } <= { serial_data_meta, serial_data };
  end
  
  reg [6:0] data_shift;
  
  always @( posedge serial_clock ) begin
    data_shift <= { data_shift[5:0], serial_data_latch };
  end
  
  always @( posedge clock ) begin
	 data <= data_shift;
  end
  
  /*
  reg [6:0] data_meta;
  reg [6:0] data_latch;
  
  always @( posedge clock ) begin
	 { data_latch, data_meta } <= { data_meta, data_shift };
  end
  
  assign data = data_latch;
  */
  
endmodule
