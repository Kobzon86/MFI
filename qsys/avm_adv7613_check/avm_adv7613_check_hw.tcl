
#package require -exact altera_terp 1.0
package require -exact qsys 12.1
# 
# module avm_adv7613_check
# 
set_module_property DESCRIPTION ""
set_module_property NAME avm_adv7613_check
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ELABORATION_CALLBACK elaborate
#set_module_property GENERATION_CALLBACK generate
#set_module_property _PREVIEW_GENERATE_VERILOG_SIMULATION_CALLBACK generate
set_module_property HIDE_FROM_SOPC true
#set_module_property SIMULATION_MODEL_IN_VHDL true
set_module_property ANALYZE_HDL FALSE
set_module_property VALIDATION_CALLBACK validate

# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL avm_adv7613_check
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file avm_adv7613_check.sv SYSTEMVERILOG PATH avm_adv7613_check.sv TOP_LEVEL_FILE

# 
# parameters
#
add_parameter DEV_FAMILY STRING 10 "Device Family"
set_parameter_property DEV_FAMILY SYSTEM_INFO DEVICE_FAMILY
set_parameter_property DEV_FAMILY DISPLAY_NAME "Device Family"
set_parameter_property DEV_FAMILY TYPE STRING
set_parameter_property DEV_FAMILY DERIVED true
set_parameter_property DEV_FAMILY VISIBLE true
set_parameter_property DEV_FAMILY HDL_PARAMETER false

add_parameter AMM_ADR_MAP STRING 10 "Address Map"
set_parameter_property AMM_ADR_MAP SYSTEM_INFO {ADDRESS_MAP "avm_master"}
set_parameter_property AMM_ADR_MAP DISPLAY_NAME "Address Map"
set_parameter_property AMM_ADR_MAP TYPE STRING
set_parameter_property AMM_ADR_MAP DERIVED true
set_parameter_property AMM_ADR_MAP VISIBLE false
set_parameter_property AMM_ADR_MAP HDL_PARAMETER false

add_parameter IN_CLK_HZ INTEGER 10 "Входная тактовая частота(Гц)"
set_parameter_property IN_CLK_HZ SYSTEM_INFO {CLOCK_RATE "clock_sink"}
set_parameter_property IN_CLK_HZ DISPLAY_NAME "Входная тактовая частота(Гц)"
set_parameter_property IN_CLK_HZ TYPE INTEGER
set_parameter_property IN_CLK_HZ DERIVED true
set_parameter_property IN_CLK_HZ VISIBLE true
set_parameter_property IN_CLK_HZ HDL_PARAMETER true

add_parameter TIMER_DELAY_MKS INTEGER 1 "Период запуска рабочего цикла(в мкс)"
set_parameter_property TIMER_DELAY_MKS DEFAULT_VALUE 1
set_parameter_property TIMER_DELAY_MKS DISPLAY_NAME "Период запуска рабочего цикла(в мкс)"
set_parameter_property TIMER_DELAY_MKS WIDTH ""
set_parameter_property TIMER_DELAY_MKS TYPE INTEGER
set_parameter_property TIMER_DELAY_MKS UNITS None
set_parameter_property TIMER_DELAY_MKS ALLOWED_RANGES 1:100000000
set_parameter_property TIMER_DELAY_MKS HDL_PARAMETER true

add_parameter AMS_I2C_AMM_ADDRESS INTEGER 1 "Адрес AMS_I2C на шине Avalon-MM"
set_parameter_property AMS_I2C_AMM_ADDRESS DEFAULT_VALUE 0
set_parameter_property AMS_I2C_AMM_ADDRESS DISPLAY_NAME "Адрес AMS_I2C на шине Avalon-MM"
set_parameter_property AMS_I2C_AMM_ADDRESS WIDTH ""
set_parameter_property AMS_I2C_AMM_ADDRESS TYPE INTEGER
set_parameter_property AMS_I2C_AMM_ADDRESS UNITS None
set_parameter_property AMS_I2C_AMM_ADDRESS HDL_PARAMETER true
 
add_parameter ADV7613_I2C_ADDRESS INTEGER 1024 "Адрес на шине I2C(DEC, A2A1A0)"
set_parameter_property ADV7613_I2C_ADDRESS DEFAULT_VALUE 3
set_parameter_property ADV7613_I2C_ADDRESS DISPLAY_NAME "Адрес на шине I2C(DEC, A2A1A0)" 
set_parameter_property ADV7613_I2C_ADDRESS WIDTH ""
set_parameter_property ADV7613_I2C_ADDRESS TYPE INTEGER
set_parameter_property ADV7613_I2C_ADDRESS UNITS None
set_parameter_property ADV7613_I2C_ADDRESS ALLOWED_RANGES 0:7
set_parameter_property ADV7613_I2C_ADDRESS HDL_PARAMETER true

add_parameter ADV7613_TIMER_RESET_MKS INTEGER 1 "Длительность сброса(в мкс)"
set_parameter_property ADV7613_TIMER_RESET_MKS DEFAULT_VALUE 10000
set_parameter_property ADV7613_TIMER_RESET_MKS DISPLAY_NAME "Длительность сброса(в мкс)"
set_parameter_property ADV7613_TIMER_RESET_MKS WIDTH ""
set_parameter_property ADV7613_TIMER_RESET_MKS TYPE INTEGER
set_parameter_property ADV7613_TIMER_RESET_MKS UNITS None
set_parameter_property ADV7613_TIMER_RESET_MKS ALLOWED_RANGES 1:100000000
set_parameter_property ADV7613_TIMER_RESET_MKS HDL_PARAMETER true

add_display_item "Основные параметры"  DEV_FAMILY parameter
add_display_item "Основные параметры"  IN_CLK_HZ parameter
add_display_item "Основные параметры"  TIMER_DELAY_MKS parameter
add_display_item "ADV7613"             AMS_I2C_AMM_ADDRESS parameter
add_display_item "ADV7613"             ADV7613_I2C_ADDRESS parameter
add_display_item "ADV7613"             ADV7613_TIMER_RESET_MKS parameter

# connection point clock_sink
add_interface clock_sink clock end
#set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink i_avs_clk clk Input 1


# connection point clock_sink_reset
add_interface clock_sink_reset reset end
set_interface_property clock_sink_reset associatedClock clock_sink
set_interface_property clock_sink_reset synchronousEdges DEASSERT
set_interface_property clock_sink_reset ENABLED true
set_interface_property clock_sink_reset EXPORT_OF ""
set_interface_property clock_sink_reset PORT_NAME_MAP ""
set_interface_property clock_sink_reset SVD_ADDRESS_GROUP ""

add_interface_port clock_sink_reset i_avs_rst_n reset_n Input 1


# 
# connection point avm_master
# 
add_interface avm_master avalon start
set_interface_property avm_master addressUnits SYMBOLS
set_interface_property avm_master associatedClock clock_sink
set_interface_property avm_master associatedReset clock_sink_reset
set_interface_property avm_master bitsPerSymbol 8
set_interface_property avm_master burstOnBurstBoundariesOnly false
set_interface_property avm_master burstcountUnits WORDS
set_interface_property avm_master doStreamReads false
set_interface_property avm_master doStreamWrites false
set_interface_property avm_master holdTime 0
set_interface_property avm_master linewrapBursts false
set_interface_property avm_master maximumPendingReadTransactions 0
set_interface_property avm_master maximumPendingWriteTransactions 0
set_interface_property avm_master readLatency 0
set_interface_property avm_master readWaitTime 1
set_interface_property avm_master setupTime 0
set_interface_property avm_master timingUnits Cycles
set_interface_property avm_master writeWaitTime 0
set_interface_property avm_master ENABLED true
set_interface_property avm_master EXPORT_OF ""
set_interface_property avm_master PORT_NAME_MAP ""

add_interface_port avm_master o_avm_address address Output 32
add_interface_port avm_master o_avm_write write Output 1
add_interface_port avm_master o_avm_writedata writedata Output 8
add_interface_port avm_master o_avm_read read Output 1
add_interface_port avm_master i_avm_readdata readdata Input 8
add_interface_port avm_master i_avm_waitrequest waitrequest Input 1


# connection point clock_output_reset
add_interface clock_output_reset reset start
set_interface_property clock_output_reset associatedClock clock_sink
set_interface_property clock_output_reset synchronousEdges DEASSERT
set_interface_property clock_output_reset ENABLED true
set_interface_property clock_output_reset EXPORT_OF ""
set_interface_property clock_output_reset PORT_NAME_MAP ""
set_interface_property clock_output_reset SVD_ADDRESS_GROUP ""

add_interface_port clock_output_reset o_avs_rst_n reset_n Output 1

# conduit_end point clock_output_reset
add_interface ext_pio conduit end
set_interface_property ext_pio associatedClock clock_sink
set_interface_property ext_pio associatedReset clock_sink_reset
set_interface_property ext_pio ENABLED true
set_interface_property ext_pio EXPORT_OF ""
set_interface_property ext_pio PORT_NAME_MAP ""
set_interface_property ext_pio CMSIS_SVD_VARIABLES ""
set_interface_property ext_pio SVD_ADDRESS_GROUP ""

add_interface_port ext_pio o_pio export Output 8

# +-----------------------------------
# | Elaboration callback
# +-----------------------------------

proc elaborate {} {
    set map_range ""
	set address_map_xml [get_parameter_value AMM_ADR_MAP]
    set address_map_dec [decode_address_map $address_map_xml]
    foreach i $address_map_dec {
      array set info $i
	  set amm_address_hex [format "%#x" $info(start)];
	  set amm_address_dec [format "%#u" $amm_address_hex];
	  
	  set str1 "\"$amm_address_dec:$info(start)->$info(name)\""
      send_message info "AVM_MASTER connected to slave $str1 "
	  append map_range " " $str1 
    }
	  
	set_parameter_property AMS_I2C_AMM_ADDRESS ALLOWED_RANGES $map_range
	send_message info "AMS_I2C_AMM_ADDRESS = [get_parameter_value AMS_I2C_AMM_ADDRESS]"

}

# +-----------------------------------
# | Validation callback
# +-----------------------------------
proc validate {} {

}
