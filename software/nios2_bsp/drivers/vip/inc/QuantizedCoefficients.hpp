#ifndef __QUANTIZED_COEFFICIENTS_HPP__
#define __QUANTIZED_COEFFICIENTS_HPP__

#include "VipMath.hpp"

class QuantizedCoefficients
{
public:
    /*
     * @brief    Create and store a quantized versions of the coefficients in coeffs
     * @param    is_signed      Whether the quantized version has a sign bit
     * @param    integer_bits   Number of integer bits (excluding sign bit)
     * @param    frac_bits      Number of fractional bits
     * @param    coeffs         Original coefficients (as float)
     * @param    number_coeffs  Number of coefficients
     */
    QuantizedCoefficients(bool is_signed, int integer_bits, int frac_bits, const float *coeffs, unsigned int number_coeffs);

    /*
     * @brief    Destructor
     */
    ~QuantizedCoefficients();

    /*
     * @brief      Accessor to the number of coefficients in the set
     * @return     Number of coefficients in the set
     */
    inline unsigned int get_number_coeffs() const {
        return number_coeffs;
    }

    /*
     * @brief      Accessor to a quantized coefficient
     * @param      c the coefficient id
     * @return     The requested coefficient in quantized from
     */
    inline long get_quantized_coeff(unsigned int c) {
        return quantized_coeffs[c];
    }

    /*
     * @brief      Return the floating point value of a coefficient after it has undergone quantization
     * @param      n the coefficient id
     * @return     The achieved floating point value for the requested coefficient
     */
    inline float get_reconstructed_coeff(unsigned int c) {
        return float(quantized_coeffs[c]) / float(1 << frac_bits);
    }

    /*
     * @brief    Conversion operator, automatic conversion to long*
     * @return   The array of coefficients in quantized form
     */
    inline operator const long* () const {
        return quantized_coeffs;
    }

private:
    bool is_signed;
    int integer_bits;
    int frac_bits;
    unsigned int number_coeffs;
    long *quantized_coeffs;
};

#endif   // __QUANTIZED_COEFFICIENTS_HPP__
