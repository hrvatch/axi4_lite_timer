#ifndef AXI4_LITE_TIMER_H
#define AXI4_LITE_TIMER_H

#include <stdint.h>

/**
 * @file axi4_lite_timer.h
 * @brief AXI4-Lite Timer/Counter Peripheral Driver
 * @version 1.1
 * @date 2026-01-03
 * 
 * This header provides register definitions and helper functions for the
 * dual 32-bit timer/counter peripheral with AXI4-Lite interface.
 * 
 * @note Designed for RV32IMC RISC-V cores with 32-bit bus
 * @note All registers are naturally aligned (4-byte boundaries)
 * @note Uses 'volatile' to prevent compiler optimizations on I/O accesses
 */

// ============================================================================
// Register Bit-Field Definitions
// ============================================================================

/**
 * @brief Timer0 Control Register (TIMER0_CTRL)
 * @details Address offset: 0x00
 * 
 * Bit assignments:
 *   [0]    - ENABLE:    0=Disable, 1=Enable
 *   [1]    - RELOAD:    0=Wrap on rollover, 1=Reload LOAD value
 *   [2]    - DIRECTION: 0=Count down, 1=Count up
 *   [31:3] - Reserved
 */
typedef union {
    struct {
        uint32_t enable    : 1;  ///< Bit 0: Timer enable (0=Disabled, 1=Enabled)
        uint32_t reload    : 1;  ///< Bit 1: Reload mode (0=Wrap, 1=Reload)
        uint32_t direction : 1;  ///< Bit 2: Count direction (0=Down, 1=Up)
        uint32_t reserved  : 29; ///< Bits 3-31: Reserved
    } bits;
    uint32_t reg; ///< Full 32-bit register access
} timer0_ctrl_t;

/**
 * @brief Timer1 Control Register (TIMER1_CTRL)
 * @details Address offset: 0x0C
 * 
 * Bit assignments:
 *   [0]    - ENABLE:    0=Disable, 1=Enable
 *   [1]    - RELOAD:    0=Wrap on rollover, 1=Reload LOAD value
 *   [2]    - DIRECTION: 0=Count down, 1=Count up
 *   [3]    - SOURCE:    0=System clock, 1=Timer0 done pulse
 *   [31:4] - Reserved
 */
typedef union {
    struct {
        uint32_t enable    : 1;  ///< Bit 0: Timer enable (0=Disabled, 1=Enabled)
        uint32_t reload    : 1;  ///< Bit 1: Reload mode (0=Wrap, 1=Reload)
        uint32_t direction : 1;  ///< Bit 2: Count direction (0=Down, 1=Up)
        uint32_t source    : 1;  ///< Bit 3: Clock source (0=Clock, 1=Timer0 done)
        uint32_t reserved  : 28; ///< Bits 4-31: Reserved
    } bits;
    uint32_t reg; ///< Full 32-bit register access
} timer1_ctrl_t;

// ============================================================================
// Complete Timer Register Blocks
// ============================================================================

/**
 * @brief Timer0 Register Block
 * @details Contains all Timer0 registers at offsets 0x00-0x0C
 */
typedef struct {
    volatile timer0_ctrl_t ctrl;     ///< 0x00: Control register
    volatile uint32_t      load;     ///< 0x04: Load/initial value
    volatile uint32_t      compare;  ///< 0x08: Compare/target value
    volatile uint32_t      value;    ///< 0x0C: Current counter value (read-only)
} timer0_regs_t;

/**
 * @brief Timer1 Register Block  
 * @details Contains all Timer1 registers at offsets 0x10-0x1C
 */
typedef struct {
    volatile timer1_ctrl_t ctrl;     ///< 0x10: Control register
    volatile uint32_t      load;     ///< 0x14: Load/initial value
    volatile uint32_t      compare;  ///< 0x18: Compare/target value
    volatile uint32_t      value;    ///< 0x1C: Current counter value (read-only)
} timer1_regs_t;

/**
 * @brief Complete AXI Timer Register Map
 * @details Full memory-mapped register structure for both timers
 * 
 * Memory layout:
 *   0x00: TIMER0_CTRL
 *   0x04: TIMER0_LOAD
 *   0x08: TIMER0_COMPARE
 *   0x0C: TIMER0_VALUE
 *   0x10: TIMER1_CTRL
 *   0x14: TIMER1_LOAD
 *   0x18: TIMER1_COMPARE
 *   0x1C: TIMER1_VALUE
 * 
 * @note All registers are 4-byte aligned for RV32IMC lw/sw instructions
 */
typedef struct {
    timer0_regs_t timer0;  ///< 0x00-0x0C: Timer0 registers
    timer1_regs_t timer1;  ///< 0x10-0x1C: Timer1 registers
} __attribute__((packed, aligned(4))) axi_timer_regs_t;

// ============================================================================
// Memory-Mapped Base Address
// ============================================================================

/**
 * @def AXI_TIMER_BASE_ADDR
 * @brief Base address of the AXI Timer peripheral
 * @note Update this address to match your system's memory map
 */
#ifndef AXI_TIMER_BASE_ADDR
#define AXI_TIMER_BASE_ADDR  0x00004000UL
#endif

/**
 * @def AXI_TIMER
 * @brief Pointer to memory-mapped AXI Timer registers
 */
#define AXI_TIMER  ((axi_timer_regs_t *)AXI_TIMER_BASE_ADDR)

// ============================================================================
// Individual Register Access Macros
// ============================================================================

/// @brief Timer0 Control register
#define TIMER0_CTRL    (AXI_TIMER->timer0.ctrl)
/// @brief Timer0 Load value register
#define TIMER0_LOAD    (AXI_TIMER->timer0.load)
/// @brief Timer0 Compare value register
#define TIMER0_COMPARE (AXI_TIMER->timer0.compare)
/// @brief Timer0 Current value register (read-only)
#define TIMER0_VALUE   (AXI_TIMER->timer0.value)

/// @brief Timer1 Control register
#define TIMER1_CTRL    (AXI_TIMER->timer1.ctrl)
/// @brief Timer1 Load value register
#define TIMER1_LOAD    (AXI_TIMER->timer1.load)
/// @brief Timer1 Compare value register
#define TIMER1_COMPARE (AXI_TIMER->timer1.compare)
/// @brief Timer1 Current value register (read-only)
#define TIMER1_VALUE   (AXI_TIMER->timer1.value)

// ============================================================================
// Timer0 Helper Functions
// ============================================================================

/**
 * @brief Enable Timer0
 */
static inline void timer0_enable(void) {
    TIMER0_CTRL.bits.enable = 1;
}

/**
 * @brief Disable Timer0
 */
static inline void timer0_disable(void) {
    TIMER0_CTRL.bits.enable = 0;
}

/**
 * @brief Set Timer0 counting direction
 * @param count_up 1 = count up, 0 = count down
 */
static inline void timer0_set_direction(uint8_t count_up) {
    TIMER0_CTRL.bits.direction = count_up ? 1 : 0;
}

/**
 * @brief Set Timer0 reload mode
 * @param reload_on_rollover 1 = reload on compare match, 0 = wrap
 */
static inline void timer0_set_reload(uint8_t reload_on_rollover) {
    TIMER0_CTRL.bits.reload = reload_on_rollover ? 1 : 0;
}

/**
 * @brief Configure Timer0 (does not enable)
 * @param load_val Initial/reload value
 * @param compare_val Target/compare value
 * @param count_up 1 = count up, 0 = count down
 * @param reload 1 = reload on match, 0 = wrap
 */
static inline void timer0_configure(uint32_t load_val, uint32_t compare_val,
                                    uint8_t count_up, uint8_t reload) {
    TIMER0_LOAD = load_val;
    TIMER0_COMPARE = compare_val;
    TIMER0_CTRL.bits.direction = count_up ? 1 : 0;
    TIMER0_CTRL.bits.reload = reload ? 1 : 0;
}

/**
 * @brief Configure and enable Timer0 for periodic operation
 * @param load_val Initial value (typically 0)
 * @param compare_val Period in clock cycles
 * @param count_up 1 = count up, 0 = count down
 */
static inline void timer0_start_periodic(uint32_t load_val, uint32_t compare_val,
                                         uint8_t count_up) {
    timer0_configure(load_val, compare_val, count_up, 1);
    timer0_enable();
}

/**
 * @brief Read Timer0 current counter value
 * @return Current counter value (32-bit)
 * @note Volatile access ensures actual hardware read
 */
static inline uint32_t timer0_get_value(void) {
    return TIMER0_VALUE;
}

// ============================================================================
// Timer1 Helper Functions
// ============================================================================

/**
 * @brief Enable Timer1
 */
static inline void timer1_enable(void) {
    TIMER1_CTRL.bits.enable = 1;
}

/**
 * @brief Disable Timer1
 */
static inline void timer1_disable(void) {
    TIMER1_CTRL.bits.enable = 0;
}

/**
 * @brief Set Timer1 counting direction
 * @param count_up 1 = count up, 0 = count down
 */
static inline void timer1_set_direction(uint8_t count_up) {
    TIMER1_CTRL.bits.direction = count_up ? 1 : 0;
}

/**
 * @brief Set Timer1 reload mode
 * @param reload_on_rollover 1 = reload on compare match, 0 = wrap
 */
static inline void timer1_set_reload(uint8_t reload_on_rollover) {
    TIMER1_CTRL.bits.reload = reload_on_rollover ? 1 : 0;
}

/**
 * @brief Set Timer1 clock source
 * @param use_timer0_done 1 = use Timer0 done pulse, 0 = use system clock
 */
static inline void timer1_set_source(uint8_t use_timer0_done) {
    TIMER1_CTRL.bits.source = use_timer0_done ? 1 : 0;
}

/**
 * @brief Configure Timer1 (does not enable)
 * @param load_val Initial/reload value
 * @param compare_val Target/compare value
 * @param count_up 1 = count up, 0 = count down
 * @param reload 1 = reload on match, 0 = wrap
 * @param source 1 = Timer0 done, 0 = system clock
 */
static inline void timer1_configure(uint32_t load_val, uint32_t compare_val,
                                    uint8_t count_up, uint8_t reload,
                                    uint8_t source) {
    TIMER1_LOAD = load_val;
    TIMER1_COMPARE = compare_val;
    TIMER1_CTRL.bits.direction = count_up ? 1 : 0;
    TIMER1_CTRL.bits.reload = reload ? 1 : 0;
    TIMER1_CTRL.bits.source = source ? 1 : 0;
}

/**
 * @brief Configure and enable Timer1 for periodic operation
 * @param load_val Initial value (typically 0)
 * @param compare_val Period in clock cycles (or Timer0 ticks if cascaded)
 * @param count_up 1 = count up, 0 = count down
 * @param source 1 = Timer0 done, 0 = system clock
 */
static inline void timer1_start_periodic(uint32_t load_val, uint32_t compare_val,
                                         uint8_t count_up, uint8_t source) {
    timer1_configure(load_val, compare_val, count_up, 1, source);
    timer1_enable();
}

/**
 * @brief Read Timer1 current counter value
 * @return Current counter value (32-bit)
 * @note Volatile access ensures actual hardware read
 */
static inline uint32_t timer1_get_value(void) {
    return TIMER1_VALUE;
}

// ============================================================================
// Application Helper Functions
// ============================================================================

/**
 * @brief Setup Timer0 as a periodic timer with millisecond period
 * @param clk_freq_hz System clock frequency in Hz
 * @param period_ms Desired period in milliseconds
 * @note Assumes clock is fast enough for the requested period
 */
static inline void timer0_setup_ms_periodic(uint32_t clk_freq_hz, uint32_t period_ms) {
    uint32_t ticks = (clk_freq_hz / 1000) * period_ms;
    timer0_start_periodic(0, ticks - 1, 1);
}

/**
 * @brief Setup cascaded 64-bit timer with Timer0 and Timer1
 * @details Timer0 counts system clocks, Timer1 counts Timer0 overflows
 */
static inline void setup_cascaded_64bit_timer(void) {
    // Timer0: count full 32-bit range
    timer0_configure(0, 0xFFFFFFFF, 1, 1);
    timer0_enable();
    
    // Timer1: count Timer0 overflows
    timer1_configure(0, 0xFFFFFFFF, 1, 1, 1);
    timer1_enable();
}

/**
 * @brief Disable both timers
 */
static inline void timer_disable_all(void) {
    timer0_disable();
    timer1_disable();
}

/**
 * @brief Read 64-bit cascaded timer value (Timer1:Timer0)
 * @return 64-bit combined counter value
 * @note Only valid when Timer1 SOURCE=1 (cascaded mode)
 * @note Uses double-read to handle rare case of Timer0 overflow during read
 */
static inline uint64_t timer_get_64bit_value(void) {
    uint32_t high, low, high_verify;
    
    // Read high, then low, then verify high didn't change
    // This handles the rare case where Timer0 overflows during our read
    do {
        high = TIMER1_VALUE;
        low = TIMER0_VALUE;
        high_verify = TIMER1_VALUE;
    } while (high != high_verify);
    
    return ((uint64_t)high << 32) | low;
}

/**
 * @brief Measure elapsed ticks since timer was started
 * @param start_value Previous timer value
 * @return Number of ticks elapsed
 * @note Works correctly even if timer wraps around (unsigned arithmetic)
 */
static inline uint32_t timer0_elapsed_ticks(uint32_t start_value) {
    uint32_t current = timer0_get_value();
    return current - start_value;  // Unsigned subtraction handles wrap-around automatically
}

/**
 * @brief Software delay using Timer0
 * @param delay_ticks Number of ticks to delay
 * @note Busy-wait, blocks CPU
 */
static inline void timer0_delay_ticks(uint32_t delay_ticks) {
    uint32_t start = timer0_get_value();
    while (timer0_elapsed_ticks(start) < delay_ticks) {
        // Busy wait
    }
}

#endif // AXI4_LITE_TIMER_H
