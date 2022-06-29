#ifndef __SWITCH_HPP__
#define __SWITCH_HPP__

#include "VipCore.hpp"

class Switch : public VipCore {
private:
    Switch(const Switch&);  // Disable copy constructor

public:
    Switch(long base_address);
};

#endif   // __SWITCH_HPP__
