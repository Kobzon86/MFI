#include <unistd.h>
#include <alt_types.h>
#include <io.h>

#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_sysid_qsys_regs.h"

#include "shared_ram.h"
#include "si5332_regs.h"
#include "tmds171_regs.h"
#include "adv7613_regs.h"
#include "adv7181d_regs.h"
#include "i2c_master.h"
#include "gpio.h"
#include "video.h"

#include "sys/alt_log_printf.h"

#define FPGA_VERSION        ( 1 )
#define FPGA_SUB_VERSION    ( 0 )
#define FPGA_LOCAL_VERSION  ( 3 )
#define FPGA_CHECKSUM_CONST ( 0x0FC6E26C )

#define LAYER_TIMEOUT   ( 3 )
#define EDP_TIMEOUT     ( 5 )

#ifdef ALT_MODULE_CLASS_shared_ram_0
volatile struct shared_ram* shared_ram0 = (struct shared_ram*)SHARED_RAM_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_0
volatile struct cvi_ctrl* cvi0 = (struct cvi_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVI_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_1
volatile struct cvi_ctrl* cvi1 = (struct cvi_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVI_1_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_2
volatile struct cvi_ctrl* cvi2 = (struct cvi_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVI_2_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_3
volatile struct cvi_ctrl* cvi3 = (struct cvi_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVI_3_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_4
volatile struct cvi_ctrl* cvi4 = (struct cvi_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVI_4_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_swi_0
volatile struct switch_ctrl* sw0 = (struct switch_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_SWI_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_clp_0
volatile struct clipper_ctrl* clp0 = (struct clipper_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CLP_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_clp_1
volatile struct clipper_ctrl* clp1 = (struct clipper_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CLP_1_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_scl_0
volatile struct scaler_ctrl* sc0 = (struct scaler_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_SCL_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_scl_1
volatile struct scaler_ctrl* sc1 = (struct scaler_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_SCL_1_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_mixer_0
volatile struct mixer_ctrl* mix0 = (struct mixer_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_MIXER_0_BASE;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvo_0
volatile struct cvo_ctrl* cvo0 = (struct cvo_ctrl*)VIDEO_CORE_0_ALT_VIP_CL_CVO_0_BASE;
#endif

volatile static alt_u8  lcd_type;
volatile static alt_u8  edp_timer;
volatile static alt_u16 layer_timer[2];
volatile static alt_u8 heart, heart_bit;

int main()
{

  while( 1 ) {

    edp_timer      = 0;
    layer_timer[0] = 0;
    layer_timer[1] = 0;
    heart          = 0;
    heart_bit      = 0;
    IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, 0xFFFFFFFF );
    usleep( 10000 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_IP_RESET_N );
    usleep( 400000 );

    lcd_type = ( ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_LCD_SIZE_MASK ) >> GPIO_LCD_SIZE_SHIFT );

    if( lcd_type == MFD_15INCH_TYPE )
      i2c_write_array( si5332_fhd_registers, SI5332_FHD_NUM_REGS );
    else if( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) )
      i2c_write_array( si5332_xga_registers, SI5332_XGA_NUM_REGS );
    else
      i2c_write_array( si5332_vga_registers, SI5332_VGA_NUM_REGS );
    usleep( 400000 );

    if( ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_BOT_LOCKED ) &&
        ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_TOP_LOCKED ) )
      IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_DDR_BOT_GLOBAL_RESET | GPIO_DDR_TOP_GLOBAL_RESET );
    else
      continue;
    usleep( 400000 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_DDR_BOT_SOFT_RESET | GPIO_DDR_TOP_SOFT_RESET );
    usleep( 200000 );

    shared_ram0->cvi[0].control = 1;
    shared_ram0->cvi[1].control = 1;
    shared_ram0->cvi[2].control = 1;
    shared_ram0->cvi[3].control = 1;
    shared_ram0->cvi[4].control = 1;

    shared_ram0->sw[0].control   = 1;
    shared_ram0->sw[0].output[0] = 2;
    shared_ram0->sw[0].output[1] = 4;

    shared_ram0->clp[0].control  = 1;
    shared_ram0->clp[0].offset.x = 0;
    shared_ram0->clp[0].offset.y = 0;
    shared_ram0->clp[0].clip.x   = 0;
    shared_ram0->clp[0].clip.y   = 0;
    shared_ram0->clp[1].control  = 1;
    shared_ram0->clp[1].offset.x = 0;
    shared_ram0->clp[1].offset.y = 0;
    shared_ram0->clp[1].clip.x   = 0;
    shared_ram0->clp[1].clip.y   = 0;

    shared_ram0->sc[0].control      = 1;
    shared_ram0->sc[0].resolution.x = ( lcd_type == MFD_15INCH_TYPE ) ? 1920 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ? 1024 : 640;
    shared_ram0->sc[0].resolution.y = ( lcd_type == MFD_15INCH_TYPE ) ? 1080 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ?  768 : 480;
    shared_ram0->sc[1].control      = 1;
    shared_ram0->sc[1].resolution.x = ( lcd_type == MFD_15INCH_TYPE ) ? 1920 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ? 1024 : 640;
    shared_ram0->sc[1].resolution.y = ( lcd_type == MFD_15INCH_TYPE ) ? 1080 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ?  768 : 480;

    shared_ram0->mix[0].control           = 1;
    shared_ram0->mix[0].resolution.x      = ( lcd_type == MFD_15INCH_TYPE ) ? 1920 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ? 1024 : 640;
    shared_ram0->mix[0].resolution.y      = ( lcd_type == MFD_15INCH_TYPE ) ? 1080 : ( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) ) ?  768 : 480;
    shared_ram0->mix[0].background.red    = 0;
    shared_ram0->mix[0].background.green  = 0;
    shared_ram0->mix[0].background.blue   = 0;
    shared_ram0->mix[0].layer[0].control  = 0;
    shared_ram0->mix[0].layer[0].position = 0;
    shared_ram0->mix[0].layer[0].alpha    = 0;
    shared_ram0->mix[0].layer[0].offset.x = 0;
    shared_ram0->mix[0].layer[0].offset.y = 0;
    shared_ram0->mix[0].layer[1].control  = 0;
    shared_ram0->mix[0].layer[1].position = 1;
    shared_ram0->mix[0].layer[1].alpha    = 0;
    shared_ram0->mix[0].layer[1].offset.x = 0;
    shared_ram0->mix[0].layer[1].offset.y = 0;
    shared_ram0->mix[0].layer[2].control  = 1;
    shared_ram0->mix[0].layer[2].position = 2;
    shared_ram0->mix[0].layer[2].alpha    = 0;
    shared_ram0->mix[0].layer[2].offset.x = 0;
    shared_ram0->mix[0].layer[2].offset.y = 0;

    shared_ram0->cvo[0].control = 1;

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvo_0
    if( ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_BOT_LOCKED ) &&
        ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_TOP_LOCKED ) ) {
      cvo0->Control                       = 1;
      cvo0->Bank_Select                   = 0;
      cvo0->ModeX_Valid                   = 0;
      cvo0->ModeX_Control                 = 0;
      cvo0->ModeX_Sample_Count            = 1024;
      cvo0->ModeX_F0_Line_Count           = 768;
      cvo0->ModeX_F1_Line_Count           = 0;
      cvo0->ModeX_Horizontal_Front_Porch  = 24;
      cvo0->ModeX_Horizontal_Sync_Length  = 136;
      cvo0->ModeX_Horizontal_Blanking     = 320;
      cvo0->ModeX_Vertical_Front_Porch    = 3;
      cvo0->ModeX_Vertical_Sync_Length    = 6;
      cvo0->ModeX_Vertical_Blanking       = 38;
      cvo0->ModeX_F0_Vertical_Front_Porch = 0;
      cvo0->ModeX_F0_Vertical_Sync_Length = 0;
      cvo0->ModeX_F0_Vertical_Blanking    = 0;
      cvo0->ModeX_Active_Picture_Line     = 135;
      cvo0->ModeX_F0_Vertical_Rising      = 0;
      cvo0->ModeX_Field_Rising            = 0;
      cvo0->ModeX_Field_Falling           = 0;
      cvo0->ModeX_Standart                = 0;
      cvo0->ModeX_SOF_Sample              = 0;
      cvo0->ModeX_SOF_Line                = 0;
      cvo0->ModeX_Vcoclk_Divider          = 0;
      cvo0->ModeX_Ancillary_Line          = 0;
      cvo0->ModeX_F0_Ancillary_Line       = 0;
      cvo0->ModeX_HSync_Polarity          = 0;
      cvo0->ModeX_VSync_Polarity          = 0;
      cvo0->ModeX_Valid                   = 1;
      cvo0->Bank_Select                   = 1;
      cvo0->ModeX_Valid                   = 0;
      cvo0->ModeX_Control                 = 0;
      cvo0->ModeX_Sample_Count            = 1920;
      cvo0->ModeX_F0_Line_Count           = 1080;
      cvo0->ModeX_F1_Line_Count           = 0;
      cvo0->ModeX_Horizontal_Front_Porch  = 88;
      cvo0->ModeX_Horizontal_Sync_Length  = 44;
      cvo0->ModeX_Horizontal_Blanking     = 280;
      cvo0->ModeX_Vertical_Front_Porch    = 4;
      cvo0->ModeX_Vertical_Sync_Length    = 5;
      cvo0->ModeX_Vertical_Blanking       = 45;
      cvo0->ModeX_F0_Vertical_Front_Porch = 0;
      cvo0->ModeX_F0_Vertical_Sync_Length = 0;
      cvo0->ModeX_F0_Vertical_Blanking    = 0;
      cvo0->ModeX_Active_Picture_Line     = 135;
      cvo0->ModeX_F0_Vertical_Rising      = 0;
      cvo0->ModeX_Field_Rising            = 0;
      cvo0->ModeX_Field_Falling           = 0;
      cvo0->ModeX_Standart                = 0;
      cvo0->ModeX_SOF_Sample              = 0;
      cvo0->ModeX_SOF_Line                = 0;
      cvo0->ModeX_Vcoclk_Divider          = 0;
      cvo0->ModeX_Ancillary_Line          = 0;
      cvo0->ModeX_F0_Ancillary_Line       = 0;
      cvo0->ModeX_HSync_Polarity          = 0;
      cvo0->ModeX_VSync_Polarity          = 0;
      cvo0->ModeX_Valid                   = 1;
    }
#endif

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_TMDS171_OE );
    usleep( 100000 );
    i2c_write_array( tmds171_registers, TMDS171_NUM_REGS );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_ADV7613_RESET );
    usleep( 200000 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_ADV7613_CS0 );
   usleep( 200000 );
    i2c_write_array( adv7613_registers, ADV7613_NUM_REGS );
    IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, GPIO_ADV7613_CS0 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_ADV7613_CS1 );
    usleep( 200000 );
    i2c_write_array( adv7613_registers, ADV7613_NUM_REGS );
    IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, GPIO_ADV7613_CS1 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_ADV7181_RESET );
    usleep( 200000 );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_ADV7613_CS1 );
        usleep( 200000 );
    alt_u8 oo = i2c_read(0x98,0xf5);



    i2c_write_array( adv7181_registers, ADV7181_NUM_REGS );

    if( lcd_type == MFD_15INCH_TYPE )
      IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, ( GPIO_DP_RESET_N | GPIO_DP_HPD ) );
    else if( ( lcd_type == MFD_12INCH_TYPE ) || ( lcd_type == MFD_10INCH_TYPE ) )
      IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, ( GPIO_LVDS_RESET_N | GPIO_LVDS_LCD_SCAN ) );

    IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, ( GPIO_AV_RESET_N | GPIO_TMDS_RESET_N | GPIO_IMX6_ALPHA ) );

    switch( lcd_type ) {
      case MFD_15INCH_TYPE:
        gpio_set( GPIO_OUT3_EN_N | GPIO_LCD_BKLT_EN0 | GPIO_LCD_BKLT_EN1 );
        break;
      case MFD_12INCH_TYPE:
        gpio_set( GPIO_LCD_BKLT_EN0 );
        break;
      case MFD_10INCH_TYPE:
        gpio_set( GPIO_OUT1_EN_N | GPIO_LCD_BKLT_EN1 );
        break;
    }

    while( ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_BOT_LOCKED       ) &&
	       ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_TOP_LOCKED       ) &&
	       ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_BOT_CAL_SUCCESS  ) &&
	       ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_TOP_CAL_SUCCESS  ) &&
	       ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_BOT_INIT_DONE    ) &&
	       ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DDR_TOP_INIT_DONE    ) &&
	       ( lcd_type == ( ( IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_LCD_SIZE_MASK ) >> GPIO_LCD_SIZE_SHIFT ) ) ) {

      shared_ram0->sys.version          = FPGA_VERSION;
      shared_ram0->sys.sub_version      = FPGA_SUB_VERSION;
      shared_ram0->sys.local_version    = FPGA_LOCAL_VERSION;
      shared_ram0->sys.version_checksum = ( 0xFF ^ FPGA_VERSION ^ FPGA_SUB_VERSION ^ FPGA_LOCAL_VERSION );
      shared_ram0->sys.checksum         = FPGA_CHECKSUM_CONST;
      shared_ram0->sys.runtime          = ( shared_ram0->sys.runtime + 1 );

      if ( shared_ram0->sys.alpha & 0x01 )
        IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, GPIO_IMX6_ALPHA );
      else
        IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_IMX6_ALPHA );

	  heart = (heart < 1) ? heart + 1 : 0;
	  if (heart == 0) {
	    heart_bit = ~heart_bit;
	    if (heart_bit)
		  gpio_set(GPIO_NIOS_HEART_BEAT);
	    else
		  gpio_clear(GPIO_NIOS_HEART_BEAT);
	  }

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_0
      cvi0->Control                    = shared_ram0->cvi[0].control;
      shared_ram0->cvi[0].status       = cvi0->Status;
      shared_ram0->cvi[0].resolution.x = cvi0->Active_Sample_Count;
      shared_ram0->cvi[0].resolution.y = cvi0->F0_Active_Line_Count;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_1
      cvi1->Control                    = shared_ram0->cvi[1].control;
      shared_ram0->cvi[1].status       = cvi1->Status;
      shared_ram0->cvi[1].resolution.x = cvi1->Active_Sample_Count;
      shared_ram0->cvi[1].resolution.y = cvi1->F0_Active_Line_Count;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_2
      cvi2->Control                    = shared_ram0->cvi[2].control;
      shared_ram0->cvi[2].status       = cvi2->Status;
      shared_ram0->cvi[2].resolution.x = cvi2->Active_Sample_Count;
      shared_ram0->cvi[2].resolution.y = cvi2->F0_Active_Line_Count;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_3
      cvi3->Control                    = shared_ram0->cvi[3].control;
      shared_ram0->cvi[3].status       = cvi3->Status;
      shared_ram0->cvi[3].resolution.x = cvi3->Active_Sample_Count;
      shared_ram0->cvi[3].resolution.y = cvi3->F0_Active_Line_Count;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvi_4
      cvi4->Control                    = shared_ram0->cvi[4].control;
      shared_ram0->cvi[4].status       = cvi4->Status;
      shared_ram0->cvi[4].resolution.x = cvi4->Active_Sample_Count;
      shared_ram0->cvi[4].resolution.y = cvi4->F0_Active_Line_Count;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_swi_0
      sw0->Control              = shared_ram0->sw[0].control;
      shared_ram0->sw[0].status = sw0->Status;
      if( ( sw0->Output_Ctrl[0] != shared_ram0->sw[0].output[0] ) |
          ( sw0->Output_Ctrl[1] != shared_ram0->sw[0].output[1] ) ) {
        sw0->Output_Ctrl[0] = shared_ram0->sw[0].output[0];
        sw0->Output_Ctrl[1] = shared_ram0->sw[0].output[1];
        sw0->Output_Switch  = 1;
      }
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_clp_0
      clp0->Control       = shared_ram0->clp[0].control;
      clp0->Left_offset   = shared_ram0->clp[0].offset.x;
      clp0->Top_offset    = shared_ram0->clp[0].offset.y;
      clp0->Right_offset  = shared_ram0->clp[0].clip.x;
      clp0->Bottom_offset = shared_ram0->clp[0].clip.y;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_clp_1
      clp1->Control       = shared_ram0->clp[1].control;
      clp1->Left_offset   = shared_ram0->clp[1].offset.x;
      clp1->Top_offset    = shared_ram0->clp[1].offset.y;
      clp1->Right_offset  = shared_ram0->clp[1].clip.x;
      clp1->Bottom_offset = shared_ram0->clp[1].clip.y;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_scl_0
      sc0->Control              = shared_ram0->sc[0].control;
      shared_ram0->sc[0].status = sc0->Status;
      sc0->Output_Width         = shared_ram0->sc[0].resolution.x;
      sc0->Output_Height        = shared_ram0->sc[0].resolution.y;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_scl_1
      sc1->Control              = shared_ram0->sc[1].control;
      shared_ram0->sc[1].status = sc1->Status;
      sc1->Output_Width         = shared_ram0->sc[1].resolution.x;
      sc1->Output_Height        = shared_ram0->sc[1].resolution.y;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_mixer_0
      mix0->Control                                      = shared_ram0->mix[0].control;
      shared_ram0->mix[0].status                         = mix0->Status;
      mix0->Background_Width                             = shared_ram0->mix[0].resolution.x;
      mix0->Background_Height                            = shared_ram0->mix[0].resolution.y;
      mix0->Uniform_background_Red                       = shared_ram0->mix[0].background.red;
      mix0->Uniform_background_Green                     = shared_ram0->mix[0].background.green;
      mix0->Uniform_background_Blue                      = shared_ram0->mix[0].background.blue;
      //mix0->layer_config[0].Input_Control.Enable         = shared_ram0->mix[0].layer[0].control;
      mix0->layer_config[0].Layer_position               = shared_ram0->mix[0].layer[0].position;
      mix0->layer_config[0].X_offset                     = shared_ram0->mix[0].layer[0].offset.x;
      mix0->layer_config[0].Y_offset                     = shared_ram0->mix[0].layer[0].offset.y;
      mix0->layer_config[0].Static_Alpha                 = shared_ram0->mix[0].layer[0].alpha;
      mix0->layer_config[0].Input_Control.Alpha_Mode     = 1;
      mix0->layer_config[0].Input_Control.Enable_Consume = 0;
      //mix0->layer_config[1].Input_Control.Enable         = shared_ram0->mix[0].layer[1].control;
      mix0->layer_config[1].Layer_position               = shared_ram0->mix[0].layer[1].position;
      mix0->layer_config[1].X_offset                     = shared_ram0->mix[0].layer[1].offset.x;
      mix0->layer_config[1].Y_offset                     = shared_ram0->mix[0].layer[1].offset.y;
      mix0->layer_config[1].Static_Alpha                 = shared_ram0->mix[0].layer[1].alpha;
      mix0->layer_config[1].Input_Control.Alpha_Mode     = 1;
      mix0->layer_config[1].Input_Control.Enable_Consume = 0;
      mix0->layer_config[2].Input_Control.Enable         = shared_ram0->mix[0].layer[2].control;
      mix0->layer_config[2].Layer_position               = shared_ram0->mix[0].layer[2].position;
      mix0->layer_config[2].X_offset                     = shared_ram0->mix[0].layer[2].offset.x;
      mix0->layer_config[2].Y_offset                     = shared_ram0->mix[0].layer[2].offset.y;
      mix0->layer_config[2].Static_Alpha                 = shared_ram0->mix[0].layer[2].alpha;
      mix0->layer_config[2].Input_Control.Alpha_Mode     = 2;
      mix0->layer_config[2].Input_Control.Enable_Consume = 0;
#endif

#ifdef ALT_MODULE_CLASS_video_core_0_alt_vip_cl_cvo_0
      cvo0->Control              = shared_ram0->cvo[0].control;
      shared_ram0->cvo[0].status = cvo0->Status;
#endif

      if( get_adv_info( 0 ) || get_adv_info( 1 ) )
        reset_flash_adv7613();

      alt_u8 i;
      alt_u8 layer_control[2];
      alt_u8 layer_status[2];

      for( i = 0; i < 2; ++i ) {

        switch( shared_ram0->sw[0].output[i] ) {
      	  case 16:
      	    layer_control[i] = ( cvi3->Control & 0x00000001 );
      	    layer_status[i]  = ( ( cvi3->Status & 0x00000400 ) >> 10 );
            break;
      	  case 8:
      	    layer_control[i] = ( cvi2->Control & 0x00000001 );
      	    layer_status[i]  = ( ( cvi2->Status & 0x00000400 ) >> 10 );
      	    break;
      	  case 4:
      	    layer_control[i] = ( cvi1->Control & 0x00000001 );
      	    layer_status[i]  = ( ( cvi1->Status & 0x00000400 ) >> 10 );
      	    break;
      	  case 2:
      	    layer_control[i] = ( cvi0->Control & 0x00000001 );
      	    layer_status[i]  = ( ( cvi0->Status & 0x00000400 ) >> 10 );
      	    break;
      	  default:
      	    layer_control[i] = 0;
      	    layer_status[i]  = 0;
      	    break;
        }

        if( layer_control[i] ) {
          if( layer_status[i] ) {
            if( layer_timer[i] < LAYER_TIMEOUT )
              layer_timer[i]++;
            else
              mix0->layer_config[i].Input_Control.Enable = shared_ram0->mix[0].layer[i].control;
          } else {
            if( layer_timer[i] > 0 )
              layer_timer[i]--;
            else
              mix0->layer_config[i].Input_Control.Enable = 0;
          }
        }

      }

      if( ( lcd_type == MFD_15INCH_TYPE ) && ( ~IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE ) & GPIO_DP_XCVR_LINK ) ) {
    	if( edp_timer < ( EDP_TIMEOUT - 1 ) ) {
      	  edp_timer++;
    	} else if( edp_timer < EDP_TIMEOUT ) {
    	  edp_timer++;
          IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, GPIO_DP_HPD );
        } else {
       	  edp_timer = 0;
          IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, GPIO_DP_HPD );
        }
      }

      usleep( 10000 );

    }

  }

  return 0;

}
