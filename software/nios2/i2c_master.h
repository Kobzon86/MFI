/*
 * i2c_master.h
 *
 *  Created on: 21 марта 2020 г.
 *      Author: gchigirev
 */

#ifndef I2C_MASTER_H
#define I2C_MASTER_H

#include "system.h"

typedef struct {
	alt_u8 addr;
	alt_u8 reg;
	alt_u8 value;
} i2c_registers_t;

alt_u8 i2c_read( alt_u8 addr, alt_u8 reg )
{
  alt_u32 address = ( ( ( (alt_u32)addr << 8 ) & 0x0000FF00 ) | ( (alt_u32)reg & 0x000000FF ) );
  alt_u8 result = IORD_8DIRECT( AMS_I2C_0_BASE, address );
  return result;
}

void i2c_write( alt_u8 addr, alt_u8 reg, alt_u8 data )
{
	alt_u8 status = 0;
	alt_u32 retry = 100;
    alt_u32 address = ( ( ( (alt_u32)addr << 8 ) & 0x0000FF00 ) | ( (alt_u32)reg & 0x000000FF ) );
    while ( retry > 0) {
		IOWR_8DIRECT( AMS_I2C_0_BASE, address, data );
		status = (IORD_8DIRECT( AMS_I2C_0_BASE, address | (1 << 8)) & 0xFB);
		if (status != 0)
			retry--;
		else
			break;
    }
}

void i2c_write_array( const i2c_registers_t* array, const alt_u32 count )
{
  alt_u32 i;
  for( i = 0; i < count; i++ )
    i2c_write( array[i].addr, array[i].reg, array[i].value );
}

void i2c_compare_array( const i2c_registers_t* array, const alt_u32 count )
{
  alt_u32 i;
  alt_u8 readed = 0;
  alt_u8 must_be = 0;
  for( i = 0; i < count; i++ ){
	readed =  i2c_read(array[i].addr,array[i].reg);
	must_be = array[i].value;
    if(readed != must_be)
    	i2c_write( array[i].addr, array[i].reg, array[i].value );
  }
}

#endif /* I2C_MASTER_H */
