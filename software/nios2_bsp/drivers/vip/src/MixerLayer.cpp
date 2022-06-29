#include "MixerLayer.hpp"

MixerLayer::MixerLayer(unsigned int layer_id, unsigned long mixer_base_address, unsigned int layer_offset)
: mixer_base_address(mixer_base_address), layer_offset(layer_offset), layer_control(0) {
    disable_layer();
    disable_alpha_blending();
    set_offset(0,0);
    set_layer_position(layer_id);
    set_static_alpha_value(0);
}

void MixerLayer::set_offset(unsigned int x, unsigned int y) {
    set_x(x);
    set_y(y);
}
