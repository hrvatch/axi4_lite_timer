#include "timer.h"

/* -------------------------------------------------------------------------- */
/*  Private helpers — direct MMIO access                                      */
/* -------------------------------------------------------------------------- */

static inline uint32_t reg_read(const timer_t *dev, uint32_t offset)
{
    return dev->base[offset / sizeof(uint32_t)];
}

static inline void reg_write(const timer_t *dev, uint32_t offset, uint32_t val)
{
    dev->base[offset / sizeof(uint32_t)] = val;
}

/* -------------------------------------------------------------------------- */
/*  Public API                                                                */
/* -------------------------------------------------------------------------- */

void timer_init(timer_t *dev, uintptr_t base_addr)
{
    dev->base = (volatile uint32_t *)base_addr;
}

void timer_start(timer_t *dev, uint32_t prescaler, uint32_t threshold,
                 int enable_irq)
{
    /* Hold counter in reset while configuring */
    reg_write(dev, TIMER_REG_CTRL, TIMER_CTRL_RESET);

    reg_write(dev, TIMER_REG_PRESCALER_VALUE, prescaler);
    reg_write(dev, TIMER_REG_THRESHOLD_VALUE, threshold);

    /* Clear any stale threshold status */
    (void)reg_read(dev, TIMER_REG_STATUS);

    /* Release reset, optionally enable interrupt */
    uint32_t ctrl = 0;
    if (enable_irq)
        ctrl |= TIMER_CTRL_IE;
    reg_write(dev, TIMER_REG_CTRL, ctrl);
}

void timer_stop(timer_t *dev)
{
    reg_write(dev, TIMER_REG_CTRL, TIMER_CTRL_RESET);
}

uint32_t timer_get_counter(timer_t *dev)
{
    return reg_read(dev, TIMER_REG_COUNTER_VALUE);
}

uint32_t timer_get_status(timer_t *dev)
{
    return reg_read(dev, TIMER_REG_STATUS);
}

int timer_threshold_reached(timer_t *dev)
{
    return (reg_read(dev, TIMER_REG_STATUS) & TIMER_STATUS_THRESHOLD) != 0;
}

void timer_enable_irq(timer_t *dev)
{
    uint32_t ctrl = reg_read(dev, TIMER_REG_CTRL);
    ctrl |= TIMER_CTRL_IE;
    reg_write(dev, TIMER_REG_CTRL, ctrl);
}

void timer_disable_irq(timer_t *dev)
{
    uint32_t ctrl = reg_read(dev, TIMER_REG_CTRL);
    ctrl &= ~TIMER_CTRL_IE;
    reg_write(dev, TIMER_REG_CTRL, ctrl);
}

void timer_delay_periods(timer_t *dev, uint32_t periods)
{
    for (uint32_t i = 0; i < periods; i++) {
        while (!(reg_read(dev, TIMER_REG_STATUS) & TIMER_STATUS_THRESHOLD))
            ;
    }
}
