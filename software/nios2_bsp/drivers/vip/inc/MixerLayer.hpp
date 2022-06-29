#ifndef __MIXER_LAYER_HPP_
#define __MIXER_LAYER_HPP_

#include "VipUtil.hpp"
#include <io.h>

class MixerLayer {
private:
    MixerLayer(const MixerLayer&);  // Disable copy constructor

public:

    /// Each bit in the control register has a different meaning but they work as a pair
    enum MixingMode {
        LAYER_DISABLED              = 0,
        LAYER_ENABLED               = 1,
        LAYER_CONSUMED              = 2,
    };

    enum BlendingMode {
        ALPHA_DISABLED              = 0,
        STATIC_ALPHA                = 1,
        IN_STREAM_ALPHA             = 2,
    };

    /// Each layer starts at a different memory base address but their registers are offset from that base address
    enum Register {
        REGISTER_POSITION_X    = 0,
        REGISTER_POSITION_Y    = 1,
        REGISTER_CONTROL       = 2,
        REGISTER_DISPLAY_ORDER = 3,
        REGISTER_LAYER_ALPHA   = 4,
        NUMBER_LAYER_REGISTERS = 5,
    };

    /*
     * @brief    mixer layer constructor
     * @param    layer_id             the layer ID (used to initialize the position)
     * @param    mixer_base_address   the base address of the mixer (in bytes)
     * @param    layer_offset         the offset to access this layer registers (in words)
     * @post     The layer starts in disabled state with no alpha-blending and at position 0x0
     */
    MixerLayer(unsigned int layer_id, unsigned long mixer_base_address, unsigned int layer_offset);

    /*
     * @brief    Choose the mixing mode
     * @see      MixingMode
     */
    inline void set_mixing_mode(MixingMode mode) {
        layer_control = (layer_control & 0xFC)| mode;
        do_write(REGISTER_CONTROL, layer_control);
    }

    /*
     * @brief    Enable the layer. Alias for set_mixing_mode(LAYER_ENABLED)
     * @see      set_mixing_mode
     */
    inline void enable_layer() {
        set_mixing_mode(LAYER_ENABLED);
    }

    /*
     * @brief    Disable the layer. Alias for set_mixing_mode(LAYER_DISABLED)
     * @see      set_mixing_mode
     */
    inline void disable_layer() {
        set_mixing_mode(LAYER_DISABLED);
    }

    /*
     * @brief    Consume the layer. Alias for set_mixing_mode(LAYER_CONSUMED)
     * @see      set_mixing_mode
     */
    inline void consume_layer() {
        set_mixing_mode(LAYER_CONSUMED);
    }


    /*
     * @return   Current mixing mode
     * @see      MixingMode
     */
    inline MixingMode get_mixing_mode() const {
        return MixingMode(layer_control & 0x03);
    }

    /*
     * @return   whether the layer is enabled
     */
    inline bool is_layer_enabled() const {
        return get_mixing_mode() == LAYER_ENABLED;
    }

    /*
     * @return   whether the layer is disabled
     */
    inline bool is_layer_disabled() const {
        return get_mixing_mode() == LAYER_DISABLED;
    }

    /*
     * @return   whether the layer is consumed
     */
    inline bool is_layer_consumed() const {
        return get_mixing_mode() == LAYER_CONSUMED;
    }

    /*
     * @brief    Choose the alpha blending mode
     * @see      MixingMode
     */
    inline void set_alpha_blending_mode(BlendingMode mode) {
        layer_control = (layer_control & 0xF3)| (mode << 2);
        do_write(REGISTER_CONTROL, layer_control);
    }

    /*
     * @brief    Enable static alpha blending. Alias for set_alpha_blending_mode(STATIC_ALPHA)
     * @see      set_alpha_blending_mode
     * @pre      This mode is allowed by the HW
     */
    inline void enable_static_alpha_blending() {
        set_alpha_blending_mode(STATIC_ALPHA);
    }
    /*
     * @brief    Disable alpha blending. Alias for set_alpha_blending_mode(ALPHA_DISABLED)
     * @see      set_alpha_blending_mode
     */
    inline void disable_alpha_blending() {
        set_alpha_blending_mode(ALPHA_DISABLED);
    }

    /*
     * @brief    Enable in stream alpha blending. Alias for set_alpha_blending_mode(IN_STREAM_ALPHA)
     * @see      set_alpha_blending_mode
     * @pre      This mode is allowed by the HW
     */
    inline void enable_in_stream_alpha_blending() {
        set_alpha_blending_mode(IN_STREAM_ALPHA);
    }


    /*
     * @return   Current mixing mode
     * @see      MixingMode
     */
    inline BlendingMode get_alpha_blending_mode() const {
        return BlendingMode((layer_control & 0x0C) >> 2);
    }

    /*
     * @return   whether static alpha blending is currently is enabled
     */
    inline bool is_static_alpha_blending_enabled() const {
        return get_alpha_blending_mode() == STATIC_ALPHA;
    }

    /*
     * @return   whether alpha blending is currently disabled
     */
    inline bool is_alpha_blending_disabled() const {
        return get_alpha_blending_mode() == ALPHA_DISABLED;
    }

    /*
     * @return   whether in stream alpha blending is currently enabled
     */
    inline bool is_in_stream_alpha_blending_enabled() const {
        return get_alpha_blending_mode() == IN_STREAM_ALPHA;
    }

    /*
     * @brief    Change the layer left offset
     * @pre      beware throughput issues when a layer goes off-screen
     */
    inline void set_x(unsigned int x) {
        do_write(REGISTER_POSITION_X, x);
    }

    /*
     * @brief    Change the layer top offset
     * @pre      beware throughput issues when a layer goes off-screen
     */
    inline void set_y(unsigned int y) {
        do_write(REGISTER_POSITION_Y, y);
    }

    /*
     * @brief    Change the layer top-left offset
     * @pre      beware throughput issues when a layer goes off-screen
     */
    void set_offset(unsigned int x, unsigned int y);

    /*
     * @brief    Change the layer position (i.e, the position among layers, use set_offset for the position of the layer on the background)
     * @pre      you should avoid using conflicting positions across your layers, even if they are disabled
     */
    inline void set_layer_position(unsigned int layer_position) {
        do_write(REGISTER_DISPLAY_ORDER, layer_position);
    }

    /*
     * @brief    Change the static alpha value position
     */
    inline void set_static_alpha_value(unsigned int alpha_value) {
        do_write(REGISTER_LAYER_ALPHA, alpha_value);
    }

protected:
    inline void do_write(long reg_offset, unsigned int value) {
        IOWR(mixer_base_address, layer_offset + reg_offset, value);
    }

private:
    unsigned long mixer_base_address;
    unsigned int layer_offset;
    unsigned int layer_control;
};

#endif   // __MIXER_LAYER_HPP_
