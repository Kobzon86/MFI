#ifndef __VIP_CORE_HPP__
#define __VIP_CORE_HPP__

#include "VipUtil.hpp"

#include <system.h>
#include <io.h>
#include <sys/alt_irq.h>
#include <cassert>

class VipCore
{
public:
    enum {
        REGISTER_CONTROL   = 0,
        REGISTER_STATUS    = 1,
        REGISTER_INTERRUPT = 2,
    };

    /**
     * @brief  Register a callback function to do custom processing during interrupt servicing
     * @param  user_isr               the callback function.
     *                                It's API is as follows unsigned user_isr(VipCore* this, unsigned interrupt_mask)
     *                                The interrupt_mask is the content of the interrupt register read after the interrupt
     *                                fired. Returning the interrupt_mask unchanged should clear all raised interrupts.
     *                                Returning 0 will leave the interrupt(s) raised.
     *                                Use NULL to disable the callback.
     * @pre   irq_number != -1        A valid IRQ number must have been specified at construction (otherwise registering
     *                                a callback would not make much sense)
     */
    inline void register_user_isr(unsigned int (*user_isr)(VipCore*, unsigned int))
    {
        assert(irq_number != -1);
        this->user_isr = user_isr;
    }

    /**
     * @brief   Accessor for base_address
     * @return  base_address
     */
    inline unsigned long get_base_address() const
    {
        return base_address;
    }

    /**
     * @brief   Start the core
     * @return  Set the go bit (bit 0 of control register 0) to 1
     */
    inline void start()
    {
        control_reg = control_reg | 1;
        reg_write(REGISTER_CONTROL, control_reg);
    }

    /**
     * @brief   Stop the core
     * @post    Set the go bit (bit 0 of control register 0) to 0
     * @post    The core will schedule a stop at the end of a current frame. Use is_running() to poll its status
     */
    inline void stop()
    {
        control_reg = control_reg & ~1;
        reg_write(REGISTER_CONTROL, control_reg);
    }

    /**
     * @brief   Stop the core and wait for it to actually stop. In many cases, the safest way to reprogram a core is to call
     *          this function before changing its run-time parameters.
     * @post    Set the go bit (bit 0 of control register 0) to 0. Poll the status bit (bit 0 of the status register 1) until it is cleared.
     * @post    The core will schedule a stop at the end of a current frame and wait for is_running() to return false
     * @pre     The system is in a state where the core can finish the frame. The call may never return is the HW core is back-pressured and cannot finish a frame
     */
    inline void stop_and_wait()
    {
        stop();
        while(is_running()) {}
    }

    /**
     * @brief   Check whether the core was started
     * @post    Check the value of the go bit on the cached control register.
     *          Note that the control register is in general not readable so the actual HW value cannot be determined.
     */
    inline bool is_on() const
    {
        return control_reg & 0x1;
    }

    /**
     * @brief   Turn on a control register bit
     * @param   control_bit        the bit to enable.
     * @post    Set a control bit
     * @pre     control_bit >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline void set_control_bit(unsigned int control_bit)
    {
        assert(control_bit >= 1);
        int control_mask = 1 << control_bit;
        control_reg = control_reg | control_mask;
        reg_write(REGISTER_CONTROL, control_reg);
    }

    /**
     * @brief   Turn off a control register bit
     * @param   control_bit        the bit to disable.
     * @post    Reset a control bit to 0
     * @pre     control_bit >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline void unset_control_bit(unsigned int control_bit)
    {
        assert(control_bit >= 1);
        int control_mask = 1 << control_bit;
        control_reg = control_reg & ~control_mask;
        reg_write(REGISTER_CONTROL, control_reg);
    }
    /**
     * @brief   Check whether the control bit is set
     * @param   control_bit        the bit to check.
     * @post    Check the value of the requested control bit on the cached control register.
     *          Note that the control register is in general not readable so the actual HW value cannot be determined.
     * @pre     control_bit >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline bool is_control_bit_enabled(unsigned int control_bit) const
    {
        assert(control_bit >= 1);
        int control_mask = 1 << control_bit;
        return control_reg & control_mask;
    }

    /**
     * @brief   Enable an interrupt
     * @param   interrupt_number   the id of the interrupt to enable. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                             circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                             they refer to different things.
     * @post    Set the interrupt bit (bit interrupt_number of control register 0) to 1.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline void enable_interrupt(unsigned int interrupt_number)
    {
        set_control_bit(interrupt_number);
    }

    /**
     * @brief   Disable an interrupt
     * @param   interrupt_number   the id of the interrupt to enable. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                             circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                             they refer to different things.
     * @post    Set the interrupt bit (interrupt_number of control register 0) to 0.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline void disable_interrupt(unsigned int interrupt_number)
    {
        unset_control_bit(interrupt_number);
    }

    /**
     * @brief   Check whether the interrupt was enabled
     * @param   interrupt_number   the id of the interrupt to enable. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                             circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                             they refer to different things.
     * @post    Check the value of the requested interrupt bit on the cached control register.
     *          Note that the control register is in general not readable so the actual HW value cannot be determined.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline bool is_interrupt_enabled(unsigned int interrupt_number) const
    {
        return is_control_bit_enabled(interrupt_number);
    }

    /**
     * @brief   Write to the control register
     * @param   new control_reg, new content for the control register
     * @post    Overwrite the full control register. Usage is discouraged.
     *          Please consider using the start/stop and enable/disable interrupts functions
     *
     */
    inline void write_control_register(unsigned int new_control_reg)
    {
        control_reg = new_control_reg;
        reg_write(REGISTER_CONTROL, control_reg);
    }

    /**
     * @brief   Read the status register
     * @return  Current status register value
     *
     */
    inline unsigned int read_status_register() const
    {
        return reg_read(REGISTER_STATUS);
    }

    /**
     * @brief   Check a bit of the status register
     * @param   bit, the bit of interest
     * @return  Current value of the bit in the status register
     *
     */
    inline bool read_status_register_bit(unsigned int bit) const
    {
        return read_status_register_bit(bit, read_status_register());
    }
    /**
     * @brief   Check a bit of the status register
     * @param   bit, the bit of interest
     * @param   status_register, the status register
     * @return  Current value of the bit in the status register
     *
     */
    inline static bool read_status_register_bit(unsigned int bit, unsigned int status_register)
    {
        return status_register & (1<<bit);
    }

    /**
     * @brief   Check whether the core is running (bit 0 of the status register).
     *          Note that most cores will go into non-running state at the end of an image packet and will stay in this
     *          state until they receive the start of the next packet (and the go bit is set to 1).
     *          The safest time to reprogram the core is when the go bit was set to 0 and wait for the running bit to read 0.
     * @return  Bit 0 of the status register
     */
    inline bool is_running() const
    {
        return reg_read(REGISTER_STATUS) & 0x1;
    }

    /**
     * @brief   Read the interrupt register
     * @return  Current interrupt register value
     *
     */
    inline unsigned int read_interrupt_register() const
    {
        return reg_read(REGISTER_INTERRUPT);
    }

    /**
     * @brief   Check whether the interrupt has fired
     * @param   interrupt_number   the id of the interrupt to enable. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                             circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                             they refer to different things.
     * @post    Check the value of the requested interrupt bit on the interrupt register.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline bool has_interrupt_fired(unsigned int interrupt_number) const
    {
        return has_interrupt_fired(read_interrupt_register(), interrupt_number);
    }

    /**
     * @brief   Check whether the interrupt has fired
     * @param   interrupt_reg       the content of the interrupt register (so that it is not read again when this is not necessary)
     * @param   interrupt_number    the id of the interrupt to enable. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                              circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                              they refer to different things.
     * @post    Check the value of the requested interrupt bit on the provided interrupt register.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline static bool has_interrupt_fired(int interrupt_reg, unsigned int interrupt_number)
    {
        assert(interrupt_number >= 1);
        int interrupt_mask = 1 << interrupt_number;
        return interrupt_reg & interrupt_mask;
    }

    /**
     * @brief   Write to the interrupt register
     * @param   interrupt_mask   the value to write to the interrupt register
     * @post    Typically, this action clears the interrupts flagged in interrupt_mask
     */
    inline void write_interrupt_register(unsigned int interrupt_mask)
    {
        reg_write(REGISTER_INTERRUPT, interrupt_mask);
    }

    /**
     * @brief   Write to the interrupt register to clear a specified interrupt
     * @param   interrupt_number    the id of the interrupt to clear. Please consult the VIP user guide to find out the mapping between interrupt numbers and the
     *                              circumstances in which an interrupt may be raised. Beware, this number is unrelated to the irq_number given at construction as
     *                              they refer to different things.
     * @post    Clears the interrupt interrupt_number. If this was the last raised interrupt the irq line should go low.
     * @pre     interrupt_number >= 1. By convention, interrupts start at 8 as the first byte of the control register is
     *          reserved for other purposes
     */
    inline void clear_interrupt(unsigned int interrupt_number)
    {
        assert(interrupt_number >= 1);
        unsigned int interrupt_mask = 1 << interrupt_number;
        reg_write(REGISTER_INTERRUPT, interrupt_mask);
    }

    /**
     * @brief   Write to the specified register
     * @param   offset    the register number
     * @param   value     new register content
     * @pre     offset > 2. Use write_control_register() and write_interrupt_register() for direct access to the base registers
     */
    inline void do_write(unsigned int offset, unsigned int value)
    {
        assert(offset > 2); // This is not the appropriate function to modify the control/status/interrupt registers
        IOWR(base_address, offset, value);
    }


    /**
     * @brief   Read the specified register
     * @param   offset    the register number
     * @return  value     the value read
     * @pre     offset > 2. Use read_status_register() and read_interrupt_register() for direct access to the base registers
     */
    inline unsigned int do_read(unsigned int offset) const
    {
        assert(offset != 0); // Control register is read-only
        return IORD(this->base_address, offset);
    }

protected:

    /**
     * @brief  An internal non-public version of do_write that may also be used for the control and interrupt register
     */
    inline void reg_write(unsigned int offset, unsigned int value)
    {
        assert(offset != 1);
        IOWR(base_address, offset, value);
    }

    /**
     * @brief  An internal non-public version of do_read that may also be used for the status and interrupt register
     */
    inline unsigned int reg_read(unsigned int offset) const
    {
        assert(offset != 0);
        return IORD(base_address, offset);
    }

    /**
     * @brief  VipCore base class constructor. Protected to prevent direct use, please only use the derived classes
     * @param  base_address           base_address of the core in the Nios address space, typically hash-defined in the BSP (system.h)
     * @param  irq_number             optional irq_number. If set, the constructor will setup an interrupt service routine to clear the interrupts raised by the core
     *                                the irq numbers for each core are usuall hash-defined by the BSP in system.h
     *                                You may register a custom callback function to add your own processing when an interrupt is raised
     *                                You may also leave it to its default -1 value should you wish to register your own interrupt service routine manually
     */
    VipCore(unsigned long base_address, int irq_number = -1);

    /**
     * @brief  VipCore base class destructor. Protected to prevent direct use, please only use the derived classes
     * @post   if a valid irq_number was specified at construction, the destructor will disable the interrupt
     */
    ~VipCore();

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
    // Interrupt service routine registered by the core at construction if the user specified an irq number (new api)
    static void genericISR(void* context);
#else
    // Interrupt service routine registered by the core at construction if the user specified an irq number (legacy api)
    static void genericISR_legacy(void* context, alt_u32 id);
#endif

private:
    /**
     * @brief   Generic interrupt service routine. If the user specified a callback function, it will be called and
     *          its return value will determine which interrupt causes should be cleared. If no user callback was specified,
     *          all interrupt causes for this core are cleared
     */
    void isr ();

    unsigned long base_address;
    int irq_number;
    unsigned int control_reg;  // The control register is write-only. It is cached locally so that individual bit may be written without clearing the others
    unsigned int (*user_isr)(VipCore*, unsigned int);      // Optional register interrupt handler
};


#endif //  __VIP_CORE_HPP__
