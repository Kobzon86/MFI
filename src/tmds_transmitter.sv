module tmds_transmitter #(
  parameter CLOCK_RATE = "sdr"
) (
  input         reset_n    ,
  input         video_clock,
  input         video_hsync,
  input         video_vsync,
  input         video_de   ,
  input  [23:0] video_data ,
  output        serial_clk ,
  output [ 2:0] serial_data
);

  altera_pll #(
    .fractional_vco_multiplier("false"         ),
    .reference_clock_frequency("74.25 MHz"     ),
    .pll_fractional_cout      (32              ),
    .pll_dsm_out_sel          ("1st_order"     ),
    .operation_mode           ("direct"        ),
    .number_of_clocks         (2               ),
    .output_clock_frequency0  ("742.500000 MHz"),
    .phase_shift0             ("0 ps"          ),
    .duty_cycle0              (50              ),
    .output_clock_frequency1  ("74.250000 MHz" ),
    .phase_shift1             ("0 ps"          ),
    .duty_cycle1              (50              ),
    .pll_type                 ("Cyclone V"     ),
    .pll_subtype              ("General"       ),
    .m_cnt_hi_div             (5               ),
    .m_cnt_lo_div             (5               ),
    .n_cnt_hi_div             (256             ),
    .n_cnt_lo_div             (256             ),
    .m_cnt_bypass_en          ("false"         ),
    .n_cnt_bypass_en          ("true"          ),
    .m_cnt_odd_div_duty_en    ("false"         ),
    .n_cnt_odd_div_duty_en    ("false"         ),
    .c_cnt_hi_div0            (256             ),
    .c_cnt_lo_div0            (256             ),
    .c_cnt_prst0              (1               ),
    .c_cnt_ph_mux_prst0       (0               ),
    .c_cnt_in_src0            ("ph_mux_clk"    ),
    .c_cnt_bypass_en0         ("true"          ),
    .c_cnt_odd_div_duty_en0   ("false"         ),
    .c_cnt_hi_div1            (5               ),
    .c_cnt_lo_div1            (5               ),
    .c_cnt_prst1              (1               ),
    .c_cnt_ph_mux_prst1       (0               ),
    .c_cnt_in_src1            ("ph_mux_clk"    ),
    .c_cnt_bypass_en1         ("false"         ),
    .c_cnt_odd_div_duty_en1   ("false"         ),
    .pll_vco_div              (1               ),
    .pll_cp_current           (30              ),
    .pll_bwctrl               (2000            ),
    .pll_output_clk_frequency ("742.5 MHz"     ),
    .pll_fractional_division  ("1"             ),
    .mimic_fbclk_type         ("gclk"          ),
    .pll_fbclk_mux_1          ("glb"           ),
    .pll_fbclk_mux_2          ("m_cnt"         ),
    .pll_m_cnt_in_src         ("ph_mux_clk"    ),
    .pll_slf_rst              ("false"         )
  ) altera_pll_i (
    .rst   (!reset_n                ),
    .outclk({slow_clock, fast_clock}),
    .fbclk (1'b0                    ),
    .refclk(video_clock             )
  );

  logic slow_clock;
  logic fast_clock;

  reg        hsync_meta ;
  reg        hsync_latch;
  reg        vsync_meta ;
  reg        vsync_latch;
  reg        de_meta    ;
  reg        de_latch   ;
  reg [23:0] data_meta  ;
  reg [23:0] data_latch ;

  always @( posedge slow_clock or negedge reset_n ) 
    begin

      if( reset_n == 1'b0 )
        begin
          { hsync_latch, hsync_meta } <= 2'b0;
          { vsync_latch, vsync_meta } <= 2'b0;
          { de_latch,    de_meta    } <= 2'b0;
          { data_latch,  data_meta  } <= 48'b0;
        end
      else
        begin
          { hsync_latch, hsync_meta } <= { hsync_meta, video_hsync };
          { vsync_latch, vsync_meta } <= { vsync_meta, video_vsync };
          { de_latch,    de_meta    } <= { de_meta,    video_de    };
          { data_latch,  data_meta  } <= { data_meta,  video_data  };
        end

      end

  (* dont_merge *) logic [2:0] tmds_load  ;
  reg   [1:0] clock_latch;
  reg         clock_meta ;

  always @( posedge fast_clock or negedge reset_n )
    begin

      if( reset_n == 1'b0 )
        begin

          tmds_load <= '0;
          { clock_latch, clock_meta } <= 3'b0;

        end
      else
        begin

          if( clock_latch == 2'b01 )
            tmds_load <= '1;
          else
            tmds_load <= '0;

          { clock_latch, clock_meta } <= { clock_latch[0], clock_meta, slow_clock };

        end

    end



  wire [1:0] tmds_ctrl         [2:0];
  wire [7:0] tmds_data         [2:0];
  wire [9:0] tmds_encoded      [2:0];
  reg  [9:0] tmds_encoded_latch[2:0];
  reg  [9:0] tmds_encoded_meta [2:0];

  assign tmds_ctrl[2] = 2'b00;
  assign tmds_ctrl[1] = 2'b00;
  assign tmds_ctrl[0] = { vsync_latch, hsync_latch };

  assign tmds_data[2] = data_latch[23:16];
  assign tmds_data[1] = data_latch[15:8];
  assign tmds_data[0] = data_latch[7:0];

  genvar i;
  generate

    for( i = 0; i < 3; i = i + 1 ) 
      begin : serial_data_gen

        tmds_encoder_dvi tmds_encoder_dvi_i (
          .i_clk  (slow_clock     ),
          .i_rst_n(reset_n        ),
          .i_de   (de_latch       ),
          .i_ctrl (tmds_ctrl[i]   ),
          .i_data (tmds_data[i]   ),
          .o_tmds (tmds_encoded[i])
        );

        always @( posedge fast_clock or negedge reset_n )
          begin

            if( reset_n == 1'b0 )
              begin
                { tmds_encoded_latch[i], tmds_encoded_meta[i] } <= 20'b0;
              end
            else
              begin
                { tmds_encoded_latch[i], tmds_encoded_meta[i] } <= { tmds_encoded_meta[i], tmds_encoded[i] };
              end

          end

        (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *)        tmds_shift_out tmds_data_shift_out_i (
          .reset_n    (reset_n              ),
          .clock      (fast_clock           ),
          .load       (tmds_load[i]         ),
          .data       (tmds_encoded_latch[i]),
          .serial_data(serial_data[i]       )
        );

        end

  endgenerate



//  (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) tmds_shift_out tmds_clock_shift_out_i (
//    .reset_n     ( reset_n         ),
//    .clock       ( serial_clock    ),
//    .load        ( tmds_load       ),
//    .data        ( 10'b0000011111  ),
//    .serial_data ( serial_clk      )
//  );

  assign serial_clk = slow_clock;



endmodule



module tmds_shift_out(
  
  input        reset_n,
  input        clock,

  input        load,
  input  [9:0] data,
  
  output       serial_data
  
);
  
  
  
  (* altera_attribute = "-name FAST_OUTPUT_REGISTER on" *)reg [9:0] data_shift;
  
  always @( posedge clock or negedge reset_n ) begin
    
    if( reset_n == 1'b0 ) begin
      
      data_shift <= 10'b0;
      
    end else begin
      
      if( load == 1'b1 )
        data_shift <= data;
      else
        data_shift <= { 1'b0, data_shift[9:1] };
      
    end
    
  end
  
  
  
  assign serial_data = data_shift[0];
  
  
  
endmodule
