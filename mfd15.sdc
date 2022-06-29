## Generated SDC file "mfd15.sdc"

## Copyright (C) 2019  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.

## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.1 Build 646 04/11/2019 SJ Standard Edition"

## DATE    "Fri Mar 20 12:33:32 2020"

##
## DEVICE  "5CGXFC7D6F31I7"
##



#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period  "10.000MHz" [get_ports {altera_reserved_tck}]
create_clock -name {int_osc}             -period  "80.000MHz" [get_nets  {osc_clk}]
create_clock -name {ddr_clk0}            -period "100.000MHz" [get_ports {si5332_clk0_p}]
create_clock -name {ddr_clk1}            -period "100.000MHz" [get_ports {si5332_clk3_p}]
#create_clock -name {out_clk}             -period  "74.250MHz" [get_ports {si5332_clk1_p}]
#create_clock -name {out_clk}             -period  "65.000MHz" [get_ports {si5332_clk1_p}] -add
create_clock -name {si5332_clk1_p}       -period   "65.00MHz" [get_ports {si5332_clk1_p}] -add
create_clock -name {si5332_clk1_p}       -period   "74.25MHz" [get_ports {si5332_clk1_p}] -add
create_clock -name {dp_clk}              -period "135.000MHz" [get_ports {si5332_clk4_p}]
create_clock -name {pcie_clk}            -period "125.000MHz" [get_ports {pcie_clk_p}]
create_clock -name {imx6_clk}            -period  "74.250MHz" [get_ports {lvds_imx6_clk_p}]
create_clock -name {tmds_clk00}          -period  "74.250MHz" [get_ports {lvds_rx0_clk_p[0]}]
create_clock -name {tmds_clk01}          -period  "74.250MHz" [get_ports {lvds_rx0_clk_p[1]}]
create_clock -name {tmds_clk10}          -period  "74.250MHz" [get_ports {lvds_rx1_clk_p[0]}]
create_clock -name {tmds_clk11}          -period  "74.250MHz" [get_ports {lvds_rx1_clk_p[1]}]
create_clock -name {av_rx0_llc}          -period  "65.000MHz" [get_ports {av_rx0_llc}]
create_clock -name {av_rx1_llc}          -period  "65.000MHz" [get_ports {av_rx1_llc}]

create_clock -name {imx_virt} -period 519.75MHz
create_clock -name {tmds0_virt} -period 519.75MHz -waveform {0.962 1.924}


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {i2c_scl}            -source [get_nets {osc_clk}]        -divide_by    800 [get_ports {i2c_scl}]

create_generated_clock -name {pu_i2c_scl}         -source [get_ports {si5332_clk0_p}] -divide_by   1000 [get_ports {pu_i2c_scl}]

create_generated_clock -name {dp_aux_rec_clock}   -source [get_ports {si5332_clk0_p}] -divide_by    100 [get_nets  {*dp_aux_clockrecovery*|rec_clock}]
create_generated_clock -name {dp_aux_rec_clock2x} -source [get_ports {si5332_clk0_p}] -divide_by     50 [get_nets  {*dp_aux_clockrecovery*|rec_clock2x}]

create_generated_clock -name {ddr_bot_dqs_p0}     -source [get_ports {si5332_clk0_p}] -multiply_by    4 [get_ports {ddr_bot_dqs_p[0]}]
create_generated_clock -name {ddr_bot_dqs_p1}     -source [get_ports {si5332_clk0_p}] -multiply_by    4 [get_ports {ddr_bot_dqs_p[1]}]
create_generated_clock -name {ddr_top_dqs_p0}     -source [get_ports {si5332_clk3_p}] -multiply_by    4 [get_ports {ddr_top_dqs_p[0]}]
create_generated_clock -name {ddr_top_dqs_p1}     -source [get_ports {si5332_clk3_p}] -multiply_by    4 [get_ports {ddr_top_dqs_p[1]}]

create_generated_clock -name {clock_16mhz}        -source [get_ports {si5332_clk0_p}] -divide_by      6 [get_registers {*clock_divider:*16mhz*|clock_output}]
create_generated_clock -name {clock_1m6hz}        -source [get_ports {si5332_clk0_p}] -divide_by     60 [get_registers {*clock_divider:*1m6hz*|clock_output}]
create_generated_clock -name {a429_tx_clk}        -source [get_ports {si5332_clk0_p}] -divide_by    240 [get_registers {*a429_txphy:*|Clock}]
create_generated_clock -name {i2c_clock4x}        -source [get_ports {osc_clk}]       -divide_by    200 [get_registers {*|ams_i2c:*|i2c_clock4x}]
create_generated_clock -name {i2c_clock2x}        -source [get_ports {osc_clk}]       -divide_by    400 [get_registers {*|ams_i2c:*|i2c_clock2x}]
create_generated_clock -name {i2c_clock}          -source [get_ports {osc_clk}]       -divide_by    800 [get_registers {*|ams_i2c:*|i2c_clock}]


create_generated_clock -name av_tx_clk -source [get_ports {si5332_clk3_p}] -multiply_by 1 [get_ports {av_tx_clk}]


derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay                  -clock [get_clocks {altera_reserved_tck}] 20.000 [get_ports {altera_reserved_tdi}]
set_input_delay -add_delay                  -clock [get_clocks {altera_reserved_tck}] 20.000 [get_ports {altera_reserved_tms}]

set_input_delay -clock [get_clocks {av_rx0_llc}]             -max  2.56 [get_ports {av_rx0_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx0_llc}]             -min  1.69 [get_ports {av_rx0_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx0_llc}] -clock_fall -max  1.81 [get_ports {av_rx0_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx0_llc}] -clock_fall -min  0.64 [get_ports {av_rx0_data[*]}] -add_delay
 
set_input_delay -clock [get_clocks {av_rx0_llc}] -clock_fall -max  0.1 [get_ports {av_rx0_hsync_n av_rx0_vsync_n av_rx0_de}] -add_delay
set_input_delay -clock [get_clocks {av_rx0_llc}] -clock_fall -min -2.8 [get_ports {av_rx0_hsync_n av_rx0_vsync_n av_rx0_de}] -add_delay

set_input_delay -clock [get_clocks {av_rx1_llc}]             -max  2.56 [get_ports {av_rx1_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx1_llc}]             -min  1.69 [get_ports {av_rx1_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx1_llc}] -clock_fall -max  1.81 [get_ports {av_rx1_data[*]}] -add_delay
set_input_delay -clock [get_clocks {av_rx1_llc}] -clock_fall -min  0.64 [get_ports {av_rx1_data[*]}] -add_delay

set_input_delay -clock [get_clocks {av_rx1_llc}] -clock_fall -max  0.1 [get_ports {av_rx1_hsync_n av_rx1_vsync_n av_rx1_de}] -add_delay
set_input_delay -clock [get_clocks {av_rx1_llc}] -clock_fall -min -2.8 [get_ports {av_rx1_hsync_n av_rx1_vsync_n av_rx1_de}] -add_delay
set_input_delay -clock { clock_1m6hz } 1 [get_ports {a429_ctrl_*}]
set_input_delay -clock { clock_1m6hz } 1 [get_ports {a429_rx_*}]
set_input_delay -clock { clock_16mhz } 1 [get_ports {a708_rx*}]
set_input_delay -clock { clock_1m6hz } 1 [get_ports {rk_fault*}]
set_input_delay -clock { clock_1m6hz } 1 [get_ports {rk_in*}]

set_input_delay -max  0.58 -clock [get_clocks imx_virt]   [get_ports {*imx6_data*}]
set_input_delay -min -0.58 -clock [get_clocks imx_virt]   [get_ports {*imx6_data*}]
set_input_delay -max -clock [get_clocks {tmds0_virt}]   0.4  [get_ports {lvds_rx0_data_p[*]*}]
set_input_delay -min -clock [get_clocks {tmds0_virt}]  -0.57 [get_ports {lvds_rx0_data_p[*]*}]

set_input_delay -max -clock [get_clocks {tmds0_virt}]   0.4  [get_ports {lvds_rx1_data_p[*]*}]
set_input_delay -min -clock [get_clocks {tmds0_virt}]  -0.57 [get_ports {lvds_rx1_data_p[*]*}]
#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -clock [get_clocks {altera_reserved_tck}] 20.000 [get_ports {altera_reserved_tdo}]
set_output_delay -clock [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -max  0.5 [get_ports lvds_lcd_data*]
set_output_delay -clock [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -min -0.5 [get_ports lvds_lcd_data*]
set_output_delay -clock [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -max  0.5 [get_ports lvds_lcd_clk*]
set_output_delay -clock [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -min -0.5 [get_ports lvds_lcd_clk*]

#set_output_delay -add_delay -clock { si5332_clk3_p } 2 [get_ports {av_tx_clk}]

set_output_delay -add_delay -clock { av_tx_clk } -min -2 [get_ports {av_tx_blue[0] av_tx_blue[1] av_tx_blue[2] av_tx_blue[3] av_tx_blue[4] av_tx_blue[5] av_tx_blue[6] av_tx_blue[7] }]
set_output_delay -add_delay -clock { av_tx_clk } -min -2 [get_ports {av_tx_green[0] av_tx_green[1] av_tx_green[2] av_tx_green[3] av_tx_green[4] av_tx_green[5] av_tx_green[6] av_tx_green[7]}]
set_output_delay -add_delay -clock { av_tx_clk } -min -2 [get_ports {av_tx_red[0] av_tx_red[1] av_tx_red[2] av_tx_red[7] av_tx_red[6] av_tx_red[5] av_tx_red[4] av_tx_red[3]}]

set_output_delay -add_delay -clock { av_tx_clk } -max 2 [get_ports {av_tx_blue[0] av_tx_blue[1] av_tx_blue[2] av_tx_blue[3] av_tx_blue[4] av_tx_blue[5] av_tx_blue[6] av_tx_blue[7] }]
set_output_delay -add_delay -clock { av_tx_clk } -max 2 [get_ports {av_tx_green[0] av_tx_green[1] av_tx_green[2] av_tx_green[3] av_tx_green[4] av_tx_green[5] av_tx_green[6] av_tx_green[7]}]
set_output_delay -add_delay -clock { av_tx_clk } -max 2 [get_ports {av_tx_red[0] av_tx_red[1] av_tx_red[2] av_tx_red[7] av_tx_red[6] av_tx_red[5] av_tx_red[4] av_tx_red[3]}]

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] \
                               -group [get_clocks {int_osc}]             \
                               -group [get_clocks {ddr_clk0}]            \
                               -group [get_clocks {ddr_clk1}]            \
                               -group [get_clocks {out_clk}]             \
                               -group [get_clocks {dp_clk}]              \
                               -group [get_clocks {tmds_clk00}]          \
                               -group [get_clocks {tmds_clk01}]          \
                               -group [get_clocks {tmds_clk10}]          \
                               -group [get_clocks {tmds_clk11}]          \
                               -group [get_clocks {av_rx0_llc}]          \
                               -group [get_clocks {av_rx1_llc}]          \
                               -group [get_clocks {clock_1m6hz}]         \
                               -group [get_clocks {clock_16mhz}]         \
                               -group [get_clocks {pu_i2c_scl}]          \
                               -group [get_clocks {*pcie_cv_hip_avmm_0|c5_hip_ast|altpcie_av_hip_ast_hwtcl|altpcie_av_hip_128bit_atom|g_cavhip.arriav_hd_altpe2_hip_top|coreclkout}] \
                               -group [get_clocks {pcie_clk}]            
										 
set_clock_groups -logically_exclusive -group [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] \
                                      -group [get_clocks {LCD_TX|LvdsOutputSdrPll_0|lvdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk}]

										 
set_clock_groups -logically_exclusive \
                 -group [get_clocks {lvds_receiver_i|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] \
                 -group [get_clocks {lvds_receiver_i|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[1].output_counter|divclk}] \
                 -group [get_clocks {lvds_receiver_i|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[2].output_counter|divclk}] \
                 -group [get_clocks {lvds_receiver_i|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[3].output_counter|divclk}] \
                 -group [get_clocks {lvds_receiver_i|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[4].output_counter|divclk}] \
                 -group [get_clocks {si5332_clk0_p}]
		
set_clock_groups -asynchronous \
            -group [get_clocks {LVDS_RX_0|lvds_sdr_cyclone_v_pll_i|cyclonev_pll|counter[1].output_counter|divclk}] \
            -group [get_clocks {ddr_clk0}] \
            -group [get_clocks {si5332_clk0_p}]

set_clock_groups -asynchronous \
            -group [get_clocks {TMDS_Transmitter_int0|TmdsOutputSdrPll_0|tmdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] \
            -group [get_clocks {TMDS_Transmitter_int0|TmdsOutputSdrPll_0|tmdsoutputsdrpll_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk}] \
            -group [get_clocks {si5332_clk1_p}] \
            -group [get_clocks {out_clk}] \
            -group [get_clocks {tmds0_virt}] \
            -group [get_clocks {int_osc}] 

#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_clocks {altera_reserved_tck}]  -to  [get_clocks {altera_reserved_tck}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|jupdate}] -to [get_registers {*|alt_jtag_atlantic:*|jupdate1*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|rdata[*]}] -to [get_registers {*|alt_jtag_atlantic*|td_shift[*]}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|read}] -to [get_registers {*|alt_jtag_atlantic:*|read1*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|read_req}] 
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|rvalid}] -to [get_registers {*|alt_jtag_atlantic*|td_shift[*]}]
set_false_path -from [get_registers {*|t_dav}] -to [get_registers {*|alt_jtag_atlantic:*|tck_t_dav}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|user_saw_rvalid}] -to [get_registers {*|alt_jtag_atlantic:*|rvalid0*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|wdata[*]}] -to [get_registers *]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write}] -to [get_registers {*|alt_jtag_atlantic:*|write1*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_stalled}] -to [get_registers {*|alt_jtag_atlantic:*|t_ena*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_stalled}] -to [get_registers {*|alt_jtag_atlantic:*|t_pause*}]
set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_valid}] 
set_false_path -to   [get_keepers {*data_out_sync0*}]
set_false_path -to   [get_registers {*alt_xcvr_resync*sync_r[0]}]
set_false_path -to   [get_keepers {*altera_std_synchronizer:*|din_s1}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_ue9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_te9:dffpipe6|dffe7a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_se9:dffpipe18|dffe19a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_re9:dffpipe15|dffe16a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_3f9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_2f9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_0f9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_ve9:dffpipe6|dffe7a*}]
set_false_path -from [get_keepers {sld_hub:*}] 
set_false_path -to   [get_keepers {sld_hub:*}]

set_false_path -to   [get_ports {led[*]}]

set_false_path -from [get_keepers {*reset_n}]
set_false_path -from [get_keepers {*reset}]
set_false_path -from [get_keepers {*nReset}]
set_false_path -from [get_keepers {*Signal_Reset}]
set_false_path -from [get_keepers {*Signal_nReset}]

set_false_path -from [get_ports {rk_in*}]
set_false_path -from [get_ports {rk_fault*}]
set_false_path -from [get_ports {lcd_bklt_flt*}]

# set_false_path -to   [get_registers {*_meta}]
# set_false_path -to   [get_registers {*_meta[*]}]

set_false_path -to   [get_ports {dp_aux_*}]
set_false_path -to   [get_ports {dp_hpd}]
set_false_path -from [get_registers {*hpd_decode*|prst}]

set_false_path -from {*ddr_reset:*|ready_reg}

set_false_path -from {*dp_main_video_calc:*|video_locked}

set_false_path -from [get_clocks {*pcie_cv_hip_avmm_0|c5_hip_ast|altpcie_av_hip_ast_hwtcl|altpcie_av_hip_128bit_atom|g_cavhip.arriav_hd_altpe2_hip_top|coreclkout}] -to [get_clocks {clock_1m6hz}]
set_false_path -from [get_clocks {*pcie_cv_hip_avmm_0|c5_hip_ast|altpcie_av_hip_ast_hwtcl|altpcie_av_hip_128bit_atom|g_cavhip.arriav_hd_altpe2_hip_top|coreclkout}] -to [get_clocks {a429_tx_clk}]
set_false_path -from [get_clocks {clock_1m6hz}] -to [get_clocks {*pcie_cv_hip_avmm_0|c5_hip_ast|altpcie_av_hip_ast_hwtcl|altpcie_av_hip_128bit_atom|g_cavhip.arriav_hd_altpe2_hip_top|coreclkout}]
set_false_path -from [get_clocks {clock_1m6hz}] -to [get_clocks {a429_tx_clk}]

##################################
set_false_path -from {LvdsTransmitter:LCD_TX|LVDS_Data[*]} -to {lvds_lcd_data_p[*]*}
set_false_path -from {LvdsTransmitter:LCD_TX|LVDS_Clock} -to {lvds_lcd_clk_p*}
set_false_path -from [get_keepers {osc_locked}]
set_false_path -to [get_keepers {*pio*readdata[*]}]
set_false_path -from [get_keepers {*pio*data_out[*]}]
##################################
set_false_path -setup -rise_from [get_clocks {av_rx0_llc}] -fall_to [get_clocks {av_rx0_llc}]
set_false_path -setup -fall_from [get_clocks {av_rx0_llc}] -rise_to [get_clocks {av_rx0_llc}]
set_false_path -hold  -rise_from [get_clocks {av_rx0_llc}] -rise_to [get_clocks {av_rx0_llc}]
set_false_path -hold  -fall_from [get_clocks {av_rx0_llc}] -fall_to [get_clocks {av_rx0_llc}]

set_false_path -setup -rise_from [get_clocks {av_rx1_llc}] -fall_to [get_clocks {av_rx1_llc}]
set_false_path -setup -fall_from [get_clocks {av_rx1_llc}] -rise_to [get_clocks {av_rx1_llc}]
set_false_path -hold  -rise_from [get_clocks {av_rx1_llc}] -rise_to [get_clocks {av_rx1_llc}]
set_false_path -hold  -fall_from [get_clocks {av_rx1_llc}] -fall_to [get_clocks {av_rx1_llc}]
#**************************************************************
# Set Multicycle Path
#**************************************************************
# set_multicycle_path -from {LvdsTransmitter:LCD_TX|\SerializerSDR:Signal_DataOut[*]} -to {lvds_lcd_data_p[*]*} -setup -end 4
# set_multicycle_path -from {LvdsTransmitter:LCD_TX|\SerializerSDR:Signal_DataOut[*]} -to {lvds_lcd_data_p[*]*} -hold  -end 4
# set_multicycle_path -from {LvdsTransmitter:LCD_TX|\SerializerSDR:Signal_ClockOut} -to {lvds_lcd_clk_p*} -setup -end 4
# set_multicycle_path -from {LvdsTransmitter:LCD_TX|\SerializerSDR:Signal_ClockOut} -to {lvds_lcd_clk_p*} -hold  -end 4
# set_multicycle_path -from {lvds_imx6_data*} -to {*lvds_receiver*|serial_data_meta} -setup -end 2
# set_multicycle_path -from {*serial_shift_submodule_i|serial_data_meta*} -to {*serial_shift_submodule_i|serial_data_latch*} -setup -end 2
# set_multicycle_path -from {*serial_shift_submodule_i|serial_data_meta*} -to {*serial_shift_submodule_i|serial_data_latch*} -hold -end 2
# set_multicycle_path -from {lvds_rx0_data*}  -to {*serial_data_meta*} -setup -end 2
# set_multicycle_path -from {lvds_rx0_data*}  -to {*serial_data_meta*} -hold  -end 2

# set_multicycle_path -from {*LVDS_RX*|serial_data_meta} -to {*LVDS_RX*|serial_data_latch_e} -setup -end 2
# set_multicycle_path -from {*LVDS_RX*|serial_data_meta} -to {*LVDS_RX*|serial_data_latch_e} -hold -end 2

#set_multicycle_path -from {lvds_rx0_data_p[*]} -to {lvds_receiver_2px:LVDS_RX_0|serial_shift:serial_data_gen[*].serial_shift_i|serial_data_meta} -hold -end 2
set_multicycle_path -to {lvds_receiver_2px*serial_data_meta} -hold -end 2

set_multicycle_path -from {lvds_imx6_data_p[*]} -to {lvds_receiver:lvds_receiver_i|serial_shift_submodule:serial_data_gen[*].serial_shift_submodule_i|serial_data_meta} -hold -end 1
# set_multicycle_path -from {lvds_receiver_2px:LVDS_RX_0|serial_shift:serial_data_gen[*].serial_shift_i|serial_data_meta} -to {lvds_receiver_2px:LVDS_RX_0|serial_shift:serial_data_gen[*].serial_shift_i|serial_data_latch_e} -setup -end 2
# set_multicycle_path -from {lvds_receiver_2px:LVDS_RX_0|serial_shift:serial_data_gen[*].serial_shift_i|serial_data_meta} -to {lvds_receiver_2px:LVDS_RX_0|serial_shift:serial_data_gen[*].serial_shift_i|serial_data_latch_e} -hold -end 2

# set_multicycle_path -from {TmdsTransmitter*|Signal_*_D*} -to {*|tmds_encoder_dvi*o_tmds[*]} -setup -end 2
# set_multicycle_path -from {TmdsTransmitter:TMDS_Transmitter_int0|Signal_*_D[*]} -to {TmdsTransmitter:TMDS_Transmitter_int0|tmds_encoder_dvi*|bias[*]} -setup -end 2
# set_multicycle_path -from {TmdsTransmitter:TMDS_Transmitter_int0|Signal_*_D[*]} -to {TmdsTransmitter:TMDS_Transmitter_int0|tmds_encoder_dvi*|bias[*]} -hold -end 2
# set_multicycle_path -from [get_registers {TmdsTransmitter*Signal_Counter[*]*}] -to [get_registers {TmdsTransmitter*Signal_Counter[*]*}] -setup -end 3
# set_multicycle_path -from [get_registers {TmdsTransmitter*Signal_Counter[*]*}] -to [get_registers {TmdsTransmitter*Signal_*Shift[*]*}] -setup -end 2
#**************************************************************
# Set Maximum Delay
#**************************************************************

#set_max_delay -from [get_keepers {*LPM_SHIFTREG_component*dffs*}] -to [get_keepers {*SerDes*Sync*}] 2.000



#**************************************************************
# Set Minimum Delay
#**************************************************************

#set_min_delay -from [get_keepers {*LPM_SHIFTREG_component*dffs*}] -to [get_keepers {*SerDes*Sync*}] -2.000



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Net Delay
#**************************************************************

#set_net_delay -max -from [get_keepers {*LPM_SHIFTREG_component*dffs*}] -to [get_keepers {*SerDes*Sync*}]         -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period
#set_net_delay -max -from [get_keepers {*dataout*}]                     -to [get_keepers {*SerDes*dffs*}]         -value_multiplier 0.450 -get_value_from_clock_period src_clock_period
#set_net_delay -max -from [get_keepers {*SerDes*dffs*}]                 -to [get_keepers {*SerDes*dffs*}]         -value_multiplier 0.800 -get_value_from_clock_period src_clock_period
#set_net_delay -max -from [get_keepers {*SerDes*dffs*}]                 -to [get_keepers {*SerDes*Sync*}]         -value_multiplier 0.800 -get_value_from_clock_period src_clock_period
#set_net_delay -max -from [get_keepers {*SerDes*Sync*}]                 -to [get_keepers {*SerDes*Data_o*}]       -value_multiplier 0.800 -get_value_from_clock_period src_clock_period
#set_net_delay -max -from [get_keepers {*SerDes*Data_o*}]               -to [get_keepers {*LVDS_RX*LatchData_D*}] -value_multiplier 0.800 -get_value_from_clock_period src_clock_period
#set_net_delay -max -from [get_keepers {*LVDS_RX*LatchData_D*}]         -to [get_keepers {*LVDS_RX*RGB*}]         -value_multiplier 0.800 -get_value_from_clock_period src_clock_period
# set_net_delay -from [get_registers *LVDS_RX*serial_data_meta*] -to [get_registers *serial_data_latch_e*] -max 3.84
# set_net_delay -from [get_registers *LVDS_RX*serial_data_meta*] -to [get_registers *serial_data_latch_e*] -min 1.92
# set_max_delay -from [get_registers *LVDS_RX*serial_data_meta*] -to [get_registers *serial_data_latch_e*] 3.84
# set_min_delay -from [get_registers *LVDS_RX*serial_data_meta*] -to [get_registers *serial_data_latch_e*] 1.92
# set_max_delay -from {*serial_shift_submodule_i|serial_data_meta*} -to {*serial_shift_submodule_i|serial_data_latch*} 3.84
# set_min_delay -from {*serial_shift_submodule_i|serial_data_meta*} -to {*serial_shift_submodule_i|serial_data_latch*} 1.92
# set_net_delay -from [get_pins -compatibility_mode *2px*serial_data_meta\|q] -max 1.3
set_max_delay -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]]  6.734
set_min_delay -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -6.734
set_net_delay -from [get_pins -compatibility_mode lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -max -get_value_from_clock_period dst_clock_period      -value_multiplier 0.6
set_max_skew  -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6


set_max_skew -from [get_ports {lvds_rx0_data_p[*]}] -to [get_registers {ldi_basic_reciever:*|data*]}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6
set_max_skew -from [get_ports {lvds_rx1_data_p[*]}] -to [get_registers {ldi_basic_reciever:*|data*]}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6

set_multicycle_path -from [get_registers {ldi_basic_reciever:*|data_latch*}] -to [get_registers {ldi_basic_reciever:*|data_slow*}] -hold -end 2


#**************************************************************
# Set Max Skew
#**************************************************************

#set_max_skew -from [get_keepers {*LPM_SHIFTREG_component*dffs*}] -to [get_keepers {*SerDes*Sync*}]         -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*Signal_ShiftData*}]            -to [get_keepers {*Signal_LatchData_D*}]  -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*dataout*}]                     -to [get_keepers {*SerDes*dffs*}]         -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.450
#set_max_skew -from [get_keepers {*SerDes*dffs*}]                 -to [get_keepers {*SerDes*dffs*}]         -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*SerDes*dffs*}]                 -to [get_keepers {*SerDes*Sync*}]         -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*SerDes*Sync*}]                 -to [get_keepers {*SerDes*Data_o*}]       -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*SerDes*Data_o*}]               -to [get_keepers {*LVDS_RX*LatchData_D*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*LVDS_RX*LatchData_D*}]         -to [get_keepers {*LVDS_RX*RGB*}]         -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*Lvds*Signal_EncodedData*}]     -to [get_keepers {*Signal_ShiftData*}]    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {*Lvds*Signal_ClockOut*}]        -to [get_keepers {*LVDS_LCD_CLK*}]        -get_skew_value_from_clock_period dst_clock_period -skew_value_multiplier 0.800
#set_max_skew -from [get_keepers {lvds_rx0_data_p[*]}]                                                      -get_skew_value_from_clock_period dst_clock_period -skew_value_multiplier 0.800

#set_max_skew -from [get_keepers {serial_data[*]}] -to [get_keepers {*lvds_receiver:*|serial_*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.500 -exclude { from_clock to_clock clock_uncertainty }
#set_max_skew -from [get_keepers {*lvds_receiver:*|serial_*}] -get_skew_value_from_clock_period dst_clock_period -skew_value_multiplier 0.500 -exclude { from_clock to_clock clock_uncertainty }

set_false_path -from [get_keepers {*lvds_receiver*|color_mode_latch}]
