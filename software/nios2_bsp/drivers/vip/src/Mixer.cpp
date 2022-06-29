#include "Mixer.hpp"

#include "VipUtil.hpp"

#include <stdlib.h>
#include <string.h>

Mixer::Mixer(unsigned long base_address, unsigned int num_inputs)
: VipCore(base_address), num_inputs(num_inputs) {
    // Create the layer objects (note: cannot use new or new [] in BSP, hence horrible hack below)
    layers = (MixerLayer**) malloc(num_inputs * sizeof(MixerLayer*));
    for (unsigned int i = 0; i < num_inputs; ++i) {
        layers[i] = (MixerLayer*) malloc(sizeof(MixerLayer));
        MixerLayer layer(i, base_address, MIX_LAYER_BASE + (i*MixerLayer::NUMBER_LAYER_REGISTERS));
        memcpy((void*)layers[i], (const void*)&layer, sizeof(MixerLayer));
    }
    // Default black background (in RGB)
    set_background_color(0, 0, 0);
}

Mixer::~Mixer() {
    for (unsigned int i = 0; i < num_inputs; ++i) {
        free(layers[i]);
    }
    free(layers);
}

void Mixer::set_background_resolution(unsigned int width, unsigned int height)
{
    VIP_DEBUG_MSG("Mixer: set_background_resolution called with %0dx%0d\n", width, height);
    set_background_width(width);
    set_background_height(height);
}

void Mixer::set_background_color(unsigned int color_1, unsigned int color_2, unsigned int color_3) {
    VIP_DEBUG_MSG("Mixer: set_background_color called with (%d,%d,%d)\n", color_1, color_2, color_3);
    set_background_color_1(color_1);
    set_background_color_2(color_2);
    set_background_color_3(color_3);
}
