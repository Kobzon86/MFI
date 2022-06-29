/*
 * types.h
 *
 *  Created on: 7 апр. 2020 г.
 *      Author: Evgeniy
 */

#ifndef TYPES_H_
#define TYPES_H_

#include "alt_types.h"

typedef struct{
	alt_u8 addr;
	alt_u8 data;
} i2c_reg_t;

#endif /* TYPES_H_ */
