set_global_assignment -entity "LvdsOutputSdrPll" -library "lib_LvdsOutputSdrPll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "LvdsOutputSdrPll" -library "lib_LvdsOutputSdrPll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "LvdsOutputSdrPll" -library "lib_LvdsOutputSdrPll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_LvdsOutputSdrPll" -name SPD_FILE [file join $::quartus(sip_path) "LvdsOutputSdrPll.spd"]

set_global_assignment -library "lib_LvdsOutputSdrPll" -name MISC_FILE [file join $::quartus(sip_path) "LvdsOutputSdrPll_sim/LvdsOutputSdrPll.vo"]
