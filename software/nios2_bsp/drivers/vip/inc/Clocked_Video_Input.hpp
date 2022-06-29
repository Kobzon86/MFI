#ifndef __CLOCKED_VIDEO_INPUT_HPP__
#define __CLOCKED_VIDEO_INPUT_HPP__

#include "VipCore.hpp"

class Clocked_Video_Input : public VipCore {
private:
    Clocked_Video_Input(const Clocked_Video_Input&);  // Disable copy constructor

public:
    /**
     * Each bit in the CVI Control register enables/disables a different
     * feature of the core.These are the addresses of each bit (indexed from 0)
     *
     * STATUS_UPDATE interrupt:
     * Fires whenever there is a change to the REGISTER_STATUS register
     *
     * END_OF_FIELD_FRAME interrupt:
     * If the Qsys synchronization settings are set to "Any field first", the EOF
     * interrupt is triggered on the falling edge of the vsync.
     * If the Qsys synchronization settings are set to "F1 first", the EOF
     * interrupt is triggered on the falling edge of the F1 vsync.
     * If the Qsys synchronization settings are set to "F0 first", the EOF
     * interrupt is triggered on the falling edge of the F0 vsync.
     * You can use this interrupt to trigger the reading of the ancillary packets
     * from the control interface before the packets are overwritten by the next
     * frame.
     *
     */
    enum CVIControlBit {
        // Interrupts:
        CVI_IRQ_STATUS_UPDATE      = 1,
        CVI_IRQ_END_OF_FIELD_FRAME = 2,
    };

    /**
     * Each bit in the status register has a different meaning. These are the
     * addresses of each bit (indexed from 0)
     */
    enum CVIStatusBit {
        CVI_PRODUCING_DATA         = 0,
        // Bits 1-6 are reserved
        CVI_INTERLACED             = 7,
        CVI_STABLE_INPUT_WIDTH     = 8,
        CVI_OVERFLOW               = 9,
        CVI_VALID_RESOLUTION       = 10,
        CVI_VIDEO_LOCKED           = 11,
    };

    // CVI specific registers
    enum CVIRegisterType {
        CVI_USED_WORDS           = 3,
        CVI_ACTIVE_SAMPLE_COUNT  = 4,
        CVI_ACTIVE_LINE_COUNT_F0 = 5,
        CVI_ACTIVE_LINE_COUNT_F1 = 6,
        CVI_TOTAL_SAMPLE_COUNT   = 7,
        CVI_TOTAL_LINE_COUNT_F0  = 8,
        CVI_TOTAL_LINE_COUNT_F1  = 9,
        CVI_VID_STANDARD         = 10,
        CVI_COLOR_PATTERN        = 14,
        CVI_ANCILLARY_PACKET     = 15,
    };

    /**
     * @brief  constructor
     * @param  base_address   the slave interface base address (hash-defined in system.h)
     * @param  irq_number     the slave interface IRQ number (hash-defined in system.h if interrupts are enabled)
     */
    Clocked_Video_Input(unsigned long base_address, int irq_number = -1);

    /**
     * @brief  Enable the status update interrupt
     * @post   Request an HW interrupt when the status register content changes
     */
    inline void enable_status_update_interrupt() {
        enable_interrupt(CVI_IRQ_STATUS_UPDATE);
    }
    /**
     * @brief  Disable the status update interrupt
     */
    inline void disable_status_update_interrupt() {
        disable_interrupt(CVI_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief  Enable the end of field/frame interrupt
     * @post   Request an HW interrupt at EOF
     *         If parameterized with "Any field first", the EOF interrupt is triggered on the falling edge of the vsync.
     *         If parameterized with "F1 first", the EOF interrupt is triggered on the falling edge of the F1 vsync.
     *         If parameterized with "F0 first", the EOF interrupt is triggered on the falling edge of the F0 vsync.
     */
    inline void enable_end_of_field_frame_interrupt() {
        enable_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
    }
    /**
     * @brief  Disable the end of field/frame interrupt
     */
    inline void disable_end_of_field_frame_interrupt() {
        disable_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
    }

    /**
     * @brief   Check the state of the status_update interrupt
     * @return  true if the status update interrupt has fired and is still on
     */
    inline bool has_status_update_interrupt_fired() const {
        return has_interrupt_fired(read_interrupt_register(), CVI_IRQ_STATUS_UPDATE);
    }
    /**
     * @brief   Check the state of the status_update interrupt
     * @param   the content of the status register (to avoid the need to poll it again)
     * @return  true if the status update interrupt has fired and is still on
     */
    inline static bool has_status_update_interrupt_fired(unsigned int interrupt_register) {
        return has_interrupt_fired(interrupt_register, CVI_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief   Check the state of the end of field/frame interrupt
     * @return  true if the end of field/frame interrupt has fired and is still on
     */
    inline bool has_end_of_field_frame_interrupt_fired() const {
        return has_interrupt_fired(read_interrupt_register(), CVI_IRQ_END_OF_FIELD_FRAME);
    }
    /**
     * @brief   Check the state of the end of field/frame interrupt
     * @param   the content of the status register (to avoid the need to poll it again)
     * @return  true if the end of field/frame interrupt has fired and is still on
     */
    inline static bool has_end_of_field_frame_interrupt_fired(unsigned int interrupt_register) {
        return has_interrupt_fired(interrupt_register, CVI_IRQ_END_OF_FIELD_FRAME);
    }

    /**
     * @brief   Clear the status update interrupt
     * @post    Issues a write to the interrupt to clear the status update interrupt (and no other!)
     */
    inline void clear_status_update_interrupt() {
        clear_interrupt(CVI_IRQ_STATUS_UPDATE);
    }

    /**
     * @brief   Clear the end of field/frame interrupt
     * @post    Issues a write to the interrupt to clear the end of field/frame interrupt (and no other!)
     */
    inline void clear_end_of_field_frame_interrupt() {
        clear_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
    }

    /**
     * @brief   is_producing_data is an alias to VipCore::is_running()
     * @see     VipCore::is_running()
     */
    inline bool is_producing_data() const {
        return is_running();
    }

    /**
     * @brief   Poll the status register and check the CVI_INTERLACED bit
     * @return  The value of the interlaced bit in the status register
     */
    inline bool is_interlaced() const {
        return read_status_register_bit(CVI_INTERLACED);
    }
    /**
     * @brief   Check the CVI_INTERLACED bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the interlaced bit in the status register
     */
    inline static bool is_interlaced(unsigned int status_register) {
        return read_status_register_bit(CVI_INTERLACED, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVI_STABLE_INPUT_WIDTH bit
     * @return  The value of the stable_width bit in the status register
     */
    inline bool is_input_width_stable() const {
        return read_status_register_bit(CVI_STABLE_INPUT_WIDTH);
    }
    /**
     * @brief   Check the CVI_STABLE_INPUT_WIDTH bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the stable_width bit in the status register
     */
    inline static bool is_input_width_stable(unsigned int status_register) {
        return read_status_register_bit(CVI_STABLE_INPUT_WIDTH, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVI_OVERFLOW bit
     * @return  The value of the (sticky) overflow bit in the status register
     */
    inline bool is_overflowed() const {
        return read_status_register_bit(CVI_OVERFLOW);
    }
    /**
     * @brief   Check the CVI_OVERFLOW bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the (sticky) overflow bit in the status register
     */
    inline static bool is_overflowed(unsigned int status_register) {
        return read_status_register_bit(CVI_OVERFLOW, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVI_VALID_RESOLUTION bit
     * @return  The value of the valid_resolution bit in the status register
     */
    inline bool is_valid_resolution() const {
        return read_status_register_bit(CVI_VALID_RESOLUTION);
    }
    /**
     * @brief   Check the CVI_VALID_RESOLUTION bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the valid_resolution bit in the status register
     */
    inline static bool is_valid_resolution(unsigned int status_register) {
        return read_status_register_bit(CVI_VALID_RESOLUTION, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVI_VIDEO_LOCKED bit
     * @return  The value of the video_locked bit in the status register
     */
    inline bool is_locked() const {
        return read_status_register_bit(CVI_VIDEO_LOCKED);
    }
    /**
     * @brief   Check the CVI_VIDEO_LOCKED bit on the given status register value
     * @param   The current value of the status register
     * @return  The value of the video_locked bit in the status register
     */
    inline static bool is_locked(unsigned int status_register) {
        return read_status_register_bit(CVI_VIDEO_LOCKED, status_register);
    }

    /**
     * @brief   Poll the status register and check the CVI_VIDEO_LOCKED, CVI_STABLE_INPUT_WIDTH and CVI_VALID_RESOLUTION bits
     * @return  true if all the three bits are set (video_locked && stable_width && valid_resolution)
     * @post    Unfortunately, this may not be enough to guarantee that the stream is "stable". So multiple calls
     *          over successive frames may be necessary
     */
    inline bool is_stream_stable() const {
        return is_stream_stable(read_status_register());
    }
    /**
     * @brief   Check the CVI_VIDEO_LOCKED, CVI_STABLE_INPUT_WIDTH and CVI_VALID_RESOLUTION bits all together on the given status register value
     * @return  true if all the three bits are set (video_locked && stable_width && valid_resolution)
     * @post    Unfortunately, this may not be enough to guarantee that the stream is "stable". So multiple calls
     *          over successive frames may be necessary
     */
    inline static bool is_stream_stable(unsigned int status_register) {
        unsigned int mask = (1 << CVI_VIDEO_LOCKED) | (1 << CVI_STABLE_INPUT_WIDTH) | (1 << CVI_VALID_RESOLUTION);
        return (status_register & mask) == mask;
    }


    /**
     * Returns the used words level of the input FIFO. Used in conjunction with the
     * total depth of the input FIFO will give you the percentage of the FIFO that
     * is filled with data.
     */
    inline unsigned int get_fifo_used_words() const {
        return do_read(CVI_USED_WORDS);
    }

    /**
     * @return   the detected sample count of the video streams (excluding blanking)
     */
    inline unsigned int get_active_sample_count() const {
        return do_read(CVI_ACTIVE_SAMPLE_COUNT);
    }

    /**
     * Alias for get_active_sample_count()
     * @see get_active_sample_count()
     */
    inline unsigned int get_width() const {
        return get_active_sample_count();
    }

    /**
     * @return   the detected line count of the video streams F0 field (excluding blanking)
     */
    inline unsigned int get_active_line_count_f0() const {
        return do_read(Clocked_Video_Input::CVI_ACTIVE_LINE_COUNT_F0);
    }

    /**
     * Alias for get_active_line_count_f0()
     * @see get_active_line_count_f0()
     */
    inline unsigned int get_height_f0() const {
        return get_active_line_count_f0();
    }

    /**
     * @return   the detected line count of the video streams F1 field (excluding blanking)
     */
    inline unsigned int get_active_line_count_f1() const {
        return do_read(CVI_ACTIVE_LINE_COUNT_F1);
    }

    /**
     * Alias for get_active_line_count_f1()
     * @see get_active_line_count_f1()
     */
    inline unsigned int get_height_f1() const {
        return get_active_line_count_f1();
    }

    /**
     * @return   the detected sample count of the video streams (including blanking)
     */
    inline unsigned int get_total_sample_count() const {
        return do_read(CVI_TOTAL_SAMPLE_COUNT);
    }

    /**
     * @return   the detected line count of the video streams F0 field (including blanking)
     */
    inline unsigned int get_total_line_count_f0() const {
        return do_read(CVI_TOTAL_LINE_COUNT_F0);
    }

    /**
     * @return   the detected line count of the video streams F1 field (including blanking)
     */
    inline unsigned int get_total_line_count_f1() const {
        return do_read(CVI_TOTAL_LINE_COUNT_F1);
    }

    /**
     * @return   the video standard
     */
    inline unsigned int get_vid_standard() const {
        return do_read(CVI_VID_STANDARD);
    }

    /**
     * @return   the 8-bit code of the value driven on the vid_color_encoding input.
     */
    inline unsigned int get_color_pattern() const {
        return do_read(CVI_COLOR_PATTERN) & 0xFF;
    }

    /**
     * @return   the 8-bit code of the value driven on the vid_bit_width input.
     */
    inline unsigned int get_bit_width() const {
        return (do_read(CVI_COLOR_PATTERN) >> 8) & 0xFF;
    }

    /**
     * @param    sample   the sample
     * @return   Selected sample of the ancillary packet
     * @pre      0 <= sample < ancillary packet mem depth
     */
    inline unsigned int get_ancillary_packet_sample(unsigned int sample) const {
        return do_read(CVI_ANCILLARY_PACKET + sample);
    }

    /**
     * Resets the overflow sticky bit to 0. When overflow of the input FIFO is
     * detected, the overflow bit will be asserted and stay asserted until reset
     * using this method. The CVI is one of the unusual core allowing writes to
     * the status register
     * @see is_overflowed()
     */
    inline void clear_overflow_flag() {
        IOWR(get_base_address(), REGISTER_STATUS, 1 << CVI_OVERFLOW);
    }
};


#endif    // __CLOCKED_VIDEO_INPUT_HPP__
