## AXI4-Lite timer/counter

This module is used to control 32-bit counter/timer via the AXI4-Lite interface. This module uses two
timers. For each timer it's possible to:
- Configure the timer/counter initial value,
- Configure the counter target (comparator) value,
- Configure the timer/counter to roll over to the inital value once it reaches the the target value
  or continue counting,
- Configure the timer/counter to count up or down.

Once the counter reaches its target (compare) value, the output done signal is set to '1' for the
duration of one AXI clock cycle (pulse).

For the Timer/Counter instance 1, it's also possible to configure the source of the counter: clock
or the Timer/Counter instance 0 output done signal i.e. it's possible to chain two Timer/Counters 
to make one 64-bit Timer/Counter.

## Integration
- Connect clock to the 'clk' port
- Connect synchronous, negative logic reset to the rst_n port,
- Connect AXI ports,
- Connect the output 'o_cntX_done'.

## Memory map

```
0x0:  TIMER0_CTRL    - Timer/Counter0 control register
      TIMER0_CTRL[0] - Timer/Counter0 enable - 0: Disable, 1: Enable
      TIMER0_CTRL[1] - Timer/Counter0 reload - 0: continue Counting, 1: Load initial value on rollover
      TIMER0_CTRL[2] - Timer/Counter0 direction - 0: Count down, 1: Count up 
0x4:  TIMER0_LOAD - Timer/Counter0 load value register, 32-bit
0x8:  TIMER0_COMPARE - Timer/Counter0 compare value register, 32-bit
0xC:  TIMER0_VALUE - Current Timer/Counter0 value, 32-bit
0x10: TIMER1_CTRL - Timer/Counter1 control register
      TIMER1_CTRL[0] - Timer/Counter1 enable - 0: Disable, 1: Enable
      TIMER1_CTRL[1] - Timer/Counter1 reload - 0: continue Counting, 1: Load initial value on rollover
      TIMER1_CTRL[2] - Timer/Counter1 direction - 0: Count down, 1: Count up 
      TIMER1_CTRL[3] - Timer/Counter1 source - 0: Clock, 1: Counter 0 Done
0x14: TIMER1_LOAD - Timer/Counter1 load value register, 32-bit
0x18: TIMER1_COMPARE - Timer/Counter1 compare register, 32-bit
0x1C: TIMER1_VALUE - Current Timer/Counter1 value, 32-bit
```

