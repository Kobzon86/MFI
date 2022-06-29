/*
 * LVDS Display Interface receiver
 */

module ldi_receiver #(
  
  parameter family              = "External", // "Cyclone IV", "Cyclone V", "External",
  
  parameter clock_freq          = 100_000_000,
  
  parameter data_rate           = "sdr",      // "sdr", "ddr"
  
  parameter pixels_in_parallel  = 1,
  
  parameter hsync_min_period_us = 8,
  parameter hsync_max_period_us = 64,
  
  parameter vsync_min_period_us = 8000,
  parameter vsync_max_period_us = 64000,
  
  parameter de_min_length_us    = 8,
  parameter de_max_length_us    = 64,
  
  parameter locked_timeout_us   = 16000,
  
  parameter post_steps_fast     = 0,
  parameter post_steps_slow     = 2
  
)(
  
  input                              reset_n,
  input                              clk,
  
  input                              color_mode,
  
  input                              ext_serial_clock,
  input                              ext_parallel_clock,
  input                              ext_locked,
  output                             ext_dps_en,
  output                             ext_dps_updn,
  input                              ext_dps_done,
  
  input     [pixels_in_parallel-1:0] ldi_clock,
  input   [4*pixels_in_parallel-1:0] ldi_data,
  
  output    [pixels_in_parallel-1:0] clock,
  output    [pixels_in_parallel-1:0] hsync_n,
  output    [pixels_in_parallel-1:0] vsync_n,
  output    [pixels_in_parallel-1:0] de,
  output [24*pixels_in_parallel-1:0] data,
  output    [pixels_in_parallel-1:0] locked
  
);
  
  
  
  logic       fast_clock;
  logic       slow_clock;
  
  logic       pll_reset;
  logic [4:0] pll_clk;
  logic       pll_locked;
  
  logic       pll_phase_step;
  logic       pll_phase_dir;
  logic [4:0] pll_phase_cntsel;
  logic       pll_phase_done;
  
  logic [4:0] fast_cntsel;
  logic [4:0] slow_cntsel;
  
  generate
    
    if( family == "Cyclone V" ) begin
      
      if( data_rate == "ddr" ) begin
        
        altera_pll #(
          .fractional_vco_multiplier ( "false"              ),
          .reference_clock_frequency ( "74.25 MHz"          ),
          .pll_fractional_cout       ( 32                   ),
          .pll_dsm_out_sel           ( "1st_order"          ),
          .operation_mode            ( "source synchronous" ),
          .number_of_clocks          ( 2                    ),
          .output_clock_frequency0   ( "259.875000 MHz"     ),
          .phase_shift0              ( "0 ps"               ),
          .duty_cycle0               ( 50                   ),
          .output_clock_frequency1   ( "74.250000 MHz"      ),
          .phase_shift1              ( "0 ps"               ),
          .duty_cycle1               ( 50                   ),
          .output_clock_frequency2   ( "74.250000 MHz"      ),
          .phase_shift2              ( "0 ps"               ),
          .duty_cycle2               ( 50                   ),
          .output_clock_frequency3   ( "74.250000 MHz"      ),
          .phase_shift3              ( "0 ps"               ),
          .duty_cycle3               ( 50                   ),
          .output_clock_frequency4   ( "74.250000 MHz"      ),
          .phase_shift4              ( "0 ps"               ),
          .duty_cycle4               ( 50                   ),
          .pll_type                  ( "Cyclone V"          ),
          .pll_subtype               ( "DPS"                ),
          .m_cnt_hi_div              ( 4                    ),
          .m_cnt_lo_div              ( 3                    ),
          .n_cnt_hi_div              ( 256                  ),
          .n_cnt_lo_div              ( 256                  ),
          .m_cnt_bypass_en           ( "false"              ),
          .n_cnt_bypass_en           ( "true"               ),
          .m_cnt_odd_div_duty_en     ( "true"               ),
          .n_cnt_odd_div_duty_en     ( "false"              ),
          .c_cnt_hi_div0             ( 1                    ),
          .c_cnt_lo_div0             ( 1                    ),
          .c_cnt_prst0               ( 1                    ),
          .c_cnt_ph_mux_prst0        ( 0                    ),
          .c_cnt_in_src0             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en0          ( "false"              ),
          .c_cnt_odd_div_duty_en0    ( "false"              ),
          .c_cnt_hi_div1             ( 4                    ),
          .c_cnt_lo_div1             ( 3                    ),
          .c_cnt_prst1               ( 1                    ),
          .c_cnt_ph_mux_prst1        ( 0                    ),
          .c_cnt_in_src1             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en1          ( "false"              ),
          .c_cnt_odd_div_duty_en1    ( "true"               ),
          .c_cnt_hi_div2             ( 4                    ),
          .c_cnt_lo_div2             ( 3                    ),
          .c_cnt_prst2               ( 1                    ),
          .c_cnt_ph_mux_prst2        ( 0                    ),
          .c_cnt_in_src2             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en2          ( "false"              ),
          .c_cnt_odd_div_duty_en2    ( "true"               ),
          .c_cnt_hi_div3             ( 4                    ),
          .c_cnt_lo_div3             ( 3                    ),
          .c_cnt_prst3               ( 1                    ),
          .c_cnt_ph_mux_prst3        ( 0                    ),
          .c_cnt_in_src3             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en3          ( "false"              ),
          .c_cnt_odd_div_duty_en3    ( "true"               ),
          .c_cnt_hi_div4             ( 4                    ),
          .c_cnt_lo_div4             ( 3                    ),
          .c_cnt_prst4               ( 1                    ),
          .c_cnt_ph_mux_prst4        ( 0                    ),
          .c_cnt_in_src4             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en4          ( "false"              ),
          .c_cnt_odd_div_duty_en4    ( "true"               ),
          .pll_vco_div               ( 2                    ),
          .pll_cp_current            ( 20                   ),
          .pll_bwctrl                ( 2000                 ),
          .pll_output_clk_frequency  ( "519.75 MHz"         ),
          .pll_fractional_division   ( "1"                  ),
          .mimic_fbclk_type          ( "gclk"               ),
          .pll_fbclk_mux_1           ( "glb"                ),
          .pll_fbclk_mux_2           ( "m_cnt"              ),
          .pll_m_cnt_in_src          ( "ph_mux_clk"         ),
          .pll_slf_rst               ( "false"              )
        ) cyclone_v_pll_i (
          .rst        ( pll_reset        ),
          .refclk     ( ldi_clock[0]     ),
          .outclk     ( pll_clk          ),
          .locked     ( pll_locked       ),
          .scanclk    ( clk              ),
          .phase_en   ( pll_phase_step   ),
          .updn       ( pll_phase_dir    ),
          .cntsel     ( pll_phase_cntsel ),
          .phase_done ( pll_phase_done   ),
          .fbclk      ( 1'b0             ),
          .fboutclk   (                  )
        );
        
      end else begin
        
        altera_pll #(
          .fractional_vco_multiplier ( "false"              ),
          .reference_clock_frequency ( "74.25 MHz"          ),
          .pll_fractional_cout       ( 32                   ),
          .pll_dsm_out_sel           ( "1st_order"          ),
          .operation_mode            ( "source synchronous" ),
          .number_of_clocks          ( 2                    ),
          .output_clock_frequency0   ( "519.750000 MHz"     ),
          .phase_shift0              ( "0 ps"               ),
          .duty_cycle0               ( 50                   ),
          .output_clock_frequency1   ( "74.250000 MHz"      ),
          .phase_shift1              ( "0 ps"               ),
          .duty_cycle1               ( 50                   ),
          .output_clock_frequency2   ( "74.250000 MHz"      ),
          .phase_shift2              ( "0 ps"               ),
          .duty_cycle2               ( 50                   ),
          .output_clock_frequency3   ( "74.250000 MHz"      ),
          .phase_shift3              ( "0 ps"               ),
          .duty_cycle3               ( 50                   ),
          .output_clock_frequency4   ( "74.250000 MHz"      ),
          .phase_shift4              ( "0 ps"               ),
          .duty_cycle4               ( 50                   ),
          .pll_type                  ( "Cyclone V"          ),
          .pll_subtype               ( "DPS"                ),
          .m_cnt_hi_div              ( 4                    ),
          .m_cnt_lo_div              ( 3                    ),
          .n_cnt_hi_div              ( 256                  ),
          .n_cnt_lo_div              ( 256                  ),
          .m_cnt_bypass_en           ( "false"              ),
          .n_cnt_bypass_en           ( "true"               ),
          .m_cnt_odd_div_duty_en     ( "true"               ),
          .n_cnt_odd_div_duty_en     ( "false"              ),
          .c_cnt_hi_div0             ( 256                  ),
          .c_cnt_lo_div0             ( 256                  ),
          .c_cnt_prst0               ( 1                    ),
          .c_cnt_ph_mux_prst0        ( 0                    ),
          .c_cnt_in_src0             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en0          ( "true"               ),
          .c_cnt_odd_div_duty_en0    ( "false"              ),
          .c_cnt_hi_div1             ( 4                    ),
          .c_cnt_lo_div1             ( 3                    ),
          .c_cnt_prst1               ( 1                    ),
          .c_cnt_ph_mux_prst1        ( 0                    ),
          .c_cnt_in_src1             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en1          ( "false"              ),
          .c_cnt_odd_div_duty_en1    ( "true"               ),
          .c_cnt_hi_div2             ( 4                    ),
          .c_cnt_lo_div2             ( 3                    ),
          .c_cnt_prst2               ( 1                    ),
          .c_cnt_ph_mux_prst2        ( 0                    ),
          .c_cnt_in_src2             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en2          ( "false"              ),
          .c_cnt_odd_div_duty_en2    ( "true"               ),
          .c_cnt_hi_div3             ( 4                    ),
          .c_cnt_lo_div3             ( 3                    ),
          .c_cnt_prst3               ( 1                    ),
          .c_cnt_ph_mux_prst3        ( 0                    ),
          .c_cnt_in_src3             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en3          ( "false"              ),
          .c_cnt_odd_div_duty_en3    ( "true"               ),
          .c_cnt_hi_div4             ( 4                    ),
          .c_cnt_lo_div4             ( 3                    ),
          .c_cnt_prst4               ( 1                    ),
          .c_cnt_ph_mux_prst4        ( 0                    ),
          .c_cnt_in_src4             ( "ph_mux_clk"         ),
          .c_cnt_bypass_en4          ( "false"              ),
          .c_cnt_odd_div_duty_en4    ( "true"               ),
          .pll_vco_div               ( 2                    ),
          .pll_cp_current            ( 20                   ),
          .pll_bwctrl                ( 2000                 ),
          .pll_output_clk_frequency  ( "519.75 MHz"         ),
          .pll_fractional_division   ( "1"                  ),
          .mimic_fbclk_type          ( "gclk"               ),
          .pll_fbclk_mux_1           ( "glb"                ),
          .pll_fbclk_mux_2           ( "m_cnt"              ),
          .pll_m_cnt_in_src          ( "ph_mux_clk"         ),
          .pll_slf_rst               ( "false"              )
        ) cyclone_v_pll_i (
          .rst        ( pll_reset        ),
          .refclk     ( ldi_clock[0]     ),
          .outclk     ( pll_clk          ),
          .locked     ( pll_locked       ),
          .scanclk    ( clk              ),
          .phase_en   ( pll_phase_step   ),
          .updn       ( pll_phase_dir    ),
          .cntsel     ( pll_phase_cntsel ),
          .phase_done ( pll_phase_done   ),
          .fbclk      ( 1'b0             ),
          .fboutclk   (                  )
        );
        
        if( data_rate != "sdr" )
          initial $warning( "Warning: incorrect value of parameter data_rate == %s, suppose sdr", data_rate );
        
      end
      
      assign fast_cntsel = 4'b00000;
      assign slow_cntsel = 4'b00001;
      
      assign slow_clock = pll_clk[1];
      assign fast_clock = pll_clk[0];
      
      assign ext_dps_en   = 1'b0;
      assign ext_dps_updn = 1'b0;
      
    end else if( family == "Cyclone IV" ) begin
      
      if( data_rate == "ddr" ) begin
        
        altpll #(
          .bandwidth_type           ( "AUTO"                               ),
          .clk0_divide_by           ( 2                                    ),
          .clk0_duty_cycle          ( 50                                   ),
          .clk0_multiply_by         ( 7                                    ),
          .clk0_phase_shift         ( "0"                                  ),
          .clk1_divide_by           ( 1                                    ),
          .clk1_duty_cycle          ( 50                                   ),
          .clk1_multiply_by         ( 1                                    ),
          .clk1_phase_shift         ( "0"                                  ),
          .clk2_divide_by           ( 1                                    ),
          .clk2_duty_cycle          ( 50                                   ),
          .clk2_multiply_by         ( 1                                    ),
          .clk2_phase_shift         ( "0"                                  ),
          .clk3_divide_by           ( 1                                    ),
          .clk3_duty_cycle          ( 50                                   ),
          .clk3_multiply_by         ( 1                                    ),
          .clk3_phase_shift         ( "0"                                  ),
          .clk4_divide_by           ( 1                                    ),
          .clk4_duty_cycle          ( 50                                   ),
          .clk4_multiply_by         ( 1                                    ),
          .clk4_phase_shift         ( "0"                                  ),
          .compensate_clock         ( "CLK0"                               ),
          .inclk0_input_frequency   ( 15384                                ),
          .intended_device_family   ( "Cyclone IV E"                       ),
          .lpm_hint                 ( "CBX_MODULE_PREFIX=cyclone_iv_pll_i" ),
          .lpm_type                 ( "altpll"                             ),
          .operation_mode           ( "SOURCE_SYNCHRONOUS"                 ),
          .pll_type                 ( "AUTO"                               ),
          .port_areset              ( "PORT_USED"                          ),
          .port_inclk0              ( "PORT_USED"                          ),
          .port_locked              ( "PORT_USED"                          ),
          .port_phasecounterselect  ( "PORT_USED"                          ),
          .port_phasedone           ( "PORT_USED"                          ),
          .port_phasestep           ( "PORT_USED"                          ),
          .port_phaseupdown         ( "PORT_USED"                          ),
          .port_scanclk             ( "PORT_USED"                          ),
          .port_clk0                ( "PORT_USED"                          ),
          .port_clk1                ( "PORT_USED"                          ),
          .port_clk2                ( "PORT_UNUSED"                        ),
          .port_clk3                ( "PORT_UNUSED"                        ),
          .port_clk4                ( "PORT_UNUSED"                        ),
          .self_reset_on_loss_lock  ( "OFF"                                ),
          .width_clock              ( 5                                    ),
          .width_phasecounterselect ( 3                                    )
        ) cyclone_iv_pll_i (
          .areset             ( pll_reset        ),
          .inclk              ( ldi_clock[0]     ),
          .clk                ( pll_clk          ),
          .locked             ( pll_locked       ),
          .scanclk            ( clk              ),
          .phasestep          ( pll_phase_step   ),
          .phaseupdown        ( pll_phase_dir    ),
          .phasecounterselect ( pll_phase_cntsel ),
          .phasedone          ( pll_phase_done   ),
          .clkena             ( { 6{1'b1} }      ),
          .clkswitch          ( 1'b0             ),
          .configupdate       ( 1'b0             ),
          .extclkena          ( { 4{1'b1} }      ),
          .fbin               ( 1'b1             ),
          .pfdena             ( 1'b1             ),
          .pllena             ( 1'b1             ),
          .scanaclr           ( 1'b0             ),
          .scanclkena         ( 1'b1             ),
          .scandata           ( 1'b0             ),
          .scanread           ( 1'b0             ),
          .scanwrite          ( 1'b0             )
        );
        
      end else begin
        
        altpll #(
          .bandwidth_type           ( "AUTO"                               ),
          .clk0_divide_by           ( 1                                    ),
          .clk0_duty_cycle          ( 50                                   ),
          .clk0_multiply_by         ( 7                                    ),
          .clk0_phase_shift         ( "0"                                  ),
          .clk1_divide_by           ( 1                                    ),
          .clk1_duty_cycle          ( 50                                   ),
          .clk1_multiply_by         ( 1                                    ),
          .clk1_phase_shift         ( "0"                                  ),
          .clk2_divide_by           ( 1                                    ),
          .clk2_duty_cycle          ( 50                                   ),
          .clk2_multiply_by         ( 1                                    ),
          .clk2_phase_shift         ( "0"                                  ),
          .clk3_divide_by           ( 1                                    ),
          .clk3_duty_cycle          ( 50                                   ),
          .clk3_multiply_by         ( 1                                    ),
          .clk3_phase_shift         ( "0"                                  ),
          .clk4_divide_by           ( 1                                    ),
          .clk4_duty_cycle          ( 50                                   ),
          .clk4_multiply_by         ( 1                                    ),
          .clk4_phase_shift         ( "0"                                  ),
          .compensate_clock         ( "CLK0"                               ),
          .inclk0_input_frequency   ( 15384                                ),
          .intended_device_family   ( "Cyclone IV E"                       ),
          .lpm_hint                 ( "CBX_MODULE_PREFIX=cyclone_iv_pll_i" ),
          .lpm_type                 ( "altpll"                             ),
          .operation_mode           ( "SOURCE_SYNCHRONOUS"                 ),
          .pll_type                 ( "AUTO"                               ),
          .port_areset              ( "PORT_USED"                          ),
          .port_inclk0              ( "PORT_USED"                          ),
          .port_locked              ( "PORT_USED"                          ),
          .port_phasecounterselect  ( "PORT_USED"                          ),
          .port_phasedone           ( "PORT_USED"                          ),
          .port_phasestep           ( "PORT_USED"                          ),
          .port_phaseupdown         ( "PORT_USED"                          ),
          .port_scanclk             ( "PORT_USED"                          ),
          .port_clk0                ( "PORT_USED"                          ),
          .port_clk1                ( "PORT_USED"                          ),
          .port_clk2                ( "PORT_UNUSED"                        ),
          .port_clk3                ( "PORT_UNUSED"                        ),
          .port_clk4                ( "PORT_UNUSED"                        ),
          .self_reset_on_loss_lock  ( "OFF"                                ),
          .width_clock              ( 5                                    ),
          .width_phasecounterselect ( 3                                    )
        ) cyclone_iv_pll_i (
          .areset             ( pll_reset        ),
          .inclk              ( ldi_clock[0]     ),
          .clk                ( pll_clk          ),
          .locked             ( pll_locked       ),
          .scanclk            ( clk              ),
          .phasestep          ( pll_phase_step   ),
          .phaseupdown        ( pll_phase_dir    ),
          .phasecounterselect ( pll_phase_cntsel ),
          .phasedone          ( pll_phase_done   ),
          .clkena             ( { 6{1'b1} }      ),
          .clkswitch          ( 1'b0             ),
          .configupdate       ( 1'b0             ),
          .extclkena          ( { 4{1'b1} }      ),
          .fbin               ( 1'b1             ),
          .pfdena             ( 1'b1             ),
          .pllena             ( 1'b1             ),
          .scanaclr           ( 1'b0             ),
          .scanclkena         ( 1'b1             ),
          .scandata           ( 1'b0             ),
          .scanread           ( 1'b0             ),
          .scanwrite          ( 1'b0             )
        );
        
        if( data_rate != "sdr" )
          initial $warning( "Warning: incorrect value of parameter data_rate == %s, suppose sdr", data_rate );
        
      end
      
      assign slow_clock = pll_clk[1];
      assign fast_clock = pll_clk[0];
      
      assign ext_dps_en   = 1'b0;
      assign ext_dps_updn = 1'b0;
      
      assign fast_cntsel = 4'b00010;
      assign slow_cntsel = 4'b00011;
      
    end else begin
      
      assign fast_clock = ext_serial_clock;
      assign slow_clock = ext_parallel_clock;
      
      assign ext_dps_en     = pll_phase_step;
      assign ext_dps_updn   = pll_phase_dir;
      assign pll_phase_done = ext_dps_done;
      assign pll_locked     = ext_locked;
      
      assign fast_cntsel = 4'b00000;
      assign slow_cntsel = 4'b00000;
      
      if( family != "External" )
        initial $warning( "Warning: incorrect value of parameter family == %s, suppose External", family );
      
    end
    
  endgenerate
  
  
  
  logic reset_n_meta;
  logic reset_n_latch;
  
  always @( posedge slow_clock or negedge reset_n ) begin
    
    if( reset_n == 1'b0 ) begin
      
      { reset_n_latch, reset_n_meta } <= 2'b00;
      
    end else begin
      
      { reset_n_latch, reset_n_meta } <= { reset_n_meta, 1'b1 };
      
    end
    
  end
  
  
  
  (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) logic [6:0] data_shift[4*pixels_in_parallel-1:0];
  
  logic [4*pixels_in_parallel-1:0] serial_data_meta;
  logic [4*pixels_in_parallel-1:0] serial_data_latch;
  
  generate
    
    genvar i;
    
    if( data_rate == "ddr" ) begin
      
      for( i = 0; i < ( 4 * pixels_in_parallel ); i = i + 1 ) begin : serial_data_gen
        (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) ldi_ddr_deserializer ldi_deserializer_i (
           .serial_clock ( fast_clock    ),
           .serial_data  ( ldi_data[i]   ),
           .clock        ( slow_clock    ),
           .data         ( data_shift[i] )
        );
      end
      
    end else begin
      
      for( i = 0; i < ( 4 * pixels_in_parallel ); i = i + 1 ) begin : serial_data_gen
        (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) ldi_sdr_deserializer ldi_deserializer_i (
           .serial_clock ( fast_clock    ),
           .serial_data  ( ldi_data[i]   ),
           .clock        ( slow_clock    ),
           .data         ( data_shift[i] )
        );
      end
      
    end
    
  endgenerate
  
  
  
  logic [27:0] data_meta[pixels_in_parallel];
  logic [27:0] data_latch[pixels_in_parallel];
  
  generate
    
    genvar j;
    
    for( j = 0; j < pixels_in_parallel; j = j + 1 ) begin : data_cdc_gen
      
      always @( posedge slow_clock or negedge reset_n_latch ) begin
        
        if( reset_n_latch == 1'b0 ) begin
          
          data_meta[j]  <= '0;
          data_latch[j] <= '0;
          
        end else begin
          
          data_meta[j]  <= { data_shift[4*j+3], data_shift[4*j+2], data_shift[4*j+1], data_shift[4*j+0] };
          data_latch[j] <= data_meta[j];
          
        end
        
      end
      
    end
    
  endgenerate
  
  
  
  logic       phase_reset;
  logic       phase_step;
  logic       phase_dir;
  logic [4:0] phase_cntsel;
  logic       phase_done;
  logic       phase_locked;
  
  ldi_dps #(
    .family              ( family              ),
    .clock_freq          ( clock_freq          ),
    .hsync_min_period_us ( hsync_min_period_us ),
    .hsync_max_period_us ( hsync_max_period_us ),
    .vsync_min_period_us ( vsync_min_period_us ),
    .vsync_max_period_us ( vsync_max_period_us ),
    .de_min_length_us    ( de_min_length_us    ),
    .de_max_length_us    ( de_max_length_us    ),
    .locked_timeout_us   ( locked_timeout_us   ),
    .post_steps_fast     ( post_steps_fast     ),
    .post_steps_slow     ( post_steps_slow     )
  ) lvds_ldi_dps (
    .reset_n    ( reset_n           ),
    .clk        ( clk               ),
    .pll_locked ( pll_locked        ),
    .hsync      ( data_latch[0][18] ),
    .vsync      ( data_latch[0][19] ),
    .de         ( data_latch[0][20] ),
    .dps_reset  ( phase_reset       ),
    .dps_step   ( phase_step        ),
    .dps_dir    ( phase_dir         ),
    .dps_cntsel ( phase_cntsel      ),
    .dps_done   ( phase_done        ),
    .dps_locked ( phase_locked      )
  );
  
  
  
  logic locked_meta;
  logic locked_latch;
  
  always @( posedge slow_clock or negedge reset_n_latch ) begin
    
    if( reset_n_latch == 1'b0 ) begin
      
      { locked_latch, locked_meta } <= 2'b00;
      
    end else begin
      
      { locked_latch, locked_meta } <= { locked_meta, phase_locked };
      
    end
    
  end
  
  
  
  logic color_mode_meta;
  logic color_mode_latch;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( reset_n == 1'b0 ) begin
      
      { color_mode_latch, color_mode_meta } <= 2'b00;
      
    end else begin
      
      { color_mode_latch, color_mode_meta } <= { color_mode_meta, color_mode };
      
    end
    
  end
  
  
  
  logic [9:0] source;
  logic       color_mode_sel;
  
  assign color_mode_sel   = ( source[9] == 1'b1 ) ? source[8]   : color_mode_latch;
  assign pll_reset        = ( source[9] == 1'b1 ) ? source[7]   : phase_reset;
  assign pll_phase_step   = ( source[9] == 1'b1 ) ? source[6]   : phase_step;
  assign pll_phase_dir    = ( source[9] == 1'b1 ) ? source[5]   : phase_dir;
  assign pll_phase_cntsel = ( source[9] == 1'b1 ) ? source[4:0] : phase_cntsel;
  assign phase_done       =                                       pll_phase_done;
  
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
  
  
  
  generate
    
    genvar k;
    
    for( k = 0; k < pixels_in_parallel; k = k + 1 ) begin : output_data
      
      assign clock[k]       = slow_clock;
      assign hsync_n[k]     = data_latch[k][18];
      assign vsync_n[k]     = data_latch[k][19];
      assign de[k]          = data_latch[k][20];
      assign data[24*k+:24] = ( color_mode_sel == 1'b1 ) ? { data_latch[k][5:0],   data_latch[k][22:21], data_latch[k][11:6],  data_latch[k][24:23], data_latch[k][17:12], data_latch[k][26:25] } :
                                                           { data_latch[k][22:21], data_latch[k][5:0],   data_latch[k][24:23], data_latch[k][11:6],  data_latch[k][26:25], data_latch[k][17:12] } ;
      assign locked[k]      = locked_latch;
      
    end
    
  endgenerate
  
  
  
endmodule
