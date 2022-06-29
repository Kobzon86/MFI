set_global_assignment -entity "TmdsOutputSdrPll" -library "lib_TmdsOutputSdrPll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "TmdsOutputSdrPll" -library "lib_TmdsOutputSdrPll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "TmdsOutputSdrPll" -library "lib_TmdsOutputSdrPll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_TmdsOutputSdrPll" -name SPD_FILE [file join $::quartus(sip_path) "TmdsOutputSdrPll.spd"]

set_global_assignment -library "lib_TmdsOutputSdrPll" -name MISC_FILE [file join $::quartus(sip_path) "TmdsOutputSdrPll_sim/TmdsOutputSdrPll.vo"]
