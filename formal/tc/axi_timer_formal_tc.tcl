clear -all
analyze -sv12 $env(AXI_LITE_TIMER_PATH)/formal/src/axi_timer_formal_tb.sv $env(AXI_LITE_TIMER_PATH)/rtl/axi_timer.sv
elaborate -top axi_timer_formal_tb
clock clk
reset !rst_n
