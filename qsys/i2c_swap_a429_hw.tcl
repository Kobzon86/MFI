# TCL File Generated by Component Editor 16.1
# Thu Nov 07 14:05:44 MSK 2019
# DO NOT MODIFY


# 
# i2c_swap_a429 "i2c_swap_a429" v16.1
#  2019.11.07.14:05:44
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module i2c_swap_a429
# 
set_module_property DESCRIPTION ""
set_module_property NAME i2c_swap_a429
set_module_property VERSION 16.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME i2c_swap_a429
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL i2c_swap_a429
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file i2c_swap_a429.vhd VHDL PATH ../src/i2c_swap_a429/i2c_swap_a429.vhd TOP_LEVEL_FILE
add_fileset_file i2c_swap_a429_pkg.vhd VHDL PATH ../src/i2c_swap_a429/i2c_swap_a429_pkg.vhd
add_fileset_file swap_control.vhd VHDL PATH ../src/i2c_swap_a429/swap_control.vhd


# 
# parameters
# 


# 
# display items
# 


# 
# connection point AV2RAM
# 
add_interface AV2RAM avalon start
set_interface_property AV2RAM addressUnits WORDS
set_interface_property AV2RAM associatedClock Avalon_Clk
set_interface_property AV2RAM associatedReset Avalon_nReset
set_interface_property AV2RAM bitsPerSymbol 8
set_interface_property AV2RAM burstOnBurstBoundariesOnly false
set_interface_property AV2RAM burstcountUnits WORDS
set_interface_property AV2RAM doStreamReads false
set_interface_property AV2RAM doStreamWrites false
set_interface_property AV2RAM holdTime 0
set_interface_property AV2RAM linewrapBursts false
set_interface_property AV2RAM maximumPendingReadTransactions 1
set_interface_property AV2RAM maximumPendingWriteTransactions 0
set_interface_property AV2RAM readLatency 0
set_interface_property AV2RAM readWaitTime 1
set_interface_property AV2RAM setupTime 0
set_interface_property AV2RAM timingUnits Cycles
set_interface_property AV2RAM writeWaitTime 0
set_interface_property AV2RAM ENABLED true
set_interface_property AV2RAM EXPORT_OF ""
set_interface_property AV2RAM PORT_NAME_MAP ""
set_interface_property AV2RAM CMSIS_SVD_VARIABLES ""
set_interface_property AV2RAM SVD_ADDRESS_GROUP ""

add_interface_port AV2RAM AV2RAM_address address Output 20
add_interface_port AV2RAM AV2RAM_byteenable byteenable Output 4
add_interface_port AV2RAM AV2RAM_read read Output 1
add_interface_port AV2RAM AV2RAM_readdata readdata Input 32
add_interface_port AV2RAM AV2RAM_readdatavalid readdatavalid Input 1
add_interface_port AV2RAM AV2RAM_waitrequest waitrequest Input 1
add_interface_port AV2RAM AV2RAM_write write Output 1
add_interface_port AV2RAM AV2RAM_writedata writedata Output 32


# 
# connection point Avalon_Clk
# 
add_interface Avalon_Clk clock end
set_interface_property Avalon_Clk clockRate 0
set_interface_property Avalon_Clk ENABLED true
set_interface_property Avalon_Clk EXPORT_OF ""
set_interface_property Avalon_Clk PORT_NAME_MAP ""
set_interface_property Avalon_Clk CMSIS_SVD_VARIABLES ""
set_interface_property Avalon_Clk SVD_ADDRESS_GROUP ""

add_interface_port Avalon_Clk Avalon_Clock clk Input 1


# 
# connection point Avalon_nReset
# 
add_interface Avalon_nReset reset end
set_interface_property Avalon_nReset associatedClock Avalon_Clk
set_interface_property Avalon_nReset synchronousEdges DEASSERT
set_interface_property Avalon_nReset ENABLED true
set_interface_property Avalon_nReset EXPORT_OF ""
set_interface_property Avalon_nReset PORT_NAME_MAP ""
set_interface_property Avalon_nReset CMSIS_SVD_VARIABLES ""
set_interface_property Avalon_nReset SVD_ADDRESS_GROUP ""

add_interface_port Avalon_nReset Avalon_nReset reset_n Input 1


# 
# connection point AVS_Config
# 
add_interface AVS_Config avalon end
set_interface_property AVS_Config addressUnits SYMBOLS
set_interface_property AVS_Config associatedClock Avalon_Clk
set_interface_property AVS_Config associatedReset Avalon_nReset
set_interface_property AVS_Config bitsPerSymbol 8
set_interface_property AVS_Config burstOnBurstBoundariesOnly false
set_interface_property AVS_Config burstcountUnits WORDS
set_interface_property AVS_Config explicitAddressSpan 0
set_interface_property AVS_Config holdTime 0
set_interface_property AVS_Config linewrapBursts false
set_interface_property AVS_Config maximumPendingReadTransactions 1
set_interface_property AVS_Config maximumPendingWriteTransactions 0
set_interface_property AVS_Config readLatency 0
set_interface_property AVS_Config readWaitTime 1
set_interface_property AVS_Config setupTime 0
set_interface_property AVS_Config timingUnits Cycles
set_interface_property AVS_Config writeWaitTime 0
set_interface_property AVS_Config ENABLED true
set_interface_property AVS_Config EXPORT_OF ""
set_interface_property AVS_Config PORT_NAME_MAP ""
set_interface_property AVS_Config CMSIS_SVD_VARIABLES ""
set_interface_property AVS_Config SVD_ADDRESS_GROUP ""

add_interface_port AVS_Config AVS_waitrequest waitrequest Output 1
add_interface_port AVS_Config AVS_address address Input 4
add_interface_port AVS_Config AVS_byteenable byteenable Input 4
add_interface_port AVS_Config AVS_read read Input 1
add_interface_port AVS_Config AVS_readdata readdata Output 32
add_interface_port AVS_Config AVS_readdatavalid readdatavalid Output 1
add_interface_port AVS_Config AVS_write write Input 1
add_interface_port AVS_Config AVS_writedata writedata Input 32
set_interface_assignment AVS_Config embeddedsw.configuration.isFlash 0
set_interface_assignment AVS_Config embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment AVS_Config embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment AVS_Config embeddedsw.configuration.isPrintableDevice 0


# 
# connection point A429_TxEnabled
# 
add_interface A429_TxEnabled conduit end
set_interface_property A429_TxEnabled associatedClock Avalon_Clk
set_interface_property A429_TxEnabled associatedReset Avalon_nReset
set_interface_property A429_TxEnabled ENABLED true
set_interface_property A429_TxEnabled EXPORT_OF ""
set_interface_property A429_TxEnabled PORT_NAME_MAP ""
set_interface_property A429_TxEnabled CMSIS_SVD_VARIABLES ""
set_interface_property A429_TxEnabled SVD_ADDRESS_GROUP ""

add_interface_port A429_TxEnabled A429_TxEnabled en Input 1

