/*
 * MFI2-15 PPOS_UNIV FPGA firmware toplevel
 */

module toplevel (
  
  input               si5332_clk0_p    ,
  input               si5332_clk1_p    ,
  input               si5332_clk3_p    ,
  input               si5332_clk4_p    ,
  
  inout               i2c_scl          ,
  inout               i2c_sda          ,
  input               adv7613_int      ,
  input               adv7181_int      ,
  
  output              ddr_bot_reset_n  ,
  output              ddr_bot_cs_n     ,
  output              ddr_bot_ck_p     ,
  output              ddr_bot_ck_n     ,
  output              ddr_bot_cke      ,
  output              ddr_bot_ras_n    ,
  output              ddr_bot_cas_n    ,
  output              ddr_bot_we_n     ,
  inout         [1:0] ddr_bot_dqs_p    ,
  inout         [1:0] ddr_bot_dqs_n    ,
  output        [2:0] ddr_bot_ba       ,
  output       [12:0] ddr_bot_addr     ,
  output        [1:0] ddr_bot_dm       ,
  inout        [15:0] ddr_bot_dq       ,
  output              ddr_bot_odt      ,
  input               ddr_bot_rzq      ,
  
  output              ddr_top_reset_n  ,
  output              ddr_top_cs_n     ,
  output              ddr_top_ck_p     ,
  output              ddr_top_ck_n     ,
  output              ddr_top_cke      ,
  output              ddr_top_ras_n    ,
  output              ddr_top_cas_n    ,
  output              ddr_top_we_n     ,
  inout         [1:0] ddr_top_dqs_p    ,
  inout         [1:0] ddr_top_dqs_n    ,
  output        [2:0] ddr_top_ba       ,
  output       [12:0] ddr_top_addr     ,
  output        [1:0] ddr_top_dm       ,
  inout        [15:0] ddr_top_dq       ,
  output              ddr_top_odt      ,
  input               ddr_top_rzq      ,
  
  input               pcie_reset       ,
  input               pcie_clk_p       ,
  input               pcie_rx_p        ,
  output              pcie_tx_p        ,
  output              pcie_ckreq       ,
  output              pcie_prsnt       ,
  
  inout               pu_i2c_scl       ,
  inout               pu_i2c_sda       ,
  input               pu_interrupt     ,
  
  output              out1_en_n        ,
  output              out3_en_n        ,
  output              btn_bklt_pwm     ,
  output              spin_bklt_pwm    ,
  output        [1:0] lcd_bklt_en      ,
  output              lcd_bklt_dim     ,
  input               lcd_bklt_flt     ,
  
  output              adv7181_reset    ,
  output    logic          adv7613_reset    ,
  output              adv7613_cs0      ,
  output              adv7613_cs1      ,
  output              tmds171_oe       ,
  output              adv7123_psave_n  ,
  output              lvds_lcd_mode    ,
  output              lvds_lcd_scan    ,
  
  inout               heater_i2c_scl   ,
  inout               heater_i2c_sda   ,
  output              heater_pwm       ,
  input               heater_sens      ,
  
  input        [15:0] a429_rx_p        ,
  input        [15:0] a429_rx_n        ,
  output              a429_rx_test_p   ,
  output              a429_rx_test_n   ,
  output        [5:0] a429_tx_p        ,
  output        [5:0] a429_tx_n        ,
  output        [5:0] a429_tx_slp      ,
  input         [5:0] a429_ctrl_p      ,
  input         [5:0] a429_ctrl_n      ,
  
  output        [1:0] a708_tx_p        ,
  output        [1:0] a708_tx_n        ,
  output        [1:0] a708_tx_inh      ,
  input         [1:0] a708_rx_p        ,
  input         [1:0] a708_rx_n        ,
  output        [1:0] a708_rx_en       ,
  
  output        [1:0] milstd_tx_p      ,
  output        [1:0] milstd_tx_n      ,
  output        [1:0] milstd_tx_inh    ,
  input         [1:0] milstd_rx_p      ,
  input         [1:0] milstd_rx_n      ,
  output        [1:0] milstd_rx_en     ,
  input         [4:0] milstd_addr      ,
  
  input         [7:0] rk_in            ,
  
  output        [3:0] rk_out           ,
  input         [3:0] rk_fault         ,
  output              rk_out_en        ,
  
  input               lvds_imx6_clk_p  ,
  input         [3:0] lvds_imx6_data_p ,
  
  input         [1:0] lvds_rx0_clk_p   ,
  input         [7:0] lvds_rx0_data_p  ,
  
  input         [1:0] lvds_rx1_clk_p   ,
  input         [7:0] lvds_rx1_data_p  ,
  
  input               av_rx0_sfl       ,
  input               av_rx0_llc       ,
  input               av_rx0_hsync_n   ,
  input               av_rx0_vsync_n   ,
  output              av_rx0_fb        ,
  input               av_rx0_de        ,
  input        [19:0] av_rx0_data      ,
  
  input               av_rx1_sfl       ,
  input               av_rx1_llc       ,
  input               av_rx1_hsync_n   ,
  input               av_rx1_vsync_n   ,
  input               av_rx1_de        ,
  input        [19:0] av_rx1_data      ,
  output              av_rx1_fb        ,
  
  input               dp_hpd           ,
  inout               dp_aux_p         ,
  inout               dp_aux_n         ,
  output        [3:0] dp_lane_p        ,
  
  output              lvds_lcd_clk_p   ,
  output        [3:0] lvds_lcd_data_p  ,
  
  input               tmds_tx_hpd      ,
  output              tmds_tx_clk_p    ,
  output        [2:0] tmds_tx_data_p   ,
  
  output              av_tx_clk        ,
  output logic        av_tx_sync_n     ,
  output logic        av_tx_blank_n    ,
  output logic  [7:0] av_tx_red        ,
  output logic  [7:0] av_tx_green      ,
  output logic  [7:0] av_tx_blue       ,
  
  output        [3:0] led              
  
);
  
  
  
  logic reset_n;
  logic clock;
  
  logic ddr_bot_clk;
  logic ddr_top_clk;
  logic dp_clock;
  
  assign ddr_bot_clk = si5332_clk0_p;
  assign ddr_top_clk = si5332_clk3_p;
  assign dp_clock    = si5332_clk4_p;
  
  assign pcie_ckreq = 1'b1;
  assign pcie_prsnt = 1'b1;
  
  assign rk_out_en = reset_n;
  
  localparam DDR_TOP_INDEX    = 1;
  localparam DDR_BOTTOM_INDEX = 0;
  
  typedef struct packed {
    logic        clock;
    logic        hsync_n;
    logic        vsync_n;
    logic        de;
    logic [23:0] data;
    logic        locked;
  } t_parallel_video;
  
  t_parallel_video iMX6_In;
  t_parallel_video TMDS_In0_even;
  t_parallel_video TMDS_In0_odd;
  t_parallel_video TMDS_In1_even;
  t_parallel_video TMDS_In1_odd;
  t_parallel_video AV_In0;
  t_parallel_video AV_In1;
  t_parallel_video Video_Out;
  t_parallel_video Av_Out;
 
  logic [1:0] ddr_clk;
  
  assign ddr_clk[DDR_BOTTOM_INDEX] = si5332_clk0_p;
  assign ddr_clk[DDR_TOP_INDEX]    = si5332_clk3_p;


 
  cyclonev_clkena #(
    .clock_type        ( "Auto"            ),
    .ena_register_mode ( "always enabled"  ),
    .lpm_type          ( "cyclonev_clkena" )
  ) sd1 (
    .inclk  ( si5332_clk1_p   ),
    .outclk ( Video_Out.clock )
  );
  
  
  
  logic [7:0] ddr_bot_timer;
  logic [7:0] ddr_bot_timer_meta;
  logic [7:0] ddr_bot_timer_latch;
  logic [7:0] ddr_bot_timer_prev;
  logic       ddr_bot_locked;
  
  logic [7:0] ddr_top_timer;
  logic [7:0] ddr_top_timer_meta;
  logic [7:0] ddr_top_timer_latch;
  logic [7:0] ddr_top_timer_prev;
  logic       ddr_top_locked;
  
  logic [7:0] pcie_timer;
  logic [7:0] pcie_timer_meta;
  logic [7:0] pcie_timer_latch;
  logic [7:0] pcie_timer_prev;
  logic       pcie_locked;
  
  logic [7:0] video_out_timer;
  logic [7:0] video_out_timer_meta;
  logic [7:0] video_out_timer_latch;
  logic [7:0] video_out_timer_prev;
  
  logic [7:0] locked_timer;
  
  always @( posedge clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      ddr_bot_locked        <= 1'b0;
      ddr_top_locked        <= 1'b0;
      pcie_locked           <= 1'b0;
      Video_Out.locked      <= 1'b0;
      ddr_bot_timer_prev    <= 8'd0;
      ddr_bot_timer_latch   <= 8'd0;
      ddr_bot_timer_meta    <= 8'd0;
      ddr_top_timer_prev    <= 8'd0;
      ddr_top_timer_latch   <= 8'd0;
      ddr_top_timer_meta    <= 8'd0;
      pcie_timer_prev       <= 8'd0;
      pcie_timer_latch      <= 8'd0;
      pcie_timer_meta       <= 8'd0;
      video_out_timer_prev  <= 8'd0;
      video_out_timer_latch <= 8'd0;
      video_out_timer_meta  <= 8'd0;
      locked_timer          <= 8'd0;
      
    end else begin
      
      if( locked_timer < 8'd79 ) begin
        
        locked_timer <= locked_timer + 8'd1;
        
      end else begin
        
        if( ddr_bot_timer_latch != ddr_bot_timer_prev ) begin
          ddr_bot_locked <= 1'b1;
        end else begin
          ddr_bot_locked <= 1'b0;
        end
        
        if( ddr_top_timer_latch != ddr_top_timer_prev ) begin
          ddr_top_locked <= 1'b1;
        end else begin
          ddr_top_locked <= 1'b0;
        end
        
        if( pcie_timer_latch != pcie_timer_prev ) begin
          pcie_locked <= 1'b1;
        end else begin
          pcie_locked <= 1'b0;
        end
        
        if( video_out_timer_latch != video_out_timer_prev ) begin
          Video_Out.locked <= 1'b1;
        end else begin
          Video_Out.locked <= 1'b0;
        end
        
        { ddr_bot_timer_prev,
          ddr_bot_timer_latch,
          ddr_bot_timer_meta } <= { ddr_bot_timer_latch,
                                    ddr_bot_timer_meta,
                                    ddr_bot_timer };
        
        { ddr_top_timer_prev,
          ddr_top_timer_latch,
          ddr_top_timer_meta } <= { ddr_top_timer_latch,
                                    ddr_top_timer_meta,
                                    ddr_top_timer };
        
        { pcie_timer_prev,
          pcie_timer_latch,
          pcie_timer_meta } <= { pcie_timer_latch,
                                 pcie_timer_meta,
                                 pcie_timer };
        
        { video_out_timer_prev,
          video_out_timer_latch,
          video_out_timer_meta } <= { video_out_timer_latch,
                                      video_out_timer_meta,
                                      video_out_timer };
        
        locked_timer <= 8'd0;
        
      end
      
    end
    
  end
  
  always @( posedge ddr_bot_clk or negedge reset_n )
    if( !reset_n )
      ddr_bot_timer <= 8'd0;
    else
      ddr_bot_timer <= ddr_bot_timer + 8'd1;
  
  always @( posedge ddr_top_clk or negedge reset_n )
    if( !reset_n )
      ddr_top_timer <= 8'd0;
    else
      ddr_top_timer <= ddr_top_timer + 8'd1;
  
  always @( posedge pcie_clk_p or negedge reset_n )
    if( !reset_n )
      pcie_timer <= 8'd0;
    else
      pcie_timer <= pcie_timer + 8'd1;
  
  always @( posedge Video_Out.clock or negedge reset_n )
    if( !reset_n )
      video_out_timer <= 8'd0;
    else
      video_out_timer <= video_out_timer + 8'd1;
  
  
  
  logic        ddr_bot_global_reset_n;
  logic        ddr_bot_soft_reset_n;
  logic        ddr_bot_cal_success;
  logic        ddr_bot_cal_fail;
  logic        ddr_bot_init_done;
  
  logic        ddr_top_global_reset_n;
  logic        ddr_top_soft_reset_n;
  logic        ddr_top_cal_success;
  logic        ddr_top_cal_fail;
  logic        ddr_top_init_done;
  
  logic        dp_reset_n;
  logic        lvds_reset_n;
  logic        tmds_reset_n;
  logic        av_reset_n;
  
  logic        dp_test;
  logic        dp_hpd_nios;
  logic        xcvr_link;
  
  logic        imx6_alpha;
  logic        nios_heart_beat;
  
  logic  [1:0] pu_type;
  
  logic [31:0] system_gpio_in;
  logic [31:0] system_gpio_out;
  
  assign system_gpio_in[7:0]   = rk_in;
  assign system_gpio_in[8]     = lcd_bklt_flt;
  assign system_gpio_in[9]     = xcvr_link;
  assign system_gpio_in[10]    = ddr_bot_locked;
  assign system_gpio_in[11]    = ddr_top_locked;
  assign system_gpio_in[12]    = ddr_bot_cal_success;
  assign system_gpio_in[13]    = ddr_top_cal_success;
  assign system_gpio_in[14]    = ddr_bot_cal_fail;
  assign system_gpio_in[15]    = ddr_top_cal_fail;
  assign system_gpio_in[16]    = ddr_bot_init_done;
  assign system_gpio_in[17]    = ddr_top_init_done;
  assign system_gpio_in[24:20] = milstd_addr;
  
//  assign pcie_ckreq             = system_gpio_out[0];
//  assign pcie_prsnt             = system_gpio_out[1];
//  assign dp_reset_n             = system_gpio_out[2];
//  assign lvds_reset_n           = system_gpio_out[3];
//  assign tmds_reset_n           = system_gpio_out[4];
//  assign av_reset_n             = system_gpio_out[5];
//  assign adv7181_reset          = system_gpio_out[6];
//  assign adv7613_reset          = system_gpio_out[7];
//  assign adv7613_cs0            = system_gpio_out[8];
//  assign adv7613_cs1            = system_gpio_out[9];
//  assign tmds171_oe             = system_gpio_out[10];
//  assign adv7123_psave_n        = system_gpio_out[11];
//  assign lvds_lcd_mode          = system_gpio_out[12];
//  assign lvds_lcd_scan          = system_gpio_out[13];
//  assign reg_out1_en_n          = system_gpio_out[14];
//  assign reg_out3_en_n          = system_gpio_out[15];
//  assign reg_lcd_bklt_en        = system_gpio_out[17:16];
//  assign dp_test                = system_gpio_out[18];
//  assign dp_hpd_nios            = system_gpio_out[19];
//  assign imx6_alpha             = system_gpio_out[20];
  assign nios_heart_beat        = system_gpio_out[22];
//  assign ddr_bot_global_reset_n = system_gpio_out[23];
//  assign ddr_top_global_reset_n = system_gpio_out[24];
//  assign ddr_bot_soft_reset_n   = system_gpio_out[25];
//  assign ddr_top_soft_reset_n   = system_gpio_out[26];
//  assign pu_type                = system_gpio_out[28:27];
  
//   assign led[3] = nios_heart_beat;
   
  
  assign dp_reset_n             = reset_n;
  assign lvds_reset_n           = reset_n;
  assign tmds_reset_n           = reset_n;
  assign av_reset_n             = reset_n;
  
  assign adv7181_reset          = reset_n;
  
//  assign adv7613_reset          = reset_n;
/*
logic [31:0] timer7613;
  always @( posedge clock or negedge reset_n )     
    if( !reset_n ) begin
		timer7613 <= '0;
		adv7613_reset <= 1'b0;
	 end
	 else begin 
	   timer7613 <= (timer7613 >= 320_000_000) ? timer7613 : (timer7613 + 1);
		adv7613_reset <= (timer7613 >= 320_000_000) || (timer7613 <= 240_000_000);
	 end
*/
	

  logic [7:0] video_ic_outputs;
  logic [7:0] video_ic_check_o_pio;
  
  assign adv7613_reset    = reset_n & video_ic_check_o_pio[0];
  assign adv7613_cs0      = video_ic_outputs[0] & video_ic_check_o_pio[1];
  assign adv7613_cs1      = video_ic_outputs[1] & video_ic_check_o_pio[2];
  
  
	
  assign tmds171_oe             = reset_n;
  assign adv7123_psave_n        = reset_n;
  
  assign lvds_lcd_mode          = 1'b0;
  assign lvds_lcd_scan          = 1'b0;
  assign dp_hpd_nios            = 1'b1;
  assign imx6_alpha             = 1'b1;
  
wire [7:0]gp_video_cnfg = {pu_type, ddr_bot_cal_success ,ddr_top_cal_success, ddr_bot_init_done, ddr_top_init_done};
wire [7:0]gp_ddr_resets;
  assign ddr_bot_global_reset_n = gp_ddr_resets[0];
  assign ddr_top_global_reset_n = gp_ddr_resets[1];
  assign ddr_bot_soft_reset_n   = gp_ddr_resets[2];
  assign ddr_top_soft_reset_n   = gp_ddr_resets[3]; 
  
wire [31:0]CRC_sig;

  qsys qsys_i (
    
    .por_reset_n                        ( 1'b1                                                      ),
    
    .clock_out_clk                      ( clock                                                     ),
    .reset_out_reset_n                  ( reset_n                                                   ),
    
    //.gpio_in_port                       ( system_gpio_in                                            ),
    //.gpio_out_port                      ( system_gpio_out                                           ),
    
    .i2c_clk                            ( i2c_scl                                                   ),
    .i2c_data                           ( i2c_sda                                                   ),
    
    .pu_i2c_clk                         ( pu_i2c_scl                                                ),
    .pu_i2c_data                        ( pu_i2c_sda                                                ),
    
    .pu_backlight_fault_n               ( lcd_bklt_flt                                              ),
    .pu_backlight_drv_en                ( lcd_bklt_en                                               ),
    .pu_backlight_out_en_n              ( { out3_en_n, out1_en_n }                                  ),
    .pu_backlight_pwm                   ( { spin_bklt_pwm, btn_bklt_pwm, lcd_bklt_dim }             ),
    
    
    .pu_type_pu_type                    ( pu_type                                                   ),
    .pu_backlight_night                 ( rk_in[1] ),               
	 .pu_backlight_backlight_bite			 ( rk_in[0] ),      
	
    .crc_out_crc                        (CRC_sig),
	 
	 .dev_info_crc_in                    (CRC_sig),                    //           dev_info.crc_in
    .dev_info_mkio_address              (milstd_addr),
    
	 .video_ic_outputs                   ( video_ic_outputs                            ),
    .check_pio_export_export            ( video_ic_check_o_pio ),
	 
	 
	 
    .pcie_npor_npor                     ( reset_n                                                   ),
    .pcie_npor_pin_perst                ( pcie_reset                                                ),
    .pcie_refclk_clk                    ( pcie_clk_p                                                ),
    .pcie_serial_rx_in0                 ( pcie_rx_p                                                 ),
    .pcie_serial_tx_out0                ( pcie_tx_p                                                 ),
    
    .ddr_global_reset_0_reset_n         ( ddr_bot_global_reset_n                                    ),
    .ddr_soft_reset_0_reset_n           ( ddr_bot_soft_reset_n                                      ),
    .ddr_status_0_local_init_done       ( ddr_bot_init_done                                         ),
    .ddr_status_0_local_cal_success     ( ddr_bot_cal_success                                       ),
    .ddr_status_0_local_cal_fail        ( ddr_bot_cal_fail                                          ),
    .ddr_clk_in_0_clk                   ( ddr_bot_clk                                               ),
    .ddr_0_mem_reset_n                  ( ddr_bot_reset_n                                           ),
    .ddr_0_mem_cs_n                     ( ddr_bot_cs_n                                              ),
    .ddr_0_mem_ck                       ( ddr_bot_ck_p                                              ),
    .ddr_0_mem_ck_n                     ( ddr_bot_ck_n                                              ),
    .ddr_0_mem_cke                      ( ddr_bot_cke                                               ),
    .ddr_0_mem_ras_n                    ( ddr_bot_ras_n                                             ),
    .ddr_0_mem_cas_n                    ( ddr_bot_cas_n                                             ),
    .ddr_0_mem_we_n                     ( ddr_bot_we_n                                              ),
    .ddr_0_mem_dqs                      ( ddr_bot_dqs_p                                             ),
    .ddr_0_mem_dqs_n                    ( ddr_bot_dqs_n                                             ),
    .ddr_0_mem_ba                       ( ddr_bot_ba                                                ),
    .ddr_0_mem_a                        ( ddr_bot_addr                                              ),
    .ddr_0_mem_dm                       ( ddr_bot_dm                                                ),
    .ddr_0_mem_dq                       ( ddr_bot_dq                                                ),
    .ddr_0_mem_odt                      ( ddr_bot_odt                                               ),
    .ddr_oct_0_rzqin                    ( ddr_bot_rzq                                               ),
    
    .ddr_global_reset_1_reset_n         ( ddr_top_global_reset_n                                    ),
    .ddr_soft_reset_1_reset_n           ( ddr_top_soft_reset_n                                      ),
    .ddr_status_1_local_init_done       ( ddr_top_init_done                                         ),
    .ddr_status_1_local_cal_success     ( ddr_top_cal_success                                       ),
    .ddr_status_1_local_cal_fail        ( ddr_top_cal_fail                                          ),
    .ddr_clk_in_1_clk                   ( ddr_top_clk                                               ),
    .ddr_1_mem_reset_n                  ( ddr_top_reset_n                                           ),
    .ddr_1_mem_cs_n                     ( ddr_top_cs_n                                              ),
    .ddr_1_mem_ck                       ( ddr_top_ck_p                                              ),
    .ddr_1_mem_ck_n                     ( ddr_top_ck_n                                              ),
    .ddr_1_mem_cke                      ( ddr_top_cke                                               ),
    .ddr_1_mem_ras_n                    ( ddr_top_ras_n                                             ),
    .ddr_1_mem_cas_n                    ( ddr_top_cas_n                                             ),
    .ddr_1_mem_we_n                     ( ddr_top_we_n                                              ),
    .ddr_1_mem_dqs                      ( ddr_top_dqs_p                                             ),
    .ddr_1_mem_dqs_n                    ( ddr_top_dqs_n                                             ),
    .ddr_1_mem_ba                       ( ddr_top_ba                                                ),
    .ddr_1_mem_a                        ( ddr_top_addr                                              ),
    .ddr_1_mem_dm                       ( ddr_top_dm                                                ),
    .ddr_1_mem_dq                       ( ddr_top_dq                                                ),
    .ddr_1_mem_odt                      ( ddr_top_odt                                               ),
    .ddr_oct_1_rzqin                    ( ddr_top_rzq                                               ),
    
    .video_cpu_in_vid_clk               ( iMX6_In.clock                                             ),
    .video_cpu_in_vid_h_sync            ( iMX6_In.hsync_n                                           ),
    .video_cpu_in_vid_v_sync            ( iMX6_In.vsync_n                                           ),
    .video_cpu_in_vid_de                ( iMX6_In.de                                                ),
    .video_cpu_in_vid_data              ( imx6_data_rgba                                            ),
    .video_cpu_in_vid_locked            ( iMX6_In.locked                                            ),
    .video_cpu_in_vid_datavalid         ( 1'b1                                                      ),
    .video_cpu_in_vid_f                 ( 1'b0                                                      ),
    .video_cpu_in_vid_color_encoding    ( '0                                                        ),
    .video_cpu_in_vid_bit_width         ( '0                                                        ),
    
    .video_tmds_in_0_vid_clk            ( TMDS_In0_even.clock                                       ),
    .video_tmds_in_0_vid_h_sync         ( { TMDS_In0_even.hsync_n, TMDS_In0_odd.hsync_n }           ),
    .video_tmds_in_0_vid_v_sync         ( { TMDS_In0_even.vsync_n, TMDS_In0_odd.vsync_n }           ),
    .video_tmds_in_0_vid_de             ( { TMDS_In0_even.de,      TMDS_In0_odd.de      }           ),
    .video_tmds_in_0_vid_data           ( { TMDS_In0_even.data,    TMDS_In0_odd.data    }           ),
    .video_tmds_in_0_vid_locked         ( ( TMDS_In0_even.locked & TMDS_In0_odd.locked  )           ),
    .video_tmds_in_0_vid_datavalid      ( 1'b1                                                      ),
    .video_tmds_in_0_vid_f              ( 1'b0                                                      ),
    .video_tmds_in_0_vid_color_encoding ( '0                                                        ),
    .video_tmds_in_0_vid_bit_width      ( '0                                                        ),
    
    .video_tmds_in_1_vid_clk            ( TMDS_In1_even.clock                                       ),
    .video_tmds_in_1_vid_h_sync         ( { TMDS_In1_even.hsync_n, TMDS_In1_odd.hsync_n }          ),
    .video_tmds_in_1_vid_v_sync         ( { TMDS_In1_even.vsync_n, TMDS_In1_odd.vsync_n }          ),
    .video_tmds_in_1_vid_de             ( { TMDS_In1_even.de,      TMDS_In1_odd.de      }          ),
    .video_tmds_in_1_vid_data           ( { TMDS_In1_even.data,    TMDS_In1_odd.data    }          ),
    .video_tmds_in_1_vid_locked         ( ( TMDS_In1_even.locked & TMDS_In1_odd.locked  )          ),
    .video_tmds_in_1_vid_datavalid      ( 1'b1                                                      ),
    .video_tmds_in_1_vid_f              ( 1'b0                                                      ),
    .video_tmds_in_1_vid_color_encoding ( '0                                                        ),
    .video_tmds_in_1_vid_bit_width      ( '0                                                        ),
    
    .video_av_in_0_vid_clk              ( AV_In0.clock                                              ),
    .video_av_in_0_vid_h_sync           ( av0_hsync[1]                                             ),
    .video_av_in_0_vid_v_sync           ( av0_vsync[1]                                             ),
    .video_av_in_0_vid_de               ( av0_de[1]                                                ),
    .video_av_in_0_vid_data             ( AV_In0.data                                               ),
    .video_av_in_0_vid_locked           ( AV_In0.locked                                             ),
    .video_av_in_0_vid_datavalid        ( 1'b1                                                      ),
    .video_av_in_0_vid_f                ( 1'b0                                                      ),
    .video_av_in_0_vid_color_encoding   ( '0                                                        ),
    .video_av_in_0_vid_bit_width        ( '0                                                        ),
    
    .video_av_in_1_vid_clk              ( AV_In1.clock                                              ),
    .video_av_in_1_vid_h_sync           ( av1_hsync[1]                                           ),
    .video_av_in_1_vid_v_sync           ( av1_vsync[1]                                            ),
    .video_av_in_1_vid_de               ( av1_de[1]                                                 ),
    .video_av_in_1_vid_data             ( AV_In1.data                                               ),
    .video_av_in_1_vid_locked           ( AV_In1.locked                                             ),
    .video_av_in_1_vid_datavalid        ( 1'b1                                                      ),
    .video_av_in_1_vid_f                ( 1'b0                                                      ),
    .video_av_in_1_vid_color_encoding   ( '0                                                        ),
    .video_av_in_1_vid_bit_width        ( '0                                                        ),
    
    .video_out_vid_clk                  ( Video_Out.clock                                           ),
    .video_out_vid_h_sync               ( Video_Out.hsync_n                                         ),
    .video_out_vid_v_sync               ( Video_Out.vsync_n                                         ),
    .video_out_vid_datavalid            ( Video_Out.de                                              ),
    .video_out_vid_data                 ( Video_Out.data                                            ),
    
	 .video_av_out_vid_clk                  ( Av_Out.clock                                           ),
    .video_av_out_vid_h_sync               ( Av_Out.hsync_n                                         ),
    .video_av_out_vid_v_sync               ( Av_Out.vsync_n                                         ),
    .video_av_out_vid_datavalid            ( Av_Out.de                                              ),
    .video_av_out_vid_data                 ( Av_Out.data                                            ),
	 
	 
	 
    .arinc708_inputa                    ( a708_rx_p                                                 ),
    .arinc708_inputb                    ( a708_rx_n                                                 ),
    .arinc708_rx_en                     ( a708_rx_en                                                ),
    .arinc708_outputa                   ( a708_tx_p                                                 ),
    .arinc708_outputb                   ( a708_tx_n                                                 ),
    .arinc708_tx_inh                    ( a708_tx_inh                                               ),
    
    .arinc429_inputa                    ( a429_rx_p                                                 ),
    .arinc429_inputb                    ( a429_rx_n                                                 ),
    .arinc429_outputa                   ( a429_tx_p                                                 ),
    .arinc429_outputb                   ( a429_tx_n                                                 ),
    .arinc429_slewrate                  ( a429_tx_slp                                               ),
    .arinc429_testab                    ( { a429_rx_test_p, a429_rx_test_n }                        ),
    
//    .discr_cmd_in_export                ( rk_in                                                     ),
//    .rk_addr_rk_addr               		( milstd_addr                                     			 ),
	 .discr_cmd_in_addr                  ( milstd_addr                                               ),
	 .discr_cmd_in_dc_in                 ( rk_in                                                     ),
    .gp_gp_inputs 		                ( gp_video_cnfg                                             ),
	 .gp_gp_outputs                      ( gp_ddr_resets                                             ),
	 
    .discr_cmd_out_fault                ( rk_fault                                                  ),
    .discr_cmd_out_export               ( rk_out                                                    )
    
  );
  
  
  
  // LVDS iMX6 receiver
  
  ldi_receiver #(
    .family             ( "Cyclone V" ),
    .clock_freq         ( 100_000_000 ),
    .data_rate          ( "sdr"       ),
    .pixels_in_parallel ( 1           ),
    .hsync_min_period_us( 8           ),
    .hsync_max_period_us( 64          ),
    .vsync_min_period_us( 8000        ),
    .vsync_max_period_us( 64000       ),
    .de_min_length_us   ( 8           ),
    .de_max_length_us   ( 64          ),
    .locked_timeout_us  ( 16000       ),
    .post_steps_fast    ( 0           ),
    .post_steps_slow    ( 2           )
  ) lvds_imx (
    .reset_n   (1'b1                     ),
    .clk       (ddr_clk[DDR_BOTTOM_INDEX]),
    .color_mode(1'b0                     ),
    .ldi_clock (lvds_imx6_clk_p          ),
    .ldi_data  (lvds_imx6_data_p         ),
    .clock     (iMX6_In.clock            ),
    .hsync_n   (iMX6_In.hsync_n          ),
    .vsync_n   (iMX6_In.vsync_n          ),
    .de        (iMX6_In.de               ),
    .data      (iMX6_In.data             ),
    .locked    (iMX6_In.locked           )
  );

  logic [31:0] imx6_data_rgba;
  
  always_comb
  begin
    if ( imx6_alpha )
      imx6_data_rgba = {  iMX6_In.data[23:18], iMX6_In.data[18], iMX6_In.data[18],
                          iMX6_In.data[17:12], iMX6_In.data[12], iMX6_In.data[12],
                          iMX6_In.data[11:6],  iMX6_In.data[6],  iMX6_In.data[6],
                         ~iMX6_In.data[5:0],  ~iMX6_In.data[0], ~iMX6_In.data[0]  };
    else
      imx6_data_rgba = { iMX6_In.data, 8'h0 };
  end
 
  ldi_basic_reciever LVDS_RX_0 (
  
  .reset_n   (1'b1),  
  .ldi_clock (lvds_rx0_clk_p),
  .ldi_data  (lvds_rx0_data_p),  
  .clock     ({ TMDS_In0_odd.clock,   TMDS_In0_even.clock   }),
  .hsync_n   ({ TMDS_In0_odd.hsync_n, TMDS_In0_even.hsync_n }),
  .vsync_n   ({ TMDS_In0_odd.vsync_n, TMDS_In0_even.vsync_n }),
  .de        ({ TMDS_In0_odd.de,      TMDS_In0_even.de      }),
  .data      ({ TMDS_In0_odd.data,    TMDS_In0_even.data    }),
  .locked    ({ TMDS_In0_odd.locked,  TMDS_In0_even.locked  })
  );
 
 /* 
  
  // LVDS(TMDS) receiver channel 1
  t_parallel_video TMDS0_tmp_even, TMDS0_tmp_odd;

  ldi_receiver #(
    .family             ( "Cyclone V" ),
    .clock_freq         ( 100_000_000 ),
    .data_rate          ( "sdr"       ),
    .pixels_in_parallel ( 2           ),
    .hsync_min_period_us( 8           ),
    .hsync_max_period_us( 64          ),
    .vsync_min_period_us( 8000        ),
    .vsync_max_period_us( 64000       ),
    .de_min_length_us   ( 8           ),
    .de_max_length_us   ( 64          ),
    .locked_timeout_us  ( 16000       ),
    .post_steps_fast    ( 0           ),
    .post_steps_slow    ( 2           )
  ) lvds_rx0 (
    .reset_n   ( 1'b1                                           ),
    .clk       ( ddr_clk[DDR_BOTTOM_INDEX]                      ),
    .color_mode( 1'b0                                           ),
    .ldi_clock ( lvds_rx0_clk_p                                 ),
    .ldi_data  ( lvds_rx0_data_p                                ),
    .clock     ( {TMDS0_tmp_even.clock,   TMDS0_tmp_odd.clock}   ),
    .hsync_n   ( {TMDS0_tmp_even.hsync_n, TMDS0_tmp_odd.hsync_n} ),
    .vsync_n   ( {TMDS0_tmp_even.vsync_n, TMDS0_tmp_odd.vsync_n} ),
    .de        ( {TMDS0_tmp_even.de,      TMDS0_tmp_odd.de}      ),
    .data      ( {TMDS0_tmp_even.data,    TMDS0_tmp_odd.data}    ),
    .locked    ( {TMDS0_tmp_even.locked,  TMDS0_tmp_odd.locked}  )
  );  

// localparam de_compare_time = 2048; 
logic[15:0] locked_de_timer=0;
wire de_compare_time = locked_de_timer[11]; // 2048
always_ff @(posedge TMDS0_tmp_even.clock )begin
//		 data <= {data_t[1], data_t[0]};
//		 hsync_n <= {hsync_n_t[1], hsync_n_t[0]};
//		 vsync_n <= {vsync_n_t[1], vsync_n_t[0]};
//		 de <= {de_t[1], de_t[0]};

	locked_de_timer <= de_compare_time ? locked_de_timer : (locked_de_timer + 1);
	
	if( ( TMDS_In0_even.hsync_n != TMDS_In0_odd.hsync_n ) || ( TMDS_In0_even.de != TMDS_In0_odd.de) ) begin
		locked_de_timer <= '0;
	end
	
	
	{ TMDS_In0_even.locked, TMDS_In0_odd.locked }<={TMDS0_tmp_even.locked,  TMDS0_tmp_odd.locked};
	if(!de_compare_time)begin
	 { TMDS_In0_even.data,   TMDS_In0_odd.data   }  <= {TMDS0_tmp_odd.data,    TMDS0_tmp_odd.data};
	 { TMDS_In0_even.hsync_n, TMDS_In0_odd.hsync_n } <= {TMDS0_tmp_odd.hsync_n, TMDS0_tmp_odd.hsync_n};
	 { TMDS_In0_even.vsync_n, TMDS_In0_odd.vsync_n } <= {TMDS0_tmp_odd.vsync_n, TMDS0_tmp_odd.vsync_n};
	 { TMDS_In0_even.de,      TMDS_In0_odd.de      } <= {TMDS0_tmp_odd.de,      TMDS0_tmp_odd.de};
	end
	else begin
	 { TMDS_In0_even.data,   TMDS_In0_odd.data   }  <= {TMDS0_tmp_even.data,    TMDS0_tmp_odd.data};
	 { TMDS_In0_even.hsync_n, TMDS_In0_odd.hsync_n } <= {TMDS0_tmp_even.hsync_n, TMDS0_tmp_odd.hsync_n};
	 { TMDS_In0_even.vsync_n, TMDS_In0_odd.vsync_n } <= {TMDS0_tmp_even.vsync_n, TMDS0_tmp_odd.vsync_n};
	 { TMDS_In0_even.de,      TMDS_In0_odd.de      } <= {TMDS0_tmp_even.de,      TMDS0_tmp_odd.de};
	end
end

assign { TMDS_In0_even.clock,  TMDS_In0_odd.clock  } = { TMDS0_tmp_even.clock,  TMDS0_tmp_odd.clock  };
*/

  // LVDS(TMDS) receiver channel 2
  
  LVDS_Receiver_Serdes LVDS_RX_1 (
    .reset        ( 1'b0                  ),
    .serial_clock ( lvds_rx1_clk_p        ),
    .serial_data  ( lvds_rx1_data_p       ),
    .even_clock   ( TMDS_In1_even.clock   ),
    .even_hsync_n ( TMDS_In1_even.hsync_n ),
    .even_vsync_n ( TMDS_In1_even.vsync_n ),
    .even_de      ( TMDS_In1_even.de      ),
    .even_data    ( TMDS_In1_even.data    ),
    .even_locked  ( TMDS_In1_even.locked  ),
    .odd_clock    ( TMDS_In1_odd.clock    ),
    .odd_hsync_n  ( TMDS_In1_odd.hsync_n  ),
    .odd_vsync_n  ( TMDS_In1_odd.vsync_n  ),
    .odd_de       ( TMDS_In1_odd.de       ),
    .odd_data     ( TMDS_In1_odd.data     ),
    .odd_locked   ( TMDS_In1_odd.locked   )
  );
 
  // LVDS(TMDS) receiver channel 1
//  t_parallel_video TMDS1_tmp_even, TMDS1_tmp_odd;
//  
//  ldi_receiver #(
//    .family             ( "Cyclone V" ),
//    .clock_freq         ( 100_000_000 ),
//    .data_rate          ( "sdr"       ),
//    .pixels_in_parallel ( 2           ),
//    .hsync_min_period_us( 8           ),
//    .hsync_max_period_us( 64          ),
//    .vsync_min_period_us( 8000        ),
//    .vsync_max_period_us( 64000       ),
//    .de_min_length_us   ( 8           ),
//    .de_max_length_us   ( 64          ),
//    .locked_timeout_us  ( 16000       ),
//    .post_steps_fast    ( 0           ),
//    .post_steps_slow    ( 2           )
//  ) LVDS_RX_1 (
//    .reset_n   ( 1'b1                                           ),
//    .clk       ( ddr_clk[DDR_BOTTOM_INDEX]                      ),
//    .color_mode( 1'b0                                           ),
//    .ldi_clock ( lvds_rx1_clk_p                                 ),
//    .ldi_data  ( lvds_rx1_data_p                                ),
//    .clock     ( {TMDS1_tmp_even.clock,   TMDS1_tmp_odd.clock}   ),
//    .hsync_n   ( {TMDS1_tmp_even.hsync_n, TMDS1_tmp_odd.hsync_n} ),
//    .vsync_n   ( {TMDS1_tmp_even.vsync_n, TMDS1_tmp_odd.vsync_n} ),
//    .de        ( {TMDS1_tmp_even.de,      TMDS1_tmp_odd.de}      ),
//    .data      ( {TMDS1_tmp_even.data,    TMDS1_tmp_odd.data}    ),
//    .locked    ( {TMDS1_tmp_even.locked,  TMDS1_tmp_odd.locked}  )
//  );   
//  
//   assign { TMDS_In1_even.clock,  TMDS_In1_odd.clock  } = { TMDS1_tmp_even.clock,  TMDS1_tmp_odd.clock  },
//         { TMDS_In1_even.data,   TMDS_In1_odd.data   } = { TMDS1_tmp_even.data,   TMDS1_tmp_odd.data   },
//         { TMDS_In1_even.locked, TMDS_In1_odd.locked } = { TMDS1_tmp_even.locked, TMDS1_tmp_odd.locked };
//
//  always_ff @(posedge TMDS1_tmp_even.clock)
//    begin
//      { TMDS_In1_even.hsync_n, TMDS_In1_odd.hsync_n } <= { TMDS1_tmp_even.hsync_n, TMDS1_tmp_odd.hsync_n };
//      { TMDS_In1_even.vsync_n, TMDS_In1_odd.vsync_n } <= { TMDS1_tmp_even.vsync_n, TMDS1_tmp_odd.vsync_n };
//      { TMDS_In1_even.de,      TMDS_In1_odd.de      } <= { TMDS1_tmp_even.de,      TMDS1_tmp_odd.de      };
//    end
	 
  
  

  Analog_Receiver Analog_0rx (
    .av_rx_sfl     ( av_reset_n     ),
    .av_rx_llc     ( av_rx0_llc     ),
    .av_rx_hsync_n ( av_rx0_hsync_n ),
    .av_rx_vsync_n ( av_rx0_vsync_n ),
    .av_rx_fb      ( av_rx0_fb      ),
    .av_rx_de      ( av_rx0_de      ),
    .av_rx_data    ( av_rx0_data    ),
    .av_video      ( AV_In0         )
  );
  
  
  
  Analog_Receiver Analog_1rx (
    .av_rx_sfl     ( av_reset_n     ),
    .av_rx_llc     ( av_rx1_llc     ),
    .av_rx_hsync_n ( av_rx1_hsync_n ),
    .av_rx_vsync_n ( av_rx1_vsync_n ),
    .av_rx_fb      ( av_rx1_fb      ),
    .av_rx_de      ( av_rx1_de      ),
    .av_rx_data    ( av_rx1_data    ),
    .av_video      ( AV_In1         )
  );
  
  logic [1:0]av0_hsync;
  logic [1:0]av0_vsync;
  logic [1:0]av0_de;
  always_ff @( posedge AV_In0.clock ) begin
	av0_hsync <= {av0_hsync[0],AV_In0.hsync_n};
	av0_vsync <= {av0_vsync[0],AV_In0.vsync_n};
	av0_de <= {av0_de[0],AV_In0.de};
  end  
 
  logic [1:0]av1_hsync;
  logic [1:0]av1_vsync;
  logic [1:0]av1_de;
  always_ff @( posedge AV_In1.clock ) begin
	av1_hsync <= {av1_hsync[0],AV_In1.hsync_n};
	av1_vsync <= {av1_vsync[0],AV_In1.vsync_n};
	av1_de <= {av1_de[0],AV_In1.de};
  end 
  
  logic        dp_aux_in;
  logic        dp_aux_out;
  logic        dp_aux_oe;
  logic  [7:0] xcvr_rate;
  logic  [4:0] xcvr_lanes;
  logic        xcvr_reset;
  logic  [3:0] xcvr_clk_in;
  logic  [7:0] xcvr_datak;
  logic [63:0] xcvr_data;
  logic        xcvr_pll_powerdown;
  logic        xcvr_pll_locked;
  logic  [3:0] xcvr_analogreset;
  logic  [3:0] xcvr_digitalreset;
  logic  [3:0] xcvr_cal_busy_gxb;
  logic  [3:0] xcvr_clk_out;
  
  assign xcvr_clk_in = { xcvr_clk_out[0], xcvr_clk_out[0], xcvr_clk_out[0], xcvr_clk_out[0] };
  
  displayport #(
    .FREERUN_FREQ ( 100_000_000 )
  ) displayport_i (
    .reset_n      ( dp_reset_n                ),
    .freerun_clk  ( ddr_bot_clk               ),
    .video_clk    ( Video_Out.clock           ),
    .video_hsync  ( Video_Out.hsync_n         ),
    .video_vsync  ( Video_Out.vsync_n         ),
    .video_de     ( Video_Out.de              ),
    .video_data   ( Video_Out.data            ),
    .hpd          ( dp_hpd_nios               ),
    .test         ( dp_test                   ),
    .aux_in       ( dp_aux_in                 ),
    .aux_out      ( dp_aux_out                ),
    .aux_oe       ( dp_aux_oe                 ),
    .xcvr_rate    ( xcvr_rate                 ),
    .xcvr_lanes   ( xcvr_lanes                ),
    .xcvr_reset   ( xcvr_reset                ),
    .xcvr_link    ( xcvr_link                 ),
    .xcvr_clk     ( xcvr_clk_in[0]            ),
    .xcvr_datak   ( xcvr_datak                ),
    .xcvr_data    ( xcvr_data                 )
  );
  
  altiobuffdiff altiobuffdiff_i (
    .oe       ( dp_aux_oe  ),
    .datain   ( dp_aux_out ),
    .dataout  ( dp_aux_in  ),
    .dataio   ( dp_aux_p   ),
    .dataio_b ( dp_aux_n   )
  );
  
  gxb_reset gxb_reset_i (
    .clock           ( ddr_bot_clk               ),
    .reset           ( xcvr_reset                ),
    .pll_locked      ( xcvr_pll_locked           ),
    .pll_select      ( 1'b0                      ),
    .tx_cal_busy     ( xcvr_cal_busy_gxb         ),
    .pll_powerdown   ( xcvr_pll_powerdown        ),
    .tx_analogreset  ( xcvr_analogreset          ),
    .tx_digitalreset ( xcvr_digitalreset         )
  );
  
  gxb_tx gxb_tx_i (
    .pll_powerdown      ( xcvr_pll_powerdown ),
    .tx_pll_refclk      ( dp_clock           ),
    .tx_analogreset     ( xcvr_analogreset   ),
    .tx_digitalreset    ( xcvr_digitalreset  ),
    .tx_cal_busy        ( xcvr_cal_busy_gxb  ),
    .tx_std_polinv      ( 4'b0000            ),
    .tx_datak           ( xcvr_datak         ),
    .tx_parallel_data   ( xcvr_data          ),
    .tx_std_coreclkin   ( xcvr_clk_in        ),
    .tx_std_clkout      ( xcvr_clk_out       ),
    .tx_serial_data     ( dp_lane_p          ),
    .pll_locked         ( xcvr_pll_locked    )
  );
  
  
  
  LvdsTransmitter LCD_TX (
    .reset_n    ( lvds_reset_n          ),
    .color_mode ( 1'b0                  ),
    .Video_Clock( Video_Out.clock       ),
    .Video_HSync( Video_Out.hsync_n     ),
    .Video_VSync( Video_Out.vsync_n     ),
    .Video_Blank( Video_Out.de          ),
    .Video_Red  ( Video_Out.data[23:16] ),
    .Video_Green( Video_Out.data[15:8]  ),
    .Video_Blue ( Video_Out.data[7:0]   ),
    .LVDS_Clock ( lvds_lcd_clk_p        ),
    .LVDS_Data  ( lvds_lcd_data_p       )
  );
  
  t_parallel_video tmds_data;
  
  always_ff @( posedge Video_Out.clock ) begin
    tmds_data.hsync_n <= Video_Out.hsync_n;
    tmds_data.vsync_n <= Video_Out.vsync_n;
    tmds_data.de      <= Video_Out.de;
    tmds_data.data    <= Video_Out.data;
  end
  
  assign tmds_data.clock = Video_Out.clock;
  
  
  
  tmds_transmitter #(
    .CLOCK_RATE  ( "sdr" )
  ) tmds_transmitter_inst (
    .reset_n     ( tmds_reset_n      ),
    .video_clock ( tmds_data.clock   ),
    .video_hsync ( tmds_data.hsync_n ),
    .video_vsync ( tmds_data.vsync_n ),
    .video_de    ( tmds_data.de      ),
    .video_data  ( tmds_data.data    ),
    .serial_clk  ( tmds_tx_clk_p     ),
    .serial_data ( tmds_tx_data_p    )
  );
  
  
  
//  assign av_tx_clk = Video_Out.clock;
//  
//  always_ff @( posedge Video_Out.clock ) begin
//    av_tx_sync_n  <= ( Video_Out.hsync_n ~^ Video_Out.vsync_n );
//    av_tx_blank_n <= Video_Out.de;
//    av_tx_red     <= {Video_Out.data[23:19] ,3'd0};
//    av_tx_green   <= Video_Out.data[15:8] ;
//    av_tx_blue    <= (&Video_Out.data[7:3])? Video_Out.data[7:0] : (Video_Out.data[7:0] + 8'd7)  ;
//  end
  
  logic [23:0]av_data_latch, av_data_lat;
  logic av_sync_latch, av_sync_lat;
  logic av_de_latch, av_de_lat;
  
  assign Av_Out.clock = ddr_top_clk;
  
  assign av_tx_clk = Av_Out.clock;
  always_ff @( posedge Av_Out.clock ) begin: AV_OUT_LOGIC
   {av_data_latch, av_data_lat} <= {av_data_lat, Av_Out.data};
	{av_sync_latch, av_sync_lat} <= {av_sync_lat, ( Av_Out.hsync_n ~^ Av_Out.vsync_n )};
	{av_de_latch, av_de_lat}     <= {av_de_lat, Av_Out.de};  
  
  
    av_tx_sync_n  <= av_sync_latch;
    av_tx_blank_n <= av_de_latch;
    av_tx_red     <= av_data_latch[23:16];//{Av_Out.data[23:19] ,3'd0};
    av_tx_green   <= av_data_latch[15:8];
    av_tx_blue    <= av_data_latch[7:0];//(&Av_Out.data[7:3])? Av_Out.data[7:0] : (Av_Out.data[7:0] + 8'd7);
  end: AV_OUT_LOGIC
  
  
  logic [7:0] ddr_error_code;
  logic [7:0] clock_error_code;
  logic [1:0] device_status;
  
  assign ddr_error_code = { ~ddr_bot_locked,
                            ~ddr_top_locked,
                            ~ddr_bot_cal_success,
                            ~ddr_top_cal_success,
                             ddr_bot_cal_fail,
                             ddr_top_cal_fail,
                            ~ddr_bot_init_done,
                            ~ddr_top_init_done };
  
  assign clock_error_code = { ~pcie_locked,
                              ~iMX6_In.locked,
                              ~( TMDS_In0_even.locked & TMDS_In0_odd.locked ),
                              ~( TMDS_In1_even.locked & TMDS_In1_odd.locked ),
                              ~AV_In0.locked,
                              ~AV_In1.locked,
                              ~Video_Out.locked,
                              ~xcvr_pll_locked };
  
  assign device_status = pu_type;
  
  led_interface #(
    .clock_freq      ( 80_000_000     ),
    .blink_period_ms ( 100            ),
    .pause_before_ms ( 1_000          ),
    .pause_after_ms  ( 10_000         ),
    .bits_count      ( 8              )
  ) led_interface_0 (
    .reset_n         ( reset_n        ),
    .clk             ( clock          ),
    .parallel_code   ( ddr_error_code ),
    .serial_code     ( led[0]         )
  );
  
  led_interface #(
    .clock_freq      ( 80_000_000       ),
    .blink_period_ms ( 100              ),
    .pause_before_ms ( 8_400            ),
    .pause_after_ms  ( 2_600            ),
    .bits_count      ( 8                )
  ) led_interface_1 (
    .reset_n         ( reset_n          ),
    .clk             ( clock            ),
    .parallel_code   ( clock_error_code ),
    .serial_code     ( led[1]           )
  );
  
  led_interface #(
    .clock_freq      ( 80_000_000    ),
    .blink_period_ms ( 100           ),
    .pause_before_ms ( 15_800        ),
    .pause_after_ms  ( 0             ),
    .bits_count      ( 2             )
  ) led_interface_2 (
    .reset_n         ( reset_n       ),
    .clk             ( clock         ),
    .parallel_code   ( device_status ),
    .serial_code     ( led[2]        )
  );
  

  
  
endmodule
