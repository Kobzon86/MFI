#ifndef __SCALER_HPP__
#define __SCALER_HPP__

#include "VipCore.hpp"
#include "VipUtil.hpp"

#include "ScalerCoefficientsSet.hpp"
#include "QuantizedCoefficients.hpp"

class Scaler : public VipCore {
private:
    Scaler(const Scaler&);  // Disable the copy constructor

public:
    enum SCLControlReg {
        CTRL_EDGE_ADAPTIVE_BIT        = 1,
    };

    // Scaler specific registers
    enum SCLRegisterType {
        SCL_OUT_WIDTH                  = 3,
        SCL_OUT_HEIGHT                 = 4,
        SCL_EDGE_THRESHOLD             = 5,
        SCL_H_COEFF_BANK_WRITE_ADDRESS = 8,
        SCL_H_COEFF_BANK_READ_ADDRESS  = 9,
        SCL_V_COEFF_BANK_WRITE_ADDRESS = 10,
        SCL_V_COEFF_BANK_READ_ADDRESS  = 11,
        // H_TAP_DATA_BEGIN and V_TAP_DATA_BEGIN are the same address (14),only
        //  by writing to H_PHASE or V_PHASE will internally "commit" them to
        //  the correct memory location within the core.
        SCL_H_TAP_DATA_BEGIN           = 14,
        SCL_H_PHASE                    = 12,
        SCL_V_TAP_DATA_BEGIN           = 14,
        SCL_V_PHASE                    = 13,
    };

    /*
     * @brief       constructor
     * @param       base_address        base address for this core slave interface
     * @pre         this constructor should be used when using compile-time coefficients
     */
    Scaler(unsigned long base_address);

    /*
     * @brief       constructor
     * @param       base_address        base address for this core slave interface
     * @param       h_taps, v_taps      number of horizontal and vertical taps
     * @param       h_phases, v_phases  number of horizontal and vertical phases
     * @param       h_integer_bits      number of integer bits for coefficient quantization
     * @param       h_fraction_bits     number of fraction bits for coefficient quantization
     * @param       v_integer_bits      number of integer bits for coefficient quantization
     * @param       v_fraction_bits     number of fraction bits for coefficient quantization
     * @pre         this constructor should be used when using run-time coefficients
     */
    Scaler(unsigned long base_address, unsigned int h_taps, unsigned int v_taps, unsigned int h_phases, unsigned int v_phases,
           unsigned int h_integer_bits, unsigned int h_fraction_bits, unsigned int v_integer_bits, unsigned int v_fraction_bits);

    /*
     * @brief       Enable edge adaptive scaling at run-time
     */
    inline void enable_edge_adaptive_scaling()
    {
        set_control_bit(CTRL_EDGE_ADAPTIVE_BIT);
    }

    /*
     * @brief       Disable edge adaptive scaling at run-time
     */
    inline void disable_edge_adaptive_scaling()
    {
        unset_control_bit(CTRL_EDGE_ADAPTIVE_BIT);
    }

    /*
     * @brief                  Change the edge adaptive threshold
     * @param new_threshold    The new threshold for the edge_adaptive algorithm
     */
    inline void set_edge_threshold(int new_threshold)
    {
        do_write(SCL_EDGE_THRESHOLD, new_threshold);
    }

    /*
     * @brief                    Change the bank where horizontal coefficients should be written to
     * @param new_h_write_bank   New horizontal write bank
     */
    inline void set_h_write_bank(int new_h_write_bank)
    {
        assert(has_runtime_coefficients);
        do_write(SCL_H_COEFF_BANK_WRITE_ADDRESS, new_h_write_bank);
    }

    /*
     * @brief                    Change the bank where horizontal coefficients should be read from
     * @param new_h_read_bank    New horizontal read bank
     */
    inline void set_h_read_bank(int new_h_read_bank)
    {
        assert(has_runtime_coefficients);
        do_write(SCL_H_COEFF_BANK_READ_ADDRESS, new_h_read_bank);
    }

    /*
     * @brief                    Change the bank where vertical coefficients should be written to
     * @param new_v_write_bank   New vertical write bank
     */
    inline void set_v_write_bank(int new_v_write_bank)
    {
        assert(has_runtime_coefficients);
        do_write(SCL_V_COEFF_BANK_WRITE_ADDRESS, new_v_write_bank);
    }

    /*
     * @brief                    Change the bank where vertical coefficients should be read from
     * @param new_v_read_bank    New vertical read bank
     */
    inline void set_v_read_bank(int new_v_read_bank)
    {
        assert(has_runtime_coefficients);
        do_write(SCL_V_COEFF_BANK_READ_ADDRESS, new_v_read_bank);
    }


    /*
     * @brief                    Change the output dimension
     * @param new_output_width   New output width
     * @param new_output_height  New output height
     * @post   this just changes the output dimensions for the scaling. When using a run-time polyphase scaler,
     *         you should also consider updating the run-time coefficient (especially when downscaling)
     */
    void set_output_resolution(unsigned int new_output_width, unsigned int new_output_height)
    {
        VIP_DEBUG_MSG("Scaler: set_output_size called with %0dx%0d\n", new_output_width, new_output_height);
        do_write(SCL_OUT_WIDTH, new_output_width);
        do_write(SCL_OUT_HEIGHT, new_output_height);
    }

    /*
     * @brief                    Apply a new set of horizontal and vertical coefficients
     * @param h_coeffs           New set of horizontal coefficients
     * @param v_coeffs           New set of vertical coefficients
     * @param h_bank             Horizontal coefficient bank
     * @param v_bank             Vertical coefficient bank
     */
    void apply(const ScalerCoefficientsSet & h_coeffs, const ScalerCoefficientsSet & v_coeffs,
               unsigned int h_bank = 0, unsigned int v_bank = 0);

    /*
     * @brief                    Apply a new set of horizontal and vertical coefficients for the edge adaptive case
     * @param h_edge_coeffs      New set of horizontal coefficients
     * @param v_edge_coeffs      New set of vertical coefficients
     * @param h_bank             Horizontal coefficient bank
     * @param v_bank             Vertical coefficient bank
     */
    void apply_edge(const ScalerCoefficientsSet & h_edge_coeffs, const ScalerCoefficientsSet & v_edge_coeffs,
                    unsigned int h_bank = 0, unsigned int v_bank = 0);

    /*
     * @brief                    Write a a new set of horizontal coeffs (h_phases * h_taps coefficients)
     * @param coeffs             New horizontal coefficients (normalized floating points values)
     * @param edge_coeffs        Use true is the is the set of coefficients to be used when the edge adaptive mode detects an edge
     * @pre                      Select the correct write h_bank before use
     * @pre                      coeffs contains h_phases * h_taps normalized coefficients
     */
    inline void write_h_coeffs(const float *coeffs, bool edge_coeffs = false)
    {
        assert(has_runtime_coefficients);
        write_h_coeffs(QuantizedCoefficients(true, h_integer_bits, h_fraction_bits, coeffs, h_taps*h_phases), edge_coeffs);
    }

    /*
     * @brief                    Write a a new set of horizontal coeffs (h_phases * h_taps coefficients)
     * @param coeffs             New horizontal coefficients (quantized values)
     * @param edge_coeffs        Use true is the is the set of coefficients to be used when the edge adaptive mode detects an edge
     * @pre                      Select the correct write h_bank before use
     * @pre                      coeffs contains h_phases * h_taps quantized coefficients
     */
    void write_h_coeffs(const long *coeffs, bool edge_coeffs = false);

    /*
     * @brief                    Write a a new set of vertical coeffs (v_phases * v_taps coefficients)
     * @param coeffs             New horizontal coefficients (normalized floating points values)
     * @param edge_coeffs        Use true is the is the set of coefficients to be used when the edge adaptive mode detects an edge
     * @pre                      Select the correct write v_bank before use
     * @pre                      coeffs containsv_phases * v_taps normalized coefficients
     */
    inline void write_v_coeffs(const float *coeffs, bool edge_coeffs = false)
    {
        assert(has_runtime_coefficients);
        write_v_coeffs(QuantizedCoefficients(true, v_integer_bits, v_fraction_bits, coeffs, v_taps*v_phases), edge_coeffs);
    }

    /*
     * @brief                    Write a a new set of vertical coeffs (v_phases * v_taps coefficients)
     * @param coeffs             New horizontal coefficients (quantized values)
     * @param edge_coeffs        Use true is the is the set of coefficients to be used when the edge adaptive mode detects an edge
     * @pre                      Select the correct write v_bank before use
     * @pre                      coeffs contains v_phases * v_taps quantized coefficients
     */
    void write_v_coeffs(const long *coeffs, bool edge_coeffs = false);

private:
    bool has_runtime_coefficients;
    unsigned int h_taps;
    unsigned int v_taps;
    unsigned int h_phases;
    unsigned int v_phases;
    unsigned int h_integer_bits;
    unsigned int h_fraction_bits;
    unsigned int v_integer_bits;
    unsigned int v_fraction_bits;
};

#endif     // __SCALER_HPP__
