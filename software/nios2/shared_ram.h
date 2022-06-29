/*
 * shared_ram.h
 *
 *  Created on: 21 марта 2020 г.
 *      Author: gchigirev
 */

#ifndef SHARED_RAM_H
#define SHARED_RAM_H

#include "alt_types.h"

struct shared_res {
	alt_u16 y;
	alt_u16 x;
};

struct shared_color {
	alt_u8 alpha;
	alt_u8 red;
	alt_u8 green;
	alt_u8 blue;
};

struct shared_sys {
  alt_u8  version_checksum;
  alt_u8  local_version;
  alt_u8  sub_version;
  alt_u8  version;
  alt_u32 checksum;
  alt_u32 runtime;
  alt_u32 alpha;
};

struct shared_cvi {
	alt_u32 control;
	alt_u32 status;
	struct  shared_res resolution;
	alt_u32 reserved;
};

struct shared_clp {
	alt_u32 control;
	struct  shared_res offset;
	struct  shared_res clip;
	alt_u32 reserved;
};

struct shared_sw {
	alt_u32 control;
	alt_u32 status;
	alt_u32 output[2];
};

struct shared_sc {
	alt_u32 control;
	alt_u32 status;
	struct shared_res resolution;
	alt_u32 reserved;
};

struct shared_layer {
	alt_u8 control;
	alt_u8 position;
	alt_u8 reserved[2];
	struct shared_res offset;
	alt_u8 alpha;
	alt_u8 reserved2[7];
};

struct shared_mix {
	alt_u32 control;
	alt_u32 status;
	struct shared_res   resolution;
	struct shared_color background;
	struct shared_layer layer[3];
};

struct shared_cvo {
	alt_u32 control;
	alt_u32 status;
	alt_u8  reserved[8];
};

struct shared_ram {
	struct shared_sys sys;    //  16 byte : 0x00000000..0x0000000F
	struct shared_cvi cvi[5]; //  80 byte : 0x00000010..0x0000005F
	struct shared_sw  sw[1];  //  16 byte : 0x00000060..0x0000006F
	struct shared_sc  sc[3];  //  48 byte : 0x00000070..0x0000009F
	struct shared_mix mix[1]; //  64 byte : 0x000000A0..0x000000DF
	struct shared_cvo cvo[1]; //  16 byte : 0x000000E0..0x000000EF
	struct shared_clp clp[2]; //  32 byte : 0x000000F0..0x0000010F
};

#define SHARED_RAM_COMMON_SYS_ID           ( 0x00000000 )
#define SHARED_RAM_COMMON_TIMESTAMP        ( 0x00000004 )
#define SHARED_RAM_COMMON_RUNTIME          ( 0x00000008 )
#define SHARED_RAM_COMMON_LCD_TYPE         ( 0x0000000C )
#define SHARED_RAM_COMMON_FW_UPDATE        ( 0x0000000C )

#define SHARED_RAM_COMMON_CVI0_CONTROL     ( 0x00000010 )
#define SHARED_RAM_COMMON_CVI0_STATUS      ( 0x00000014 )
#define SHARED_RAM_COMMON_CVI0_RESOLUTUION ( 0x00000018 )

#define SHARED_RAM_COMMON_CVI1_CONTROL     ( 0x00000020 )
#define SHARED_RAM_COMMON_CVI1_STATUS      ( 0x00000024 )
#define SHARED_RAM_COMMON_CVI1_RESOLUTUION ( 0x00000028 )

#define SHARED_RAM_COMMON_CVI2_CONTROL     ( 0x00000030 )
#define SHARED_RAM_COMMON_CVI2_STATUS      ( 0x00000034 )
#define SHARED_RAM_COMMON_CVI2_RESOLUTUION ( 0x00000038 )

#define SHARED_RAM_COMMON_CVI3_CONTROL     ( 0x00000040 )
#define SHARED_RAM_COMMON_CVI3_STATUS      ( 0x00000044 )
#define SHARED_RAM_COMMON_CVI3_RESOLUTUION ( 0x00000048 )

#define SHARED_RAM_COMMON_CVI4_CONTROL     ( 0x00000050 )
#define SHARED_RAM_COMMON_CVI4_STATUS      ( 0x00000054 )
#define SHARED_RAM_COMMON_CVI4_RESOLUTUION ( 0x00000058 )

#define SHARED_RAM_COMMON_SW0_CONTROL      ( 0x00000060 )
#define SHARED_RAM_COMMON_SW0_STATUS       ( 0x00000064 )
#define SHARED_RAM_COMMON_SW0_OUTPUT0      ( 0x00000068 )
#define SHARED_RAM_COMMON_SW0_OUTPUT1      ( 0x0000006C )

#define SHARED_RAM_COMMON_SC0_CONTROL      ( 0x00000070 )
#define SHARED_RAM_COMMON_SC0_STATUS       ( 0x00000074 )
#define SHARED_RAM_COMMON_SC0_RESOLUTUION  ( 0x00000078 )

#define SHARED_RAM_COMMON_SC1_CONTROL      ( 0x00000080 )
#define SHARED_RAM_COMMON_SC1_STATUS       ( 0x00000084 )
#define SHARED_RAM_COMMON_SC1_RESOLUTUION  ( 0x00000088 )

#define SHARED_RAM_COMMON_SC2_CONTROL      ( 0x00000090 )
#define SHARED_RAM_COMMON_SC2_STATUS       ( 0x00000094 )
#define SHARED_RAM_COMMON_SC2_RESOLUTUION  ( 0x00000098 )

#define SHARED_RAM_COMMON_MIX0_CONTROL     ( 0x000000A0 )
#define SHARED_RAM_COMMON_MIX0_STATUS      ( 0x000000A4 )
#define SHARED_RAM_COMMON_MIX0_RESOLUTUION ( 0x000000A8 )
#define SHARED_RAM_COMMON_MIX0_BACKGROUND  ( 0x000000AC )

#define SHARED_RAM_COMMON_LY0_CONTROL      ( 0x000000B0 )
#define SHARED_RAM_COMMON_LY0_OFFSET       ( 0x000000B4 )
#define SHARED_RAM_COMMON_LY0_ALPHA        ( 0x000000B8 )

#define SHARED_RAM_COMMON_LY1_CONTROL      ( 0x000000C0 )
#define SHARED_RAM_COMMON_LY1_OFFSET       ( 0x000000C4 )
#define SHARED_RAM_COMMON_LY1_ALPHA        ( 0x000000C8 )

#define SHARED_RAM_COMMON_LY2_CONTROL      ( 0x000000D0 )
#define SHARED_RAM_COMMON_LY2_OFFSET       ( 0x000000D4 )
#define SHARED_RAM_COMMON_LY2_ALPHA        ( 0x000000D8 )

#define SHARED_RAM_COMMON_CVO0_CONTROL     ( 0x000000E0 )
#define SHARED_RAM_COMMON_CVO0_STATUS      ( 0x000000E4 )
#define SHARED_RAM_COMMON_CVO0_RESOLUTION  ( 0x000000F0 )
#define SHARED_RAM_COMMON_CVO0_FRONTPORCH  ( 0x000000F4 )
#define SHARED_RAM_COMMON_CVO0_SYNCLENGTH  ( 0x000000F8 )
#define SHARED_RAM_COMMON_CVO0_BACKPORCH   ( 0x000000FC )

#define CVI_CONTROL_MASK                   ( 0x00000001 )
#define CVI_STATUS_MASK                    ( 0x00000001 )
#define SW_CONTROL_MASK                    ( 0x00000001 )
#define SW_STATUS_MASK                     ( 0x00000001 )
#define SW_OUTPUT_MASK                     ( 0x00000007 )
#define SC_CONTROL_MASK                    ( 0x00000001 )
#define SC_STATUS_MASK                     ( 0x00000001 )
#define MIX_CONTROL_MASK                   ( 0x00000001 )
#define MIX_STATUS_MASK                    ( 0x00000001 )
#define LY_CONTROL_MASK                    ( 0x00000001 )
#define LY_ALPHA_MASK                      ( 0x000000FF )
#define CVO_CONTROL_MASK                   ( 0x00000001 )
#define CVO_STATUS_MASK                    ( 0x00000001 )

#define GET_RESOLUTION_WIDTH( VAL )        ( (alt_u32)( VAL & 0x0000FFFF )           )
#define GET_RESOLUTION_HEIGHT( VAL )       ( (alt_u32)( ( VAL & 0xFFFF0000 ) >> 16 ) )
#define GET_RED_COLOR( VAL )               ( (alt_u32)( ( VAL & 0x00FF0000 ) >> 16 ) )
#define GET_GREEN_COLOR( VAL )             ( (alt_u32)( ( VAL & 0x0000FF00 ) >>  8 ) )
#define GET_BLUE_COLOR( VAL )              ( (alt_u32)( VAL & 0x000000FF ) )
#define GET_LY_POSITION( VAL )             ( (alt_u32)( ( VAL & 0x00000030 ) >> 4 ) )



#define FACTORY_CONTROL                    ( 0x00000000 )
#define FACTORY_SECTOR                     ( 0x00000004 )
#define FACTORY_BANK                       ( 0x00000008 )
#define FACTORY_CHECKSUM                   ( 0x0000000C )

#define FACTORY_CONTROL_READY              ( 0x00000000 )
#define FACTORY_CONTROL_BUSY               ( 0x00000001 )
#define FACTORY_CONTROL_READ               ( 0x00000002 )
#define FACTORY_CONTROL_WRITE              ( 0x00000004 )
#define FACTORY_CONTROL_CHECK              ( 0x00000008 )
#define FACTORY_CONTROL_UPDATE             ( 0x00000010 )
#define FACTORY_CONTROL_EEPROM_FAIL        ( 0x00000010 )
#define FACTORY_CONTROL_BOOT               ( 0x00000020 )
#define FACTORY_CONTROL_BOOT_FAIL          ( 0x00000020 )
#define FACTORY_CONTROL_BANK_FAIL          ( 0x00000040 )
#define FACTORY_CONTROL_SECTOR_FAIL        ( 0x00000080 )

#define SHARED_RAM_FACTORY_VERSION_A       ( 0x00000000 )
#define SHARED_RAM_FACTORY_TIMESTAMP_A     ( 0x00000004 )
#define SHARED_RAM_FACTORY_VERSION_B       ( 0x00000008 )
#define SHARED_RAM_FACTORY_TIMESTAMP_B     ( 0x0000000C )

#define SHARED_RAM_FACTORY_LCD_TYPE        ( 0x00000010 )



#endif /* SHARED_RAM_H */
