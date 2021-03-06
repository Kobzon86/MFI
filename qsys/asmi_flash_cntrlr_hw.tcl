# TCL File Generated by Component Editor 18.1
# Thu Jan 20 14:05:07 MSK 2022
# DO NOT MODIFY


# 
# asmi_flash_cntrlr "asmi_flash_cntrlr" v1.0
#  2022.01.20.14:05:07
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module asmi_flash_cntrlr
# 
set_module_property DESCRIPTION ""
set_module_property NAME asmi_flash_cntrlr
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME asmi_flash_cntrlr
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL asmi_flash_cntrlr
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file asmi_flash_cntrlr.sv SYSTEM_VERILOG PATH asmi_cntrlr/asmi_flash_cntrlr.sv TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter ASMI_CSR STD_LOGIC_VECTOR 33554432
set_parameter_property ASMI_CSR DEFAULT_VALUE 33554432
set_parameter_property ASMI_CSR DISPLAY_NAME ASMI_CSR
set_parameter_property ASMI_CSR WIDTH 34
set_parameter_property ASMI_CSR TYPE STD_LOGIC_VECTOR
set_parameter_property ASMI_CSR UNITS None
set_parameter_property ASMI_CSR ALLOWED_RANGES 0:17179869183
set_parameter_property ASMI_CSR HDL_PARAMETER true


# 
# display items
# 


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point ams_mem
# 
add_interface ams_mem avalon end
set_interface_property ams_mem addressUnits SYMBOLS
set_interface_property ams_mem associatedClock clock
set_interface_property ams_mem associatedReset reset
set_interface_property ams_mem bitsPerSymbol 8
set_interface_property ams_mem burstOnBurstBoundariesOnly false
set_interface_property ams_mem burstcountUnits WORDS
set_interface_property ams_mem explicitAddressSpan 0
set_interface_property ams_mem holdTime 0
set_interface_property ams_mem linewrapBursts false
set_interface_property ams_mem maximumPendingReadTransactions 1
set_interface_property ams_mem maximumPendingWriteTransactions 0
set_interface_property ams_mem readLatency 0
set_interface_property ams_mem readWaitTime 1
set_interface_property ams_mem setupTime 0
set_interface_property ams_mem timingUnits Cycles
set_interface_property ams_mem writeWaitTime 0
set_interface_property ams_mem ENABLED true
set_interface_property ams_mem EXPORT_OF ""
set_interface_property ams_mem PORT_NAME_MAP ""
set_interface_property ams_mem CMSIS_SVD_VARIABLES ""
set_interface_property ams_mem SVD_ADDRESS_GROUP ""

add_interface_port ams_mem ams_mem_read read Input 1
add_interface_port ams_mem ams_mem_write write Input 1
add_interface_port ams_mem ams_mem_readdata readdata Output 32
add_interface_port ams_mem ams_mem_writedata writedata Input 32
add_interface_port ams_mem ams_mem_waitrequest waitrequest Output 1
add_interface_port ams_mem ams_mem_readdatavalid readdatavalid Output 1
add_interface_port ams_mem ams_mem_address address Input 17
add_interface_port ams_mem ams_mem_burstcount burstcount Input 7
set_interface_assignment ams_mem embeddedsw.configuration.isFlash 0
set_interface_assignment ams_mem embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment ams_mem embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment ams_mem embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clock clk Input 1


# 
# connection point amm_mem
# 
add_interface amm_mem avalon start
set_interface_property amm_mem addressUnits SYMBOLS
set_interface_property amm_mem associatedClock clock
set_interface_property amm_mem associatedReset reset
set_interface_property amm_mem bitsPerSymbol 8
set_interface_property amm_mem burstOnBurstBoundariesOnly false
set_interface_property amm_mem burstcountUnits WORDS
set_interface_property amm_mem doStreamReads false
set_interface_property amm_mem doStreamWrites false
set_interface_property amm_mem holdTime 0
set_interface_property amm_mem linewrapBursts false
set_interface_property amm_mem maximumPendingReadTransactions 0
set_interface_property amm_mem maximumPendingWriteTransactions 0
set_interface_property amm_mem readLatency 0
set_interface_property amm_mem readWaitTime 1
set_interface_property amm_mem setupTime 0
set_interface_property amm_mem timingUnits Cycles
set_interface_property amm_mem writeWaitTime 0
set_interface_property amm_mem ENABLED true
set_interface_property amm_mem EXPORT_OF ""
set_interface_property amm_mem PORT_NAME_MAP ""
set_interface_property amm_mem CMSIS_SVD_VARIABLES ""
set_interface_property amm_mem SVD_ADDRESS_GROUP ""

add_interface_port amm_mem asmi_amm_waitrequest waitrequest Input 1
add_interface_port amm_mem asmi_amm_write write Output 1
add_interface_port amm_mem asmi_amm_read read Output 1
add_interface_port amm_mem asmi_amm_readdata readdata Input 32
add_interface_port amm_mem asmi_amm_readdatavalid readdatavalid Input 1
add_interface_port amm_mem asmi_amm_address address Output 26
add_interface_port amm_mem asmi_amm_burstcount burstcount Output 7
add_interface_port amm_mem asmi_amm_writedata writedata Output 32

