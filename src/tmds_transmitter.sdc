#
# TMDS transmitter constraints
#

# set_multicycle_path -from {*tmds_transmitter:*|tmds_shift_out:serial_data_gen[*].*|data_shift[0]} -setup 3

# set_multicycle_path -to {*tmds_transmitter:*|tmds_encoder_dvi*o_tmds[*]} -setup -end 2

# set_multicycle_path -to {*tmds_transmitter:*|tmds_encoder_dvi*|bias[*]} -setup -end 2
# set_multicycle_path -to {*tmds_transmitter:*|tmds_encoder_dvi*|bias[*]} -hold  -end 2

# set_false_path -to {*tmds_transmitter:*|*_meta}
# set_false_path -to {*tmds_transmitter:*|*_meta[*]}


set_max_delay -from [get_registers                tmds_transmitter*o_tmds[*]] -to [get_registers tmds_transmitter*tmds_encoded_meta[*]]  6.734
set_min_delay -from [get_registers                tmds_transmitter*o_tmds[*]] -to [get_registers tmds_transmitter*tmds_encoded_meta[*]] -6.734
set_net_delay -from [get_pins -compatibility_mode tmds_transmitter*o_tmds[*]] -to [get_registers tmds_transmitter*tmds_encoded_meta[*]] -max -get_value_from_clock_period dst_clock_period      -value_multiplier 0.6
set_max_skew  -from [get_registers                tmds_transmitter*o_tmds[*]] -to [get_registers tmds_transmitter*tmds_encoded_meta[*]] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.6
