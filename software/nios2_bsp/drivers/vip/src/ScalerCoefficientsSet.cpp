#include "ScalerCoefficientsSet.hpp"

#include "VipMath.hpp"

#include <stdlib.h>

ScalerCoefficientsSet::ScalerCoefficientsSet(unsigned int number_phases, unsigned int number_taps)
: number_phases(number_phases), number_taps(number_taps) {
    coeffs = (float*)malloc(number_phases * number_taps * sizeof(float));
}

ScalerCoefficientsSet::~ScalerCoefficientsSet() {
    free(coeffs);
}

void ScalerCoefficientsSet::lanczos_generate(unsigned int input_size, unsigned int output_size) {
    float float_lobes = (output_size < input_size) ? (float(number_taps * output_size) / float(2*input_size)) : float(number_taps)/2.0f;
    int lobes = int(float_lobes);
    // Limit to one of the standard Lanczos functions (1 or 2 lobes)
    lobes = (lobes < 1) ? 1 : (lobes > 2) ? 2 : lobes;

    lanczos_generate(input_size, output_size, lobes);
}

void ScalerCoefficientsSet::lanczos_generate(unsigned int input_size, unsigned int output_size, unsigned int lobes) {
    float ideal_number_taps = (input_size <= output_size) ? float(2 * lobes) : float(2 * lobes * input_size) / float(output_size);

    // Can't use more taps than we have
    ideal_number_taps = ideal_number_taps > number_taps ? float(number_taps) : ideal_number_taps;

    int ceil_taps_in_use = int(ideal_number_taps);
    if (float(ceil_taps_in_use) != ideal_number_taps) ceil_taps_in_use += 1;

    int ceil_coeff_offset = int((number_taps - 1) / 2) - ((ceil_taps_in_use - 1) / 2);
    ceil_coeff_offset = ceil_coeff_offset < 0 ? 0 : ceil_coeff_offset;

    //if there is an odd number of taps we center the kernel at floor(taps/2)
    //in phase 0 all taps have no zero coefficients - divide lanczos kernel into taps + 1 samples
    //ignore the first and last sample as they will be zero (taken at +/- lobes exactly)
    //if there are even taps we again center at floor(taps/2)
    //in phase 0 the final tap will have coefficient of 0 - divide lanczos kernel into taps samples
    //only ignore the first sample (at -lobes) and use the last sample (at +lobes) to generate the 0 for phase 0
    float lanczos_offset_per_tap = float(2*lobes);
    if (ceil_taps_in_use & 0x1)
        lanczos_offset_per_tap /= (ceil_taps_in_use+1);
    else
        lanczos_offset_per_tap /= ceil_taps_in_use;

    for (unsigned int i = 0; i < number_phases; i++) {
        // We are going to add this value to move the function left.
        // Generally f(x+1) is to the right of f(x) so phaseOffset counts down
        float phase_offset = float(i) * (lanczos_offset_per_tap / float(number_phases));
        for (unsigned int j = 0; j < number_taps; ++j) {
            // Move by one tap each time, scaling these taps appropriately
            // to the natural size of the lanczos function (-lobes to lobes)
            float value;
            if((int(j) >= ceil_coeff_offset) && (int(j) < ceil_coeff_offset + ceil_taps_in_use))
            {
                float tap_offset = float(j-ceil_coeff_offset+1) * lanczos_offset_per_tap;
                value = VipMath::lanczos(tap_offset - phase_offset - float(lobes), float(lobes));
            }
            else
            {
                value = 0.0f;
            }
            set_coefficient(i, j, value);
        }
        VipMath::normalise_coefficients(coeffs + i * number_taps, number_taps);
    }
}
