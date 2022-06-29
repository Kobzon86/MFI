	qsys u0 (
		.arinc429_inputa                    (<connected-to-arinc429_inputa>),                    //           arinc429.inputa
		.arinc429_inputb                    (<connected-to-arinc429_inputb>),                    //                   .inputb
		.arinc429_outputa                   (<connected-to-arinc429_outputa>),                   //                   .outputa
		.arinc429_outputb                   (<connected-to-arinc429_outputb>),                   //                   .outputb
		.arinc429_slewrate                  (<connected-to-arinc429_slewrate>),                  //                   .slewrate
		.arinc429_testab                    (<connected-to-arinc429_testab>),                    //                   .testab
		.arinc708_inputa                    (<connected-to-arinc708_inputa>),                    //           arinc708.inputa
		.arinc708_inputb                    (<connected-to-arinc708_inputb>),                    //                   .inputb
		.arinc708_outputa                   (<connected-to-arinc708_outputa>),                   //                   .outputa
		.arinc708_outputb                   (<connected-to-arinc708_outputb>),                   //                   .outputb
		.arinc708_tx_inh                    (<connected-to-arinc708_tx_inh>),                    //                   .tx_inh
		.arinc708_rx_en                     (<connected-to-arinc708_rx_en>),                     //                   .rx_en
		.av_clock65_clk                     (<connected-to-av_clock65_clk>),                     //         av_clock65.clk
		.av_clock_ref_clk                   (<connected-to-av_clock_ref_clk>),                   //       av_clock_ref.clk
		.check_pio_export_export            (<connected-to-check_pio_export_export>),            //   check_pio_export.export
		.clock_out_clk                      (<connected-to-clock_out_clk>),                      //          clock_out.clk
		.crc_out_crc                        (<connected-to-crc_out_crc>),                        //            crc_out.crc
		.ddr_0_mem_a                        (<connected-to-ddr_0_mem_a>),                        //              ddr_0.mem_a
		.ddr_0_mem_ba                       (<connected-to-ddr_0_mem_ba>),                       //                   .mem_ba
		.ddr_0_mem_ck                       (<connected-to-ddr_0_mem_ck>),                       //                   .mem_ck
		.ddr_0_mem_ck_n                     (<connected-to-ddr_0_mem_ck_n>),                     //                   .mem_ck_n
		.ddr_0_mem_cke                      (<connected-to-ddr_0_mem_cke>),                      //                   .mem_cke
		.ddr_0_mem_cs_n                     (<connected-to-ddr_0_mem_cs_n>),                     //                   .mem_cs_n
		.ddr_0_mem_dm                       (<connected-to-ddr_0_mem_dm>),                       //                   .mem_dm
		.ddr_0_mem_ras_n                    (<connected-to-ddr_0_mem_ras_n>),                    //                   .mem_ras_n
		.ddr_0_mem_cas_n                    (<connected-to-ddr_0_mem_cas_n>),                    //                   .mem_cas_n
		.ddr_0_mem_we_n                     (<connected-to-ddr_0_mem_we_n>),                     //                   .mem_we_n
		.ddr_0_mem_reset_n                  (<connected-to-ddr_0_mem_reset_n>),                  //                   .mem_reset_n
		.ddr_0_mem_dq                       (<connected-to-ddr_0_mem_dq>),                       //                   .mem_dq
		.ddr_0_mem_dqs                      (<connected-to-ddr_0_mem_dqs>),                      //                   .mem_dqs
		.ddr_0_mem_dqs_n                    (<connected-to-ddr_0_mem_dqs_n>),                    //                   .mem_dqs_n
		.ddr_0_mem_odt                      (<connected-to-ddr_0_mem_odt>),                      //                   .mem_odt
		.ddr_1_mem_a                        (<connected-to-ddr_1_mem_a>),                        //              ddr_1.mem_a
		.ddr_1_mem_ba                       (<connected-to-ddr_1_mem_ba>),                       //                   .mem_ba
		.ddr_1_mem_ck                       (<connected-to-ddr_1_mem_ck>),                       //                   .mem_ck
		.ddr_1_mem_ck_n                     (<connected-to-ddr_1_mem_ck_n>),                     //                   .mem_ck_n
		.ddr_1_mem_cke                      (<connected-to-ddr_1_mem_cke>),                      //                   .mem_cke
		.ddr_1_mem_cs_n                     (<connected-to-ddr_1_mem_cs_n>),                     //                   .mem_cs_n
		.ddr_1_mem_dm                       (<connected-to-ddr_1_mem_dm>),                       //                   .mem_dm
		.ddr_1_mem_ras_n                    (<connected-to-ddr_1_mem_ras_n>),                    //                   .mem_ras_n
		.ddr_1_mem_cas_n                    (<connected-to-ddr_1_mem_cas_n>),                    //                   .mem_cas_n
		.ddr_1_mem_we_n                     (<connected-to-ddr_1_mem_we_n>),                     //                   .mem_we_n
		.ddr_1_mem_reset_n                  (<connected-to-ddr_1_mem_reset_n>),                  //                   .mem_reset_n
		.ddr_1_mem_dq                       (<connected-to-ddr_1_mem_dq>),                       //                   .mem_dq
		.ddr_1_mem_dqs                      (<connected-to-ddr_1_mem_dqs>),                      //                   .mem_dqs
		.ddr_1_mem_dqs_n                    (<connected-to-ddr_1_mem_dqs_n>),                    //                   .mem_dqs_n
		.ddr_1_mem_odt                      (<connected-to-ddr_1_mem_odt>),                      //                   .mem_odt
		.ddr_clk_in_0_clk                   (<connected-to-ddr_clk_in_0_clk>),                   //       ddr_clk_in_0.clk
		.ddr_clk_in_1_clk                   (<connected-to-ddr_clk_in_1_clk>),                   //       ddr_clk_in_1.clk
		.ddr_global_reset_0_reset_n         (<connected-to-ddr_global_reset_0_reset_n>),         // ddr_global_reset_0.reset_n
		.ddr_global_reset_1_reset_n         (<connected-to-ddr_global_reset_1_reset_n>),         // ddr_global_reset_1.reset_n
		.ddr_oct_0_rzqin                    (<connected-to-ddr_oct_0_rzqin>),                    //          ddr_oct_0.rzqin
		.ddr_oct_1_rzqin                    (<connected-to-ddr_oct_1_rzqin>),                    //          ddr_oct_1.rzqin
		.ddr_soft_reset_0_reset_n           (<connected-to-ddr_soft_reset_0_reset_n>),           //   ddr_soft_reset_0.reset_n
		.ddr_soft_reset_1_reset_n           (<connected-to-ddr_soft_reset_1_reset_n>),           //   ddr_soft_reset_1.reset_n
		.ddr_status_0_local_init_done       (<connected-to-ddr_status_0_local_init_done>),       //       ddr_status_0.local_init_done
		.ddr_status_0_local_cal_success     (<connected-to-ddr_status_0_local_cal_success>),     //                   .local_cal_success
		.ddr_status_0_local_cal_fail        (<connected-to-ddr_status_0_local_cal_fail>),        //                   .local_cal_fail
		.ddr_status_1_local_init_done       (<connected-to-ddr_status_1_local_init_done>),       //       ddr_status_1.local_init_done
		.ddr_status_1_local_cal_success     (<connected-to-ddr_status_1_local_cal_success>),     //                   .local_cal_success
		.ddr_status_1_local_cal_fail        (<connected-to-ddr_status_1_local_cal_fail>),        //                   .local_cal_fail
		.dev_info_crc_in                    (<connected-to-dev_info_crc_in>),                    //           dev_info.crc_in
		.dev_info_mkio_address              (<connected-to-dev_info_mkio_address>),              //                   .mkio_address
		.discr_cmd_in_vwet                  (<connected-to-discr_cmd_in_vwet>),                  //       discr_cmd_in.vwet
		.discr_cmd_in_ths_int               (<connected-to-discr_cmd_in_ths_int>),               //                   .ths_int
		.discr_cmd_in_ths_sel               (<connected-to-discr_cmd_in_ths_sel>),               //                   .ths_sel
		.discr_cmd_in_sense                 (<connected-to-discr_cmd_in_sense>),                 //                   .sense
		.discr_cmd_in_dc_in                 (<connected-to-discr_cmd_in_dc_in>),                 //                   .dc_in
		.discr_cmd_in_addr                  (<connected-to-discr_cmd_in_addr>),                  //                   .addr
		.discr_cmd_out_fault                (<connected-to-discr_cmd_out_fault>),                //      discr_cmd_out.fault
		.discr_cmd_out_export               (<connected-to-discr_cmd_out_export>),               //                   .export
		.gp_gp_inputs                       (<connected-to-gp_gp_inputs>),                       //                 gp.gp_inputs
		.gp_gp_outputs                      (<connected-to-gp_gp_outputs>),                      //                   .gp_outputs
		.i2c_clk                            (<connected-to-i2c_clk>),                            //                i2c.clk
		.i2c_data                           (<connected-to-i2c_data>),                           //                   .data
		.pcie_npor_npor                     (<connected-to-pcie_npor_npor>),                     //          pcie_npor.npor
		.pcie_npor_pin_perst                (<connected-to-pcie_npor_pin_perst>),                //                   .pin_perst
		.pcie_refclk_clk                    (<connected-to-pcie_refclk_clk>),                    //        pcie_refclk.clk
		.pcie_serial_rx_in0                 (<connected-to-pcie_serial_rx_in0>),                 //        pcie_serial.rx_in0
		.pcie_serial_tx_out0                (<connected-to-pcie_serial_tx_out0>),                //                   .tx_out0
		.por_reset_n                        (<connected-to-por_reset_n>),                        //                por.reset_n
		.pu_backlight_drv_en                (<connected-to-pu_backlight_drv_en>),                //       pu_backlight.drv_en
		.pu_backlight_out_en_n              (<connected-to-pu_backlight_out_en_n>),              //                   .out_en_n
		.pu_backlight_pwm                   (<connected-to-pu_backlight_pwm>),                   //                   .pwm
		.pu_backlight_fault_n               (<connected-to-pu_backlight_fault_n>),               //                   .fault_n
		.pu_backlight_night                 (<connected-to-pu_backlight_night>),                 //                   .night
		.pu_backlight_backlight_bite        (<connected-to-pu_backlight_backlight_bite>),        //                   .backlight_bite
		.pu_i2c_clk                         (<connected-to-pu_i2c_clk>),                         //             pu_i2c.clk
		.pu_i2c_data                        (<connected-to-pu_i2c_data>),                        //                   .data
		.pu_type_pu_type                    (<connected-to-pu_type_pu_type>),                    //            pu_type.pu_type
		.reset_out_reset_n                  (<connected-to-reset_out_reset_n>),                  //          reset_out.reset_n
		.reset_out_reset_req                (<connected-to-reset_out_reset_req>),                //                   .reset_req
		.video_av_in_0_vid_clk              (<connected-to-video_av_in_0_vid_clk>),              //      video_av_in_0.vid_clk
		.video_av_in_0_vid_data             (<connected-to-video_av_in_0_vid_data>),             //                   .vid_data
		.video_av_in_0_vid_de               (<connected-to-video_av_in_0_vid_de>),               //                   .vid_de
		.video_av_in_0_vid_datavalid        (<connected-to-video_av_in_0_vid_datavalid>),        //                   .vid_datavalid
		.video_av_in_0_vid_locked           (<connected-to-video_av_in_0_vid_locked>),           //                   .vid_locked
		.video_av_in_0_vid_f                (<connected-to-video_av_in_0_vid_f>),                //                   .vid_f
		.video_av_in_0_vid_v_sync           (<connected-to-video_av_in_0_vid_v_sync>),           //                   .vid_v_sync
		.video_av_in_0_vid_h_sync           (<connected-to-video_av_in_0_vid_h_sync>),           //                   .vid_h_sync
		.video_av_in_0_vid_color_encoding   (<connected-to-video_av_in_0_vid_color_encoding>),   //                   .vid_color_encoding
		.video_av_in_0_vid_bit_width        (<connected-to-video_av_in_0_vid_bit_width>),        //                   .vid_bit_width
		.video_av_in_0_sof                  (<connected-to-video_av_in_0_sof>),                  //                   .sof
		.video_av_in_0_sof_locked           (<connected-to-video_av_in_0_sof_locked>),           //                   .sof_locked
		.video_av_in_0_refclk_div           (<connected-to-video_av_in_0_refclk_div>),           //                   .refclk_div
		.video_av_in_0_clipping             (<connected-to-video_av_in_0_clipping>),             //                   .clipping
		.video_av_in_0_padding              (<connected-to-video_av_in_0_padding>),              //                   .padding
		.video_av_in_0_overflow             (<connected-to-video_av_in_0_overflow>),             //                   .overflow
		.video_av_in_1_vid_clk              (<connected-to-video_av_in_1_vid_clk>),              //      video_av_in_1.vid_clk
		.video_av_in_1_vid_data             (<connected-to-video_av_in_1_vid_data>),             //                   .vid_data
		.video_av_in_1_vid_de               (<connected-to-video_av_in_1_vid_de>),               //                   .vid_de
		.video_av_in_1_vid_datavalid        (<connected-to-video_av_in_1_vid_datavalid>),        //                   .vid_datavalid
		.video_av_in_1_vid_locked           (<connected-to-video_av_in_1_vid_locked>),           //                   .vid_locked
		.video_av_in_1_vid_f                (<connected-to-video_av_in_1_vid_f>),                //                   .vid_f
		.video_av_in_1_vid_v_sync           (<connected-to-video_av_in_1_vid_v_sync>),           //                   .vid_v_sync
		.video_av_in_1_vid_h_sync           (<connected-to-video_av_in_1_vid_h_sync>),           //                   .vid_h_sync
		.video_av_in_1_vid_color_encoding   (<connected-to-video_av_in_1_vid_color_encoding>),   //                   .vid_color_encoding
		.video_av_in_1_vid_bit_width        (<connected-to-video_av_in_1_vid_bit_width>),        //                   .vid_bit_width
		.video_av_in_1_sof                  (<connected-to-video_av_in_1_sof>),                  //                   .sof
		.video_av_in_1_sof_locked           (<connected-to-video_av_in_1_sof_locked>),           //                   .sof_locked
		.video_av_in_1_refclk_div           (<connected-to-video_av_in_1_refclk_div>),           //                   .refclk_div
		.video_av_in_1_clipping             (<connected-to-video_av_in_1_clipping>),             //                   .clipping
		.video_av_in_1_padding              (<connected-to-video_av_in_1_padding>),              //                   .padding
		.video_av_in_1_overflow             (<connected-to-video_av_in_1_overflow>),             //                   .overflow
		.video_av_out_vid_clk               (<connected-to-video_av_out_vid_clk>),               //       video_av_out.vid_clk
		.video_av_out_vid_data              (<connected-to-video_av_out_vid_data>),              //                   .vid_data
		.video_av_out_underflow             (<connected-to-video_av_out_underflow>),             //                   .underflow
		.video_av_out_vid_datavalid         (<connected-to-video_av_out_vid_datavalid>),         //                   .vid_datavalid
		.video_av_out_vid_v_sync            (<connected-to-video_av_out_vid_v_sync>),            //                   .vid_v_sync
		.video_av_out_vid_h_sync            (<connected-to-video_av_out_vid_h_sync>),            //                   .vid_h_sync
		.video_av_out_vid_f                 (<connected-to-video_av_out_vid_f>),                 //                   .vid_f
		.video_av_out_vid_h                 (<connected-to-video_av_out_vid_h>),                 //                   .vid_h
		.video_av_out_vid_v                 (<connected-to-video_av_out_vid_v>),                 //                   .vid_v
		.video_cpu_in_vid_clk               (<connected-to-video_cpu_in_vid_clk>),               //       video_cpu_in.vid_clk
		.video_cpu_in_vid_data              (<connected-to-video_cpu_in_vid_data>),              //                   .vid_data
		.video_cpu_in_vid_de                (<connected-to-video_cpu_in_vid_de>),                //                   .vid_de
		.video_cpu_in_vid_datavalid         (<connected-to-video_cpu_in_vid_datavalid>),         //                   .vid_datavalid
		.video_cpu_in_vid_locked            (<connected-to-video_cpu_in_vid_locked>),            //                   .vid_locked
		.video_cpu_in_vid_f                 (<connected-to-video_cpu_in_vid_f>),                 //                   .vid_f
		.video_cpu_in_vid_v_sync            (<connected-to-video_cpu_in_vid_v_sync>),            //                   .vid_v_sync
		.video_cpu_in_vid_h_sync            (<connected-to-video_cpu_in_vid_h_sync>),            //                   .vid_h_sync
		.video_cpu_in_vid_color_encoding    (<connected-to-video_cpu_in_vid_color_encoding>),    //                   .vid_color_encoding
		.video_cpu_in_vid_bit_width         (<connected-to-video_cpu_in_vid_bit_width>),         //                   .vid_bit_width
		.video_cpu_in_sof                   (<connected-to-video_cpu_in_sof>),                   //                   .sof
		.video_cpu_in_sof_locked            (<connected-to-video_cpu_in_sof_locked>),            //                   .sof_locked
		.video_cpu_in_refclk_div            (<connected-to-video_cpu_in_refclk_div>),            //                   .refclk_div
		.video_cpu_in_clipping              (<connected-to-video_cpu_in_clipping>),              //                   .clipping
		.video_cpu_in_padding               (<connected-to-video_cpu_in_padding>),               //                   .padding
		.video_cpu_in_overflow              (<connected-to-video_cpu_in_overflow>),              //                   .overflow
		.video_ic_outputs                   (<connected-to-video_ic_outputs>),                   //           video_ic.outputs
		.video_out_vid_clk                  (<connected-to-video_out_vid_clk>),                  //          video_out.vid_clk
		.video_out_vid_data                 (<connected-to-video_out_vid_data>),                 //                   .vid_data
		.video_out_underflow                (<connected-to-video_out_underflow>),                //                   .underflow
		.video_out_vid_mode_change          (<connected-to-video_out_vid_mode_change>),          //                   .vid_mode_change
		.video_out_vid_std                  (<connected-to-video_out_vid_std>),                  //                   .vid_std
		.video_out_vid_datavalid            (<connected-to-video_out_vid_datavalid>),            //                   .vid_datavalid
		.video_out_vid_v_sync               (<connected-to-video_out_vid_v_sync>),               //                   .vid_v_sync
		.video_out_vid_h_sync               (<connected-to-video_out_vid_h_sync>),               //                   .vid_h_sync
		.video_out_vid_f                    (<connected-to-video_out_vid_f>),                    //                   .vid_f
		.video_out_vid_h                    (<connected-to-video_out_vid_h>),                    //                   .vid_h
		.video_out_vid_v                    (<connected-to-video_out_vid_v>),                    //                   .vid_v
		.video_tmds_in_0_vid_clk            (<connected-to-video_tmds_in_0_vid_clk>),            //    video_tmds_in_0.vid_clk
		.video_tmds_in_0_vid_data           (<connected-to-video_tmds_in_0_vid_data>),           //                   .vid_data
		.video_tmds_in_0_vid_de             (<connected-to-video_tmds_in_0_vid_de>),             //                   .vid_de
		.video_tmds_in_0_vid_datavalid      (<connected-to-video_tmds_in_0_vid_datavalid>),      //                   .vid_datavalid
		.video_tmds_in_0_vid_locked         (<connected-to-video_tmds_in_0_vid_locked>),         //                   .vid_locked
		.video_tmds_in_0_vid_f              (<connected-to-video_tmds_in_0_vid_f>),              //                   .vid_f
		.video_tmds_in_0_vid_v_sync         (<connected-to-video_tmds_in_0_vid_v_sync>),         //                   .vid_v_sync
		.video_tmds_in_0_vid_h_sync         (<connected-to-video_tmds_in_0_vid_h_sync>),         //                   .vid_h_sync
		.video_tmds_in_0_vid_color_encoding (<connected-to-video_tmds_in_0_vid_color_encoding>), //                   .vid_color_encoding
		.video_tmds_in_0_vid_bit_width      (<connected-to-video_tmds_in_0_vid_bit_width>),      //                   .vid_bit_width
		.video_tmds_in_0_sof                (<connected-to-video_tmds_in_0_sof>),                //                   .sof
		.video_tmds_in_0_sof_locked         (<connected-to-video_tmds_in_0_sof_locked>),         //                   .sof_locked
		.video_tmds_in_0_refclk_div         (<connected-to-video_tmds_in_0_refclk_div>),         //                   .refclk_div
		.video_tmds_in_0_clipping           (<connected-to-video_tmds_in_0_clipping>),           //                   .clipping
		.video_tmds_in_0_padding            (<connected-to-video_tmds_in_0_padding>),            //                   .padding
		.video_tmds_in_0_overflow           (<connected-to-video_tmds_in_0_overflow>),           //                   .overflow
		.video_tmds_in_1_vid_clk            (<connected-to-video_tmds_in_1_vid_clk>),            //    video_tmds_in_1.vid_clk
		.video_tmds_in_1_vid_data           (<connected-to-video_tmds_in_1_vid_data>),           //                   .vid_data
		.video_tmds_in_1_vid_de             (<connected-to-video_tmds_in_1_vid_de>),             //                   .vid_de
		.video_tmds_in_1_vid_datavalid      (<connected-to-video_tmds_in_1_vid_datavalid>),      //                   .vid_datavalid
		.video_tmds_in_1_vid_locked         (<connected-to-video_tmds_in_1_vid_locked>),         //                   .vid_locked
		.video_tmds_in_1_vid_f              (<connected-to-video_tmds_in_1_vid_f>),              //                   .vid_f
		.video_tmds_in_1_vid_v_sync         (<connected-to-video_tmds_in_1_vid_v_sync>),         //                   .vid_v_sync
		.video_tmds_in_1_vid_h_sync         (<connected-to-video_tmds_in_1_vid_h_sync>),         //                   .vid_h_sync
		.video_tmds_in_1_vid_color_encoding (<connected-to-video_tmds_in_1_vid_color_encoding>), //                   .vid_color_encoding
		.video_tmds_in_1_vid_bit_width      (<connected-to-video_tmds_in_1_vid_bit_width>),      //                   .vid_bit_width
		.video_tmds_in_1_sof                (<connected-to-video_tmds_in_1_sof>),                //                   .sof
		.video_tmds_in_1_sof_locked         (<connected-to-video_tmds_in_1_sof_locked>),         //                   .sof_locked
		.video_tmds_in_1_refclk_div         (<connected-to-video_tmds_in_1_refclk_div>),         //                   .refclk_div
		.video_tmds_in_1_clipping           (<connected-to-video_tmds_in_1_clipping>),           //                   .clipping
		.video_tmds_in_1_padding            (<connected-to-video_tmds_in_1_padding>),            //                   .padding
		.video_tmds_in_1_overflow           (<connected-to-video_tmds_in_1_overflow>)            //                   .overflow
	);

