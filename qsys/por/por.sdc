#
# Power-on reset module constraints
#

create_clock -name {osc_clock} -period "100.000MHz" [get_nets {*|ring_osc_clock}]
create_clock -name {osc_clock} -period "80.000MHz"  [get_nets {*|cyclone_v_clock}] -add

create_generated_clock -name {half_clock}    -source [get_nets {*|clock_reg}] -divide_by 2 [get_registers {por:*|half_clock_reg}]
create_generated_clock -name {quarter_clock} -source [get_nets {*|clock_reg}] -divide_by 4 [get_registers {por:*|quarter_clock_reg}]

set_multicycle_path -to [get_registers {por:*|*_meta}] -hold -end 2

set_false_path -to   [get_registers {por:*|locked_reg}]
set_false_path -from [get_registers {por:*|locked_reg}]

set_false_path -from [get_nets {por:*|reset_n}]
