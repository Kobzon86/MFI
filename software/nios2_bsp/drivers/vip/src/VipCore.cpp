#include "VipCore.hpp"

#include "VipUtil.hpp"

VipCore::VipCore(unsigned long base_address, int irq_number)
: base_address(base_address), irq_number(irq_number) {
    // Stop the core, reset to default state
    control_reg = 0;
    reg_write(REGISTER_CONTROL, control_reg);
    user_isr = NULL;

    if (irq_number != -1) {
        // Clear all interrupts
        reg_write(REGISTER_INTERRUPT, -1);

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
        // Enhanced mode, use prototype:
        //  extern int alt_ic_isr_register(alt_u32 ic_id, alt_u32 irq, alt_isr_func isr, void *isr_context, void *flags);
        alt_ic_isr_register(0, irq_number, genericISR, this, NULL);
#else
        // Legacy mode, use prototype:
        // extern int alt_irq_register (alt_u32 id, void* context, alt_isr_func handler)
        alt_irq_register(irq_number, this, genericISR_legacy);
#endif
    }
}

VipCore::~VipCore()
{
    // Deregister the ISR
    if (irq_number != -1) {
#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
        alt_ic_isr_register(0, irq_number, NULL, this, NULL);
#else
        alt_irq_register(irq_number, this, NULL);
#endif
    }
}

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
void VipCore::genericISR(void* context)
#else
void VipCore::genericISR_legacy(void* context, alt_u32 id)
#endif
{
    VipCore* core = (VipCore*)context;
    core->isr();
}

void VipCore::isr()
{
    // Get the status that triggered the interrupt
    unsigned int interrupt_status = read_interrupt_register();
    // User callback (optional)
    if (user_isr) {
        interrupt_status = user_isr(this, interrupt_status);
    }
    // Clear the interrupt(s)
    write_interrupt_register(interrupt_status);
}
