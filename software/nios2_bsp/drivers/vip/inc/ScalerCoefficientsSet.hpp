#ifndef __SCALER_COEFFICIENTS_SET_HPP__
#define __SCALER_COEFFICIENTS_SET_HPP__

/*
 * @brief   a set of quantized coefficients for the scaler
 */
class ScalerCoefficientsSet
{
public:
    /*
     * @brief constructor
     * @param   number_phases            Number of phases
     * @param   number_taps              Number of taps
     * @post  Create number_phases sets of scaler coefficients.
     */
    ScalerCoefficientsSet(unsigned int number_phases, unsigned int number_taps);

    /*
     * @brief destructor
     */
    ~ScalerCoefficientsSet();

    inline float *get_coeffs() {
        return coeffs;
    }

    // @post set a value for the coefficient at position x,y
    inline void set_coefficient(unsigned int phase, unsigned int tap, float value) {
        set_coefficient(phase * number_taps + tap, value);
    }

    // @post set a value for the coefficient n
    void set_coefficient(unsigned int n, float value) {
        coeffs[n] = value;
    }

    // @return the coefficient at position x,y
    inline float get_coefficient(unsigned int phase, unsigned int tap) const {
        return get_coefficient(phase * number_taps + tap);
    }

    // @return the coefficient n
    inline float get_coefficient(unsigned int n) const {
        return coeffs[n];
    }

    // @return the number of phases
    inline unsigned int get_number_of_phases() const {
        return number_phases;
    }

    // @return the number of taps
    inline unsigned int get_number_of_taps() const {
        return number_taps;
    }

    // @return the number of coefficients (number_phases*numbers_taps)
    inline unsigned int get_number_of_coefficients() const {
        return number_phases * number_taps;
    }

    // @return the array of coefficients
    inline operator const float * () const {
        return coeffs;
    }

    // @brief    Generate a set of scaling coefficients for the given scaling ratio padding 0s around a Lanczos-N function
    // @param    input_size   the input width or height
    // @param    output_size  the output width or height
    // @post     Determine the most appropriate number of lobes and call lanczos_generate(input_size,output_size,lobes)
    void lanczos_generate(unsigned int input_size, unsigned int output_size);

    // @brief    Generate a set of scaling coefficients for the given scaling ratio by padding 0s around a Lanczos-N
    //           function with a fixed number of lobes
    // @param    input_size   the input width or height
    // @param    output_size  the output width or height
    // @param    lobes        the number of lobes for the Lanczos function
    void lanczos_generate(unsigned int input_size, unsigned int output_size, unsigned int lobes);

private:
    unsigned int number_phases;
    unsigned int number_taps;

    float *coeffs;
};

#endif    // __SCALER_COEFFICIENTS_SET_HPP__
