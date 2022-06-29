#ifndef __CLIPPER_HPP__
#define __CLIPPER_HPP__

#include "VipCore.hpp"

class Clipper : public VipCore {
private:
    Clipper (const Clipper&);  // Disable the copy constructor

public:
    // Clipper specific registers
    enum ClipperRegisterType {
        CLP_LEFT_OFFSET   = 3,
        CLP_RIGHT_OFFSET  = 4,
        CLP_TOP_OFFSET    = 5,
        CLP_BOTTOM_OFFSET = 6,
        // In "rectangle" mode, registers 4 and 6 are now the width and height instead of right offset and bottom offset
        CLP_WIDTH         = 4,
        CLP_HEIGHT        = 6,
    };

    /*
     * @brief   constructor
     * @param   base_address    Base address of the slave interface (usually found in system.h)
     * @param   rectangle_mode  Whether the clipper was parmaeterized in rectangle mode
     */
    Clipper(const long base_address, bool rectangle_mode);

    /*
     * @brief   change the left offset
     * @param   left_offset     New left offset
     */
    inline void set_left_offset(unsigned int left_offset) {
        do_write(CLP_LEFT_OFFSET, left_offset);
    }

    /*
     * @brief   change the right offset
     * @param   right_offset     New right offset
     * @pre     rectangle_mode == false
     */
    inline void set_right_offset(unsigned int right_offset) {
        assert(!rectangle_mode);
        do_write(CLP_RIGHT_OFFSET, right_offset);
    }

    /*
     * @brief   change the top offset
     * @param   top_offset      New top offset
     */
    inline void set_top_offset(unsigned int top_offset) {
        do_write(CLP_TOP_OFFSET, top_offset);
    }

    /*
     * @brief   change the bottom offset
     * @param   bottom_offset      New bottom offset
     * @pre     rectangle_mode == false
     */
    inline void set_bottom_offset(unsigned int bottom_offset) {
        assert(!rectangle_mode);
        do_write(CLP_BOTTOM_OFFSET, bottom_offset);
    }

    /*
     * @brief   change the width
     * @param   width        New width
     * @pre     rectangle_mode == true
     */
    inline void set_width(unsigned int width){
        assert(rectangle_mode);
        do_write(CLP_WIDTH, width);
    }

    /*
     * @brief   change the height
     * @param   height       New height
     * @pre     rectangle_mode == true
     */
    inline void set_height(unsigned int height) {
        assert(rectangle_mode);
        do_write(CLP_HEIGHT, height);
    }


    /*
     * @brief   change the offsets
     * @param   left_offset     New left offset
     * @param   right_offset     New right offset
     * @param   top_offset      New top offset
     * @param   bottom_offset      New bottom offset
     * @pre     rectangle_mode == false
     */
    void set_offsets(unsigned int left_offset, unsigned int right_offset,
                     unsigned int top_offset, unsigned int bottom_offset);

    /*
     * @brief   change the rectangle top-left corner and dimensions
     * @param   left_offset     New left offset
     * @param   top_offset      New top offset
     * @param   width           New width
     * @param   height          New height
     * @pre     rectangle_mode == true
     */
    void set_rectangle(unsigned int left_offset, unsigned int top_offset,
                       unsigned int width, unsigned int height);

private:
    bool rectangle_mode;
};

#endif    // __CLIPPER_HPP__
