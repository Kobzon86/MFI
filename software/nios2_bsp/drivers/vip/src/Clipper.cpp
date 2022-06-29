#include "Clipper.hpp"

Clipper::Clipper(const long base_address, bool rectangle_mode)
: VipCore(base_address), rectangle_mode(rectangle_mode)
{
}


void Clipper::set_offsets(unsigned int left_offset, unsigned int right_offset,
                 unsigned int top_offset, unsigned int bottom_offset) {
    set_left_offset(left_offset);
    set_right_offset(right_offset);
    set_top_offset(top_offset);
    set_bottom_offset(bottom_offset);
}


void Clipper::set_rectangle(unsigned int left_offset, unsigned int top_offset,
                   unsigned int width, unsigned int height) {
    set_left_offset(left_offset);
    set_top_offset(top_offset);
    set_width(width);
    set_height(height);
}
