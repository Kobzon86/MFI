#ifndef VIDEO_MODES_H
#define VIDEO_MODES_H

#include "alt_types.h"
#include "video.h"

extern struct scaler_ctrl* scaler0;
extern struct scaler_ctrl* scaler1;
extern struct scaler_ctrl* scaler2;
extern struct mixer_ctrl*  mix    ;
extern struct switch_ctrl* sw     ;
extern struct cvi_ctrl*    cvi0   ;
extern struct cvi_ctrl*    cvi1   ;
extern struct cvi_ctrl*    cvi2   ;
extern struct cvi_ctrl*    cvi3   ;
extern struct cvi_ctrl*    cvi4   ;
extern struct cvo_ctrl*    cvo    ;

extern alt_u32 screen_width;
extern alt_u32 screen_height;

/*
 * в”Њв”Ђв”Ђв”Ђв”¬в”Ђв”Ђв”Ђв”ђ
 * в”‚ 1 в”‚в–‘2в–‘в”‚
 * в”‚   в”‚в–‘в–‘в–‘в”‚
 * в””в”Ђв”Ђв”Ђв”ґв”Ђв”Ђв”Ђв”�
 * 1 - Р’Рѕ РІРµСЃСЊ СЌРєСЂР°РЅ, РЅРµРїСЂРѕР·СЂР°С‡РЅС‹Р№
 * 2 - РџСЂР°РІР°СЏ РїРѕР»РѕРІРёРЅР° СЌРєСЂР°РЅР°, РїСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ 25%
 */
void split_alpha() {
	set_scaler(scaler0, 1, screen_width, screen_height);
	set_scaler(scaler1, 1, screen_width / 2, screen_height);
	set_scaler(scaler2, 1, screen_width, screen_height);
	set_layer_cfg(&mix->layer_config[0], 0, 1, 0, 0, 0, 0);
	set_layer_cfg(&mix->layer_config[1], 1, 1, 0, screen_width / 2, 1, 64);
}

/*
 * в”Њв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”ђ
 * в”‚ 1 в”Њв”Ђв”Ђв”Ђв”¤
 * в”‚   в”‚2  в”‚
 * в””в”Ђв”Ђв”Ђв”ґв”Ђв”Ђв”Ђв”�
 * 1 - Р’Рѕ РІРµСЃСЊ СЌРєСЂР°РЅ, РЅРµРїСЂРѕР·СЂР°С‡РЅС‹Р№
 * 2 - 40% РѕС‚ РІС‹С…РѕРґРЅРѕРіРѕ СЂР°Р·РјРµСЂР° СЌРєСЂР°РЅР° РїСЂР°РІС‹Р№ РЅРёР¶РЅРёР№ СѓРіРѕР», РїСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ 30%
 */
void pip() {
	const alt_u32 board = 30;		// РџРёРєСЃРµР»Рё
	const double opacity = 0.3; 	// Р’ РїСЂРѕС†РµРЅС‚Р°С…
	set_scaler(scaler0, 1, screen_width, screen_height);
	set_scaler(scaler1, 1, screen_width * 2 / 5, screen_height * 2 / 5);
	set_scaler(scaler2, 1, screen_width, screen_height);
	set_layer_cfg(&mix->layer_config[0], 0, 1, 0, 0, 0, 0);
	set_layer_cfg(&mix->layer_config[1], 1, 1, screen_height - scaler1->Output_Height - board, screen_width - scaler1->Output_Width - board, 1, (alt_u32)(opacity * 255));
}


/*
 * в”Њв”Ђв”Ђв”Ђв”Ђв”¬в”Ђв”Ђв”ђ
 * в”‚1 в”Њв”Ђв”ґв”Ђв”Ђв”¤
 * в”њв”Ђв”Ђв”¤ 2  в”‚
 * в””в”Ђв”Ђв”ґв”Ђв”Ђв”Ђв”Ђв”�
 * 1 - 3/4 СЌРєСЂР°РЅР°, Р»РµРІС‹Р№ РІРµСЂС…РЅРёР№ СѓРіРѕР», РЅРµРїСЂРѕР·СЂР°С‡РЅС‹Р№
 * 2 - 3/4 СЌРєСЂР°РЅР°, РїСЂР°РІС‹Р№ РЅРёР¶РЅРёР№ СѓРіРѕР», РЅРµРїСЂРѕР·СЂР°С‡РЅС‹Р№
 */
void layers() {
	set_scaler(scaler0, 1, (screen_width >> 2) * 3, (screen_height >> 2) * 3);
	set_scaler(scaler1, 1, (screen_width >> 2) * 3, (screen_height >> 2) * 3);
	set_scaler(scaler2, 1, screen_width, screen_height);
	set_layer_cfg(&mix->layer_config[0], 0, 1, 0, 0, 0, 0);
	set_layer_cfg(&mix->layer_config[1], 1, 1, screen_height - scaler1->Output_Height, screen_width - scaler1->Output_Width, 0, 0);
}


/*
 * в”Њв”Ђв”Ђв”Ђв”¬в”Ђв”Ђв”Ђв”ђ
 * в”‚ 1 в”‚ 2 в”‚
 * в”‚   в”‚   в”‚
 * в””в”Ђв”Ђв”Ђв”ґв”Ђв”Ђв”Ђв”�
 * 1 - 1/2 С€РёСЂРёРЅС‹, Р»РµРІР°СЏ РїРѕР»РѕРІРёРЅР° СЌРєСЂР°РЅР°
 * 2 - 1/2 С€РёСЂРёРЅС‹, РїСЂР°РІР°СЏ РїРѕР»РѕРІРёРЅР° СЌРєСЂР°РЅР°
 */
void split_screen() {
	set_scaler(scaler0, 1, screen_width / 2, screen_height);
	set_scaler(scaler1, 1, screen_width / 2, screen_height);
	set_scaler(scaler2, 1, screen_width, screen_height);
	set_layer_cfg(&mix->layer_config[0], 0, 1, 0, 0, 0, 0);
	set_layer_cfg(&mix->layer_config[1], 1, 1, 0, screen_width / 2, 0, 0);
	set_layer_cfg(&mix->layer_config[2], 2, 1, 0, 0, 2, 0);
}

/*
 * в”Њв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”ђ
 * в”‚ 1/2в–‘в–‘в–‘в”‚
 * в”‚в–‘в–‘в–‘в–‘в–‘в–‘в–‘в”‚
 * в””в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”�
 * 1 - Р’Рѕ РІРµСЃСЊ СЌРєСЂР°РЅ, РЅРµРїСЂРѕР·СЂР°С‡РЅС‹Р№
 * 2 - Р’Рѕ РІРµСЃСЊ СЌРєСЂР°РЅ, РїСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ РїРѕРїРёРєСЃРµР»СЊРЅР°СЏ
 */

void cpu_alpha() {
	set_scaler(scaler0, 1, screen_width, screen_height);
	set_scaler(scaler1, 1, screen_width, screen_height);
	set_scaler(scaler2, 1, screen_width, screen_height);
	set_layer_cfg(&mix->layer_config[0], 0, 1, 0, 0, 1, 0);
	set_layer_cfg(&mix->layer_config[1], 1, 0, 0, 0, 0, 0);
	set_layer_cfg(&mix->layer_config[2], 2, 0, 0, 0, 1, 128);
}

void freeplace(alt_u32 x0, alt_u32 y0, alt_u32 w0, alt_u32 h0, alt_u32 a0, alt_u32 x1, alt_u32 y1, alt_u32 w1, alt_u32 h1, alt_u32 a1) {
	set_layer_cfg(&mix->layer_config[0], 0, 1, y0, x0, (a0 > 0) ? 1 : 0, a0);
	set_layer_cfg(&mix->layer_config[1], 1, 1, y1, x1, (a1 > 0) ? 1 : 0, a1);
	set_scaler(scaler0, 1, w0, h0);
	set_scaler(scaler1, 1, w1, h1);
	set_scaler(scaler2, 1, screen_width, screen_height);
}


#endif
