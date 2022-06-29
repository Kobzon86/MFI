/*
 * LVDS Display Interface
 */

module lvds_receiver #(
  
  parameter SSNP_ENABLE        = 0,
  parameter PIXELS_IN_PARALLEL = 2
  
)(
  
  input                              reset_n,
  input                              clk,
  input                              color_mode,
  input                              serial_clk,
  input   [4*PIXELS_IN_PARALLEL-1:0] serial_data,
  output    [PIXELS_IN_PARALLEL-1:0] video_clock,
  output    [PIXELS_IN_PARALLEL-1:0] video_hsync_n,
  output    [PIXELS_IN_PARALLEL-1:0] video_vsync_n,
  output    [PIXELS_IN_PARALLEL-1:0] video_de,
  output [24*PIXELS_IN_PARALLEL-1:0] video_data,
  output    [PIXELS_IN_PARALLEL-1:0] video_locked
  
);
  
  logic fast_clock;
  logic slow_clock;
  
  logic [28*PIXELS_IN_PARALLEL-1:0] data_latch;
  logic                       [6:0] data_shift[4*PIXELS_IN_PARALLEL-1:0];
  
  logic color_mode_latch;
  
  logic       dps_reset;
  logic       dps_step;
  logic       dps_dir;
  logic [4:0] dps_cntsel;
  logic       dps_done;
  logic       dps_locked;
  
  logic       color_mode_sel;
  logic       pll_reset;
  logic       pll_phase_en;
  logic       pll_phase_updn;
  logic [4:0] pll_phase_cntsel;
    
  
  
  generate
    
    if( SSNP_ENABLE == 1 ) begin
      
      logic [9:0] source;
      
      altsource_probe #(
        .sld_auto_instance_index( "YES"  ),
        .sld_instance_index     ( 0      ),
        .instance_id            ( "DPS"  ),
        .probe_width            ( 0      ),
        .source_width           ( 10     ),
        .source_initial_value   ( "0"    ),
        .enable_metastability   ( "NO"   )
      ) altsource_probe_i (
        .source_ena( 1'b1   ),
        .source    ( source )
      );
      
      assign color_mode_sel   = ( source[9] ) ? source[8]   : color_mode_latch;
      assign pll_reset        = ( source[9] ) ? source[7]   : dps_reset;
      assign pll_phase_en     = ( source[9] ) ? source[6]   : dps_step;
      assign pll_phase_updn   = ( source[9] ) ? source[5]   : dps_dir;
      assign pll_phase_cntsel = ( source[9] ) ? source[4:0] : dps_cntsel;
      
    end else begin
      
      assign color_mode_sel   = color_mode_latch;
      assign pll_reset        = dps_reset;
      assign pll_phase_en     = dps_step;
      assign pll_phase_updn   = dps_dir;
      assign pll_phase_cntsel = 4'b0001;
      
    end
    
  endgenerate
  
  
  
  lvds_receiver_pll lvds_receiver_pll_i (
    .scanclk   ( clk              ),
    .rst       ( pll_reset        ),
    .refclk    ( serial_clk       ),
    .outclk_0  ( fast_clock       ),
    .outclk_1  ( slow_clock       ),
    .phase_en  ( pll_phase_en     ),
    .updn      ( pll_phase_updn   ),
    .cntsel    ( pll_phase_cntsel ),
    .phase_done( dps_done         )
  );
  
  
  
  genvar i;
  
  generate
    
    for( i = 0; i < ( 4 * PIXELS_IN_PARALLEL ); i = i + 1 ) begin : serial_data_gen
      (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) lvds_serial_shift lvds_serial_shift_i (
        .serial_clock ( fast_clock     ),
        .serial_data  ( serial_data[i] ),
        .clock        ( slow_clock     ),
        .data         ( data_shift[i]  )
      );
    end
    
  endgenerate
  
  
  
  lvds_ldi_dps #(
    .family           ( "Cyclone V"  ),
    .hsync_min_period ( 16'd800      ), //   8 us at 100 MHz
    .hsync_max_period ( 16'd6400     ), //  64 us at 100 MHz
    .vsync_min_period ( 24'd800000   ), //   8 ms at 100 MHz
    .vsync_max_period ( 24'd6400000  ), //  64 ms at 100 MHz
    .locked_timeout   ( 32'd12800000 ), // 128 ms at 100 MHz
    .post_steps_fast  ( 8'd0         ),
    .post_steps_slow  ( 8'd0         )
  ) lvds_ldi_dps (
    .reset_n    ( reset_n        ),
    .clk        ( clk            ),
    .hsync      ( data_latch[18] ),
    .vsync      ( data_latch[19] ),
    .de         ( data_latch[20] ),
    .dps_reset  ( dps_reset      ),
    .dps_step   ( dps_step       ),
    .dps_dir    ( dps_dir        ),
    .dps_cntsel ( dps_cntsel     ),
    .dps_done   ( dps_done       ),
    .dps_locked ( dps_locked     )
  );
  
  
  
  generate
    
    genvar k;
    
    for( k = 0; k < PIXELS_IN_PARALLEL; k = k + 1 ) begin : color_decode
      
      color_mode_decode color_mode_decode_inst (
        .clk            ( slow_clock                 ),
        .reset_n        ( reset_n                    ),
        .color_mode     ( color_mode_sel             ),
        .in_video_data  ( data_latch[28*(k+1)-1-:28] ),
        .in_hsync       ( data_latch[28*k + 18]      ),
        .in_vsync       ( data_latch[28*k + 19]      ),
        .in_de          ( data_latch[28*k + 20]      ),
        .out_video_data ( video_data[24*(k+1)-1-:24] ),
        .out_hsync      ( video_hsync_n[k]           ),
        .out_vsync      ( video_vsync_n[k]           ),
        .out_de         ( video_de[k]                )
      );
      
      assign video_clock[k]  = slow_clock;
      assign video_locked[k] = dps_locked;
      
    end
    
  endgenerate
  
  
  
  always_ff @( posedge slow_clock or negedge reset_n )
  begin
    
    if( !reset_n )
      data_latch <= '0;
    else
      for( int j = 0; j < PIXELS_IN_PARALLEL; j = j + 1 )
        data_latch[28*(j+1)-1-:28] <= { data_shift[4*j+3], data_shift[4*j+2], data_shift[4*j+1], data_shift[4*j] };
    
  end
  
  always_ff @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n )
      color_mode_latch <= '0;
    else
      color_mode_latch <= color_mode;
    
  end
  
  
  
endmodule



module color_mode_decode (
  
  input               clk,
  input               reset_n,
  input               color_mode,
  input        [27:0] in_video_data,
  input               in_hsync,
  input               in_vsync,
  input               in_de,
  output logic [23:0] out_video_data,
  output logic        out_hsync,
  output logic        out_vsync,
  output logic        out_de
  
);
  
  always_ff @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      out_hsync      <= '0;
      out_vsync      <= '0;
      out_de         <= '0;
      out_video_data <= '0;
      
    end else begin
      
      out_hsync      <= in_hsync;
      out_vsync      <= in_vsync;
      out_de         <= in_de   ;
      out_video_data <= ( color_mode == 1'b1 ) ? { in_video_data[5:0],   in_video_data[22:21], in_video_data[11:6],
                                                   in_video_data[24:23], in_video_data[17:12], in_video_data[26:25] } :
                                                 { in_video_data[22:21], in_video_data[5:0],   in_video_data[24:23],
                                                   in_video_data[11:6],  in_video_data[26:25], in_video_data[17:12] } ;
      
    end
    
  end
  
endmodule
