# TCL File Generated by Component Editor 18.1
# Tue Apr 21 14:19:36 MSK 2020
# DO NOT MODIFY


# 
# A429_Transmitter "A429_Transmitter" v16.1
#  2020.04.21.14:19:36
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module A429_Transmitter
# 
set_module_property DESCRIPTION ""
set_module_property NAME A429_Transmitter
set_module_property VERSION 16.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME A429_Transmitter
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL A429_Transmitter
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file FIFO.vhd VHDL PATH ../src/MISC/FIFO.vhd
add_fileset_file timer.vhd VHDL PATH ../src/MISC/timer.vhd
add_fileset_file AVMM_Master.vhd VHDL PATH ../src/MISC/AVMM_Master.vhd
add_fileset_file AvMM2Mux1.vhd VHDL PATH ../src/MISC/AvMM2Mux1.vhd
add_fileset_file arinc429tx_pkg.vhd VHDL PATH ../src/A429_Transmitter/arinc429tx_pkg.vhd
add_fileset_file a429_TxControl.vhd VHDL PATH ../src/A429_Transmitter/a429_TxControl.vhd
add_fileset_file a429_txphy.vhd VHDL PATH ../src/A429_Transmitter/a429_txphy.vhd
add_fileset_file a429_RxPhy.vhd VHDL PATH ../src/A429_Receiver/a429_RxPhy.vhd
add_fileset_file A429_Transmitter.vhd VHDL PATH ../src/A429_Transmitter/A429_Transmitter.vhd TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point A429_Clk
# 
add_interface A429_Clk clock end
set_interface_property A429_Clk clockRate 0
set_interface_property A429_Clk ENABLED true
set_interface_property A429_Clk EXPORT_OF ""
set_interface_property A429_Clk PORT_NAME_MAP ""
set_interface_property A429_Clk CMSIS_SVD_VARIABLES ""
set_interface_property A429_Clk SVD_ADDRESS_GROUP ""

add_interface_port A429_Clk A429_Clock clk Input 1


# 
# connection point AV2RAM
# 
add_interface AV2RAM avalon start
set_interface_property AV2RAM addressUnits WORDS
set_interface_property AV2RAM associatedClock Avalon_Clk
set_interface_property AV2RAM associatedReset Avalon_Reset
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

add_interface_port AV2RAM AV2RAM_address address Output 11
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
# connection point Avalon_Reset
# 
add_interface Avalon_Reset reset end
set_interface_property Avalon_Reset associatedClock Avalon_Clk
set_interface_property Avalon_Reset synchronousEdges DEASSERT
set_interface_property Avalon_Reset ENABLED true
set_interface_property Avalon_Reset EXPORT_OF ""
set_interface_property Avalon_Reset PORT_NAME_MAP ""
set_interface_property Avalon_Reset CMSIS_SVD_VARIABLES ""
set_interface_property Avalon_Reset SVD_ADDRESS_GROUP ""

add_interface_port Avalon_Reset Avalon_nReset reset_n Input 1


# 
# connection point Interrupt
# 
add_interface Interrupt interrupt end
set_interface_property Interrupt associatedAddressablePoint ""
set_interface_property Interrupt associatedClock Avalon_Clk
set_interface_property Interrupt associatedReset Avalon_Reset
set_interface_property Interrupt bridgedReceiverOffset ""
set_interface_property Interrupt bridgesToReceiver ""
set_interface_property Interrupt ENABLED true
set_interface_property Interrupt EXPORT_OF ""
set_interface_property Interrupt PORT_NAME_MAP ""
set_interface_property Interrupt CMSIS_SVD_VARIABLES ""
set_interface_property Interrupt SVD_ADDRESS_GROUP ""

add_interface_port Interrupt Interrupt irq Output 1


# 
# connection point AVS_Config
# 
add_interface AVS_Config avalon end
set_interface_property AVS_Config addressUnits WORDS
set_interface_property AVS_Config associatedClock Avalon_Clk
set_interface_property AVS_Config associatedReset Avalon_Reset
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
# connection point AV2PCIE
# 
add_interface AV2PCIE avalon end
set_interface_property AV2PCIE addressUnits WORDS
set_interface_property AV2PCIE associatedClock Avalon_Clk
set_interface_property AV2PCIE associatedReset Avalon_Reset
set_interface_property AV2PCIE bitsPerSymbol 8
set_interface_property AV2PCIE burstOnBurstBoundariesOnly false
set_interface_property AV2PCIE burstcountUnits WORDS
set_interface_property AV2PCIE explicitAddressSpan 0
set_interface_property AV2PCIE holdTime 0
set_interface_property AV2PCIE linewrapBursts false
set_interface_property AV2PCIE maximumPendingReadTransactions 1
set_interface_property AV2PCIE maximumPendingWriteTransactions 0
set_interface_property AV2PCIE readLatency 0
set_interface_property AV2PCIE readWaitTime 1
set_interface_property AV2PCIE setupTime 0
set_interface_property AV2PCIE timingUnits Cycles
set_interface_property AV2PCIE writeWaitTime 0
set_interface_property AV2PCIE ENABLED true
set_interface_property AV2PCIE EXPORT_OF ""
set_interface_property AV2PCIE PORT_NAME_MAP ""
set_interface_property AV2PCIE CMSIS_SVD_VARIABLES ""
set_interface_property AV2PCIE SVD_ADDRESS_GROUP ""

add_interface_port AV2PCIE AV2PCIE_waitrequest waitrequest Output 1
add_interface_port AV2PCIE AV2PCIE_address address Input 11
add_interface_port AV2PCIE AV2PCIE_byteenable byteenable Input 4
add_interface_port AV2PCIE AV2PCIE_read read Input 1
add_interface_port AV2PCIE AV2PCIE_readdata readdata Output 32
add_interface_port AV2PCIE AV2PCIE_readdatavalid readdatavalid Output 1
add_interface_port AV2PCIE AV2PCIE_write write Input 1
add_interface_port AV2PCIE AV2PCIE_writedata writedata Input 32
set_interface_assignment AV2PCIE embeddedsw.configuration.isFlash 0
set_interface_assignment AV2PCIE embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment AV2PCIE embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment AV2PCIE embeddedsw.configuration.isPrintableDevice 0


# 
# connection point AV2RAM2
# 
add_interface AV2RAM2 avalon start
set_interface_property AV2RAM2 addressUnits WORDS
set_interface_property AV2RAM2 associatedClock Avalon_Clk
set_interface_property AV2RAM2 associatedReset Avalon_Reset
set_interface_property AV2RAM2 bitsPerSymbol 8
set_interface_property AV2RAM2 burstOnBurstBoundariesOnly false
set_interface_property AV2RAM2 burstcountUnits WORDS
set_interface_property AV2RAM2 doStreamReads false
set_interface_property AV2RAM2 doStreamWrites false
set_interface_property AV2RAM2 holdTime 0
set_interface_property AV2RAM2 linewrapBursts false
set_interface_property AV2RAM2 maximumPendingReadTransactions 1
set_interface_property AV2RAM2 maximumPendingWriteTransactions 0
set_interface_property AV2RAM2 readLatency 0
set_interface_property AV2RAM2 readWaitTime 1
set_interface_property AV2RAM2 setupTime 0
set_interface_property AV2RAM2 timingUnits Cycles
set_interface_property AV2RAM2 writeWaitTime 0
set_interface_property AV2RAM2 ENABLED true
set_interface_property AV2RAM2 EXPORT_OF ""
set_interface_property AV2RAM2 PORT_NAME_MAP ""
set_interface_property AV2RAM2 CMSIS_SVD_VARIABLES ""
set_interface_property AV2RAM2 SVD_ADDRESS_GROUP ""

add_interface_port AV2RAM2 AV2RAM2_waitrequest waitrequest Input 1
add_interface_port AV2RAM2 AV2RAM2_address address Output 11
add_interface_port AV2RAM2 AV2RAM2_byteenable byteenable Output 4
add_interface_port AV2RAM2 AV2RAM2_read read Output 1
add_interface_port AV2RAM2 AV2RAM2_readdata readdata Input 32
add_interface_port AV2RAM2 AV2RAM2_readdatavalid readdatavalid Input 1
add_interface_port AV2RAM2 AV2RAM2_write write Output 1
add_interface_port AV2RAM2 AV2RAM2_writedata writedata Output 32


# 
# connection point arinc429
# 
add_interface arinc429 conduit end
set_interface_property arinc429 associatedClock A429_Clk
set_interface_property arinc429 associatedReset ""
set_interface_property arinc429 ENABLED true
set_interface_property arinc429 EXPORT_OF ""
set_interface_property arinc429 PORT_NAME_MAP ""
set_interface_property arinc429 CMSIS_SVD_VARIABLES ""
set_interface_property arinc429 SVD_ADDRESS_GROUP ""

add_interface_port arinc429 A429_LineA a429_tx_p Output 1
add_interface_port arinc429 A429_LineB a429_tx_n Output 1
add_interface_port arinc429 A429_Slp a429_slp Output 1
add_interface_port arinc429 A429_CtrlA a429_ctrl_p Input 1
add_interface_port arinc429 A429_CtrlB a429_ctrl_n Input 1


# 
# connection point misc
# 
add_interface misc conduit end
set_interface_property misc associatedClock A429_Clk
set_interface_property misc associatedReset ""
set_interface_property misc ENABLED true
set_interface_property misc EXPORT_OF ""
set_interface_property misc PORT_NAME_MAP ""
set_interface_property misc CMSIS_SVD_VARIABLES ""
set_interface_property misc SVD_ADDRESS_GROUP ""

add_interface_port misc RxLineBusy linebusy Input 1
add_interface_port misc TxFlag tx_flag Output 1
add_interface_port misc RxTestEn rx_test_en Input 1
add_interface_port misc TxReg txword Output 32

