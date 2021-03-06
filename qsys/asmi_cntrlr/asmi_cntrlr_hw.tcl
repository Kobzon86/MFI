# TCL File Generated by Component Editor 18.1
# Fri Dec 17 09:53:59 MSK 2021
# DO NOT MODIFY


# 
# asmi_cntrlr "asmi_cntrlr" v1.0
#  2021.12.17.09:53:59
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module asmi_cntrlr
# 
set_module_property DESCRIPTION ""
set_module_property NAME asmi_cntrlr
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME asmi_cntrlr
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL asmi_cntrlr
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file asmi_cntrlr.sv SYSTEM_VERILOG PATH asmi_cntrlr.sv TOP_LEVEL_FILE


# 
# parameters
# 


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
# connection point completed
# 
add_interface completed conduit end
set_interface_property completed associatedClock ""
set_interface_property completed associatedReset ""
set_interface_property completed ENABLED true
set_interface_property completed EXPORT_OF ""
set_interface_property completed PORT_NAME_MAP ""
set_interface_property completed CMSIS_SVD_VARIABLES ""
set_interface_property completed SVD_ADDRESS_GROUP ""

add_interface_port completed CRC crc Output 32


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
# connection point asmi_avalon_master
# 
add_interface asmi_avalon_master avalon start
set_interface_property asmi_avalon_master addressUnits SYMBOLS
set_interface_property asmi_avalon_master associatedClock clock
set_interface_property asmi_avalon_master associatedReset reset
set_interface_property asmi_avalon_master bitsPerSymbol 8
set_interface_property asmi_avalon_master burstOnBurstBoundariesOnly false
set_interface_property asmi_avalon_master burstcountUnits WORDS
set_interface_property asmi_avalon_master doStreamReads false
set_interface_property asmi_avalon_master doStreamWrites false
set_interface_property asmi_avalon_master holdTime 0
set_interface_property asmi_avalon_master linewrapBursts false
set_interface_property asmi_avalon_master maximumPendingReadTransactions 0
set_interface_property asmi_avalon_master maximumPendingWriteTransactions 0
set_interface_property asmi_avalon_master readLatency 0
set_interface_property asmi_avalon_master readWaitTime 1
set_interface_property asmi_avalon_master setupTime 0
set_interface_property asmi_avalon_master timingUnits Cycles
set_interface_property asmi_avalon_master writeWaitTime 0
set_interface_property asmi_avalon_master ENABLED true
set_interface_property asmi_avalon_master EXPORT_OF ""
set_interface_property asmi_avalon_master PORT_NAME_MAP ""
set_interface_property asmi_avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property asmi_avalon_master SVD_ADDRESS_GROUP ""

add_interface_port asmi_avalon_master asmi_amm_address address Output 26
add_interface_port asmi_avalon_master asmi_amm_burstcount burstcount Output 7
add_interface_port asmi_avalon_master asmi_amm_read read Output 1
add_interface_port asmi_avalon_master asmi_amm_readdata readdata Input 32
add_interface_port asmi_avalon_master asmi_amm_readdatavalid readdatavalid Input 1
add_interface_port asmi_avalon_master asmi_amm_waitrequest waitrequest Input 1
add_interface_port asmi_avalon_master asmi_amm_write write Output 1
add_interface_port asmi_avalon_master asmi_amm_writedata writedata Output 32


# 
# connection point ru_avalon_master
# 
add_interface ru_avalon_master avalon start
set_interface_property ru_avalon_master addressUnits SYMBOLS
set_interface_property ru_avalon_master associatedClock clock
set_interface_property ru_avalon_master associatedReset reset
set_interface_property ru_avalon_master bitsPerSymbol 8
set_interface_property ru_avalon_master burstOnBurstBoundariesOnly false
set_interface_property ru_avalon_master burstcountUnits WORDS
set_interface_property ru_avalon_master doStreamReads false
set_interface_property ru_avalon_master doStreamWrites false
set_interface_property ru_avalon_master holdTime 0
set_interface_property ru_avalon_master linewrapBursts false
set_interface_property ru_avalon_master maximumPendingReadTransactions 0
set_interface_property ru_avalon_master maximumPendingWriteTransactions 0
set_interface_property ru_avalon_master readLatency 0
set_interface_property ru_avalon_master readWaitTime 1
set_interface_property ru_avalon_master setupTime 0
set_interface_property ru_avalon_master timingUnits Cycles
set_interface_property ru_avalon_master writeWaitTime 0
set_interface_property ru_avalon_master ENABLED true
set_interface_property ru_avalon_master EXPORT_OF ""
set_interface_property ru_avalon_master PORT_NAME_MAP ""
set_interface_property ru_avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property ru_avalon_master SVD_ADDRESS_GROUP ""

add_interface_port ru_avalon_master ru_amm_waitrequest waitrequest Input 1
add_interface_port ru_avalon_master ru_amm_write write Output 1
add_interface_port ru_avalon_master ru_amm_read read Output 1
add_interface_port ru_avalon_master ru_amm_readdata readdata Input 32
add_interface_port ru_avalon_master ru_amm_readdatavalid readdatavalid Input 1
add_interface_port ru_avalon_master ru_amm_address address Output 5
add_interface_port ru_avalon_master ru_amm_writedata writedata Output 32


# 
# connection point csr
# 
add_interface csr avalon end
set_interface_property csr addressUnits SYMBOLS
set_interface_property csr associatedClock clock
set_interface_property csr associatedReset reset
set_interface_property csr bitsPerSymbol 8
set_interface_property csr burstOnBurstBoundariesOnly false
set_interface_property csr burstcountUnits WORDS
set_interface_property csr explicitAddressSpan 0
set_interface_property csr holdTime 0
set_interface_property csr linewrapBursts false
set_interface_property csr maximumPendingReadTransactions 1
set_interface_property csr maximumPendingWriteTransactions 0
set_interface_property csr readLatency 0
set_interface_property csr readWaitTime 1
set_interface_property csr setupTime 0
set_interface_property csr timingUnits Cycles
set_interface_property csr writeWaitTime 0
set_interface_property csr ENABLED true
set_interface_property csr EXPORT_OF ""
set_interface_property csr PORT_NAME_MAP ""
set_interface_property csr CMSIS_SVD_VARIABLES ""
set_interface_property csr SVD_ADDRESS_GROUP ""

add_interface_port csr ams_read read Input 1
add_interface_port csr ams_readdata readdata Output 32
add_interface_port csr ams_readdatavalid readdatavalid Output 1
add_interface_port csr ams_address address Input 17
add_interface_port csr ams_waitrequest waitrequest Output 1
add_interface_port csr ams_write write Input 1
add_interface_port csr ams_writedata writedata Input 32
set_interface_assignment csr embeddedsw.configuration.isFlash 0
set_interface_assignment csr embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment csr embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment csr embeddedsw.configuration.isPrintableDevice 0

