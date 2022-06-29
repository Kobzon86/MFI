#ifndef __VIP_MATH_HPP__
#define __VIP_MATH_HPP__

namespace VipMath {
    /**
     * @brief     pi = 3.14159265f
     */
    const float pi = 3.14159265f;

    /**
     * @brief     sync function coeffs
     */
    const float a[] = {-.1666666664f, .0083333315f, -.0001984090f, .0000027526f, -.0000000239f};

    /**
     * @brief     Returns the greatest common divisor of a and b
     * @param     a   one of two numbers to find the gcd of
     * @param     b   one of two numbers to find the gcd of
     * @return    the gcd of a and b
     */
    int gcd(int a, int b);

    /**
     * @brief     Returns the greatest common divisor of a and b. a must be the larger number
     * @param     a   one of two numbers to find the gcd of
     * @param     b   one of two numbers to find the gcd of
     * @return    the gcd of a and b
     * @pre       a >= b
     */
    int gcd_ordered(int a, int b);

    /**
     * @brief    Helper function to quantize a floating point value
     * @param    is signed     whether the value should be quantized as a signed integer
     * @param    int_bits      number of integer bits (excluding sign bits)
     * @param    is frac_bits  number of fractional bits
     * @return   The quantized value
     */
    long quantize_coefficient(bool is_signed, int int_bits, int frac_bits, float value);

    // @brief sinc function
    //        The sin() function from math.h makes the program code too large, so use this instead.
    //        Source AMS 55, eqn 4.3.97. Handbook of Mathematical Functions, Pub by U.S. Dept of Commerce
    // @return   an approximation of sin(x)/x
    float sinc(float x);

    // @brief lanczos function
    // @param    x         the x value
    // @param    lobes     number of lobes for the Lanczos function
    // @return   lanczosN(x).  lanczosN is explicitly defined to be 1 at 0 and 0 outside the lobes
    float lanczos(float x, float lobes);

    /**
     * @brief    Normalises a set of coefficients so that they sum to 1. The process may not be exact due to finite
     *           precision arithmetic, so the actual sum (which will be very close to 1) is returned.
     *
     * @param    coeffs some coefficients, which get changed in place
     * @return   The sum after calculation
     */
    float normalise_coefficients(float coeffs[], unsigned int number_taps);
};

#endif  // __VIP_MATH_HPP__
