# TCL File Generated by Component Editor 18.1
# Tue Nov 02 10:08:52 MSK 2021
# DO NOT MODIFY


# 
# configurator "configurator" v18.1
#  2021.11.02.10:08:52
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module configurator
# 
set_module_property DESCRIPTION ""
set_module_property NAME configurator
set_module_property VERSION 18.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME configurator
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL configurator
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file configurator.sv SYSTEM_VERILOG PATH configurator.sv TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter FAMILY STRING "Cyclone V"
set_parameter_property FAMILY DEFAULT_VALUE "Cyclone V"
set_parameter_property FAMILY DISPLAY_NAME FAMILY
set_parameter_property FAMILY TYPE STRING
set_parameter_property FAMILY UNITS None
set_parameter_property FAMILY HDL_PARAMETER true
add_parameter ROM_TYPE STRING AUTO
set_parameter_property ROM_TYPE DEFAULT_VALUE AUTO
set_parameter_property ROM_TYPE DISPLAY_NAME ROM_TYPE
set_parameter_property ROM_TYPE TYPE STRING
set_parameter_property ROM_TYPE UNITS None
set_parameter_property ROM_TYPE HDL_PARAMETER true
add_parameter ROM_SIZE INTEGER 256
set_parameter_property ROM_SIZE DEFAULT_VALUE 256
set_parameter_property ROM_SIZE DISPLAY_NAME ROM_SIZE
set_parameter_property ROM_SIZE TYPE INTEGER
set_parameter_property ROM_SIZE UNITS None
set_parameter_property ROM_SIZE ALLOWED_RANGES -2147483648:2147483647
set_parameter_property ROM_SIZE HDL_PARAMETER true
add_parameter ROM_INIT STRING ""
set_parameter_property ROM_INIT DEFAULT_VALUE ""
set_parameter_property ROM_INIT DISPLAY_NAME ROM_INIT
set_parameter_property ROM_INIT TYPE STRING
set_parameter_property ROM_INIT UNITS None
set_parameter_property ROM_INIT HDL_PARAMETER true
add_parameter INPUT_FREQ INTEGER 100000000 CLOCK_RATE
set_parameter_property INPUT_FREQ DEFAULT_VALUE 100000000
set_parameter_property INPUT_FREQ ALLOWED_RANGES 0:250000000
set_parameter_property INPUT_FREQ DISPLAY_NAME "Input frequency"
set_parameter_property INPUT_FREQ TYPE INTEGER
set_parameter_property INPUT_FREQ UNITS Hertz
set_parameter_property INPUT_FREQ HDL_PARAMETER true
set_parameter_property INPUT_FREQ SYSTEM_INFO_TYPE CLOCK_RATE
set_parameter_property INPUT_FREQ SYSTEM_INFO_ARG clock
add_parameter ADDR_OUT_WIDTH INTEGER 16
set_parameter_property ADDR_OUT_WIDTH DEFAULT_VALUE 16
set_parameter_property ADDR_OUT_WIDTH DISPLAY_NAME ADDR_OUT_WIDTH
set_parameter_property ADDR_OUT_WIDTH TYPE INTEGER
set_parameter_property ADDR_OUT_WIDTH UNITS None
set_parameter_property ADDR_OUT_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property ADDR_OUT_WIDTH HDL_PARAMETER true
add_parameter DATA_OUT_WIDTH INTEGER 8
set_parameter_property DATA_OUT_WIDTH DEFAULT_VALUE 8
set_parameter_property DATA_OUT_WIDTH DISPLAY_NAME DATA_OUT_WIDTH
set_parameter_property DATA_OUT_WIDTH TYPE INTEGER
set_parameter_property DATA_OUT_WIDTH UNITS None
set_parameter_property DATA_OUT_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DATA_OUT_WIDTH HDL_PARAMETER true
add_parameter DELAY_MS INTEGER 0
set_parameter_property DELAY_MS DEFAULT_VALUE 0
set_parameter_property DELAY_MS DISPLAY_NAME DELAY_MS
set_parameter_property DELAY_MS TYPE INTEGER
set_parameter_property DELAY_MS UNITS None
set_parameter_property DELAY_MS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DELAY_MS HDL_PARAMETER true


# 
# display items
# 


# 
# connection point avalon_master
# 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock_sink
set_interface_property avalon_master associatedReset reset_sink
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master maximumPendingWriteTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master amm_waitrequest waitrequest Input 1
add_interface_port avalon_master amm_write write Output 1
add_interface_port avalon_master amm_address address Output 32
add_interface_port avalon_master amm_writedata writedata Output DATA_OUT_WIDTH


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink reset_n reset_n Input 1


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink clock clk Input 1


# 
# connection point gpio
# 
add_interface gpio conduit end
set_interface_property gpio associatedClock ""
set_interface_property gpio associatedReset ""
set_interface_property gpio ENABLED true
set_interface_property gpio EXPORT_OF ""
set_interface_property gpio PORT_NAME_MAP ""
set_interface_property gpio CMSIS_SVD_VARIABLES ""
set_interface_property gpio SVD_ADDRESS_GROUP ""

add_interface_port gpio gp_outs outputs Output 8


# 
# connection point reset_source
# 
add_interface reset_source reset start
set_interface_property reset_source associatedClock clock_sink
set_interface_property reset_source associatedDirectReset ""
set_interface_property reset_source associatedResetSinks ""
set_interface_property reset_source synchronousEdges DEASSERT
set_interface_property reset_source ENABLED true
set_interface_property reset_source EXPORT_OF ""
set_interface_property reset_source PORT_NAME_MAP ""
set_interface_property reset_source CMSIS_SVD_VARIABLES ""
set_interface_property reset_source SVD_ADDRESS_GROUP ""

add_interface_port reset_source completed reset_n Output 1
