#include "timer_driver.h"

Timer_RegMap* Timer_Init(uintptr_t base_addr) {
    Timer_RegMap* timer = (Timer_RegMap*)base_addr;
    
    // Put timer in reset state initially (Assert RESET bit)
    // CTRL Bit 0 = 1 (Reset active) 
    timer->CTRL |= TIMER_CTRL_RESET_MASK;
    
    // Disable interrupts by default
    timer->CTRL &= ~TIMER_CTRL_IE_MASK;
    
    return timer;
}

void Timer_SetPrescaler(Timer_RegMap* timer, uint32_t prescaler) {
    // Write to Offset 0x0C 
    timer->PRESCALER_VALUE = prescaler;
}

void Timer_SetThreshold(Timer_RegMap* timer, uint32_t threshold) {
    // Write to Offset 0x10
    timer->THRESHOLD_VALUE = threshold;
}

uint32_t Timer_GetPrescaler(Timer_RegMap* timer) {
    // Read Offset 0x0C
    return timer->PRESCALER_VALUE;
}

uint32_t Timer_GetThreshold(Timer_RegMap* timer) {
    // Read Offset 0x10
    return timer->THRESHOLD_VALUE;
}

void Timer_EnableInterrupt(Timer_RegMap* timer, bool enable) {
    uint32_t ctrl = timer->CTRL;
    
    if (enable) {
        ctrl |= TIMER_CTRL_IE_MASK; // Set Bit 1 
    } else {
        ctrl &= ~TIMER_CTRL_IE_MASK;
    }
    
    timer->CTRL = ctrl;
}

void Timer_Start(Timer_RegMap* timer) {
    // To start: RESET bit must be 0
    uint32_t ctrl = timer->CTRL;
    ctrl &= ~TIMER_CTRL_RESET_MASK; 
    timer->CTRL = ctrl;
}

void Timer_Stop(Timer_RegMap* timer) {
    // To stop/reset: RESET bit must be 1 
    uint32_t ctrl = timer->CTRL;
    ctrl |= TIMER_CTRL_RESET_MASK;
    timer->CTRL = ctrl;
}

uint32_t Timer_GetValue(Timer_RegMap* timer) {
    // Read Offset 0x08 [cite: 136]
    return timer->COUNTER_VALUE;
}

bool Timer_GetStatusAndClear(Timer_RegMap* timer) {
    // Reading Offset 0x00 returns status and clears the sticky bit
    uint32_t status = timer->STATUS;
    return (status & TIMER_STATUS_THRESHOLD_MASK) ? true : false;
}
