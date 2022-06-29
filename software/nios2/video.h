/*
 * structs.h
 *
 *  Created on: Feb 5, 2020
 *      Author: rash
 */

#ifndef VIDEO_H
#define VIDEO_H

#include "alt_types.h"

struct pio_ctrl
{
	alt_u32 data;
	alt_u32 direction;
	alt_u32 interruptmask;
	alt_u32 edgecapture;
	alt_u32 outset;
	alt_u32 outclear;
};

struct scaler_ctrl
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Output_Width;
	alt_u32 Output_Height;
	alt_u32 Edge_Threshold;
};

struct layer_ctrl
{
	unsigned Enable : 1;
	unsigned Enable_Consume : 1;
	unsigned Alpha_Mode : 2;
	unsigned Unused : 28;
};

struct layer_cfg
{
	alt_u32 X_offset;
	alt_u32 Y_offset;
	struct layer_ctrl Input_Control;
	alt_u32 Layer_position;
	alt_u32 Static_Alpha;
};

struct mixer_ctrl
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Reserved;
	alt_u32 Background_Width;
	alt_u32 Background_Height;
	alt_u32 Uniform_background_Red;
	alt_u32 Uniform_background_Green;
	alt_u32 Uniform_background_Blue;
	struct layer_cfg layer_config[3];
};

struct switch_ctrl
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Output_Switch;
	alt_u32 Output_Ctrl[2];
	alt_u32 Consume_Mode;
};

struct cvo_ctrl
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Video_Mode_Match;
	alt_u32 Bank_Select;
	alt_u32 ModeX_Control;
	alt_u32 ModeX_Sample_Count;
	alt_u32 ModeX_F0_Line_Count;
	alt_u32 ModeX_F1_Line_Count;
	alt_u32 ModeX_Horizontal_Front_Porch;
	alt_u32 ModeX_Horizontal_Sync_Length;
	alt_u32 ModeX_Horizontal_Blanking;
	alt_u32 ModeX_Vertical_Front_Porch;
	alt_u32 ModeX_Vertical_Sync_Length;
	alt_u32 ModeX_Vertical_Blanking;
	alt_u32 ModeX_F0_Vertical_Front_Porch;
	alt_u32 ModeX_F0_Vertical_Sync_Length;
	alt_u32 ModeX_F0_Vertical_Blanking;
	alt_u32 ModeX_Active_Picture_Line;
	alt_u32 ModeX_F0_Vertical_Rising;
	alt_u32 ModeX_Field_Rising;
	alt_u32 ModeX_Field_Falling;
	alt_u32 ModeX_Standart;
	alt_u32 ModeX_SOF_Sample;
	alt_u32 ModeX_SOF_Line;
	alt_u32 ModeX_Vcoclk_Divider;
	alt_u32 ModeX_Ancillary_Line;
	alt_u32 ModeX_F0_Ancillary_Line;
	alt_u32 ModeX_HSync_Polarity;
	alt_u32 ModeX_VSync_Polarity;
	alt_u32 ModeX_Valid;
};

struct fb_reader
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Frame_Counter;
	alt_u32 Drop_Repeat_Counter;
	alt_u32 Frame_Information;
	alt_u32 Frame_Start_Address;
	alt_u32 Frame_Reader;
	alt_u32 Misc;
};

struct cvi_ctrl
{
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Used_Words;
	alt_u32 Active_Sample_Count;
	alt_u32 F0_Active_Line_Count;
	alt_u32 F1_Active_Line_Count;
	alt_u32 Total_Sample_Count;
	alt_u32 F0_Total_Line_Count;
	alt_u32 F1_Total_Line_Count;
	alt_u32 Standart;
	alt_u32 Reserved[3];
	alt_u32 Color_Pattern;
};

struct clipper_ctrl {
	alt_u32 Control;
	alt_u32 Status;
	alt_u32 Interrupt;
	alt_u32 Left_offset;
	alt_u32 Right_offset;
	alt_u32 Top_offset;
	alt_u32 Bottom_offset;
};

void init_clp(struct clipper_ctrl *clp, alt_u32 Control){
	clp->Control = Control;
}

void set_rectangle(struct clipper_ctrl *clp, alt_u32 x0, alt_u32 y0, alt_u32 x1, alt_u32 y1){
	clp->Left_offset = x0;
	clp->Top_offset = y0;
	clp->Right_offset = x1;
	clp->Bottom_offset = y1;
}

void init_cvi(struct cvi_ctrl *cvi, alt_u32 Control)
{
	cvi->Control = Control;
}

void set_scaler(struct scaler_ctrl *scl, alt_u32 Control, alt_u32 Output_Width, alt_u32 Output_Height)
{
	scl->Control = Control;
	scl->Output_Width = Output_Width;
	scl->Output_Height = Output_Height;
}

void set_layer_cfg(struct layer_cfg *lyr, alt_u32 Layer_position, alt_u32 Enable, alt_u32 X_offset, alt_u32 Y_offset, alt_u32 Alpha_Mode, alt_u32 Static_Alpha)
{
	lyr->X_offset = X_offset;
	lyr->Y_offset = Y_offset;
	lyr->Static_Alpha = Static_Alpha;
	lyr->Layer_position = Layer_position;
	lyr->Input_Control.Enable = Enable;
	lyr->Input_Control.Alpha_Mode = Alpha_Mode;
	lyr->Input_Control.Enable_Consume = 0;
}

void set_mixer_background(struct mixer_ctrl *mix, alt_u32 Red, alt_u32 Green, alt_u32 Blue)
{
	mix->Uniform_background_Red = Red;
	mix->Uniform_background_Green = Green;
	mix->Uniform_background_Blue = Blue;
}

void init_mixer(struct mixer_ctrl *mix, alt_u32 Background_Width, alt_u32 Background_Height)
{
	mix->Background_Height = Background_Height;
	mix->Background_Width = Background_Width;
	set_mixer_background(mix, 254, 97, 0);
	for (alt_u32 i = 0; i < 4; i++)
		set_layer_cfg(&mix->layer_config[i], i, 0, 0, 0, 0, 0);
	mix->Control = 1;
}

void set_switch(struct switch_ctrl *sw, alt_u32 Control, alt_u32 Out0, alt_u32 Out1)
{
	sw->Control = Control;
	sw->Output_Ctrl[0] = Out0;
	sw->Output_Ctrl[1] = Out1;
	sw->Output_Switch = 1;
}

alt_u32 get_status(alt_u32 *ptr)
{
	return *(ptr++);
}

void init_switch(struct switch_ctrl *sw)
{
	sw->Control = 1;
}

void set_CVO_1024(struct cvo_ctrl *cvo)
{
	cvo->Bank_Select = 1;
	cvo->ModeX_Valid = 0;

	cvo->ModeX_Control = 0;

	// Dimensions
	cvo->ModeX_Sample_Count = 1024;
	cvo->ModeX_F0_Line_Count = 768;
	cvo->ModeX_F1_Line_Count = 0;

	// Blanking
	cvo->ModeX_Horizontal_Front_Porch = 24;
	cvo->ModeX_Horizontal_Sync_Length = 136;
	cvo->ModeX_Horizontal_Blanking = 320;
	cvo->ModeX_Vertical_Front_Porch = 3;
	cvo->ModeX_Vertical_Sync_Length = 6;
	cvo->ModeX_Vertical_Blanking = 38;
	cvo->ModeX_F0_Vertical_Front_Porch = 0;
	cvo->ModeX_F0_Vertical_Sync_Length = 0;
	cvo->ModeX_F0_Vertical_Blanking = 0;

	// Active data start
	cvo->ModeX_Active_Picture_Line = 0; // �� �� ���, ��� � 135

	// Field toggle parameterization
	cvo->ModeX_F0_Vertical_Rising = 0;
	cvo->ModeX_Field_Rising = 0;
	cvo->ModeX_Field_Falling = 0;

	// Ancillary data insertion
	cvo->ModeX_Ancillary_Line = 0;
	cvo->ModeX_F0_Ancillary_Line = 0;

	// h_sync/v_sync polarity
	cvo->ModeX_HSync_Polarity = 0;
	cvo->ModeX_VSync_Polarity = 0;

	// Genlock params
	cvo->ModeX_Standart = 0;
	cvo->ModeX_SOF_Sample = 0;
	cvo->ModeX_SOF_Line = 0;
	cvo->ModeX_Vcoclk_Divider = 0;

	// Revalidate the bank
	cvo->ModeX_Valid = 1;

	cvo->Control = 1;
}

void update_switch(struct switch_ctrl *sw, alt_u32 out_port, alt_u32 in_port)
{
	sw->Output_Ctrl[out_port] = 1 << in_port;
	sw->Output_Switch = 1;
}

void set_CVO_1920(struct cvo_ctrl *cvo)
{
	cvo->Bank_Select = 1;
	cvo->ModeX_Valid = 0;

	cvo->ModeX_Control = 0;

	// Dimensions
	cvo->ModeX_Sample_Count = 1920;
	cvo->ModeX_F0_Line_Count = 1080;
	cvo->ModeX_F1_Line_Count = 0;

	// Blanking
	cvo->ModeX_Horizontal_Front_Porch = 88; //88
	cvo->ModeX_Horizontal_Sync_Length = 44;
	cvo->ModeX_Horizontal_Blanking = 280;
	cvo->ModeX_Vertical_Front_Porch = 4;
	cvo->ModeX_Vertical_Sync_Length = 5;
	cvo->ModeX_Vertical_Blanking = 45;
	cvo->ModeX_F0_Vertical_Front_Porch = 0;
	cvo->ModeX_F0_Vertical_Sync_Length = 0;
	cvo->ModeX_F0_Vertical_Blanking = 0;

	// Active data start
	cvo->ModeX_Active_Picture_Line = 135; // �� �� ���, ��� � 135(42)

	// Field toggle parameterization
	cvo->ModeX_F0_Vertical_Rising = 0;
	cvo->ModeX_Field_Rising = 0;
	cvo->ModeX_Field_Falling = 0;

	// Ancillary data insertion
	cvo->ModeX_Ancillary_Line = 10;
	cvo->ModeX_F0_Ancillary_Line = 0;

	// h_sync/v_sync polarity
	cvo->ModeX_HSync_Polarity = 0;
	cvo->ModeX_VSync_Polarity = 0;

	// Genlock params
	cvo->ModeX_Standart = 0;
	cvo->ModeX_SOF_Sample = 0;
	cvo->ModeX_SOF_Line = 0;
	cvo->ModeX_Vcoclk_Divider = 0;

	// Revalidate the bank
	cvo->ModeX_Valid = 1;

	cvo->Control = 1;
}

void init_cvo(struct cvo_ctrl *cvo, alt_u32 mode)
{
	cvo->Control = 1;
	if (mode == 0)
		set_CVO_1024(cvo);
	else
		set_CVO_1920(cvo);
}

#endif /* VIDEO_H */
