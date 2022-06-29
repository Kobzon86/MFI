#include "QuantizedCoefficients.hpp"

#include "VipMath.hpp"

#include <stdlib.h>

QuantizedCoefficients::QuantizedCoefficients(bool is_signed, int integer_bits, int frac_bits, const float *coeffs, unsigned int number_coeffs)
: is_signed(is_signed), integer_bits(integer_bits), frac_bits(frac_bits), number_coeffs(number_coeffs) {
    quantized_coeffs = (long*)malloc(number_coeffs * sizeof(long));
    for (unsigned int c = 0; c < number_coeffs; ++c) {
        quantized_coeffs[c] = VipMath::quantize_coefficient(is_signed, integer_bits, frac_bits, coeffs[c]);
    }
}

QuantizedCoefficients::~QuantizedCoefficients() {
    free(quantized_coeffs);
}
