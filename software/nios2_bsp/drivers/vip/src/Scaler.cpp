#include "Scaler.hpp"

#include "VipUtil.hpp"

#include <cassert>

Scaler::Scaler(unsigned long base_address)
: VipCore(base_address), has_runtime_coefficients(false),
  h_taps(0), v_taps(0), h_phases(0), v_phases(0),
  h_integer_bits(0), h_fraction_bits(0), v_integer_bits(0), v_fraction_bits(0) {
}

Scaler::Scaler(unsigned long base_address, unsigned int h_taps, unsigned int v_taps, unsigned int h_phases, unsigned int v_phases,
               unsigned int h_integer_bits, unsigned int h_fraction_bits, unsigned int v_integer_bits, unsigned int v_fraction_bits)
: VipCore(base_address), has_runtime_coefficients(true),
  h_taps(h_taps), v_taps(v_taps), h_phases(h_phases), v_phases(v_phases),
  h_integer_bits(h_integer_bits), h_fraction_bits(h_fraction_bits), v_integer_bits(v_integer_bits), v_fraction_bits(v_fraction_bits) {
}

void Scaler::apply(const ScalerCoefficientsSet & h_coeffs, const ScalerCoefficientsSet & v_coeffs,
                   unsigned int h_bank, unsigned int v_bank)
{
    assert(has_runtime_coefficients);
    assert(h_coeffs.get_number_of_phases() == h_phases);
    assert(h_coeffs.get_number_of_taps() == h_taps);
    assert(v_coeffs.get_number_of_phases() == v_phases);
    assert(v_coeffs.get_number_of_taps() == v_taps);
    set_h_write_bank(h_bank);
    set_v_write_bank(v_bank);
    write_h_coeffs(h_coeffs);
    write_v_coeffs(v_coeffs);
}

void Scaler::apply_edge(const ScalerCoefficientsSet & h_edge_coeffs, const ScalerCoefficientsSet & v_edge_coeffs,
                        unsigned int h_bank, unsigned int v_bank)
{
    assert(has_runtime_coefficients);
    assert(h_edge_coeffs.get_number_of_phases() == h_phases);
    assert(h_edge_coeffs.get_number_of_taps() == h_taps);
    assert(v_edge_coeffs.get_number_of_phases() == v_phases);
    assert(v_edge_coeffs.get_number_of_taps() == v_taps);
    set_h_write_bank(h_bank);
    set_v_write_bank(v_bank);
    write_h_coeffs(h_edge_coeffs, true);
    write_v_coeffs(v_edge_coeffs, true);
}

void Scaler::write_h_coeffs(const long *coeffs, bool edge_coeffs)
{
    assert(has_runtime_coefficients);

    VIP_DEBUG_MSG("Scaler: Setting coefficients for the horizontal phases\n");
    for(unsigned int i=0; i < h_phases; i++)
    {
        for(unsigned int j=0; j < h_taps; j++)
        {
            do_write(SCL_H_TAP_DATA_BEGIN + j, *coeffs++);
        }
        do_write(SCL_H_PHASE, i + (edge_coeffs ? (1 << 15) : 0));
    }
}

void Scaler::write_v_coeffs(const long *coeffs, bool edge_coeffs)
{
    assert(has_runtime_coefficients);
    VIP_DEBUG_MSG("Scaler: Setting coefficients for the vertical phases\n");
    for(unsigned int i=0; i < v_phases; i++)
    {
        for(unsigned int j=0; j < v_taps; j++)
        {
            do_write(SCL_V_TAP_DATA_BEGIN + j, *coeffs++);
        }
        do_write(SCL_V_PHASE, i + (edge_coeffs ? (1 << 15) : 0));
    }
}
