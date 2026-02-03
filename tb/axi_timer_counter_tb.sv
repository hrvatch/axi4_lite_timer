`timescale 1ns/1ps

module axi_timer_counter_tb;

  // Parameters
  parameter int AXI_DATA_BW_p = 32;
  parameter int AXI_ADDR_BW_p = 12;
  parameter int CLK_PERIOD = 10; // 100 MHz
  
  // Register offsets
  parameter logic [AXI_ADDR_BW_p-1:0] ADDR_STATUS     = 12'h000;
  parameter logic [AXI_ADDR_BW_p-1:0] ADDR_CTRL       = 12'h004;
  parameter logic [AXI_ADDR_BW_p-1:0] ADDR_COUNTER    = 12'h008;
  parameter logic [AXI_ADDR_BW_p-1:0] ADDR_PRESCALER  = 12'h00C;
  parameter logic [AXI_ADDR_BW_p-1:0] ADDR_THRESHOLD  = 12'h010;
  
  // AXI response codes
  parameter logic [1:0] RESP_OKAY   = 2'b00;
  parameter logic [1:0] RESP_SLVERR = 2'b10;

  // DUT signals
  logic clk;
  logic rst_n;
  logic [AXI_ADDR_BW_p-1:0] i_axi_awaddr;
  logic i_axi_awvalid;
  logic [AXI_DATA_BW_p-1:0] i_axi_wdata;
  logic i_axi_wvalid;
  logic i_axi_bready;
  logic [AXI_ADDR_BW_p-1:0] i_axi_araddr;
  logic i_axi_arvalid;
  logic i_axi_rready;
  logic o_axi_awready;
  logic o_axi_wready;
  logic [1:0] o_axi_bresp;
  logic o_axi_bvalid;
  logic o_axi_arready;
  logic [AXI_DATA_BW_p-1:0] o_axi_rdata;
  logic [1:0] o_axi_rresp;
  logic o_axi_rvalid;
  logic o_irq;

  // Test variables
  int error_count = 0;
  int test_count = 0;

  // Clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // DUT instantiation
  axi_timer_counter_top #(
    .AXI_DATA_BW_p(AXI_DATA_BW_p),
    .AXI_ADDR_BW_p(AXI_ADDR_BW_p)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .i_axi_awaddr(i_axi_awaddr),
    .i_axi_awvalid(i_axi_awvalid),
    .i_axi_wdata(i_axi_wdata),
    .i_axi_wvalid(i_axi_wvalid),
    .i_axi_bready(i_axi_bready),
    .i_axi_araddr(i_axi_araddr),
    .i_axi_arvalid(i_axi_arvalid),
    .i_axi_rready(i_axi_rready),
    .o_axi_awready(o_axi_awready),
    .o_axi_wready(o_axi_wready),
    .o_axi_bresp(o_axi_bresp),
    .o_axi_bvalid(o_axi_bvalid),
    .o_axi_arready(o_axi_arready),
    .o_axi_rdata(o_axi_rdata),
    .o_axi_rresp(o_axi_rresp),
    .o_axi_rvalid(o_axi_rvalid),
    .o_irq(o_irq)
  );

  // ============================================================
  // Task: Initialize all AXI signals
  // ============================================================
  task automatic init_axi_signals();
    i_axi_awaddr  = '0;
    i_axi_awvalid = 1'b0;
    i_axi_wdata   = '0;
    i_axi_wvalid  = 1'b0;
    i_axi_bready  = 1'b0;
    i_axi_araddr  = '0;
    i_axi_arvalid = 1'b0;
    i_axi_rready  = 1'b0;
  endtask

  // ============================================================
  // Task: Reset sequence
  // ============================================================
  task automatic reset_dut();
    $display("[%0t] Applying reset...", $time);
    rst_n = 1'b0;
    init_axi_signals();
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);
    $display("[%0t] Reset complete", $time);
  endtask

  // ============================================================================
  // AXI4-Lite Write Task
  // ============================================================================
  task automatic axi_write(
    input logic [AXI_ADDR_BW_p-1:0] addr,
    input logic [31:0] data,
    output logic [1:0] resp
  );
    @(posedge clk);
    i_axi_awaddr  <= addr;
    i_axi_awvalid <= 1'b1;
    i_axi_wdata   <= data;
    i_axi_wvalid  <= 1'b1;
    i_axi_bready  <= 1'b1;
    
    // Wait for write address acceptance
    @(posedge clk);
    while (!o_axi_awready) @(posedge clk);
    i_axi_awvalid <= 1'b0;
    
    // Wait for write data acceptance  
    while (!o_axi_wready) @(posedge clk);
    i_axi_wvalid <= 1'b0;
    
    // Wait for write response
    while (!o_axi_bvalid) @(posedge clk);
    resp = o_axi_bresp;
    @(posedge clk);
    i_axi_bready <= 1'b0;
  endtask

  // ============================================================================
  // AXI4-Lite Read Task
  // ============================================================================
  task automatic axi_read(
    input logic [AXI_ADDR_BW_p-1:0] addr,
    output logic [31:0] data,
    output logic [1:0] resp
  );
    @(posedge clk);
    i_axi_araddr  <= addr;
    i_axi_arvalid <= 1'b1;
    i_axi_rready  <= 1'b1;
    
    // Wait for read address acceptance
    @(posedge clk);
    while (!o_axi_arready) @(posedge clk);
    i_axi_arvalid <= 1'b0;
    
    // Wait for read data
    while (!o_axi_rvalid) @(posedge clk);
    data = o_axi_rdata;
    resp = o_axi_rresp;
    @(posedge clk);
    i_axi_rready <= 1'b0;
  endtask

  // ============================================================
  // Task: Check value and report errors
  // ============================================================
  task automatic check_value(
    input string name,
    input logic [AXI_DATA_BW_p-1:0] expected,
    input logic [AXI_DATA_BW_p-1:0] actual
  );
    test_count++;
    if (expected !== actual) begin
      $display("[ERROR] %s mismatch: expected=0x%08x, actual=0x%08x", name, expected, actual);
      error_count++;
    end else begin
      $display("[PASS]  %s check: 0x%08x", name, actual);
    end
  endtask

  // ============================================================
  // Test 1: Reset behavior verification
  // ============================================================
  task automatic test_reset();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 1: Reset Behavior ===");
    
    // Read all registers after reset
    axi_read(ADDR_STATUS, rdata, resp);
    check_value("STATUS after reset", 32'h0, rdata);
    
    axi_read(ADDR_CTRL, rdata, resp);
    check_value("CTRL after reset", 32'h1, rdata);
    
    axi_read(ADDR_COUNTER, rdata, resp);
    check_value("COUNTER after reset", 32'h0, rdata);
    
    axi_read(ADDR_PRESCALER, rdata, resp);
    check_value("PRESCALER after reset", 32'h0, rdata);
    
    axi_read(ADDR_THRESHOLD, rdata, resp);
    check_value("THRESHOLD after reset", 32'hFFFFFFFF, rdata);
    
    if (!o_irq) begin
      $display("[PASS]  Interrupt deasserted after reset");
      test_count++;
    end else begin
      $display("[ERROR] Interrupt asserted after reset");
      error_count++;
      test_count++;
    end
  endtask

  // ============================================================
  // Test 2: Register write/read
  // ============================================================
  task automatic test_register_write_read();
    logic [AXI_DATA_BW_p-1:0] wdata, rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 2: Register Write/Read ===");
    
    // Write and read CTRL register
    wdata = 32'h00000003; // IE=1, RESET=1
    axi_write(ADDR_CTRL, wdata, resp);
    check_value("CTRL write response", RESP_OKAY, {30'h0, resp});
    axi_read(ADDR_CTRL, rdata, resp);
    check_value("CTRL readback", wdata, rdata);
    
    // Write and read PRESCALER register
    wdata = 32'h00000063; // Prescaler = 99 (divide by 100)
    axi_write(ADDR_PRESCALER, wdata, resp);
    check_value("PRESCALER write response", RESP_OKAY, {30'h0, resp});
    axi_read(ADDR_PRESCALER, rdata, resp);
    check_value("PRESCALER readback", wdata, rdata);
    
    // Write and read THRESHOLD register
    wdata = 32'h000003E7; // Threshold = 999
    axi_write(ADDR_THRESHOLD, wdata, resp);
    check_value("THRESHOLD write response", RESP_OKAY, {30'h0, resp});
    axi_read(ADDR_THRESHOLD, rdata, resp);
    check_value("THRESHOLD readback", wdata, rdata);
    
    // Try writing to read-only STATUS register (should get SLVERR)
    axi_write(ADDR_STATUS, 32'hDEADBEEF, resp);
    check_value("STATUS write response (expect SLVERR)", RESP_SLVERR, {30'h0, resp});
    
    // Try writing to read-only COUNTER register (should get SLVERR)
    axi_write(ADDR_COUNTER, 32'hDEADBEEF, resp);
    check_value("COUNTER write response (expect SLVERR)", RESP_SLVERR, {30'h0, resp});
  endtask

  // ============================================================
  // Test 3: Counter operation without prescaler
  // ============================================================
  task automatic test_counter_basic();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    int counter;
    bit stop;
    
    $display("\n=== TEST 3: Basic Counter Operation ===");
    
    // Configure: RESET=0, IE=1, PRESCALER=0, THRESHOLD=10
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'h0000000A, resp);
    axi_write(ADDR_CTRL, 32'h00000002, resp); // IE=1, RESET=0
    
    // Wait for a few clock cycles and check counter increments
    repeat(3) @(posedge clk);
    axi_read(ADDR_COUNTER, rdata, resp);
    if (rdata >= 32'h1 && rdata <= 32'h5) begin
      $display("[PASS]  Counter incrementing (value=%0d)", rdata);
      test_count++;
    end else begin
      $display("[ERROR] Counter not incrementing properly (value=%0d)", rdata);
      error_count++;
      test_count++;
    end
    
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'h00000064, resp);
    axi_write(ADDR_CTRL, 32'h00000003, resp); // IE=1, RESET=1
    axi_read(ADDR_STATUS, rdata, resp); // Clear interrupt
    axi_write(ADDR_CTRL, 32'h00000002, resp); // IE=1, RESET=0

    stop = 0;
    fork
      begin
        repeat(10) begin
          wait (o_irq);
          counter=0;
          axi_read(ADDR_STATUS, rdata, resp); // Clear interrupt
          repeat(10) begin
            @(posedge clk);
          end
          wait (o_irq);
          if (counter != 101) begin
            $display("[ERROR] Expected 100 cycles between interrupts, counted %0d cycles", counter);
            error_count++;
            test_count++;
          end else begin
            $display("[PASS] Counter working correctly!");
            test_count++;
          end
        end
        stop=1;
      end
      begin
        while (!stop) begin
          @(posedge clk);
          counter++;
        end
      end
    join

  endtask

  // ============================================================
  // Test 4: Prescaler operation
  // ============================================================
  task automatic test_prescaler();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    int counter;
    bit stop;
    
    $display("\n=== TEST 4: Prescaler Operation ===");
    
    // Reset counter
    axi_write(ADDR_CTRL, 32'h00000003, resp); // RESET=1
    repeat(2) @(posedge clk);
    
    // Set prescaler to divide by 4 (prescaler value = 3)
    axi_write(ADDR_CTRL, 32'h00000003, resp); // RESET=1, IE = 1
    axi_read(ADDR_STATUS, rdata, resp); // Clear interrupt
    axi_write(ADDR_PRESCALER, 32'h00000003, resp);
    axi_write(ADDR_THRESHOLD, 32'h00000064, resp);
    axi_write(ADDR_CTRL, 32'h00000002, resp); // RESET=0
    
    stop = 0;
    fork
      begin
        repeat(10) begin
          wait (o_irq);
          counter=0;
          axi_read(ADDR_STATUS, rdata, resp); // Clear interrupt
          repeat(10) begin
            @(posedge clk);
          end
          wait (o_irq);
          if (counter != 400) begin
            $display("[ERROR] Expected 400 cycles between interrupts, counted %0d cycles", counter);
            error_count++;
            test_count++;
          end else begin
            $display("[PASS] Prescaler working correctly!");
            test_count++;
          end
        end
        stop=1;
      end
      begin
        while (!stop) begin
          @(posedge clk);
          counter++;
        end
      end
    join
    
  endtask

  // ============================================================
  // Test 5: Threshold detection and STATUS register
  // ============================================================
  task automatic test_threshold_detection();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 5: Threshold Detection ===");
    
    // Reset counter
    axi_write(ADDR_CTRL, 32'h00000003, resp);
    repeat(2) @(posedge clk);
    axi_write(ADDR_CTRL, 32'h00000002, resp); // IE=1, RESET=0
    
    // Set threshold to 5, no prescaler
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'h00000005, resp);
    
    // Wait for threshold to be reached
    repeat(10) @(posedge clk);
    
    // Check STATUS register - should show threshold reached
    axi_read(ADDR_STATUS, rdata, resp);
    if (rdata[0] == 1'b1) begin
      $display("[PASS]  Threshold detected in STATUS register");
      test_count++;
    end else begin
      $display("[ERROR] Threshold not detected in STATUS register");
      error_count++;
      test_count++;
    end
    
    // STATUS read should clear the threshold bit (sticky bit behavior)
    axi_read(ADDR_STATUS, rdata, resp);
    if (rdata[0] == 1'b0) begin
      $display("[PASS]  STATUS threshold bit cleared after read");
      test_count++;
    end else begin
      $display("[ERROR] STATUS threshold bit not cleared after read");
      error_count++;
      test_count++;
    end
    
    // Counter should have reset to 0 after reaching threshold
    axi_read(ADDR_COUNTER, rdata, resp);
    if (rdata < 32'h5) begin
      $display("[PASS]  Counter reset after threshold (value=%0d)", rdata);
      test_count++;
    end else begin
      $display("[ERROR] Counter didn't reset after threshold (value=%0d)", rdata);
      error_count++;
      test_count++;
    end
  endtask

  // ============================================================
  // Test 6: Interrupt generation
  // ============================================================
  task automatic test_interrupt();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 6: Interrupt Generation ===");
    
    // Reset and configure with interrupt enabled
    axi_write(ADDR_CTRL, 32'h00000003, resp);
    repeat(2) @(posedge clk);
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'h00000010, resp);
    axi_write(ADDR_CTRL, 32'h00000002, resp); // IE=1, RESET=0
    
    // Wait for threshold
    repeat(8) @(posedge clk);
    
    // Check interrupt asserted
    if (o_irq) begin
      $display("[PASS]  Interrupt asserted when threshold reached with IE=1");
      test_count++;
    end else begin
      $display("[ERROR] Interrupt not asserted");
      error_count++;
      test_count++;
    end
    
    // Clear interrupt by reading STATUS
    axi_read(ADDR_STATUS, rdata, resp);
    repeat(2) @(posedge clk);
    
    if (!o_irq) begin
      $display("[PASS]  Interrupt cleared after STATUS read");
      test_count++;
    end else begin
      $display("[ERROR] Interrupt still asserted after STATUS read");
      error_count++;
      test_count++;
    end
    
    // Test with interrupt disabled
    axi_write(ADDR_CTRL, 32'h00000003, resp); // Reset
    repeat(2) @(posedge clk);
    axi_write(ADDR_CTRL, 32'h00000000, resp); // IE=0, RESET=0
    
    // Wait for threshold
    repeat(16) @(posedge clk);
    
    if (!o_irq) begin
      $display("[PASS]  Interrupt not asserted when IE=0");
      test_count++;
    end else begin
      $display("[ERROR] Interrupt asserted even with IE=0");
      error_count++;
      test_count++;
    end
  endtask

  // ============================================================
  // Test 7: Counter reset via CTRL register
  // ============================================================
  task automatic test_counter_reset();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 7: Counter Reset via CTRL ===");
    
    // Let counter run for a bit
    axi_write(ADDR_CTRL, 32'h00000002, resp); // RESET=0
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'hFFFFFFFF, resp);
    repeat(10) @(posedge clk);
    
    // Check counter has incremented
    axi_read(ADDR_COUNTER, rdata, resp);
    if (rdata > 32'h5) begin
      $display("[PASS]  Counter running (value=%0d)", rdata);
      test_count++;
    end else begin
      $display("[ERROR] Counter value too low (value=%0d)", rdata);
      error_count++;
      test_count++;
    end
    
    // Assert RESET bit
    axi_write(ADDR_CTRL, 32'h00000003, resp); // RESET=1
    repeat(2) @(posedge clk);
    
    // Check counter is 0
    axi_read(ADDR_COUNTER, rdata, resp);
    check_value("Counter after RESET=1", 32'h0, rdata);
    
    // Deassert RESET and verify counter starts counting again
    axi_write(ADDR_CTRL, 32'h00000002, resp); // RESET=0
    repeat(5) @(posedge clk);
    
    axi_read(ADDR_COUNTER, rdata, resp);
    if (rdata > 32'h0) begin
      $display("[PASS]  Counter resumed after RESET=0 (value=%0d)", rdata);
      test_count++;
    end else begin
      $display("[ERROR] Counter didn't resume (value=%0d)", rdata);
      error_count++;
      test_count++;
    end
  endtask

  // ============================================================
  // Test 8: Invalid address access
  // ============================================================
  task automatic test_invalid_address();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    
    $display("\n=== TEST 8: Invalid Address Access ===");
    
    // Try reading from invalid address
    axi_read(12'h014, rdata, resp);
    check_value("Read invalid addr response", RESP_SLVERR, {30'h0, resp});
    
    axi_read(12'hFFC, rdata, resp);
    check_value("Read high addr response", RESP_SLVERR, {30'h0, resp});
    
    // Try writing to invalid address
    axi_write(12'h018, 32'hDEADBEEF, resp);
    check_value("Write invalid addr response", RESP_SLVERR, {30'h0, resp});
  endtask

  // ============================================================
  // Test 9: Rapid threshold cycles
  // ============================================================
  task automatic test_rapid_threshold();
    logic [AXI_DATA_BW_p-1:0] rdata;
    logic [1:0] resp;
    int cycle_count = 0;
    
    $display("\n=== TEST 9: Rapid Threshold Cycles ===");
    
    // Configure for very fast threshold (threshold=2, no prescaler)
    axi_write(ADDR_CTRL, 32'h00000003, resp);
    repeat(2) @(posedge clk);
    axi_write(ADDR_PRESCALER, 32'h0, resp);
    axi_write(ADDR_THRESHOLD, 32'h00000002, resp);
    axi_write(ADDR_CTRL, 32'h00000002, resp); // IE=1, RESET=0
    
    // Let it run and count interrupt cycles
    for (int i = 0; i < 20; i++) begin
      @(posedge clk);
      if (dut.timer_counter_inst.s_threshold) cycle_count++;
    end
    
    if (cycle_count >= 3) begin
      $display("[PASS]  Multiple threshold cycles detected (%0d interrupts)", cycle_count);
      test_count++;
    end else begin
      $display("[ERROR] Insufficient threshold cycles (%0d interrupts)", cycle_count);
      error_count++;
      test_count++;
    end
  endtask

  // ============================================================
  // Main test sequence
  // ============================================================
  initial begin
    $display("\n========================================");
    $display("AXI4-Lite Timer/Counter Testbench");
    $display("========================================\n");
    
    // Initialize and reset
    init_axi_signals();
    reset_dut();
    
    // Run all tests
    test_reset();
    test_register_write_read();
    test_counter_basic();
    test_prescaler();
    test_threshold_detection();
    test_interrupt();
    test_counter_reset();
    test_invalid_address();
    test_rapid_threshold();
    
    // Final summary
    $display("\n========================================");
    $display("Test Summary");
    $display("========================================");
    $display("Total tests: %0d", test_count);
    $display("Passed:      %0d", test_count - error_count);
    $display("Failed:      %0d", error_count);
    
    if (error_count == 0) begin
      $display("\n*** ALL TESTS PASSED ***\n");
    end else begin
      $display("\n*** TESTS FAILED ***\n");
    end
    
    $finish;
  end

  // Timeout watchdog
  initial begin
    #100000;
    $display("\n[ERROR] Testbench timeout!");
    $finish;
  end

endmodule
