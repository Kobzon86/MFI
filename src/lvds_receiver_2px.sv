module lvds_receiver_2px #(parameter SSNP_ENABLE = 0) (
    input               reset_n     ,
    input               clk         ,
    input               color_mode  ,
    input               serial_clk  ,
    input        [ 7:0] serial_data ,
    output              even_clock  ,
    output logic        even_hsync_n,
    output logic        even_vsync_n,
    output logic        even_de     ,
    output       [23:0] even_data   ,
    output logic        even_locked ,
    output              odd_clock   ,
    output logic        odd_hsync_n ,
    output logic        odd_vsync_n ,
    output logic        odd_de      ,
    output       [23:0] odd_data    ,
    output logic        odd_locked
);

    logic fast_clock      ;
    logic slow_clock      ;

    logic reset_n_latch;

    logic [6:0] data_shift[7:0];

    genvar i;

    logic [27:0] data_latch_e;
    logic [27:0] data_latch_o;

    logic [4:0] phase_cntsel;

    logic color_mode_latch;

    logic dps_reset ;
    logic dps_step  ;
    logic dps_dir   ;
    logic dps_done  ;
    logic dps_locked;

    assign phase_cntsel = 4'b0001;

    always_ff @(posedge slow_clock)
        begin
            even_hsync_n <= data_latch_e[18];
            even_vsync_n <= data_latch_e[19];
            even_de      <= data_latch_e[20];
            odd_hsync_n  <= data_latch_o[18];
            odd_vsync_n  <= data_latch_o[19];
            odd_de       <= data_latch_o[20];
        end

    assign even_clock   = slow_clock;
    assign even_locked  = dps_locked;
    assign even_data    = ( color_mode_sel == 1'b1 ) ? { data_latch_e[5:0],   data_latch_e[22:21], data_latch_e[11:6], 
                                                         data_latch_e[24:23], data_latch_e[17:12], data_latch_e[26:25] } :
                                                       { data_latch_e[22:21], data_latch_e[5:0],   data_latch_e[24:23], 
                                                         data_latch_e[11:6],  data_latch_e[26:25], data_latch_e[17:12] } ;

    assign odd_clock   = slow_clock;
    assign odd_locked  = dps_locked;
    assign odd_data    = ( color_mode_sel == 1'b1 ) ? { data_latch_o[5:0],   data_latch_o[22:21], data_latch_o[11:6], 
                                                        data_latch_o[24:23], data_latch_o[17:12], data_latch_o[26:25] } :
                                                      { data_latch_o[22:21], data_latch_o[5:0],   data_latch_o[24:23], 
                                                        data_latch_o[11:6],  data_latch_o[26:25], data_latch_o[17:12] } ;

    generate 

        logic       color_mode_sel  ;
        logic       pll_reset       ;
        logic       pll_phase_en    ;
        logic       pll_phase_updn  ;
        logic [4:0] pll_phase_cntsel;

        if ( SSNP_ENABLE == 1 )  
        begin
            logic [9:0] source;

            altsource_probe #(
                .sld_auto_instance_index("YES" ),
                .sld_instance_index     (0     ),
                .instance_id            ("TMDS"),
                .probe_width            (0     ),
                .source_width           (10    ),
                .source_initial_value   ("0"   ),
                .enable_metastability   ("NO"  )
            ) altsource_probe_i (
                .source    (source),
                .source_ena(1'b1  )
            );

            assign color_mode_sel   = ( source[9] == 1'b1 ) ? source[8]   : color_mode_latch;
            assign pll_reset        = ( source[9] == 1'b1 ) ? source[7]   : dps_reset;
            assign pll_phase_en     = ( source[9] == 1'b1 ) ? source[6]   : dps_step;
            assign pll_phase_updn   = ( source[9] == 1'b1 ) ? source[5]   : dps_dir;
            assign pll_phase_cntsel = ( source[9] == 1'b1 ) ? source[4:0] : phase_cntsel;
        end
        else
            begin
                assign color_mode_sel = color_mode_latch;
                assign pll_reset        = dps_reset;
                assign pll_phase_en     = dps_step;
                assign pll_phase_updn   = dps_dir;
                assign pll_phase_cntsel = phase_cntsel;
            end 

    endgenerate

    altera_pll #(
        .fractional_vco_multiplier("false"         ),
        .reference_clock_frequency("74.25 MHz"     ),
        .pll_fractional_cout      (32              ),
        .pll_dsm_out_sel          ("1st_order"     ),
        .operation_mode           ("direct"        ),
        .number_of_clocks         (6               ),
        .output_clock_frequency0  ("519.750000 MHz"),
        .phase_shift0             ("0 ps"          ),
        .duty_cycle0              (50              ),
        .output_clock_frequency1  ("74.250000 MHz" ),
        .phase_shift1             ("0 ps"          ),
        .duty_cycle1              (50              ),
        .pll_type                 ("Cyclone V"     ),
        .pll_subtype              ("DPS"           ),
        .m_cnt_hi_div             (4               ),
        .m_cnt_lo_div             (3               ),
        .n_cnt_hi_div             (256             ),
        .n_cnt_lo_div             (256             ),
        .m_cnt_bypass_en          ("false"         ),
        .n_cnt_bypass_en          ("true"          ),
        .m_cnt_odd_div_duty_en    ("true"          ),
        .n_cnt_odd_div_duty_en    ("false"         ),
        .c_cnt_hi_div0            (256             ),
        .c_cnt_lo_div0            (256             ),
        .c_cnt_prst0              (1               ),
        .c_cnt_ph_mux_prst0       (4               ),
        .c_cnt_in_src0            ("ph_mux_clk"    ),
        .c_cnt_bypass_en0         ("true"          ),
        .c_cnt_odd_div_duty_en0   ("false"         ),
        .c_cnt_hi_div1            (4               ),
        .c_cnt_lo_div1            (3               ),
        .c_cnt_prst1              (1               ),
        .c_cnt_ph_mux_prst1       (0               ),
        .c_cnt_in_src1            ("ph_mux_clk"    ),
        .c_cnt_bypass_en1         ("false"         ),
        .c_cnt_odd_div_duty_en1   ("true"          ),
        .pll_vco_div              (2               ),
        .pll_cp_current           (20              ),
        .pll_bwctrl               (2000            ),
        .pll_output_clk_frequency ("519.75 MHz"    ),
        .pll_fractional_division  ("1"             ),
        .mimic_fbclk_type         ("none"          ),
        .pll_fbclk_mux_1          ("glb"           ),
        .pll_fbclk_mux_2          ("m_cnt"         ),
        .pll_m_cnt_in_src         ("ph_mux_clk"    ),
        .pll_slf_rst              ("false"         )
    ) lvds_sdr_cyclone_v_pll_i (
        .rst       (pll_reset                 ),
        .refclk    (serial_clk                ),
        .outclk    ({ slow_clock, fast_clock }),
        .scanclk   (clk                       ),
        .phase_en  (pll_phase_en              ),
        .updn      (pll_phase_updn            ),
        .cntsel    (pll_phase_cntsel          ),
        .phase_done(dps_done                  ),
        .fbclk     (1'b0                      )
    );


    ldi_dps ldi_dps_inst (
        .reset_n   (reset_n         ),
        .clk       (slow_clock      ),
        .hsync     (data_latch_e[18]),
        .vsync     (data_latch_e[19]),
        .dps_reset (dps_reset       ),
        .dps_step  (dps_step        ),
        .dps_dir   (dps_dir         ),
        .dps_done  (dps_done        ),
        .dps_locked(dps_locked      )
    );

    generate
        for( i = 0; i < 8; i = i + 1 )
            begin : serial_data_gen
                (* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *) serial_shift serial_shift_i (
                    .serial_clock ( fast_clock     ),
                    .serial_data  ( serial_data[i] ),
                    .clock        ( slow_clock     ),
                    .data         ( data_shift[i]  )
                );
            end

    endgenerate

    always_ff @( posedge slow_clock or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                reset_n_latch <= '0;
            else
                reset_n_latch <= 1'b1;
        end

    always_ff @( posedge slow_clock or negedge reset_n_latch )
        begin
            if( reset_n_latch == 1'b0 )
                begin
                    data_latch_e <= '0;
                    data_latch_o <= '0;
                end
            else
                begin
                    data_latch_e <= { data_shift[3], data_shift[2], data_shift[1], data_shift[0] };
                    data_latch_o <= { data_shift[7], data_shift[6], data_shift[5], data_shift[4] };
                end
        end

    always_ff @( posedge clk or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                begin
                    color_mode_latch <= '0;
                end
            else
                begin
                    color_mode_latch <= color_mode ;
                end
        end

endmodule

module serial_shift (
    input            serial_clock,
    input            serial_data ,
    input            clock       ,
    output reg [6:0] data
);

    (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) logic serial_data_meta ;
    logic serial_data_latch_e;

    always @( posedge serial_clock )
        begin
            { serial_data_latch_e, serial_data_meta } <= { serial_data_meta, serial_data };
        end

    logic [6:0] data_shift;

    always @( posedge serial_clock )
        begin
            data_shift <= { data_shift[5:0], serial_data_latch_e };
        end

    always @( posedge clock )
        begin
            data <= data_shift;
        end

endmodule

/*
 * LVDS Display Interface dynamic phase shift.
 */

module ldi_dps #(
    parameter hsync_min_period = 16'd512     ,
    parameter hsync_max_period = 16'd65534   ,
    parameter vsync_min_period = 24'd65536   ,
    parameter vsync_max_period = 24'd16777214,
    parameter locked_timeout   = 32'd5000000 ,
    parameter post_steps       = 32'd0
) (
    input  reset_n   ,
    input  clk       ,
    input  hsync     ,
    input  vsync     ,
    output dps_reset ,
    output dps_step  ,
    output dps_dir   ,
    input  dps_done  ,
    output dps_locked
);



    reg       hsync_clk_meta ;
    reg [1:0] hsync_clk_latch;
    reg       vsync_clk_meta ;
    reg [1:0] vsync_clk_latch;

    always @( posedge clk or negedge reset_n ) 
        begin

            if( reset_n == 1'b0 ) 
                begin

                    { hsync_clk_latch, hsync_clk_meta } <= 3'b000;
                    { vsync_clk_latch, vsync_clk_meta } <= 3'b000;

                end 
            else 
                begin

                    { hsync_clk_latch, hsync_clk_meta } <= { hsync_clk_latch[0], hsync_clk_meta, hsync };
                    { vsync_clk_latch, vsync_clk_meta } <= { vsync_clk_latch[0], vsync_clk_meta, vsync };

                end

        end



    reg [15:0] hsync_period;
    reg        hsync_locked;
    reg [23:0] vsync_period;
    reg        vsync_locked;

    always @( posedge clk or negedge reset_n )
        begin

            if( reset_n == 1'b0 )
                begin

                    hsync_period <= 16'd0;
                    hsync_locked <= 1'b0;
                    vsync_period <= 24'd0;
                    vsync_locked <= 1'b0;

                end
            else
                begin

                    if( hsync_period > hsync_max_period )
                        begin

                            hsync_period <= 16'd0;
                            hsync_locked <= 1'b0;

                        end
                    else if( hsync_clk_latch == 2'b01 )
                        begin

                            if( ( hsync_period >= hsync_min_period ) && ( hsync_period < hsync_max_period ) )
                                hsync_locked <= 1'b1;
                            else
                                hsync_locked <= 1'b0;

                            hsync_period <= 16'd0;

                        end
                    else
                        begin

                            hsync_period <= hsync_period + 16'd1;

                        end

                    if( vsync_period > vsync_max_period )
                        begin

                            vsync_period <= 24'd0;
                            vsync_locked <= 1'b0;

                        end
                    else if( vsync_clk_latch == 2'b01 )
                        begin

                            if( ( vsync_period >= vsync_min_period ) && ( vsync_period < vsync_max_period ) )
                                vsync_locked <= 1'b1;
                            else
                                vsync_locked <= 1'b0;

                            vsync_period <= 24'd0;

                        end
                    else
                        begin

                            vsync_period <= vsync_period + 24'd1;

                        end

                end

        end



    reg phase_done_neg_meta ;
    reg phase_done_neg_latch;

    always @( negedge clk or negedge reset_n ) 
        begin

            if( reset_n == 1'b0 ) 
                begin

                    { phase_done_neg_latch, phase_done_neg_meta } <= 2'b00;

                end 
            else 
                begin

                    { phase_done_neg_latch, phase_done_neg_meta } <= { phase_done_neg_meta, dps_done };

                end

        end



    reg phase_done_meta ;
    reg phase_done_latch;

    always @( posedge clk or negedge reset_n ) 
        begin

            if( reset_n == 1'b0 ) 
                begin

                    { phase_done_latch, phase_done_meta } <= 2'b00;

                end 
            else 
                begin

                    { phase_done_latch, phase_done_meta } <= { phase_done_meta, phase_done_neg_latch };

                end

        end



    localparam state_idle  = 3'b001;
    localparam state_step  = 3'b010;
    localparam state_ack   = 3'b100;
    localparam state_reset = 3'b111;

    logic                                     phase_locked;
    logic                                     phase_reset ;
    logic                                     phase_en    ;
    logic                                     phase_updn  ;
    logic signed [  $clog2(locked_timeout):0] phase_post  ;
    logic        [$clog2(locked_timeout)-1:0] phase_timer ;
    logic        [                       2:0] phase_state ;

    always @( posedge clk or negedge reset_n )
        begin

            if( reset_n == 1'b0 )
                begin

                    phase_locked <= 1'b0;
                    phase_reset  <= 1'b1;
                    phase_en     <= 1'b0;
                    phase_updn   <= 1'b0;
                    phase_post   <= 32'd0;
                    phase_timer  <= 32'd0;
                    phase_state  <= state_reset;

                end
            else
                begin

                    case( phase_state )

                        state_idle :
                            begin
                                if( ( hsync_locked == 1'b1 ) && ( vsync_locked == 1'b1 ) )
                                    begin
                                        if( phase_post > 32'd0 )
                                            begin
                                                phase_locked <= 1'b0;
                                                phase_updn   <= 1'b1;
                                                phase_post   <= phase_post - 32'd1;
                                                phase_state  <= state_step;
                                            end
                                        else if( phase_post < 0 )
                                            begin
                                                phase_locked <= 1'b0;
                                                phase_updn   <= 1'b0;
                                                phase_post   <= phase_post + 32'd1;
                                                phase_state  <= state_step;
                                            end
                                        else
                                            begin
                                                phase_locked <= 1'b1;
                                            end
                                    end
                                else if( phase_timer < ( locked_timeout - 1 ) )
                                    begin
                                        phase_timer <= phase_timer + 32'd1;
                                    end
                                else
                                    begin
                                        phase_locked <= 1'b0;
                                        phase_updn   <= 1'b1;
                                        phase_post   <= post_steps;
                                        phase_timer  <= 32'd0;
                                        phase_state  <= state_step;
                                    end
                                phase_reset <= 1'b0;
                                phase_en    <= 1'b0;
                            end

                        state_step :
                            begin
                                if( phase_done_latch == 1'b0 )
                                    begin
                                        phase_timer <= 32'd0;
                                        phase_state <= state_ack;
                                    end
                                else if( phase_timer < ( locked_timeout - 1 ) )
                                    begin
                                        phase_timer <= phase_timer + 32'd1;
                                    end
                                else
                                    begin
                                        phase_timer <= 32'd0;
                                        phase_state <= state_reset;
                                    end
                                phase_locked <= 1'b0;
                                phase_reset  <= 1'b0;
                                phase_en     <= 1'b1;
                            end

                        state_ack :
                            begin
                                if( phase_done_latch == 1'b1 )
                                    begin
                                        phase_timer <= 32'd0;
                                        phase_state <= state_idle;
                                    end
                                else if( phase_timer < ( locked_timeout - 1 ) )
                                    begin
                                        phase_timer <= phase_timer + 32'd1;
                                    end
                                else
                                    begin
                                        phase_timer <= 32'd0;
                                        phase_state <= state_reset;
                                    end
                                phase_locked <= 1'b0;
                                phase_reset  <= 1'b0;
                                phase_en     <= 1'b0;
                            end

                        default :
                            begin
                                phase_locked <= 1'b0;
                                phase_reset  <= 1'b1;
                                phase_en     <= 1'b0;
                                phase_updn   <= 1'b0;
                                phase_post   <= 32'd0;
                                phase_timer  <= 32'd0;
                                phase_state  <= state_idle;
                            end

                    endcase

                end

        end



    assign dps_reset  = phase_reset;
    assign dps_step   = phase_en;
    assign dps_dir    = phase_updn;
    assign dps_locked = phase_locked;



endmodule