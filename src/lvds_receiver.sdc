# create_clock -name {tmds0_virt}  -period 519.75MHz 
#
# set_input_delay -max -clock [get_clocks {tmds0_virt}]   0.4  [get_ports {lvds_rx_data[*]*}]
# set_input_delay -min -clock [get_clocks {tmds0_virt}]  -0.57 [get_ports {lvds_rx_data[*]*}]
#
#

set_multicycle_path -to {*lvds_receiver*serial_data_meta} -hold  -end   2

set_max_delay -from [get_registers *lvds_receiver*data_shift*] -to [get_registers lvds_receiver*serial_shift*data\[*\]]  6.734
set_min_delay -from [get_registers *lvds_receiver*data_shift*] -to [get_registers lvds_receiver*serial_shift*data\[*\]] -6.734
set_net_delay -from [get_nets      *lvds_receiver*data_shift*] -to [get_registers lvds_receiver*serial_shift*data\[*\]] -max -get_value_from_clock_period dst_clock_period -value_multiplier      0.6
set_max_skew  -from [get_registers *lvds_receiver*data_shift*] -to [get_registers lvds_receiver*serial_shift*data\[*\]] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6

set_false_path -from [get_registers *lvds_receiver*ldi_dps*phase_locked] -to [get_registers *alt_vip_cvi_core*]