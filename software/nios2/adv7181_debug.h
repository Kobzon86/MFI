// #define EN_INCTRL
// #define EN_VIDEO_SELECTION
// #define EN_OUTPUT_CONTROL
// #define EN_EX_OUTPUT_CONTROL
#define EN_VIDEO_STANDART
//#define EN_POWER_MENEGEMENT
#define EN_ADC_CONTROL
#define EN_BIAS_CTRL
#define EN_TTLC_CTRL
#define EN_MANUAL_WINDOW
#define EN_LOCK_CNT
#define EN_CONFIGURE1
#define EN_TLLC_PA
#define EN_CP_OUT_SEL
#define EN_CP_MEASURE_CTRL
#define EN_CP_DETECTION_CTRL
#define EN_CP_MISC_CONTROL
#define EN_CP_TLLC_CONTROL
#define EN_CP_DEF_COLOR
#define EN_ADC_SWITCH
#define EN_DDR_MODE
#define EN_FIELD_LENGTH
#define EN_STATUS
#define EN_LETTER_BOX
#define EN_RB

#include "sys/alt_log_printf.h"

#ifdef EN_INCTRL
void INCTRL_DECODE(alt_u8 Input_Control){

  const char* INSEL;
  const char *VIDSEL;

  switch (Input_Control & 0xf) {
    case 0:  INSEL = "CVBS in on AIN2";                    break;
    case 1:  INSEL = "CVBS in on AIN3";                    break;
    case 2:  INSEL = "CVBS in on AIN5";                    break;
    case 3:  INSEL = "CVBS in on AIN6";                    break;
    case 4:  INSEL = "CVBS in on AIN8";                    break;
    case 5:  INSEL = "CVBS in on AIN10";                   break;
    case 6:  INSEL = "Y on AIN2, C on AIN6";               break;
    case 7:  INSEL = "Y on AIN3, C on AIN8";               break;
    case 8:  INSEL = "Y on AIN5, C on AIN10";              break;
    case 9:  INSEL = "Y on AIN2, Pr on AIN6, Pb on AIN8";  break;
    case 10: INSEL = "Y on AIN3, Pr on AIN5, Pb on AIN10"; break;
    case 11: INSEL = "CVBS in on AIN1";                    break;
    case 13: INSEL = "CVBS in on AIN4";                    break;
    case 15: INSEL = "CVBS in on AIN7";                    break;
    default: INSEL = "Reserved";                           break;
  }

  switch ((Input_Control >> 4) & 0xf) {
    case 0:  VIDSEL = "Auto detect PAL (BGHID), NTSC(without pedestal)";  break;
    case 1:  VIDSEL = "Auto detect PAL (BGHID), NTSC(M) (with pedestal)"; break;
    case 2:  VIDSEL = "Auto detect PAL (N), NTSC (M)(without pedestal)";  break;
    case 3:  VIDSEL = "Auto detect PAL (N), NTSC (M)(with pedestal)";     break;
    case 4:  VIDSEL = "NTSC (J)";                                         break;
    case 5:  VIDSEL = "NTSC (M)";                                         break;
    case 6:  VIDSEL = "PAL 60";                                           break;
    case 7:  VIDSEL = "NTSC 4.43";                                        break;
    case 8:  VIDSEL = "PAL BGHID";                                        break;
    case 9:  VIDSEL = "PAL N (BGHID without pedestal)";                   break;
    case 10: VIDSEL = "PAL M (without pedestal)";                         break;
    case 11: VIDSEL = "PAL M";                                            break;
    case 12: VIDSEL = "PAL combination N";                                break;
    case 13: VIDSEL = "PAL combination N (with Pedestal)";                break;
    case 14: VIDSEL = "SECAM";                                            break;
    case 15: VIDSEL = "SECAM (with pedestal)";                            break;
    default: VIDSEL = "Reserved";                                         break;
  }

  ALT_LOG_PRINTF("\tINSEL:\t%s\n",  INSEL);
  ALT_LOG_PRINTF("\tVIDSEL:\t%s\n", VIDSEL);
}
#endif

#ifdef EN_VIDEO_SELECTION
void VIDEO_SELECTION_DECODE(alt_u8 Video_Selection){
  const char *ENVSPROC = ((Video_Selection >> 3) & 0x1) ? "Enable VSync Processor" : "Disable VSync Processor";
  const char *BETACAM = ((Video_Selection >> 5) & 0x1) ? "Betacam input enable" : "Standard video input";
  const char *ENHSPLL = ((Video_Selection >> 6) & 0x1) ? "Enable HSync PLL" : "Disable HSync PLL";
  ALT_LOG_PRINTF("\tENVSPROC:\t%s\n", ENVSPROC);
  ALT_LOG_PRINTF("\tBETACAM:\t%s\n",  BETACAM);
  ALT_LOG_PRINTF("\tENHSPLL:\t%s\n",  ENHSPLL);
}
#endif

#ifdef EN_OUTPUT_CONTROL
void OUTPUT_CONTROL_DECODE(alt_u8 Output_Control){
  const char* SD_DUP_AV = ((Output_Control     ) & 0x1) ? "AV codes duplicated (for 16-bit interfaces)" : "AV codes to suit 8-bit interleaved data output";
  const char* OF_SEL    ;
  const char* TOD       = ((Output_Control >> 6) & 0x1) ? "Drivers tri-stated." : "Output pins enabled";
  const char* VBI_EN    = ((Output_Control >> 7) & 0x1) ? "Only active video region filtered" : "All lines filtered and scaled";

  switch ((Output_Control >> 2) & 0xF) {
    case 0: OF_SEL = "10-bit @ LLC1 4:2:2 ITU-R BT.656"; break;
    case 1: OF_SEL = "20-bit @ LLC2 4:2:2";              break;
    case 2: OF_SEL = "16-bit @ LLC2 4:2:2";              break;
    case 3: OF_SEL = "8-bit@LLC1 4:2:2 ITU-R BT.656";    break;
    default: OF_SEL = "Not Used";                        break;
  }

  ALT_LOG_PRINTF("\tSD_DUP_AV:\t%s\n", SD_DUP_AV);
  ALT_LOG_PRINTF("\tOF_SEL   :\t%s\n", OF_SEL   );
  ALT_LOG_PRINTF("\tTOD      :\t%s\n", TOD      );
  ALT_LOG_PRINTF("\tVBI_EN   :\t%s\n", VBI_EN   );
}
#endif

#ifdef EN_EX_OUTPUT_CONTROL
void EX_OUTPUT_CONTROL_DECODE(alt_u8 ex_out_ctrl){
  const char* RANGE      = ((ex_out_ctrl     ) & 0x1) ? "1<Y<254,1<C<254" : "16<Y<235,16<C<240";
  const char* EN_SFL_PIN = ((ex_out_ctrl >> 1) & 0x1) ? "SFL information output on Encoder & Decoder the SFL pin" : "SFL output is disabled";
  const char* BL_C_VBI   = ((ex_out_ctrl >> 2) & 0x1) ? "Blank Cr and Cb" : "Decode and Output colour";
  const char* TIM_OE     = ((ex_out_ctrl >> 3) & 0x1) ? "HS,VS,F forced active" : "HS,VS,F tri-stated ";
  const char* BT656_4    = ((ex_out_ctrl >> 7) & 0x1) ? "BT656-4 compatible" : "BT656-3 compatible";

  ALT_LOG_PRINTF("\tRANGE     :\t%s\n", RANGE     );
  ALT_LOG_PRINTF("\tEN_SFL_PIN:\t%s\n", EN_SFL_PIN);
  ALT_LOG_PRINTF("\tBL_C_VBI  :\t%s\n", BL_C_VBI  );
  ALT_LOG_PRINTF("\tTIM_OE    :\t%s\n", TIM_OE    );
  ALT_LOG_PRINTF("\tBT656_4   :\t%s\n", BT656_4   );
}
#endif

#ifdef EN_VIDEO_STANDART
void VIDEO_STANDART_DECODE(alt_u8 prim, alt_u8 vid){
  const char* PRIM_MODE = "Error";
  const char* VID_STD = "Error";
  if ((prim & 0xf) == 0){
    PRIM_MODE = "Standard Definition";
    switch(vid & 0xf){
      case 2:  VID_STD = "SD 4X1 (54MHz sampling)";break;
      case 10: VID_STD = "525i 4X1 (720x480)";break;
      case 11: VID_STD = "625i 4X1 (720x576)";break;
      case 14: VID_STD = "525i 2X1 (720x480)";break;
      case 15: VID_STD = "625i 2X1 (720x576)";break;
      default: VID_STD = "Reserved";break;
    }
  }
  else if ((prim & 0xf) == 1){
    PRIM_MODE = "Component Video(YPbPr/RGB)";
    switch(vid & 0xf){
      case 0:  VID_STD = "525i 2X2 (1440x480)";break;
      case 1:  VID_STD = "625i 2X2 (1440x576)";break;
      case 2:  VID_STD = "525i 4X2 (1440x480)";break;
      case 3:  VID_STD = "625i 4X2 (1440x576)";break;
      case 6:  VID_STD = "525P 2X1 (720x480)";break;
      case 7:  VID_STD = "625P 2X1 (720x576)";break;
      case 8:  VID_STD = "525P 2X2 (1440x480)";break;
      case 9:  VID_STD = "625P 2X2 (1440x576)";break;
      case 10: VID_STD = "HD 720P 1X1 (1280x720)";break;
      case 12: VID_STD = "HD 1125 1X1 (1920x1080)";break;
      case 13: VID_STD = "HD 1125 1X1 (1920x1035)";break;
      case 14: VID_STD = "HD 1250 1X1 (1920x1080)";break;
      case 15: VID_STD = "HD 1250 1X1 (1920x1152)";break;
      default: VID_STD = "Reserved";break;
    }
  }
  else if ((prim & 0xf) == 2){
    PRIM_MODE = "RGB Graphics mode";
    switch(vid & 0xf){
      case 0:  VID_STD = "SVGA (800x600@56)";break;
      case 1:  VID_STD = "SVGA (800x600@60)";break;
      case 2:  VID_STD = "SVGA (800x600@72)";break;
      case 3:  VID_STD = "SVGA (800x600@75)";break;
      case 4:  VID_STD = "SVGA (800x600@85)";break;
      case 8:  VID_STD = "VGA (640x480@60)";break;
      case 9:  VID_STD = "VGA (640x480@72)";break;
      case 10: VID_STD = "VGA (640x480@75)";break;
      case 11: VID_STD = "VGA (640x480@85)";break;
      case 12: VID_STD = "XVGA (1024x768@60)";break;
      case 13: VID_STD = "XVGA (1024x768@70)";break;
      default: VID_STD = "Reserved";break;
    }
  } else {
    PRIM_MODE = "Error2";
    VID_STD = "Error2";
  }

  ALT_LOG_PRINTF("\tPRIM_MODE:\t%s\n", PRIM_MODE);
  ALT_LOG_PRINTF("\tVID_STD:\t%s\n",   VID_STD  );
}
#endif

#ifdef EN_POWER_MENEGEMENT
void POWER_MENEGEMENT_DECODE(alt_u8 Power_Mgr){
  const char* FB_PWRDN = ((Power_Mgr >> 1) & 0x1) ? "FB input in power save mode" : "FB input operational";
  const char* PWRDN_0  = ((Power_Mgr >> 2) & 0x1) ? "Powered Down (in conjunction with PWRDN[1])" : "System functional";
  const char* CP_PWRDN = ((Power_Mgr >> 3) & 0x1) ? "CP in Power save mode" : "CP Operational";
  const char* PWRSAV   = ((Power_Mgr >> 4) & 0x1) ? "Enable PWRSAV mode" : "System functional ";
  const char* PWRDN_1  = ((Power_Mgr >> 5) & 0x1) ? "Powered Down (in conjunction with PWRDN[0])" : "System functional";
  const char* RESET    = ((Power_Mgr >> 7) & 0x1) ? "Start reset sequence" : "Normal operation";
  ALT_LOG_PRINTF("\tFB_PWRDN:\t%s\n", FB_PWRDN);
  ALT_LOG_PRINTF("\tPWRDN_0 :\t%s\n", PWRDN_0 );
  ALT_LOG_PRINTF("\tCP_PWRDN:\t%s\n", CP_PWRDN);
  ALT_LOG_PRINTF("\tPWRSAV  :\t%s\n", PWRSAV  );
  ALT_LOG_PRINTF("\tPWRDN_1 :\t%s\n", PWRDN_1 );
  ALT_LOG_PRINTF("\tRESET   :\t%s\n", RESET   );
}
#endif

#ifdef EN_ADC_CONTROL
void ADC_CONTROL_DECODE(alt_u8 ADC_ctrl){
  ALT_LOG_PRINTF("\t|3|2|1|0|  Range|\n\t=================\n");
  ALT_LOG_PRINTF("\t|%c|%c|%c|%c|%s|\n", ((ADC_ctrl >> 0) & 0x1) ? '+' : '-',
                                         ((ADC_ctrl >> 1) & 0x1) ? '+' : '-',
                                         ((ADC_ctrl >> 2) & 0x1) ? '+' : '-',
                                         ((ADC_ctrl >> 3) & 0x1) ? '+' : '-',
                                         ((ADC_ctrl >> 4) == 0x01) ? "13.5-55" : ((ADC_ctrl >> 4) == 0x02) ? " 55-111" : "Reserv");
}
#endif

#ifdef EN_BIAS_CTRL
void BIAS_CTRL_DECODE(alt_u8 BIAS_CTRL){
  const char* EN_INTERNAL_RES = ((BIAS_CTRL >> 0) & 0x1 ) ? "Internal resistor" : "External resistor";
  alt_u8  IBIAS_SET       = (BIAS_CTRL >> 3) & 0x1F;
  ALT_LOG_PRINTF("\tEN_INTERNAL_RES:\t%s\n", EN_INTERNAL_RES);
  ALT_LOG_PRINTF("\tIBIAS_SET      :\t%d(~%d uA)\n", IBIAS_SET, (alt_u32)IBIAS_SET*375/10 );
}
#endif

#ifdef EN_TTLC_CTRL
void TTLC_CTRL_DECODE(alt_u8 TLLC_CTRL){
  const char* PLL_QPUMP;
  switch(TLLC_CTRL & 0x7){
    case 0: PLL_QPUMP = "50uA";break;
    case 1: PLL_QPUMP = "100uA";break;
    case 2: PLL_QPUMP = "150uA";break;
    case 3: PLL_QPUMP = "250uA";break;
    case 4: PLL_QPUMP = "350uA";break;
    case 5: PLL_QPUMP = "500uA";break;
    case 6: PLL_QPUMP = "750uA";break;
    case 7: PLL_QPUMP = "1500uA";break;
    default: PLL_QPUMP = "Undefined";break;
  }
  ALT_LOG_PRINTF("\tPLL_QPUMP     :\t%s\n", PLL_QPUMP);
  ALT_LOG_PRINTF("\tSOG_SYNC_LEVEL:\t%d(%d uA)\n", (TLLC_CTRL >> 3), ((TLLC_CTRL >> 3) * 300 ) >> 5 );
}
#endif

#ifdef EN_MANUAL_WINDOW
void MANUAL_WINDOW_DECODE(alt_u8 MNL_WDW){
  const char* CKILLTHR;
  switch((MNL_WDW >> 4 ) & 0x7){
    case 0: CKILLTHR = ".5%"; break;
    case 1: CKILLTHR = "1.5%";break;
    case 2: CKILLTHR = "2.5%";break;
    case 3: CKILLTHR = "4%";  break;
    case 4: CKILLTHR = "8.5%";break;
    case 5: CKILLTHR = "16%"; break;
    case 6: CKILLTHR = "32%"; break;
    default: CKILLTHR = "Reserved";break;
  }
  ALT_LOG_PRINTF("\tCKILLTHR:\tkill at %s\n", CKILLTHR);
}
#endif

#ifdef EN_LOCK_CNT
void LOCK_CNT_DECODE(alt_u8 LOCK_CNT){
  const char* CIL;
  const char* COL;
  const char* SRLS  = ((LOCK_CNT >> 6) & 0x1) ? "Line to Line evaluation" : "Over field with verticle info";
  const char* FSCLE = ((LOCK_CNT >> 7) & 0x1) ? "Lock Status set by horizontal" : "Lock Status set only by horizontal lock";
  switch((LOCK_CNT >> 3 ) & 0x7){
    case 0: CIL = "1";     break;
    case 1: CIL = "2";     break;
    case 2: CIL = "5";     break;
    case 3: CIL = "10";    break;
    case 4: CIL = "100";   break;
    case 5: CIL = "500";   break;
    case 6: CIL = "1000";  break;
    case 7: CIL = "100000";break;
    default: CIL = "Undefined";break;
  }
  switch((LOCK_CNT >> 0 ) & 0x7){
    case 0: COL = "1";     break;
    case 1: COL = "2";     break;
    case 2: COL = "5";     break;
    case 3: COL = "10";    break;
    case 4: COL = "100";   break;
    case 5: COL = "500";   break;
    case 6: COL = "1000";  break;
    case 7: COL = "100000";break;
    default: COL = "Undefined";break;
  }
  ALT_LOG_PRINTF("\tCIL[2:0]:\t%s Line of Video\n", CIL);
  ALT_LOG_PRINTF("\tCOL[2:0]:\t%s Lines of Video\n", COL);
  ALT_LOG_PRINTF("\tSRLS    :\t%s\n", SRLS);
  ALT_LOG_PRINTF("\tFSCLE   :\t%s\n", FSCLE);
}
#endif

#ifdef EN_CONFIGURE1
void CONFIGURE1_DECODE(alt_u8 CFG1){
  const char* SDM_SEL     = ((CFG1 & 0x3) == 0) ? "as per INSEL[3:0]" : ((CFG1 & 0x3) == 3) ? "CVBS Ain7,Y=Ain7, C=Ain9" : "Reserved";
  const char* INV_DINCLK  = ((CFG1 >> 5) & 0x1) ? "Normal" : "Invert";
  const char* SYN_LO_TRIG = ((CFG1 >> 6) & 0x1) ? "1V trigger for HS/VS" : "3.3V trigger for HS/VS";
  const char* TRI_LEVEL   = ((CFG1 >> 7) & 0x1) ? "Sync detection for tri level sync" : "Sync detection for bi-level sync";
  ALT_LOG_PRINTF("\tSDM_SEL    :\t%s\n", SDM_SEL    );
  ALT_LOG_PRINTF("\tINV_DINCLK :\t%s\n", INV_DINCLK );
  ALT_LOG_PRINTF("\tSYN_LO TRIG:\t%s\n", SYN_LO_TRIG);
  ALT_LOG_PRINTF("\tTRI_LEVEL  :\t%s\n", TRI_LEVEL  );
}
#endif

#ifdef EN_TLLC_PA
void TLLC_PA_DECODE(alt_u8 TLLC_PA){
  const char* BYP_DLL = ((TLLC_PA >> 5) & 0x1) ? "Bypass DLL block" : "ADC clock through DLL block";
  ALT_LOG_PRINTF("\tDLL_PH[4:0]:\tSelect Phase %d\n", (TLLC_PA & 0x1F));
  ALT_LOG_PRINTF("\tBYP_DLL    :\t%s\n", BYP_DLL );
}
#endif

#ifdef EN_CP_OUT_SEL
void CP_OUT_SEL_DECODE(alt_u8 CP_OUT_SEL){
  const char* CPOP_SEL;
  const char* F_OUT_SEL  = ((CP_OUT_SEL >> 6) & 0x1) ? "Field signal o/p on FIELD pin" : "DE (Data Enable) output on the FIELD pin";
  const char* HS_OUT_SEL = ((CP_OUT_SEL >> 7) & 0x1) ? "HSync o/p on the HS pin" : "CSync o/p on the HS pin";
  switch(CP_OUT_SEL & 0xF){
    case 1:  CPOP_SEL = "20-bit out, Y=P19-P10, PrPb=P9-P0";break;
    case 3:  CPOP_SEL = "16-bit out, Y=P19-P12, PrPb=P9-P2";break;
    case 4:  CPOP_SEL = "12-bit DDR";break;
    default: CPOP_SEL = "Reserved";
  }
  ALT_LOG_PRINTF("\tCPOP_SEL  :\t%s\n", CPOP_SEL  );
  ALT_LOG_PRINTF("\tF_OUT_SEL :\t%s\n", F_OUT_SEL );
  ALT_LOG_PRINTF("\tHS_OUT_SEL:\t%s\n", HS_OUT_SEL);
}
#endif

#ifdef EN_CP_MEASURE_CTRL
void CP_MEASURE_CTRL_DECODE(alt_u8 CP_MS_CTRL3, alt_u8 CP_MS_CTRL4){
  const char* CP_GAIN_FILT;
  switch(CP_MS_CTRL4 >> 4){
    case 0:  CP_GAIN_FILT = "No Filtering i.e. Coeffficient A = 1"; break;
    case 1:  CP_GAIN_FILT = "Coefficient A = 1/128 Lines";  break;
    case 2:  CP_GAIN_FILT = "Coefficient A = 1/256 Lines";  break;
    case 3:  CP_GAIN_FILT = "Coefficient A = 1/512 Lines";  break;
    case 4:  CP_GAIN_FILT = "Coefficient A = 1/1024 Lines"; break;
    case 5:  CP_GAIN_FILT = "Coefficient A = 1/2048 Lines"; break;
    case 6:  CP_GAIN_FILT = "Coefficient A = 1/4096 Lines"; break;
    case 7:  CP_GAIN_FILT = "Coefficient A = 1/8192 Lines"; break;
    case 8:  CP_GAIN_FILT = "Coefficient A = 1/16K Lines";  break;
    case 9:  CP_GAIN_FILT = "Coefficient A = 1/32K Lines";  break;
    case 10: CP_GAIN_FILT = "Coefficient A = 1/64K Lines";  break;
    case 11: CP_GAIN_FILT = "Coefficient A = 1/128K Lines"; break;
    default: CP_GAIN_FILT = "Reserved"; break;
  }
  ALT_LOG_PRINTF("\tISD_THR[7:0]     :\t%d\n", CP_MS_CTRL3);
  ALT_LOG_PRINTF("\tISFD_AVG         :\tAverage over %d lines\n", (CP_MS_CTRL4 & 0x1) ? 256 : 128 );
  ALT_LOG_PRINTF("\tCP_GAIN_FILT[3:0]:\t%s\n", CP_GAIN_FILT );
}
#endif

#ifdef EN_CP_DETECTION_CTRL
void CP_DETECTION_CTRL_DECODE(alt_u8 CP_DET_CTRL){
  const char* DS_OUT    = ( (CP_DET_CTRL >> 0) & 0x01 ) ? "" : "a";
  const char* SSPD_CONT = ( (CP_DET_CTRL >> 1) & 0x01 ) ? "0 to 1 transition will cause SSPD block to examine sync signals" : "one shot triggered by TRIG_SSPD";
  const char* SYN_SRC;
  switch( (CP_DET_CTRL >> 3) & 0x07 ){
    case 0: SYN_SRC = "Autodetect mode for sync source"; break;
    case 1: SYN_SRC = "Manual, separate HS_IN & VS_IN"; break;
    case 2: SYN_SRC = "Manual, CS on HS_IN pin"; break;
    case 3: SYN_SRC = "Manual, sync on SOG/SOG"; break;
    default: SYN_SRC = "Undefined"; break;
  }
  const char* POL_HSCS   = ( (CP_DET_CTRL >> 5) & 0x01 ) ? "positive" : "negative";
  const char* POL_VS     = ( (CP_DET_CTRL >> 6) & 0x01 ) ? "positive" : "negative";
  const char* POL_MAN_EN = ( (CP_DET_CTRL >> 7) & 0x01 ) ? "Use POL_VS and POL_HS" : "Use result from SSPD autodetection";
  ALT_LOG_PRINTF("\tDS_OUT    :\toutput %ssynchronous VS/asynchronous CS\n", DS_OUT    );
  ALT_LOG_PRINTF("\tSSPD_CONT :\t%s\n", SSPD_CONT );
  ALT_LOG_PRINTF("\tSYN_SRC   :\t%s\n", SYN_SRC   );
  ALT_LOG_PRINTF("\tPOL_HSCS  :\tHS_IN pin %s polarity (HS or CS)\n", POL_HSCS  );
  ALT_LOG_PRINTF("\tPOL_VS    :\tVS_IN pin %s polarity\n", POL_VS    );
  ALT_LOG_PRINTF("\tPOL_MAN_EN:\t%s\n", POL_MAN_EN);
}
#endif

#ifdef EN_CP_MISC_CONTROL
void CP_MISC_CTRL_DECODE(alt_u8 CP_MISC_CTRL){
  const char* STDI_CONT            = ( (CP_MISC_CTRL >> 1) & 0x01 ) ? "Detector in continous mode" : "one shot triggered by TRIG_STDI";
  const char* STDI_LINE_COUNT_MODE = ( (CP_MISC_CTRL >> 3) & 0x01 ) ? "New STDI \"Line Count\" mode" : "Old STDI \"Sync Count\" mode";
  const char* CPOP_INV_Crb         = ( (CP_MISC_CTRL >> 4) & 0x01 ) ? "invert the order of Cr & Cb o/p" : "Output Cr & Cb interleaved";
  ALT_LOG_PRINTF("\tSTDI_CONT           :\t%s\n", STDI_CONT           );
  ALT_LOG_PRINTF("\tSTDI_LINE_COUNT_MODE:\t%s\n", STDI_LINE_COUNT_MODE);
  ALT_LOG_PRINTF("\tCPOP_INV_Crb        :\t%s\n", CPOP_INV_Crb        );
}
#endif

#ifdef EN_CP_TLLC_CONTROL
void CP_TLLC_CONTROL_DECODE(alt_u8 CP_TLLC_CTRL1,
                            alt_u8 CP_TLLC_CTRL2,
                            alt_u8 CP_TLLC_CTRL3,
                            alt_u8 CP_TLLC_CTRL4){
  alt_u16 PLL_DIV_RATIO     = (CP_TLLC_CTRL1 & 0x0F << 8) | CP_TLLC_CTRL2;
  const char* PLL_DLL_UPD_VS_EN = ( (CP_TLLC_CTRL1 >> 4) & 0x01 ) ? "PLL Divide Ration and DLL Phase update with following Vsync" : "PLL Divide Ratio and DLL Phase update immediately";
  const char* PLL_DIV_MAN_EN    = ( (CP_TLLC_CTRL1 >> 7) & 0x01 ) ? "Use PLL_DIV_RATIO[11:0] as the multiplying factor" : "Auto-from PRIM_MODE[1:0] & VID_STD[3:0]";
  const char* SWAP_CR_CB_WB     = ( (CP_TLLC_CTRL3 >> 4) & 0x01 ) ? "Swap Cr & Cb (OF_SEL[3:0]wide bus modes)" : "Output Cr & Cb as per OF_SEL[3:0]";
  char VCO_RANGE         ;
  const char* VCO_RANGE_MAN     = ( (CP_TLLC_CTRL3 >> 7) & 0x01 ) ? "PLL range from VCO_RANGE[1:0]" : "Automatic VCO Range selection";

  switch((CP_TLLC_CTRL3 >> 5) & 0x03){
    case 0: VCO_RANGE = 21;break;
    case 1: VCO_RANGE = 42;break;
    case 2: VCO_RANGE = 85;break;
    case 3: VCO_RANGE = 170;break;
    default:VCO_RANGE = 0;break;
  }

  ALT_LOG_PRINTF("\tPLL_DIV_RATIO    :\t%d\n", PLL_DIV_RATIO    );
  ALT_LOG_PRINTF("\tPLL_DLL_UPD_VS_EN:\t%s\n", PLL_DLL_UPD_VS_EN);
  ALT_LOG_PRINTF("\tPLL_DIV_MAN_EN   :\t%s\n", PLL_DIV_MAN_EN   );
  ALT_LOG_PRINTF("\tSWAP_CR_CB_WB    :\t%s\n", SWAP_CR_CB_WB    );
  ALT_LOG_PRINTF("\tVCO_RANGE        :\tVCO center freq. %dMhz. Max\n", VCO_RANGE        );
  ALT_LOG_PRINTF("\tVCO_RANGE_MAN    :\t%s\n", VCO_RANGE_MAN    );
}
#endif

#ifdef EN_CP_DEF_COLOR
void CP_DEF_COLOR_DECODE(alt_u8 CP_DEF_COLOR1,
                         alt_u8 CP_DEF_COLOR2,
                         alt_u8 CP_DEF_COLOR3,
                         alt_u8 CP_DEF_COLOR4){
  const char* CP_DEF_COL_FORCE   = ( (CP_DEF_COLOR1 >> 0) & 0x01 ) ? "Force default colour output" : "Do not force default colour output";
  const char* CP_DEF_COL_AUTO    = ( (CP_DEF_COLOR1 >> 1) & 0x01 ) ? "Output default colours" : "Disable auto insertion of default col";
  const char* CP_DEF_COL_MAN_VAL = ( (CP_DEF_COLOR1 >> 2) & 0x01 ) ? "Output user programmable value" : "Use default colour blue";
  ALT_LOG_PRINTF("\tCP_DEF_COL_FORCE  :\t%s\n", CP_DEF_COL_FORCE  );
  ALT_LOG_PRINTF("\tCP_DEF_COL_AUTO   :\t%s\n", CP_DEF_COL_AUTO   );
  ALT_LOG_PRINTF("\tCP_DEF_COL_MAN_VAL:\t%s\n", CP_DEF_COL_MAN_VAL);
  ALT_LOG_PRINTF("\tDEF_COL_CHA       :\t%d\n", CP_DEF_COLOR2     );
  ALT_LOG_PRINTF("\tDEF_COL_CHB       :\t%d\n", CP_DEF_COLOR3     );
  ALT_LOG_PRINTF("\tDEF_COL_CHC       :\t%d\n", CP_DEF_COLOR4     );
}
#endif

#ifdef EN_ADC_SWITCH
void ADC_SWITCH_DECODE(alt_u8 ADC_SWITCH1, alt_u8 ADC_SWITCH2){
  const char* ADC0_SW       = "No connection";
  const char* ADC1_SW       = "No connection";
  const char* ADC2_SW       = "No connection";
  const char* SOG_SEL       = ((ADC_SWITCH2 >> 6) & 0x01) ? "Sync stripper connected to SOG" : "Sync stripper connected to SOY";
  const char* ADC_SW_MAN_EN = ((ADC_SWITCH2 >> 7) & 0x01) ? "Enable" : "Disable";
  switch((ADC_SWITCH1 >> 0) & 0x0F){
    case 1:  ADC0_SW = "Ain2"; break;
    case 2:  ADC0_SW = "Ain3"; break;
    case 3:  ADC0_SW = "Ain5"; break;
    case 4:  ADC0_SW = "Ain6"; break;
    case 5:  ADC0_SW = "Ain8"; break;
    case 6:  ADC0_SW = "Ain10"; break;
    case 9:  ADC0_SW = "Ain1"; break;
    case 11: ADC0_SW = "Ain4"; break;
    case 13: ADC0_SW = "Ain7"; break;
    case 14: ADC0_SW = "Ain9"; break;
    default: ADC0_SW = "No Connection"; break;
  }
  switch((ADC_SWITCH1 >> 4) & 0x0F){
    case 3:  ADC1_SW = "Ain5";  break;
    case 4:  ADC1_SW = "Ain6";  break;
    case 5:  ADC1_SW = "Ain8";  break;
    case 6:  ADC1_SW = "Ain10"; break;
    case 11: ADC1_SW = "Ain4";  break;
    case 13: ADC1_SW = "Ain7";  break;
    case 14: ADC1_SW = "Ain9";  break;
    default: ADC1_SW = "No Connection"; break;
  }
  switch((ADC_SWITCH2 >> 0) & 0x0F){
    case 2:  ADC2_SW = "Ain3";  break;
    case 4:  ADC2_SW = "Ain6";  break;
    case 5:  ADC2_SW = "Ain8";  break;
    case 6:  ADC2_SW = "Ain10"; break;
    case 13: ADC2_SW = "Ain7";  break;
    case 14: ADC2_SW = "Ain9";  break;
    default: ADC2_SW = "No Connection"; break;
  }
  ALT_LOG_PRINTF("\tADC0_SW      :\t%s\n", ADC0_SW      );
  ALT_LOG_PRINTF("\tADC1_SW      :\t%s\n", ADC1_SW      );
  ALT_LOG_PRINTF("\tADC2_SW      :\t%s\n", ADC2_SW      );
  ALT_LOG_PRINTF("\tSOG_SEL      :\t%s\n", SOG_SEL      );
  ALT_LOG_PRINTF("\tADC_SW_MAN_EN:\t%s\n", ADC_SW_MAN_EN );
}
#endif

#ifdef EN_DDR_MODE
void DDR_MODE_DECODE(char DDR_MODE){
  const char* DPP_CP_BYPASS    = ((DDR_MODE >> 0) & 0x01) ? "" : "Analogue processing";
  const char* DDS_DIN_CLK_EN   = ((DDR_MODE >> 1) & 0x01) ? "" : "DLL input clock same as ADC clock";
  const char* DDR_I2C_RC_FIRST = ((DDR_MODE >> 2) & 0x01) ? "First" : "Last";
  const char* DDR_EN           = ((DDR_MODE >> 3) & 0x01) ? "Enabled" : "Disabled";
  ALT_LOG_PRINTF("\tDPP_CP_BYPASS   :\t%s\n", DPP_CP_BYPASS   );
  ALT_LOG_PRINTF("\tDDS_DIN_CLK_EN  :\t%s\n", DDS_DIN_CLK_EN  );
  ALT_LOG_PRINTF("\tDDR_I2C_RC_FIRST:\tRed component out %s\n", DDR_I2C_RC_FIRST);
  ALT_LOG_PRINTF("\tDDR_EN          :\tDDR Mode %s\n", DDR_EN          );
}
#endif

#ifdef EN_STATUS
void STATUS_DECODE(alt_u8 STATUS1,
                   alt_u8 INFO   ,
                   alt_u8 STATUS2,
                   alt_u8 STATUS3){
  const char* AD_RESULT;
  switch((STATUS1 >> 0) & 0x01){
    case 0: AD_RESULT = "NTSM-MJ";           break;
    case 1: AD_RESULT = "NTSM-443";          break;
    case 2: AD_RESULT = "PAL-M";             break;
    case 3: AD_RESULT = "PAL-60";            break;
    case 4: AD_RESULT = "PAL-BGHID";         break;
    case 5: AD_RESULT = "SECAM";             break;
    case 6: AD_RESULT = "PAL Combination N"; break;
    case 7: AD_RESULT = "SECAM 525";         break;
  }
  ALT_LOG_PRINTF("\tREVISION     :\t0x%x(%d)\n",  INFO, INFO                  );
  ALT_LOG_PRINTF("\tIN_LOCK      :\t%c(Now)\n", ((STATUS1 >> 0) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tLOST_LOCK    :\t%c(Since last read)\n", ((STATUS1 >> 1) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tFSC_LOCK     :\t%c(Now)\n", ((STATUS1 >> 2) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tFOLLOW_PW    :\t%c(Peak white AGC mode active)\n", ((STATUS1 >> 3) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tAD_RESULT    :\t%s\n",  AD_RESULT                         );
  ALT_LOG_PRINTF("\tCOL_KILL     :\t%c(Colour Kill is active)\n", ((STATUS1 >> 7) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tMCVS_DET     :\t%c(MV Colour striping detected)\n", ((STATUS2 >> 0) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tMCVS_T3      :\t%c(MV Colour striping type)\n", ((STATUS2 >> 1) & 0x01) ? '3' : '2');
  ALT_LOG_PRINTF("\tMV_PS_DET    :\t%c(MV Pseudo Sync detected)\n", ((STATUS2 >> 2) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tMV_AGC       :\t%c(MV AGC pulses detected)\n", ((STATUS2 >> 3) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tLL_NSTD      :\t%c(Non Standard line length)\n", ((STATUS2 >> 4) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tFSC_NSTD     :\t%c(Fsc Frequency non standard)\n", ((STATUS2 >> 5) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tCP_FREE_RUN  :\t%s\n", ((STATUS2 >> 6) & 0x01) ? "CP free running" : "Valid Video signal found");
  ALT_LOG_PRINTF("\tTLLC_PLL_LOCK:\t%c(PLL Locked)\n", ((STATUS2 >> 7) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tINST_HLOCK   :\t%c(Horizontal lock achieved)\n", ((STATUS3 >> 0) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tGEMD         :\t%c(Gemstar data detected)\n", ((STATUS3 >> 1) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tSD_OP_50Hz   :\tSD %c0Hz detected\n", ((STATUS3 >> 2) & 0x01) ? '5' : '6');
  ALT_LOG_PRINTF("\tCVBS         :\t%s signal detected\n", ((STATUS3 >> 3) & 0x01) ? "CVBS" : "Y/C");
  ALT_LOG_PRINTF("\tFREE_RUN_ACT :\t%c(Free Run mode Active aka Blue screen)\n", ((STATUS3 >> 4) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tSTD_FLD_LEN  :\t%c(Field length standard)\n", ((STATUS3 >> 5) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tINTERLACE    :\t%c(Interlaced Video detected)\n", ((STATUS3 >> 6) & 0x01) ? '+' : '-');
  ALT_LOG_PRINTF("\tPAL_SW_LOCK  :\t%c(Swinging Burst Detected)\n", ((STATUS3 >> 7) & 0x01) ? '+' : '-');
}
#endif

void adv7181d_status(alt_u8 addr){
  #ifdef EN_STATUS
  char STATUS1 = i2c_read(addr, 0x10);
  char INFO    = i2c_read(addr, 0x11);
  char STATUS2 = i2c_read(addr, 0x12);
  char STATUS3 = i2c_read(addr, 0x13);
  ALT_LOG_PRINTF("STATUS1[%x]:\t0x%x\n", addr, STATUS1);
  ALT_LOG_PRINTF("STATUS2[%x]:\t0x%x\n", addr, STATUS2);
  ALT_LOG_PRINTF("STATUS3[%x]:\t0x%x\n", addr, STATUS3);
  ALT_LOG_PRINTF("INFO[%x]   :\t0x%x\n", addr, INFO);
  STATUS_DECODE(STATUS1, INFO, STATUS2, STATUS3);
  #endif
  #ifdef EN_INCTRL
  alt_u8 Input_Control = i2c_read(addr, 0x00);
  ALT_LOG_PRINTF("INPUT CONTROL[%x]:\t0x%x\n", addr, Input_Control);
  INCTRL_DECODE(Input_Control);
  #endif
  #ifdef EN_VIDEO_SELECTION
  alt_u8 Video_Selection    = i2c_read(addr, 0x01);
  ALT_LOG_PRINTF("VIDEO SELECTION[%x]:\t0x%x\n", addr, Video_Selection);
  VIDEO_SELECTION_DECODE(Video_Selection);
  #endif
  #ifdef EN_OUTPUT_CONTROL
  alt_u8 Output_Control     = i2c_read(addr, 0x03);
  ALT_LOG_PRINTF("OUTPUT CONTROL[%x]:\t0x%x\n", addr, Output_Control);
  OUTPUT_CONTROL_DECODE(Output_Control);
  #endif
  #ifdef EN_EX_OUTPUT_CONTROL
  alt_u8 Ex_Output_Control  = i2c_read(addr, 0x04);
  ALT_LOG_PRINTF("EX OUTPUT CONTROL[%x]:\t0x%x\n", addr, Ex_Output_Control);
  EX_OUTPUT_CONTROL_DECODE(Ex_Output_Control);
  #endif
  #ifdef EN_VIDEO_STANDART
  alt_u8 Prim_Mode = i2c_read(addr, 0x05);
  alt_u8 Vid_Std   = i2c_read(addr, 0x06);
  ALT_LOG_PRINTF("PRIM_MODE[%x]:\t0x%x\n", addr, Prim_Mode);
  ALT_LOG_PRINTF("VID_STD[%x]  :\t0x%x\n", addr, Vid_Std);
  VIDEO_STANDART_DECODE(Prim_Mode, Vid_Std);
  #endif
  #ifdef EN_POWER_MENEGEMENT
  alt_u8 Power_Mgr = i2c_read(addr, 0x0F);
  ALT_LOG_PRINTF("POWER MANAGEMENT[%x]:\t0x%x\n", addr, Power_Mgr);
  POWER_MENEGEMENT_DECODE(Power_Mgr);
  #endif
  #ifdef EN_ADC_CONTROL
  alt_u8 ADC_ctrl   = i2c_read(addr, 0x3A);
  ALT_LOG_PRINTF("ADC CONTROL[%x]:\t0x%x\n", addr, ADC_ctrl);
  ADC_CONTROL_DECODE(ADC_ctrl);
  #endif
  #ifdef EN_BIAS_CTRL
  alt_u8 BIAS_CTRL  = i2c_read(addr, 0x3B);
  ALT_LOG_PRINTF("BIAS CONTROL[%x]:\t0x%x\n", addr, BIAS_CTRL);
  BIAS_CTRL_DECODE(BIAS_CTRL);
  #endif
  #ifdef EN_TTLC_CTRL
  alt_u8 TLLC_ctrl  = i2c_read(addr, 0x3C);
  ALT_LOG_PRINTF("TLLC CONTROL[%x]:\t0x%x\n", addr, TLLC_ctrl);
  TTLC_CTRL_DECODE(TLLC_ctrl);
  #endif
  #ifdef EN_MANUAL_WINDOW
  alt_u8 MNL_WDW    = i2c_read(addr, 0x3C);
  ALT_LOG_PRINTF("MANUAL WINDOW[%x]:\t0x%x\n", addr, MNL_WDW);
  MANUAL_WINDOW_DECODE(TLLC_ctrl);
  #endif
  #ifdef EN_LOCK_CNT
  alt_u8 LOCK_CNT   = i2c_read(addr, 0x51);
  ALT_LOG_PRINTF("LOCK COUNT[%x]:\t0x%x\n", addr, LOCK_CNT);
  LOCK_CNT_DECODE(LOCK_CNT);
  #endif
  #ifdef EN_CONFIGURE1
  alt_u8 CONFIGURE1 = i2c_read(addr, 0x69);
  ALT_LOG_PRINTF("CONFIGURE 1[%x]:\t0x%x\n", addr, CONFIGURE1);
  CONFIGURE1_DECODE(CONFIGURE1);
  #endif
  #ifdef EN_TLLC_PA
  alt_u8 TLLC_PA    = i2c_read(addr, 0x69);
  ALT_LOG_PRINTF("TLLC PHASE ADJUST[%x]:\t0x%x\n", addr, TLLC_PA);
  TLLC_PA_DECODE(TLLC_PA);
  #endif
  #ifdef EN_CP_OUT_SEL
  alt_u8 CP_OUT_SEL = i2c_read(addr, 0x6B);
  ALT_LOG_PRINTF("CP OUTPUT SELECTION[%x]:\t0x%x\n", addr, CP_OUT_SEL);
  CP_OUT_SEL_DECODE(CP_OUT_SEL);
  #endif
  #ifdef EN_CP_MEASURE_CTRL
  alt_u8 CP_MS_CTRL3 = i2c_read(addr, 0x83);
  alt_u8 CP_MS_CTRL4 = i2c_read(addr, 0x84);
  ALT_LOG_PRINTF("CP MEASURE CONTROL 3[%x]:\t0x%x\n", addr, CP_MS_CTRL3);
  ALT_LOG_PRINTF("CP MEASURE CONTROL 4[%x]:\t0x%x\n", addr, CP_MS_CTRL4);
  CP_MEASURE_CTRL_DECODE(CP_MS_CTRL3, CP_MS_CTRL4);
  #endif
  #ifdef EN_CP_DETECTION_CTRL
  alt_u8 CP_DET_CTRL = i2c_read(addr, 0x85);
  ALT_LOG_PRINTF("CP DETECTION CONTROL[%x]:\t0x%x\n", addr, CP_DET_CTRL);
  CP_DETECTION_CTRL_DECODE(CP_DET_CTRL);
  #endif
  #ifdef EN_CP_MISC_CONTROL
  alt_u8 CP_MISC_CTRL = i2c_read(addr, 0x86);
  ALT_LOG_PRINTF("CP MISC CONTROL[%x]:\t0x%x\n", addr, CP_MISC_CTRL);
  CP_MISC_CTRL_DECODE(CP_MISC_CTRL);
  #endif
  #ifdef EN_CP_TLLC_CONTROL
  alt_u8 CP_TLLC_CTRL1 = i2c_read(addr, 0x87);
  alt_u8 CP_TLLC_CTRL2 = i2c_read(addr, 0x88);
  alt_u8 CP_TLLC_CTRL3 = i2c_read(addr, 0x89);
  alt_u8 CP_TLLC_CTRL4 = i2c_read(addr, 0x8A);
  ALT_LOG_PRINTF("CP TLLC CONTROL1[%x]:\t0x%x\n", addr, CP_TLLC_CTRL1);
  ALT_LOG_PRINTF("CP TLLC CONTROL2[%x]:\t0x%x\n", addr, CP_TLLC_CTRL2);
  ALT_LOG_PRINTF("CP TLLC CONTROL3[%x]:\t0x%x\n", addr, CP_TLLC_CTRL3);
  ALT_LOG_PRINTF("CP TLLC CONTROL4[%x]:\t0x%x\n", addr, CP_TLLC_CTRL4);
  CP_TLLC_CONTROL_DECODE(CP_TLLC_CTRL1, CP_TLLC_CTRL2, CP_TLLC_CTRL3, CP_TLLC_CTRL4);
  #endif
  #ifdef EN_CP_DEF_COLOR
  alt_u8 CP_DEF_COLOR1 = i2c_read(addr, 0xBF);
  alt_u8 CP_DEF_COLOR2 = i2c_read(addr, 0xC0);
  alt_u8 CP_DEF_COLOR3 = i2c_read(addr, 0xC1);
  alt_u8 CP_DEF_COLOR4 = i2c_read(addr, 0xC2);
  ALT_LOG_PRINTF("CP DEF COLOR[%x]:\t0x%x\n", addr, CP_DEF_COLOR1);
  CP_DEF_COLOR_DECODE(CP_DEF_COLOR1, CP_DEF_COLOR2, CP_DEF_COLOR3, CP_DEF_COLOR4);
  #endif
  #ifdef EN_ADC_SWITCH
  alt_u8 ADC_SWITCH1 = i2c_read(addr, 0xC3);
  alt_u8 ADC_SWITCH2 = i2c_read(addr, 0xC4);
  ALT_LOG_PRINTF("ADC SWITCH1[%x]:\t0x%x\n", addr, ADC_SWITCH1);
  ALT_LOG_PRINTF("ADC SWITCH2[%x]:\t0x%x\n", addr, ADC_SWITCH2);
  ADC_SWITCH_DECODE(ADC_SWITCH1, ADC_SWITCH2);
  #endif
  #ifdef EN_DDR_MODE
  alt_u8 DDR_MODE = i2c_read(addr, 0xC9);
  ALT_LOG_PRINTF("DDR MODE[%x]:\t0x%x\n", addr, DDR_MODE);
  DDR_MODE_DECODE(DDR_MODE);
  #endif
  #ifdef EN_FIELD_LENGTH
  alt_u8 FLC1 = i2c_read(addr, 0xCA);
  alt_u8 FLC2 = i2c_read(addr, 0xCB);
  ALT_LOG_PRINTF("Field Length Count[%x]:\t0x%x(%d)\n", addr, (FLC1 & 0x1F)<<8|FLC2, (FLC1 & 0x1F)<<8|FLC2);
  #endif
  #ifdef EN_LETTER_BOX
  alt_u8 LB_LCT = i2c_read(addr, 0x9B);
  alt_u8 LB_LCM = i2c_read(addr, 0x9C);
  alt_u8 LB_LCB = i2c_read(addr, 0x9D);
  ALT_LOG_PRINTF("Letter box(number of black lines detected):\r\n");
  ALT_LOG_PRINTF("\tLB_LCT\t:%x(at top of active video)\r\n ", LB_LCT);
  ALT_LOG_PRINTF("\tLB_LCM\t:%x(in bottom half of active video if subtitles detected)\r\n ", LB_LCM);
  ALT_LOG_PRINTF("\tLB_LCB\t:%x(at bottom of active video)\r\n ", LB_LCB);
  #endif
  #ifdef EN_RB
  alt_u16 CP_AGC  = ((i2c_read(addr, 0xA0) & 0x03) << 8) | i2c_read(addr, 0xA1);
  alt_u16 ISD     = ((i2c_read(addr, 0xA3) & 0x01) << 8) | i2c_read(addr, 0xA4);
  alt_u16 IFSD    = ((i2c_read(addr, 0xA3) & 0x02) << 8) | i2c_read(addr, 0xA5);
  alt_u16 CALIB   = ((i2c_read(addr, 0xA3) & 0x1C) << 6) | 0;
  alt_u16 HSD_CHA = ((i2c_read(addr, 0xA7) & 0x03) << 8) | i2c_read(addr, 0xA8);
  alt_u16 HSD_CHB = ((i2c_read(addr, 0xA7) & 0x0C) << 6) | i2c_read(addr, 0xA9);
  alt_u16 HSD_CHC = ((i2c_read(addr, 0xA7) & 0x30) << 4) | i2c_read(addr, 0xAA);
  alt_u16 HSD_FB  = ((i2c_read(addr, 0xAB) & 0x0F) << 8) | i2c_read(addr, 0xAC);
  alt_u16 PKV_CHA = ((i2c_read(addr, 0xAD) & 0x03) << 8) | i2c_read(addr, 0xAE);
  alt_u16 PKV_CHB = ((i2c_read(addr, 0xAD) & 0x0C) << 6) | i2c_read(addr, 0xAF);
  alt_u16 PKV_CHC = ((i2c_read(addr, 0xAD) & 0x30) << 4) | i2c_read(addr, 0xB0);
  alt_u16 BL   = ((i2c_read(addr, 0xB1) & 0x3F) << 8) | i2c_read(addr, 0xB2);
  alt_u16 LCF  = ((i2c_read(addr, 0xB3) & 0x07) << 8) | i2c_read(addr, 0xB4);
  alt_u8  LCVS = ((i2c_read(addr, 0xB3) & 0xF8) >> 3);
  ALT_LOG_PRINTF("Read back registers:\r\n");
  ALT_LOG_PRINTF("\tCP_AGC_GAIN:\t%x(%d)\r\n", CP_AGC, CP_AGC);
  ALT_LOG_PRINTF("\tISD        :\t%x\r\n", ISD);
  ALT_LOG_PRINTF("\tIFSD       :\t%x\r\n", IFSD);
  ALT_LOG_PRINTF("\tCALIB      :\t%x\r\n", CALIB);
  ALT_LOG_PRINTF("\tHSD_CHA    :\t%x\r\n", HSD_CHA);
  ALT_LOG_PRINTF("\tHSD_CHB    :\t%x\r\n", HSD_CHB);
  ALT_LOG_PRINTF("\tHSD_CHC    :\t%x\r\n", HSD_CHC);
  ALT_LOG_PRINTF("\tHSD_FB     :\t%x\r\n", HSD_FB);
  ALT_LOG_PRINTF("\tPKV_CHA    :\t%x\r\n", PKV_CHA);
  ALT_LOG_PRINTF("\tPKV_CHB    :\t%x\r\n", PKV_CHB);
  ALT_LOG_PRINTF("\tPKV_CHC    :\t%x\r\n", PKV_CHC);
  ALT_LOG_PRINTF("\tBL         :\t%x(%d)(block length readback, number of 27Mhz cycles in a block of 8 lines of input video)\r\n", BL, BL);
  ALT_LOG_PRINTF("\tLCF        :\t%x(%d)(Number of lines in field)\r\n", LCF, LCF);
  ALT_LOG_PRINTF("\tLCVS       :\t%x(%d)(Number of lines in a Vsync period)\r\n", LCVS, LCVS);
  ALT_LOG_PRINTF("\tSTDI_INTLCD:\t%s\r\n", (i2c_read(addr, 0xB1) & 0x40) ? "Interlaced I/P standard detected" : "Non-Interlaced standard detected");
  ALT_LOG_PRINTF("\tSTDI_DVALID:\t%s\r\n", (i2c_read(addr, 0xB1) & 0x80) ? "Valid BL, SCVS and SCF parameters" : "BL, SCVS and SCF not valid");
  ALT_LOG_PRINTF("\tCUR_SYNC   :\t%s\r\n", (i2c_read(addr, 0xB5) & 0x03 == 0) ? "Invalid" 
                                         : (i2c_read(addr, 0xB5) & 0x03 == 1) ? "Separate HS and VS sync on pins"
                                         : (i2c_read(addr, 0xB5) & 0x03 == 0) ? "Externl CS sync on HS_IN pin"
                                         : "Embedded SOG/SOY");
  ALT_LOG_PRINTF("\tCUR_POL_HS :\tHS_IN pin %s polarity signal\r\n", (i2c_read(addr, 0xB5) & 0x08) ? "negative" : "positive");
  ALT_LOG_PRINTF("\tHS_ACT     :\t%s\r\n", (i2c_read(addr, 0xB5) & 0x10) ? "No activity detected" : "HS_IN pin carries an active signal");
  ALT_LOG_PRINTF("\tCUR_POL_VS :\tVS_IN pin %s polarity signal\r\n", (i2c_read(addr, 0xB5) & 0x20) ? "negative" : "positive");
  ALT_LOG_PRINTF("\tVS_ACT     :\t%s\r\n", (i2c_read(addr, 0xB5) & 0x40) ? "No activity detected" : "VS_IN pin carries an active signal");
  ALT_LOG_PRINTF("\tSSPD_DVALID:\tSSPD results %s\r\n", (i2c_read(addr, 0xB5) & 0x80) ? "not valid for read back" : "valid");
#endif
}

alt_u8 buff[256];
void adv7181d_readall(alt_u8 addr){
  for(alt_u16 i = 0; i < 256; i++){
    buff[i] = i2c_read(addr, i);
  }
  asm("nop");
}
