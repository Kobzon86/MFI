# TCL File Generated by Component Editor 18.1
# Tue Aug 10 12:15:14 MSK 2021
# DO NOT MODIFY


# 
# RK_Transceiver "RK_Transceiver" v16.1
#  2021.08.10.12:15:14
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module RK_Transceiver
# 
set_module_property DESCRIPTION ""
set_module_property NAME RK_Transceiver
set_module_property VERSION 16.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME RK_Transceiver
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL RK_Transceiver
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file timer.vhd VHDL PATH ../src/MISC/timer.vhd
add_fileset_file rk_pkg.vhd VHDL PATH ../src/RK_Transceiver/rk_pkg.vhd
add_fileset_file RK_Transceiver.vhd VHDL PATH ../src/RK_Transceiver/RK_Transceiver.vhd TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point RK_IN
# 
add_interface RK_IN conduit end
set_interface_property RK_IN associatedClock ""
set_interface_property RK_IN associatedReset ""
set_interface_property RK_IN ENABLED true
set_interface_property RK_IN EXPORT_OF ""
set_interface_property RK_IN PORT_NAME_MAP ""
set_interface_property RK_IN CMSIS_SVD_VARIABLES ""
set_interface_property RK_IN SVD_ADDRESS_GROUP ""

add_interface_port RK_IN RK_Input rk_in Input 8


# 
# connection point RK_OUT
# 
add_interface RK_OUT conduit end
set_interface_property RK_OUT associatedClock ""
set_interface_property RK_OUT associatedReset ""
set_interface_property RK_OUT ENABLED true
set_interface_property RK_OUT EXPORT_OF ""
set_interface_property RK_OUT PORT_NAME_MAP ""
set_interface_property RK_OUT CMSIS_SVD_VARIABLES ""
set_interface_property RK_OUT SVD_ADDRESS_GROUP ""

add_interface_port RK_OUT RK_Output rk_out Output 4


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
# connection point interrupt
# 
add_interface interrupt interrupt end
set_interface_property interrupt associatedAddressablePoint ""
set_interface_property interrupt associatedReset Avalon_Reset
set_interface_property interrupt bridgedReceiverOffset ""
set_interface_property interrupt bridgesToReceiver ""
set_interface_property interrupt ENABLED true
set_interface_property interrupt EXPORT_OF ""
set_interface_property interrupt PORT_NAME_MAP ""
set_interface_property interrupt CMSIS_SVD_VARIABLES ""
set_interface_property interrupt SVD_ADDRESS_GROUP ""

add_interface_port interrupt Interrupt irq Output 1


# 
# connection point RK_OUT_fault
# 
add_interface RK_OUT_fault conduit end
set_interface_property RK_OUT_fault associatedClock ""
set_interface_property RK_OUT_fault associatedReset ""
set_interface_property RK_OUT_fault ENABLED true
set_interface_property RK_OUT_fault EXPORT_OF ""
set_interface_property RK_OUT_fault PORT_NAME_MAP ""
set_interface_property RK_OUT_fault CMSIS_SVD_VARIABLES ""
set_interface_property RK_OUT_fault SVD_ADDRESS_GROUP ""

add_interface_port RK_OUT_fault RK_Fault rk_fault Input 4


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
add_interface_port AVS_Config AVS_address address Input 3
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
# connection point RK_Test_out
# 
add_interface RK_Test_out conduit end
set_interface_property RK_Test_out associatedClock ""
set_interface_property RK_Test_out associatedReset ""
set_interface_property RK_Test_out ENABLED true
set_interface_property RK_Test_out EXPORT_OF ""
set_interface_property RK_Test_out PORT_NAME_MAP ""
set_interface_property RK_Test_out CMSIS_SVD_VARIABLES ""
set_interface_property RK_Test_out SVD_ADDRESS_GROUP ""

add_interface_port RK_Test_out RK_TEST rk_test Output 1


# 
# connection point RK_LVL_Sel
# 
add_interface RK_LVL_Sel conduit end
set_interface_property RK_LVL_Sel associatedClock ""
set_interface_property RK_LVL_Sel associatedReset ""
set_interface_property RK_LVL_Sel ENABLED true
set_interface_property RK_LVL_Sel EXPORT_OF ""
set_interface_property RK_LVL_Sel PORT_NAME_MAP ""
set_interface_property RK_LVL_Sel CMSIS_SVD_VARIABLES ""
set_interface_property RK_LVL_Sel SVD_ADDRESS_GROUP ""

add_interface_port RK_LVL_Sel RK_In_Set in_set Output 1
add_interface_port RK_LVL_Sel RK_Sense_Sel sense_sel Output 1
add_interface_port RK_LVL_Sel RK_Ths_Sel ths_sel Output 1
add_interface_port RK_LVL_Sel RK_VWet_Sel vwet_sel Output 1


# 
# connection point RK_bipolar_out
# 
add_interface RK_bipolar_out conduit end
set_interface_property RK_bipolar_out associatedClock ""
set_interface_property RK_bipolar_out associatedReset ""
set_interface_property RK_bipolar_out ENABLED true
set_interface_property RK_bipolar_out EXPORT_OF ""
set_interface_property RK_bipolar_out PORT_NAME_MAP ""
set_interface_property RK_bipolar_out CMSIS_SVD_VARIABLES ""
set_interface_property RK_bipolar_out SVD_ADDRESS_GROUP ""

add_interface_port RK_bipolar_out RK_0V_Output rk_0v_out Output 1
add_interface_port RK_bipolar_out RK_27V_0V_Fault rk_27v_0v_out_fault Input 1
add_interface_port RK_bipolar_out RK_27V_0V_Sel rk_27v_0v_sel Input 1
add_interface_port RK_bipolar_out RK_27V_Output rk_27v_out Output 1


# 
# connection point RK_ADDR
# 
add_interface RK_ADDR conduit end
set_interface_property RK_ADDR associatedClock ""
set_interface_property RK_ADDR associatedReset ""
set_interface_property RK_ADDR ENABLED true
set_interface_property RK_ADDR EXPORT_OF ""
set_interface_property RK_ADDR PORT_NAME_MAP ""
set_interface_property RK_ADDR CMSIS_SVD_VARIABLES ""
set_interface_property RK_ADDR SVD_ADDRESS_GROUP ""

add_interface_port RK_ADDR RK_Input_Addr rk_addr Input 5

