/*
 * gpio.h
 *
 *  Created on: 21 марта 2020 г.
 *      Author: gchigirev
 */

#ifndef GPIO_H
#define GPIO_H

#include "alt_types.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"

#define GPIO_RK_IN0                ( 1 <<  0 )
#define GPIO_RK_IN1                ( 1 <<  1 )
#define GPIO_RK_IN2                ( 1 <<  2 )
#define GPIO_RK_IN3                ( 1 <<  3 )
#define GPIO_RK_IN4                ( 1 <<  4 )
#define GPIO_RK_IN5                ( 1 <<  5 )
#define GPIO_RK_IN6                ( 1 <<  6 )
#define GPIO_RK_IN7                ( 1 <<  7 )
#define GPIO_LCD_BKLT_FLT          ( 1 <<  8 )
#define GPIO_DP_XCVR_LINK          ( 1 <<  9 )
#define GPIO_DDR_BOT_LOCKED        ( 1 << 10 )
#define GPIO_DDR_TOP_LOCKED        ( 1 << 11 )
#define GPIO_DDR_BOT_CAL_SUCCESS   ( 1 << 12 )
#define GPIO_DDR_TOP_CAL_SUCCESS   ( 1 << 13 )
#define GPIO_DDR_BOT_CAL_FAIL      ( 1 << 14 )
#define GPIO_DDR_TOP_CAL_FAIL      ( 1 << 15 )
#define GPIO_DDR_BOT_INIT_DONE     ( 1 << 16 )
#define GPIO_DDR_TOP_INIT_DONE     ( 1 << 17 )

#define GPIO_PCIE_CKREQ            ( 1 <<  0 )
#define GPIO_PCIE_PRSNT            ( 1 <<  1 )
#define GPIO_DP_RESET_N            ( 1 <<  2 )
#define GPIO_LVDS_RESET_N          ( 1 <<  3 )
#define GPIO_TMDS_RESET_N          ( 1 <<  4 )
#define GPIO_AV_RESET_N            ( 1 <<  5 )
#define GPIO_ADV7181_RESET         ( 1 <<  6 )
#define GPIO_ADV7613_RESET         ( 1 <<  7 )
#define GPIO_ADV7613_CS0           ( 1 <<  8 )
#define GPIO_ADV7613_CS1           ( 1 <<  9 )
#define GPIO_TMDS171_OE            ( 1 << 10 )
#define GPIO_ADV7123_PSAVE_N       ( 1 << 11 )
#define GPIO_LVDS_LCD_MODE         ( 1 << 12 )
#define GPIO_LVDS_LCD_SCAN         ( 1 << 13 )
#define GPIO_OUT1_EN_N             ( 1 << 14 )
#define GPIO_OUT3_EN_N             ( 1 << 15 )
#define GPIO_LCD_BKLT_EN0          ( 1 << 16 )
#define GPIO_LCD_BKLT_EN1          ( 1 << 17 )
#define GPIO_DP_TEST               ( 1 << 18 )
#define GPIO_DP_HPD                ( 1 << 19 )
#define GPIO_IMX6_ALPHA            ( 1 << 20 )
#define GPIO_IP_RESET_N            ( 1 << 21 )
#define GPIO_NIOS_HEART_BEAT       ( 1 << 22 )
#define GPIO_DDR_BOT_GLOBAL_RESET  ( 1 << 23 )
#define GPIO_DDR_TOP_GLOBAL_RESET  ( 1 << 24 )
#define GPIO_DDR_BOT_SOFT_RESET    ( 1 << 25 )
#define GPIO_DDR_TOP_SOFT_RESET    ( 1 << 26 )

#define GPIO_PU_TYPE_MASK          ( 0x18000000 )
#define GPIO_PU_TYPE_SHIFT         ( 27         )

#define GPIO_LCD_SIZE_MASK         ( 0x000C0000 )
#define GPIO_LCD_SIZE_SHIFT        ( 18         )
#define MFD_15INCH_TYPE            ( 0x02       )
#define MFD_12INCH_TYPE            ( 0x01       )
#define MFD_10INCH_TYPE            ( 0x00       )

#define GPIO_MILSTD1553_ADDR_MASK  ( 0x01F00000 )
#define GPIO_MILSTD1553_ADDR_SHIFT ( 20         )

#define GPIO_DDR_READY             ( GPIO_DDR_BOT_LOCKED      | \
                                     GPIO_DDR_TOP_LOCKED      | \
                                     GPIO_DDR_BOT_CAL_SUCCESS | \
                                     GPIO_DDR_TOP_CAL_SUCCESS | \
                                     GPIO_DDR_BOT_INIT_DONE   | \
                                     GPIO_DDR_TOP_INIT_DONE )

alt_u32 gpio_get( alt_u32 mask )
{
	/*
	alt_u32 state = IORD_32DIRECT( PIO_0_BASE, 0 );
	return ( state & mask );
	*/
	alt_u32 state = IORD_ALTERA_AVALON_PIO_DATA( PIO_0_BASE );
	return ( state & mask );
}

void gpio_set( alt_u32 mask )
{
	/*
	alt_u32 state = IORD_32DIRECT( PIO_0_BASE, 0 );
	IOWR_32DIRECT( PIO_0_BASE, 0, ( state | mask ) );
	*/
	IOWR_ALTERA_AVALON_PIO_SET_BITS( PIO_0_BASE, mask );
}

void gpio_clear( alt_u32 mask )
{
	/*
	alt_u32 state = IORD_32DIRECT( PIO_0_BASE, 0 );
	IOWR_32DIRECT( PIO_0_BASE, 0, ( state & ~mask ) );
	*/
	IOWR_ALTERA_AVALON_PIO_CLEAR_BITS( PIO_0_BASE, mask );
}

#endif /* GPIO_H */
