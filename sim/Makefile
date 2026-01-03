.PHONY: jg clean sim_batch sim_gui compile

TC=TC1
XRUN_ARGS= -sv
XRUN_ARGS+= -access +rwc
XRUN_ARGS+= -f $(AXI_LITE_TIMER_PATH)/rtl/axi_lite_timer.f
XRUN_ARGS+= -f $(AXI_LITE_TIMER_PATH)/tb/timer_counter_tb.f
XRUN_ARGS+= -top timer_counter_tb
XRUN_ARGS+= -64bit
XRUN_ARGS+= -timescale 1ns/1ps
XRUN_ARGS+= +define+$(TC)


jg:
	jg $(AXI_LITE_TIMER_PATH)/formal/tc/axi_timer_formal_tc.tcl

sim_batch:
	xrun $(XRUN_ARGS) 

sim_gui:
	xrun $(XRUN_ARGS) -gui -input $(AXI_LITE_TIMER_PATH)/sim/probe.tcl

compile:
	xrun -c $(XRUN_ARGS)

clean:
	rm -rf jgproject

help:
	@echo "Available targets:"
	@echo "  jg         - Start Jasper FPV"
	@echo "  sim_batch  - Start simulation in batch mode"
	@echo "  sim_gui    - Start simulation in GUI mode"
	@echo "  clean      - Remvoe simulation artefacts"
