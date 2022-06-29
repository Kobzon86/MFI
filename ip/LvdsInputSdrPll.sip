set_global_assignment -entity "LvdsInputSdrPll" -library "lib_LvdsInputSdrPll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "LvdsInputSdrPll" -library "lib_LvdsInputSdrPll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "LvdsInputSdrPll" -library "lib_LvdsInputSdrPll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_LvdsInputSdrPll" -name SPD_FILE [file join $::quartus(sip_path) "LvdsInputSdrPll.spd"]

set_global_assignment -library "lib_LvdsInputSdrPll" -name MISC_FILE [file join $::quartus(sip_path) "LvdsInputSdrPll_sim/LvdsInputSdrPll.vo"]
