# AXI4-Lite Timer/Counter

A dual 32-bit timer/counter peripheral with AXI4-Lite interface, supporting both independent and cascaded operation for extended 64-bit timing.

## Features

- **Dual 32-bit timers/counters** (Timer0 and Timer1)
- **Flexible counting modes:**
  - Count up or count down
  - One-shot or continuous operation
  - Reload on compare match or free-running wrap
- **Cascading support:** Chain Timer0 → Timer1 for 64-bit operation
- **Interrupt generation:** Pulse outputs on compare match (o_cnt0_done, o_cnt1_done)
- **AXI4-Lite interface** for easy SoC integration

## Integration

### Port Connections

```systemverilog
axi4_lite_timer #(
    .AXI_ADDR_WIDTH(32),
    .AXI_DATA_WIDTH(32)
) timer_inst (
    .clk            (sys_clk),           // System clock
    .rst_n          (sys_rst_n),         // Active-low reset
    
    // AXI4-Lite interface
    .s_axi_awaddr   (...),
    .s_axi_awprot   (...),
    .s_axi_awvalid  (...),
    .s_axi_awready  (...),
    // ... (remaining AXI signals)
    
    // Interrupt outputs
    .o_cnt0_done    (timer0_irq),        // Timer0 compare match pulse
    .o_cnt1_done    (timer1_irq)         // Timer1 compare match pulse
);
```

### RISC-V Integration (RV32IMC)

**Interrupt Connection:**
- Wire `o_cnt0_done` and `o_cnt1_done` to PLIC (Platform-Level Interrupt Controller) or CLIC inputs
- Or connect directly to external interrupt pins if using machine-mode external interrupts

**Memory Map:**
- Peripheral uses 32-bit aligned accesses (natural for RV32)
- All registers are 32-bit wide, matching RISC-V word size
- Base address should be 4-byte aligned (required for `lw`/`sw` instructions)

**Example SoC Address:**
```c
#define TIMER_BASE 0x40000000  // Memory-mapped I/O region
```

## Memory Map

| Offset | Register         | Access | Description                              |
|--------|------------------|--------|------------------------------------------|
| 0x00   | TIMER0_CTRL      | R/W    | Timer0 control register                  |
| 0x04   | TIMER0_LOAD      | R/W    | Timer0 initial/reload value (32-bit)     |
| 0x08   | TIMER0_COMPARE   | R/W    | Timer0 compare/target value (32-bit)     |
| 0x0C   | TIMER0_VALUE     | RO     | Timer0 current counter value (32-bit)    |
| 0x10   | TIMER1_CTRL      | R/W    | Timer1 control register                  |
| 0x14   | TIMER1_LOAD      | R/W    | Timer1 initial/reload value (32-bit)     |
| 0x18   | TIMER1_COMPARE   | R/W    | Timer1 compare/target value (32-bit)     |
| 0x1C   | TIMER1_VALUE     | RO     | Timer1 current counter value (32-bit)    |

## Register Descriptions

### TIMER0_CTRL (0x00)

| Bit   | Name      | R/W | Reset | Description                                    |
|-------|-----------|-----|-------|------------------------------------------------|
| [31:3]| Reserved  | -   | 0     | Reserved                                       |
| [2]   | DIRECTION | R/W | 0     | 0=Count down, 1=Count up                       |
| [1]   | RELOAD    | R/W | 0     | 0=Wrap on rollover, 1=Reload LOAD value        |
| [0]   | ENABLE    | R/W | 0     | 0=Timer disabled, 1=Timer enabled              |

### TIMER1_CTRL (0x0C)

| Bit   | Name      | R/W | Reset | Description                                    |
|-------|-----------|-----|-------|------------------------------------------------|
| [31:4]| Reserved  | -   | 0     | Reserved                                       |
| [3]   | SOURCE    | R/W | 0     | 0=System clock, 1=Timer0 done pulse            |
| [2]   | DIRECTION | R/W | 0     | 0=Count down, 1=Count up                       |
| [1]   | RELOAD    | R/W | 0     | 0=Wrap on rollover, 1=Reload LOAD value        |
| [0]   | ENABLE    | R/W | 0     | 0=Timer disabled, 1=Timer enabled              |

### TIMERx_LOAD (0x04, 0x14)

32-bit initial/reload value. When timer is first enabled, counter starts from this value.
If RELOAD=1, counter reloads this value when it reaches COMPARE value.

### TIMERx_COMPARE (0x08, 0x18)

32-bit compare/target value. When counter equals this value:
- `o_cntX_done` pulses high for one clock cycle
- If RELOAD=1, counter reloads LOAD value
- If RELOAD=0, counter wraps (to 0 if counting up, to 0xFFFFFFFF if counting down)

### TIMERx_VALUE (0x0C, 0x1C)

**Read-only** 32-bit register containing the current counter value.
- Allows software to monitor timer/counter progress in real-time
- Useful for measuring elapsed time or implementing software delays
- Writes to this register are ignored

## Operation Modes

### Mode 1: Periodic Timer (Reload Enabled)

```
LOAD = 0, COMPARE = 999, DIRECTION = 1 (up), RELOAD = 1

Counter: 0→1→2→...→999→0→1→2→...→999→0...
                    ↑           ↑
               done pulse   done pulse
```

**Use case:** Generate periodic interrupts (e.g., 1ms tick)

### Mode 2: Free-Running Counter (Reload Disabled)

```
LOAD = 0, COMPARE = 999, DIRECTION = 1 (up), RELOAD = 0

Counter: 0→1→2→...→999→1000→1001→...→0xFFFFFFFF→0→1...
                    ↑
               done pulse
```

**Use case:** One-shot timeout, event counting with overflow

### Mode 3: Cascaded 64-bit Timer

```
Timer0: COMPARE = 0xFFFFFFFF, RELOAD = 1
Timer1: SOURCE = 1 (Timer0 done), COMPARE = <high_32_bits>

Timer0 counts system clocks, Timer1 counts Timer0 overflows
Effective counter = (Timer1 << 32) | Timer0
```

**Use case:** Long-duration timers (seconds, minutes)

## Behavioral Notes

1. **Dynamic Direction Change:** Changing DIRECTION while ENABLE=1 immediately reverses counting direction from the current counter value.

2. **Wrap Behavior (RELOAD=0):**
   - Count up: Wraps from 0xFFFFFFFF → 0x00000000
   - Count down: Wraps from 0x00000000 → 0xFFFFFFFF

3. **Interrupt Timing:** `o_cntX_done` is a single-cycle pulse, synchronous to `clk`.

4. **Initialization:** On reset, all registers = 0 (timers disabled).

## Software Examples

### Example 1: 1ms Periodic Interrupt (100 MHz Clock)

```c
// Configure Timer0 for 1ms periodic interrupts
#define TIMER_BASE 0x40000000
#define CLK_FREQ   100000000

uint32_t ticks_per_ms = CLK_FREQ / 1000;  // 100,000

*(volatile uint32_t *)(TIMER_BASE + 0x04) = 0;                    // LOAD = 0
*(volatile uint32_t *)(TIMER_BASE + 0x08) = ticks_per_ms - 1;    // COMPARE
*(volatile uint32_t *)(TIMER_BASE + 0x00) = 0x7;                  // ENABLE|RELOAD|UP

// Enable IRQ in your interrupt controller
```

### Example 2: 64-bit Cascaded Timer

```c
// Chain Timer0 and Timer1 for 64-bit counting
*(volatile uint32_t *)(TIMER_BASE + 0x04) = 0;           // Timer0 LOAD
*(volatile uint32_t *)(TIMER_BASE + 0x08) = 0xFFFFFFFF;  // Timer0 COMPARE
*(volatile uint32_t *)(TIMER_BASE + 0x00) = 0x7;         // Timer0: EN|RELOAD|UP

*(volatile uint32_t *)(TIMER_BASE + 0x10) = 0;           // Timer1 LOAD
*(volatile uint32_t *)(TIMER_BASE + 0x14) = 0x00001000;  // Timer1 COMPARE (high 32-bits)
*(volatile uint32_t *)(TIMER_BASE + 0x0C) = 0xF;         // Timer1: EN|RELOAD|UP|TIMER0_SRC
```

### Example 3: One-Shot Timeout (10ms)

```c
uint32_t timeout_ticks = CLK_FREQ / 100;  // 10ms

*(volatile uint32_t *)(TIMER_BASE + 0x04) = 0;               // LOAD = 0
*(volatile uint32_t *)(TIMER_BASE + 0x08) = timeout_ticks;   // COMPARE
*(volatile uint32_t *)(TIMER_BASE + 0x00) = 0x5;             // ENABLE|UP (no RELOAD)

// Wait for interrupt, then timer keeps counting (free-run)
```

### Example 4: Read Current Counter Value

```c
// Start a timer
*(volatile uint32_t *)(TIMER_BASE + 0x04) = 0;           // LOAD = 0
*(volatile uint32_t *)(TIMER_BASE + 0x08) = 1000000;     // COMPARE
*(volatile uint32_t *)(TIMER_BASE + 0x00) = 0x5;         // ENABLE|UP

// Later, read current progress
uint32_t current_value = *(volatile uint32_t *)(TIMER_BASE + 0x0C);
printf("Timer has counted to: %u\n", current_value);

// Calculate time elapsed (assuming 100 MHz clock)
float elapsed_us = (float)current_value / 100.0;
```

### Example 5: Microsecond Delay (RV32IMC)

```c
// Precise microsecond delay using timer
void delay_us(uint32_t us) {
    const uint32_t TICKS_PER_US = 100;  // For 100 MHz clock
    
    uint32_t start = *(volatile uint32_t *)(TIMER_BASE + 0x0C);
    uint32_t target_ticks = us * TICKS_PER_US;
    
    while (1) {
        uint32_t current = *(volatile uint32_t *)(TIMER_BASE + 0x0C);
        uint32_t elapsed = current - start;  // Works with wrap-around
        if (elapsed >= target_ticks) break;
    }
}
```

## Known Limitations / TODO

- No interrupt status/clear registers (done signals are pulses only)
- No prescaler for very slow clock rates
- Direction change while counting may cause unexpected behavior near compare value
