#include "VipMath.hpp"

#include "VipUtil.hpp"

#include <cassert>

/**
 * Returns the greatest common divisor of a and b (using Euclid's
 * algorithm).
 * 
 * @param a
 *            one of two numbers to find the gcd of
 * @param b
 *            one of two numbers to find the gcd of
 * @return the gcd of a and b
 */
int VipMath::gcd(int a, int b)
{
    int min, max;
    if (a > b)
    {
        min = b;
        max = a;
    }
    else
    {
        min = a;
        max = b;
    }
    return gcd_ordered(max, min);
}


int VipMath::gcd_ordered(int a, int b)
{
    if (b == 0)
        return a;
    else
        return gcd_ordered(b, a % b);
}

long VipMath::quantize_coefficient(bool is_signed, int int_bits, int frac_bits, float value)
{
    int nb_bits = int_bits + frac_bits;
    assert(nb_bits < 32);

    float scaled = value * float(1 << frac_bits);
    long rval = (scaled >= 0.0f) ? scaled + 0.5f : scaled - 0.5f;   // Round up

    long lower = is_signed ? -(1 << nb_bits) : 0;
    long upper = (1 << nb_bits) - 1;

    if ((rval < lower) || (rval > upper)) {
        VIP_WARNING_MSG("VipMath: coefficient cannot be adequately quantized using fixed point representation %s%d.%d\n",
                         is_signed ? "+/-" : "", int_bits, frac_bits);
    }
    if (rval < lower) rval = lower;
    if (rval > upper) rval = upper;

    return rval;
}

// Source AMS 55, eqn 4.3.97. Handbook of Mathematical Functions, Pub by U.S. Dept of Commerce
float VipMath::sinc(float x){
    float xsq = x*x;
    float temp = 1 + a[0]*xsq + a[1]*xsq*xsq + a[2]* xsq*xsq*xsq
                   + a[3]*xsq*xsq*xsq*xsq
                   + a[4]*xsq*xsq*xsq*xsq*xsq;
    return temp;
}

float VipMath::lanczos(float x, float lobes) {
    // sinc(0) is explicitly defined to be 1
    // Outside the lobes is defined to be 0
    if (x == 0) {
        return 1;
    } else if (!(x <= lobes && x >= -lobes)) {
        return 0;
    } else {
        return sinc(pi * x) * sinc((pi * x) / lobes);
    }
}

float VipMath::normalise_coefficients(float coeffs[], unsigned int number_taps) {
    float total = 0.0f;
    for (unsigned int i = 0; i < number_taps; i++) {
        total += coeffs[i];
    }

    float sum = 0.0f;
    for (unsigned int i = 0; i < number_taps; i++) {
        coeffs[i] /= total;
        sum += coeffs[i];
    }

    return sum;
}
