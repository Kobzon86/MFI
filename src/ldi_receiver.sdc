#
# LVDS Display Interface receiver constraints
#

#set_max_delay -from [get_registers                {*ldi_receiver:*|data_shift*}] -to [get_registers *ldi_receiver:*|*:ldi_deserializer_i|data\[*\]]  6.734
#set_min_delay -from [get_registers                {*ldi_receiver:*|data_shift*}] -to [get_registers *ldi_receiver:*|*:ldi_deserializer_i|data\[*\]] -6.734
#set_net_delay -from [get_pins -compatibility_mode {*ldi_receiver:*|data_shift*}] -to [get_registers *ldi_receiver:*|*:ldi_deserializer_i|data\[*\]] -max -get_value_from_clock_period dst_clock_period      -value_multiplier 0.6
#set_max_skew  -from [get_registers                {*ldi_receiver:*|data_shift*}] -to [get_registers *ldi_receiver:*|*:ldi_deserializer_i|data\[*\]] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6

set_multicycle_path -to {*ldi_receiver:*|serial_data_meta} -hold -end 2

set_false_path -to [get_registers {*ldi_receiver:*|reset_n_meta}]
set_false_path -to [get_registers {*ldi_receiver:*|color_mode_meta}]
