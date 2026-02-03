#ifndef TIMER_DRIVER_H
#define TIMER_DRIVER_H

#include <stdint.h>
#include <stdbool.h>

/* --------------------------------------------------------------------------
   Register Map Structure
   Offsets derived from axi_timer.sv [cite: 63-66] and README 
   -------------------------------------------------------------------------- */
typedef struct {
    volatile uint32_t STATUS;          // 0x00: Status Register (RO, clear on read)
    volatile uint32_t CTRL;            // 0x04: Control Register (RW)
    volatile uint32_t COUNTER_VALUE;   // 0x08: Current Counter Value (RO)
    volatile uint32_t PRESCALER_VALUE; // 0x0C: Prescaler Value (RW)
    volatile uint32_t THRESHOLD_VALUE; // 0x10: Threshold Value (RW)
} Timer_RegMap;

/* --------------------------------------------------------------------------
   Bit Definitions
   -------------------------------------------------------------------------- */

// STATUS Register (0x00)
#define TIMER_STATUS_THRESHOLD_MASK (1U << 0) // Bit 0: Threshold reached [cite: 118]

// CTRL Register (0x04)
#define TIMER_CTRL_IE_MASK          (1U << 1) // Bit 1: Interrupt Enable [cite: 127]
#define TIMER_CTRL_RESET_MASK       (1U << 0) // Bit 0: Reset (Active High) 

/* --------------------------------------------------------------------------
   Function Prototypes
   -------------------------------------------------------------------------- */

/**
 * @brief Initialize the timer instance.
 * @param base_addr Physical base address of the AXI Timer.
 * @return Pointer to the Timer_RegMap structure.
 */
Timer_RegMap* Timer_Init(uintptr_t base_addr);

/**
 * @brief Configure the prescaler.
 * Formula: Fcnt = Fclk / (1 + prescaler) 
 * @param timer Pointer to timer instance.
 * @param prescaler Value to divide clock by.
 */
void Timer_SetPrescaler(Timer_RegMap* timer, uint32_t prescaler);

/**
 * @brief Set the target threshold value.
 * @param timer Pointer to timer instance.
 * @param threshold Value at which the timer resets and interrupts.
 */
void Timer_SetThreshold(Timer_RegMap* timer, uint32_t threshold);

/**
 * @brief Read the currently configured prescaler value.
 * @param timer Pointer to timer instance.
 * @return Current 32-bit prescaler value.
 */
uint32_t Timer_GetPrescaler(Timer_RegMap* timer);

/**
 * @brief Read the currently configured threshold value.
 * @param timer Pointer to timer instance.
 * @return Current 32-bit threshold value.
 */
uint32_t Timer_GetThreshold(Timer_RegMap* timer);

/**
 * @brief Enable or disable timer interrupts.
 * @param timer Pointer to timer instance.
 * @param enable true to enable, false to disable.
 */
void Timer_EnableInterrupt(Timer_RegMap* timer, bool enable);

/**
 * @brief Start the timer (releases the RESET bit).
 * @param timer Pointer to timer instance.
 */
void Timer_Start(Timer_RegMap* timer);

/**
 * @brief Stop/Reset the timer (asserts the RESET bit).
 * Note: Keeps counter held at 0 while stopped.
 * @param timer Pointer to timer instance.
 */
void Timer_Stop(Timer_RegMap* timer);

/**
 * @brief Get the current counter value.
 * @param timer Pointer to timer instance.
 * @return Current 32-bit counter value.
 */
uint32_t Timer_GetValue(Timer_RegMap* timer);

/**
 * @brief Check if threshold was reached and clear the status bit.
 * Note: Reading the status register clears the hardware sticky bit[cite: 122].
 * @param timer Pointer to timer instance.
 * @return true if threshold was reached, false otherwise.
 */
bool Timer_GetStatusAndClear(Timer_RegMap* timer);

#endif // TIMER_DRIVER_H
