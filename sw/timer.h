#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

/* -------------------------------------------------------------------------- */
/*  Register offsets                                                          */
/* -------------------------------------------------------------------------- */
#define TIMER_REG_STATUS          0x00
#define TIMER_REG_CTRL            0x04
#define TIMER_REG_COUNTER_VALUE   0x08
#define TIMER_REG_PRESCALER_VALUE 0x0C
#define TIMER_REG_THRESHOLD_VALUE 0x10

/* -------------------------------------------------------------------------- */
/*  STATUS register (RO, clear-on-read)                                       */
/* -------------------------------------------------------------------------- */
#define TIMER_STATUS_THRESHOLD    (1U << 0)

/* -------------------------------------------------------------------------- */
/*  CTRL register                                                             */
/* -------------------------------------------------------------------------- */
#define TIMER_CTRL_RESET          (1U << 0)
#define TIMER_CTRL_IE             (1U << 1)

/* -------------------------------------------------------------------------- */
/*  Driver handle                                                             */
/* -------------------------------------------------------------------------- */
typedef struct {
    volatile uint32_t *base;
} timer_t;

/* -------------------------------------------------------------------------- */
/*  API                                                                       */
/* -------------------------------------------------------------------------- */

/** Bind handle to MMIO base address. Does not touch HW. */
void timer_init(timer_t *dev, uintptr_t base_addr);

/**
 * Configure and start the timer in one call.
 *
 * @param prescaler   Clock divider: Fcnt = Fclk / (1 + prescaler)
 * @param threshold   Counter target value (counter resets to 0 on match).
 *                    Effective period = (1 + prescaler) * (threshold + 1) / Fclk
 * @param enable_irq  Non-zero to assert interrupt on threshold match.
 */
void timer_start(timer_t *dev, uint32_t prescaler, uint32_t threshold,
                 int enable_irq);

/** Hold prescaler and counter in reset. */
void timer_stop(timer_t *dev);

/** Read current counter value. */
uint32_t timer_get_counter(timer_t *dev);

/** Read STATUS register (clears sticky THRESHOLD bit). */
uint32_t timer_get_status(timer_t *dev);

/** Check if threshold was reached. Clears the sticky bit as side-effect. */
int timer_threshold_reached(timer_t *dev);

/** Enable interrupt generation (counter keeps running). */
void timer_enable_irq(timer_t *dev);

/** Disable interrupt generation (counter keeps running). */
void timer_disable_irq(timer_t *dev);

/**
 * Blocking delay for a number of threshold periods.
 * Polls STATUS register — clears the sticky bit each iteration.
 */
void timer_delay_periods(timer_t *dev, uint32_t periods);

#endif /* TIMER_H */
