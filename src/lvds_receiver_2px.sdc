set_multicycle_path -to {lvds_receiver_2px*serial_data_meta} -hold -end 2

set_max_delay -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]]  6.734
set_min_delay -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -6.734
set_net_delay -from [get_pins -compatibility_mode lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -max -get_value_from_clock_period dst_clock_period      -value_multiplier 0.6
set_max_skew  -from [get_registers                lvds_receiver_2px*data_shift*] -to [get_registers lvds_receiver_2px*serial_shift*data\[*\]] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6
