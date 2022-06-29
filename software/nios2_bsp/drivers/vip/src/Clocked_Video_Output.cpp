#include "Clocked_Video_Output.hpp"

Clocked_Video_Output::Clocked_Video_Output(unsigned long base_address, int irq_number)
: VipCore(base_address, irq_number) {
}

void Clocked_Video_Output::set_output_mode(unsigned int bank_sel,
                                bool interlaced, bool sequential,
                                unsigned int sample_count, unsigned int f0_line_count, unsigned int f1_line_count,
                                unsigned int h_front_porch, unsigned int h_sync_length, unsigned int h_blanking,
                                unsigned int v_front_porch, unsigned int v_sync_length, unsigned int v_blanking,
                                unsigned int f0_v_front_porch, unsigned int f0_v_sync_length, unsigned int f0_v_blanking,
                                unsigned int active_picture_line, unsigned int f0_v_rising, unsigned int field_rising, unsigned int field_falling,
                                unsigned int ancillary_line, unsigned int f0_ancillary_line, bool h_sync_polarity, bool v_sync_polarity,
                                unsigned int vid_std, unsigned int sof_sample, unsigned int sof_line, unsigned int vco_clk_div) {
    // Select the bank to overwrite and invalidate it
    do_write(CVO_BANK_SELECT, bank_sel);
    do_write(CVO_MODEX_VALID, false);

    do_write(CVO_MODEX_CONTROL, ((sequential ? 1 : 0) << CVO_SEQUENTIAL_OUTPUT) | ((interlaced ? 1 : 0) << CVO_INTERLACED_OUTPUT));

    // Dimensions
    do_write(CVO_MODEX_SAMPLE_COUNT, sample_count);
    do_write(CVO_MODEX_F0_LINE_COUNT, f0_line_count);
    do_write(CVO_MODEX_F1_LINE_COUNT, f1_line_count);

    // Blanking
    do_write(CVO_MODEX_HORIZONTAL_FRONT_PORCH, h_front_porch);
    do_write(CVO_MODEX_HORIZONTAL_SYNC_LENGTH, h_sync_length);
    do_write(CVO_MODEX_HORIZONTAL_BLANKING, h_blanking);
    do_write(CVO_MODEX_VERTICAL_FRONT_PORCH, v_front_porch);
    do_write(CVO_MODEX_VERTICAL_SYNC_LENGTH, v_sync_length);
    do_write(CVO_MODEX_VERTICAL_BLANKING, v_blanking);
    do_write(CVO_MODEX_F0_VERTICAL_FRONT_PORCH, f0_v_front_porch);
    do_write(CVO_MODEX_F0_VERTICAL_SYNC_LENGTH, f0_v_sync_length);
    do_write(CVO_MODEX_F0_VERTICAL_BLANKING, f0_v_blanking);

    // Active data start
    do_write(CVO_MODEX_ACTIVE_PICTURE_LINE, active_picture_line);

    // Field toggle parameterization
    do_write(CVO_MODEX_F0_VERTICAL_RISING, f0_v_rising);
    do_write(CVO_MODEX_FIELD_RISING, field_rising);
    do_write(CVO_MODEX_FIELD_FALLING, field_falling);

    // Ancillary data insertion
    do_write(CVO_MODEX_ANCILLARY_LINE, ancillary_line);
    do_write(CVO_MODEX_F0_ANCILLARY_LINE, f0_ancillary_line);

    // h_sync/v_sync polarity
    do_write(CVO_MODEX_HSYNC_POLARITY, h_sync_polarity);
    do_write(CVO_MODEX_VSYNC_POLARITY, v_sync_polarity);

    // Genlock params
    do_write(CVO_MODEX_STANDARD, vid_std);
    do_write(CVO_MODEX_SOF_SAMPLE, sof_sample);
    do_write(CVO_MODEX_SOF_LINE, sof_line);
    do_write(CVO_MODEX_VCO_CLK_DIVIDER, vco_clk_div);

    // Revalidate the bank
    do_write(CVO_MODEX_VALID, true);
}

