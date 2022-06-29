#ifndef __CLOCKED_VIDEO_OUTPUT_HPP__
#define __CLOCKED_VIDEO_OUTPUT_HPP__

#include "VipCore.hpp"

// Some convenient defines to use when calling the set_output_mode function

//                     interl,   seq, width, height, f1_h,      h blanking,  v_blanking,   f0_blanking,  active_line, field_toggles, ancillary,   sync_pol,
#define CVO_1080P_MODE  false, false,  1920,   1080,    0,     88, 44, 280,    4, 5, 45,       0, 0, 0,           42,       0, 0, 0,     10, 0, true, true
#define CVO_2160P_MODE  false, false,  3840,   2160,    0,    176, 88, 560,   8, 10, 90,       0, 0, 0,           84,       0, 0, 0,     20, 0, true, true


class Clocked_Video_Output : public VipCore {
private:
    Clocked_Video_Output(const Clocked_Video_Output&);  // Disable copy constructor

public:
    /**
     * Each bit in the CVO Control register enables/disables a different
     * feature of the core.These are the addresses of each bit (indexed from 0)
     */
    enum CVOControlBit {
        // Interrupts:
        CVO_IRQ_STATUS_UPDATE      = 1,
        CVO_IRQ_FRAME_LOCKED       = 2,
    };

    /**
     * Each bit in the status register has a different meaning. These are the
     * addresses of each bit (indexed from 0)
     */
    enum CVOStatusBit {
        CVO_PRODUCING_DATA         = 0,
        // Bits 1 is reserved
        CVO_UNDERFLOW              = 2,
        CVO_FRAME_LOCKED           = 3,
    };

    enum CVOModeXControlBit {
        CVO_INTERLACED_OUTPUT      = 0,
        CVO_SEQUENTIAL_OUTPUT      = 1,
    };

    // CVO specific registers
    enum CVORegisterType {
        CVO_VIDEO_MODE_MATCH               =  3,
        CVO_BANK_SELECT                    =  4,
        CVO_MODEX_CONTROL                  =  5,
        CVO_MODEX_SAMPLE_COUNT             =  6,
        CVO_MODEX_F0_LINE_COUNT            =  7,
        CVO_MODEX_F1_LINE_COUNT            =  8,
        CVO_MODEX_HORIZONTAL_FRONT_PORCH   =  9,
        CVO_MODEX_HORIZONTAL_SYNC_LENGTH   = 10,
        CVO_MODEX_HORIZONTAL_BLANKING      = 11,
        CVO_MODEX_VERTICAL_FRONT_PORCH     = 12,
        CVO_MODEX_VERTICAL_SYNC_LENGTH     = 13,
        CVO_MODEX_VERTICAL_BLANKING        = 14,
        CVO_MODEX_F0_VERTICAL_FRONT_PORCH  = 15,
        CVO_MODEX_F0_VERTICAL_SYNC_LENGTH  = 16,
        CVO_MODEX_F0_VERTICAL_BLANKING     = 17,
        CVO_MODEX_ACTIVE_PICTURE_LINE      = 18,
        CVO_MODEX_F0_VERTICAL_RISING       = 19,
        CVO_MODEX_FIELD_RISING             = 20,
        CVO_MODEX_FIELD_FALLING            = 21,
        CVO_MODEX_STANDARD                 = 22,
        CVO_MODEX_SOF_SAMPLE               = 23,
        CVO_MODEX_SOF_LINE                 = 24,
        CVO_MODEX_VCO_CLK_DIVIDER          = 25,
        CVO_MODEX_ANCILLARY_LINE           = 26,
        CVO_MODEX_F0_ANCILLARY_LINE        = 27,
        CVO_MODEX_HSYNC_POLARITY           = 28,
        CVO_MODEX_VSYNC_POLARITY           = 29,
        CVO_MODEX_VALID                    = 30,
    };

    /**
     * @brief  constructor
     * @param  base_address   the slave interface base address (hash-defined in system.h)
     * @param  irq_number     the slave interface IRQ number (hash-defined in system.h if interrupts are enabled)
     */
    Clocked_Video_Output(unsigned long base_address, int irq_number = -1);
    
    
    /**
     * @brief  Enable the status update interrupt
     * @post   Request an HW interrupt when the status register content changes
     */
    inline void enable_status_update_interrupt() {
        enable_interrupt(CVO_IRQ_STATUS_UPDATE);
    }
    /**
     * @brief  Disable the status update interrupt
     */
    inline void disable_status_update_interrupt() {
        disable_interrupt(CVO_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief  Enable the frame locked interrupt
     * @post   Trigger an interrupt when the CVO has aligned with the incoming sof signal
     */
    inline void enable_frame_locked_interrupt() {
        enable_interrupt(CVO_IRQ_FRAME_LOCKED);
    }
    /**
     * @brief  Disable the frame locked interrupt
     */
    inline void disable_frame_locked_interrupt() {
        disable_interrupt(CVO_IRQ_FRAME_LOCKED);
    }

    /**
     * @brief   Check the state of the status_update interrupt
     * @return  true if the status update interrupt has fired and is still on
     */
    inline bool has_status_update_interrupt_fired() const {
        return has_interrupt_fired(read_interrupt_register(), CVO_IRQ_STATUS_UPDATE);
    }
    /**
     * @brief   Check the state of the status_update interrupt
     * @param   the content of the status register (to avoid the need to poll it again)
     * @return  true if the status update interrupt has fired and is still on
     */
    inline static bool has_status_update_interrupt_fired(int interrupt_register) {
        return has_interrupt_fired(interrupt_register, CVO_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief   Check the state of the end of field/frame interrupt
     * @return  true if the end of field/frame interrupt has fired and is still on
     */
    inline bool has_frame_locked_interrupt_fired() const {
        return has_interrupt_fired(read_interrupt_register(), CVO_IRQ_FRAME_LOCKED);
    }
    /**
     * @brief   Check the state of the end of field/frame interrupt
     * @param   the content of the status register (to avoid the need to poll it again)
     * @return  true if the end of field/frame interrupt has fired and is still on
     */
    inline static bool has_frame_locked_interrupt_fired(int interrupt_register) {
        return has_interrupt_fired(interrupt_register, CVO_IRQ_FRAME_LOCKED);
    }

    /**
     * @brief   Clear the status update interrupt
     * @post    Issues a write to the interrupt to clear the status update interrupt (and no other!)
     */
    inline void clear_status_update_interrupt() {
        clear_interrupt(CVO_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief   Clear the frame locked interrupt
     * @post    Issues a write to the interrupt to clear the frame locked interrupt (and no other!)
     */
    inline void clear_frame_locked_interrupt() {
        clear_interrupt(CVO_IRQ_FRAME_LOCKED);
    }

    /**
     * @brief   is_producing_data is an alias to VipCore::is_running()
     * @see     VipCore::is_running()
     */
    inline bool is_producing_data() const {
        return is_running();
    }

    /**
     * @brief   Poll the status register and check the CVO_UNDERFLOW bit
     * @return  The value of the interlaced bit in the status register
     */
    inline bool is_underflowed() const {
        return read_status_register_bit(CVO_UNDERFLOW);
    }
    /**
     * @brief   Check the CVO_UNDERFLOW bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the underflow bit in the status register
     */
    inline static bool is_underflowed(unsigned int status_register) {
        return read_status_register_bit(CVO_UNDERFLOW, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVO_FRAME_LOCKED bit
     * @return  The value of the interlaced bit in the status register
     */
    inline bool is_frame_locked() const {
        return read_status_register_bit(CVO_FRAME_LOCKED);
    }
    /**
     * @brief   Check the CVO_FRAME_LOCKED bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the underflow bit in the status register
     */
    inline static bool is_frame_locked(unsigned int status_register) {
        return read_status_register_bit(CVO_FRAME_LOCKED, status_register);
    }
          
    /**
     * @brief  Enable an output mode
     * @param  bank_sel              the bank
     */
    inline void validate_output_mode(unsigned int bank_sel) {
        do_write(CVO_BANK_SELECT, bank_sel);
        do_write(CVO_MODEX_VALID, true);
    }

    /**
     * @brief  Disable an output mode
     * @param  bank_sel              the bank
     */
    inline void invalidate_output_mode(unsigned int bank_sel) {
        do_write(CVO_BANK_SELECT, bank_sel);
        do_write(CVO_MODEX_VALID, false);
    }

    /**
     * @brief  Program an output mode
     * @param  bank_sel              the bank
     * @param  interlaced            interlaced mode (bool)
     * @param  sequential            sequential output (bool)
     * @param  sample_count          the width
     * @param  f0_line_count         F0 line count (or height for progressive output)
     * @param  f1_line_count         F1 line count (for interlaced output)
     * @param  h_front_porch         horizontal front porch
     * @param  h_sync_length         horizontal Sync Length
     * @param  h_blanking            horizontal blanking
     * @param  v_front_porch         vertical front porch
     * @param  v_sync_length         vertical sync Length
     * @param  v_blanking            vertical blanking
     * @param  f0_v_front_porch      F0 vertical front porch (for interlaced output)
     * @param  f0_v_sync_length      F0 vertical sync Length (for interlaced output)
     * @param  f0_v_blanking         F0 vertical blanking (for interlaced output)
     * @param  active_picture_line   active picture line
     * @param  f0_v_rising           F0 vertical rising (for interlaced output)
     * @param  field_rising          field rising (for interlaced output)
     * @param  field_falling         field falling (for interlaced output)
     * @param  ancillary_line        line for insertion of ancillary data
     * @param  f0_ancillary_line     line for insertion of ancillary data for F0 (for interlaced output)
     * @param  h_sync_polarity       h_sync polarity (bool)
     * @param  v_sync_polarity       v_sync polarity (bool)
     * @param  vid_std               standard line
     * @param  sof_sample            SOF sample (if genlock is used)
     * @param  sof_line              SOF line (if genlock is used)
     * @param  vco_clk_div           Vcoclk divider (if genlock is used)
     * @pre    bank_sel is a valid bank number (for the HW parameterization)
     * @see    Look for pre-defined hash-defined modes to set up parameters from "interlaced" to "v_sync_polarity"
     */
    void set_output_mode(unsigned int bank_sel,
            bool interlaced, bool sequential,
            unsigned int sample_count, unsigned int f0_line_count, unsigned int f1_line_count,
            unsigned int h_front_porch, unsigned int h_sync_length, unsigned int h_blanking,
            unsigned int v_front_porch, unsigned int v_sync_length, unsigned int v_blanking,
            unsigned int f0_v_front_porch, unsigned int f0_v_sync_length, unsigned int f0_v_blanking,
            unsigned int active_picture_line, unsigned int f0_v_rising, unsigned int field_rising, unsigned int field_falling,
            unsigned int ancillary_line, unsigned int f0_ancillary_line, bool h_sync_polarity, bool v_sync_polarity,
            unsigned int vid_std = 0, unsigned int sof_sample = 0, unsigned int sof_line = 0, unsigned int vco_clk_div = 0);

    /**
     * Resets the underflow sticky bit to 0. When underflow of the output FIFO is
     * detected, the underflow bit will be asserted and stay asserted until reset
     * using this method. The CVO is one of the unusual core allowing writes to
     * the status register
     * @see is_underflowed()
     */
    inline void clear_underflow_flag() {
        IOWR(get_base_address(), REGISTER_STATUS, 1 << CVO_UNDERFLOW);
    }
};

#endif  // __CLOCKED_VIDEO_OUTPUT_HPP__

