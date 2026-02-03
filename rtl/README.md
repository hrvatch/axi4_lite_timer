# AXI4-Lite Timer/Counter

A 32-bit counter peripheral with AXI4-Lite interface and a prescaler. Counts prescaled (divided) 
clock cycles. Raises interrupt when counter reaches threshold value (interrupt must be enabled).

Counter period = (1+PRESCALER_VALUE)/Fclk, where Fclk is the system frequency (usually 100 MHz).

## Features

- **32-bit prescaler:** Reduces the clock frequency by a set value before it reaches the counter.
- **32-bit counter:** Counts prescaled clock cycles.
- **32-bit comparator:** Compares current counter value and THRESHOLD_VALUE. Outputs a pulse when
counter reaches THRESHOLD_VALUE. 
- **Interrupt generation:** Generates interrupt when counter reaches THRESHOLD_VALUE and when
interrupt is enabled.
- **AXI4-Lite interface** for easy SoC integration.

## Integration

### Port Connections

```systemverilog
axi4_lite_timer #(
    .AXI_ADDR_WIDTH(8),
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
    .o_int          (timer_interrupt)
);
```

### RISC-V Integration (RV32IMC)

**Interrupt Connection:**
- Wire `o_int`  PLIC (Platform-Level Interrupt Controller) or CLIC inputs
- Or connect directly to external interrupt pins if using machine-mode external interrupts

**Memory Map:**
- Peripheral uses 32-bit aligned accesses (natural for RV32)
- All registers are 32-bit wide, matching RISC-V word size
- Base address should be 4-byte aligned (required for `lw`/`sw` instructions)

## Memory Map

| Offset | Register         | Access | Description                              |
|--------|------------------|--------|------------------------------------------|
| 0x00   | STATUS           | RO     | Status register                          |
| 0x04   | CTRL             | RW     | Counter control register                 |
| 0x08   | COUNTER_VALUE    | RO     | Current counter value                    |
| 0x0c   | PRESCALER_VALUE  | R/W    | Value of a counter prescaler (32-bit)    |
| 0x10   | THRESHOLD_VALUE  | R/W    | Counter target/threshold value (32-bit)  |

## Register Descriptions

### STATUS (0x0)

| Bit   | Name      | R/W | Reset | Description                                    |
|-------|-----------|-----|-------|------------------------------------------------|
| [31:1]| Reserved  | -   | 0     | Reserved                                       |
| [0]   | THRESHOLD | RO  | 0     | Counter threshold status                       |

THRESHOLD = 1: Counter has reached THRESHOLD_VALUE
THRESHOLD = 0: Counter hasn't reached THRESHOLD_VALUE

Note: THRESHOLD is a sticky bit. When counter reaches threshold value, this bit
will be set to '1' and it will stay '1' until STATUS register is read. Reading
status register will clear THRESHOLD bit (i.e., set it to '0').


### CTRL (0x04)

| Bit   | Name      | R/W | Reset | Description                                    |
|-------|-----------|-----|-------|------------------------------------------------|
| [31:2]| Reserved  | -   | 0     | Reserved                                       |
| [1]   | IE        | R/W | 1     | Interrupt enable                               |
| [0]   | RESET     | R/W | 1     | Counter reset                                  |

IE = 1: Interrupt generation is enabled
IE = 0: Interrupt generation is disabled

RESET = 1: Resets prescaler to zero; resets counter to zero.
RESET = 0: Normal prescaler and counter operation.

### COUNTER_VALUE (0x08)

| Bit   | Name           | R/W | Reset | Description                                    |
|-------|----------------|-----|-------|------------------------------------------------|
| [31:0]| COUNTER_VALUE  | R   | 0x0   | Counter value                                  |

**Read-only** 32-bit register containing the current counter value.
- Allows software to monitor timer/counter progress in real-time
- Useful for measuring elapsed time or implementing software delays
- Writes to this register are ignored

### PRESCALER_VALUE (0x0C)

| Bit   | Name             | R/W  | Reset | Description                                    |
|-------|------------------|------|-------|------------------------------------------------|
| [31:0]| PRESCALER_VALUE  | RW   | 0x0   | Prescaler value                                |

Prescaler is a hardware divider that reduces the system clock frequency before it reaches 
the counter.

Counter frequency is calculated with the following formula:
Fcnt = Fclk/(1+PRESCALER_VALUE)

For example, with a 100 MHz system frequency and a PRESCALER_VALUE of 3, the timer 
input frequency will be 25 MHz (100 MHz / (1+3) = 25 MHz).

### THRESHOLD_VALUE (0x10)

| Bit   | Name             | R/W  | Reset         | Description                                |
|-------|------------------|------|---------------|--------------------------------------------|
| [31:0]| THRESHOLD_VALUE  | RW   | 0xFFFF_FFFF   | Counter threshold value                    |

When counter reaches THRESHOLD_VALUE it generates a pulse. This pulse is is used to reset
counter value to zero, and sets the THRESHOLD field in the STATUS register to '1'. If IE field
in the CTRL register is set to '1', interrupt line is asserted.

