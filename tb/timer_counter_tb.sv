module timer_counter_tb;
  
  // Clock and reset
  logic tb_clk;
  logic tb_rst_n;

  // Timer/Counter0 related signals
  logic tb_cnt0_en;
  logic tb_cnt0_reload;
  logic tb_cnt0_count_up;
  logic [31:0] tb_cnt0_load_value;
  logic [31:0] tb_cnt0_compare_value;

  // Timer/Counter1 related signals
  logic tb_cnt1_en;
  logic tb_cnt1_reload;
  logic tb_cnt1_count_up;
  logic tb_cnt1_src;
  logic [31:0] tb_cnt1_load_value;
  logic [31:0] tb_cnt1_compare_value;
  
  // Timer/Counter interrupt
  logic tb_cnt0_done;
  logic tb_cnt1_done;

  // Clock
  initial begin
    tb_clk <= 1'b0;
    forever #5ns tb_clk <= ~tb_clk;
  end

  // Reset
  initial begin
    tb_rst_n <= 1'b0;
    repeat(5) @(posedge tb_clk);
    tb_rst_n <= 1'b1;
  end

`ifdef TC1 // Counter up
  initial begin
    $display("Starting TC1!");
    // Wait until reset is released
    wait (tb_rst_n === 1'b1);
   
    tb_cnt0_load_value <= '0;
    tb_cnt0_compare_value <= 'd100;
    tb_cnt0_count_up <= 1'b1;
    tb_cnt0_reload <= 1'b1;
    tb_cnt0_en <= 1'b1;

    $display("Waiting 100cc for IRQ0 assertion...");
    repeat (102) @(posedge tb_clk);
    check_irq_asserted : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end
    
    $display("Expecting counter reload and another IRQ0 assertion...");
    repeat (101) @(posedge tb_clk);
    check_another_irq_assertion : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat (5) @(posedge tb_clk);

    $display("Disabling the counter0...");
    tb_cnt0_en <= 1'b0;
    repeat (2) @(posedge tb_clk);
    $display("Checking if counter0 value is correct...");
    check_disabled_counter_value : assert (timer_counter_dut.s_cnt0_value == tb_cnt0_load_value) begin
      $display("OK: Counter0 value is correct!");
    end else begin
      $display("NOK: Counter0 value is NOT correct!");
      $fatal;
    end

    $display("Enabling the counter0 and disabling reload...");
    tb_cnt0_en <= 1'b1;
    tb_cnt0_reload <= 1'b0;
    
    $display("Waiting 100cc for IRQ0 assertion...");
    repeat (102) @(posedge tb_clk);
    checking_irq_after_reload_disabled : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat(5) @(posedge tb_clk);
    $display("Expecting counter0 value to be greater than 100...");
    checking_value_after_reload_disabled : assert(timer_counter_dut.s_cnt0_value > tb_cnt0_compare_value) begin
      $display("OK: Counter0 value is correct!");
    end else begin
      $display("NOK: Counter0 value is not greater than 100!");
      $fatal;
    end

    $display("Test completed succesfully!");
    $finish;
  end
  
  initial begin
    // Wait until reset is released
    wait (tb_rst_n === 1'b1);
   
    tb_cnt1_load_value <= '0;
    tb_cnt1_compare_value <= 'd100;
    tb_cnt1_count_up <= 1'b1;
    tb_cnt1_reload <= 1'b1;
    tb_cnt1_en <= 1'b1;
    tb_cnt1_src <= 1'b0;

    $display("Waiting 100cc for IRQ1 assertion...");
    repeat (102) @(posedge tb_clk);
    check_irq1_asserted : assert (tb_cnt1_done === 1'b1) begin
      $display("OK: Counter1 IRQ asserted!");
    end else begin
      $display("NOK: Counter1 IRQ wasn't asserted after 100cc");
      $fatal;
    end
    
    $display("Expecting counter reload and another IRQ1 assertion...");
    repeat (101) @(posedge tb_clk);
    check_another_irq1_assertion : assert (tb_cnt1_done === 1'b1) begin
      $display("OK: Counter1 IRQ asserted!");
    end else begin
      $display("NOK: Counter1 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat (5) @(posedge tb_clk);

    $display("Disabling the counter1...");
    tb_cnt1_en <= 1'b0;
    repeat (2) @(posedge tb_clk);
    $display("Checking if counter1 value is correct...");
    check_disabled_counter1_value : assert (timer_counter_dut.s_cnt1_value == tb_cnt1_load_value) begin
      $display("OK: Counter1 value is correct!");
    end else begin
      $display("NOK: Counter1 value is NOT correct!");
      $fatal;
    end

    $display("Enabling the counter1 and disabling reload...");
    tb_cnt1_en <= 1'b1;
    tb_cnt1_reload <= 1'b0;
    
    $display("Waiting 100cc for IRQ1 assertion...");
    repeat (102) @(posedge tb_clk);
    checking_irq1_after_reload_disabled : assert (tb_cnt1_done === 1'b1) begin
      $display("OK: Counter1 IRQ asserted!");
    end else begin
      $display("NOK: Counter1 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat(5) @(posedge tb_clk);
    $display("Expecting counter1 value to be greater than 100...");
    checking_value_after_cnouter1_reload_disabled : assert(timer_counter_dut.s_cnt1_value > tb_cnt1_compare_value) begin
      $display("OK: Counter1 value is correct!");
    end else begin
      $display("NOK: Counter1 value is not greater than 100!");
      $fatal;
    end

    $finish;
  end
  
`endif

`ifdef TC2 // Counter down 
  initial begin
    $display("Starting TC2!");
    // Wait until reset is released
    wait (tb_rst_n === 1'b1);
   
    tb_cnt0_load_value <= 'd100;
    tb_cnt0_compare_value <= '0;
    tb_cnt0_count_up <= 1'b0;
    tb_cnt0_reload <= 1'b1;
    @(posedge tb_clk);
    tb_cnt0_en <= 1'b1;

    $display("Waiting 100cc for IRQ0 assertion...");
    repeat (102) @(posedge tb_clk);
    check_irq_asserted : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end
    
    $display("Expecting counter reload and another IRQ0 assertion...");
    repeat (101) @(posedge tb_clk);
    check_another_irq_assertion : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat (5) @(posedge tb_clk);

    $display("Disabling the counter0...");
    tb_cnt0_en <= 1'b0;
    repeat (2) @(posedge tb_clk);
    $display("Checking if counter0 value is correct...");
    check_disabled_counter_value : assert (timer_counter_dut.s_cnt0_value == tb_cnt0_load_value) begin
      $display("OK: Counter0 value is correct!");
    end else begin
      $display("NOK: Counter0 value is NOT correct!");
      $fatal;
    end

    $display("Enabling the counter0 and disabling reload...");
    tb_cnt0_en <= 1'b1;
    tb_cnt0_reload <= 1'b0;
    
    $display("Waiting 100cc for IRQ0 assertion...");
    repeat (102) @(posedge tb_clk);
    checking_irq_after_reload_disabled : assert (tb_cnt0_done === 1'b1) begin
      $display("OK: Counter0 IRQ asserted!");
    end else begin
      $display("NOK: Counter0 IRQ wasn't asserted after 100cc");
      $fatal;
    end

    repeat(5) @(posedge tb_clk);
    $display("Expecting counter0 value to be greater than 2**30...");
    checking_value_after_reload_disabled : assert(timer_counter_dut.s_cnt0_value > 2**30) begin
      $display("OK: Counter0 value is correct!");
    end else begin
      $display("NOK: Counter0 value is not greater than 2**30!");
      $fatal;
    end

    $display("Test completed succesfully!");
    $finish;
  end
`endif

`ifdef TC3 // Test timer1 having timer0 as a source
  initial begin
    static int cnt1_expected_value = 0;
    $display("Starting TC3!");
    // Wait until reset is released
    wait (tb_rst_n === 1'b1);
   
    $display("Enabling timer0");
    tb_cnt0_load_value <= '0;
    tb_cnt0_compare_value <= 'd100;
    tb_cnt0_count_up <= 1'b1;
    tb_cnt0_reload <= 1'b1;
    tb_cnt0_en <= 1'b1;
    
    $display("Setting timer0 IRQ as a source for timer1");
    tb_cnt1_load_value <= '0;
    tb_cnt1_compare_value <= 'd5;
    tb_cnt1_count_up <= 1'b1;
    tb_cnt1_reload <= 1'b1;
    tb_cnt1_src <= 1'b1;
    tb_cnt1_en <= 1'b1;

    $display("Tsting counter1 value...");
    repeat(5) begin
      wait(tb_cnt0_done);
      cnt1_expected_value++;
      repeat(2) @(posedge tb_clk);
      check_counter1_value : assert(cnt1_expected_value == timer_counter_dut.s_cnt1_value) begin
        $display("OK: Expected counter1 value of %0d matches the actual value", cnt1_expected_value);
      end else begin
        $display("NOK: Invalid counter1 value!");
        $fatal;
      end

      @(posedge tb_clk);
      if (cnt1_expected_value == 5) begin
        check_counter1_irq : assert(tb_cnt1_done == 1'b1) begin
          $display("IRQ1 matches expected value!");
        end else begin
          $display("IRQ1 doesn't match expected value!");
          $fatal;
        end
      end else begin
        check_counter1_irq_not_asserted : assert(tb_cnt1_done == 1'b0) begin
          $display("IRQ1 matches expected value!");
        end else begin
          $display("IRQ1 doesn't match expected value!");
          $fatal;
        end
      end
    end

    @(posedge tb_clk);
    check_counter1_irq_not_asserted_again : assert(tb_cnt1_done == 1'b0) begin
      $display("IRQ1 matches expected value!");
    end else begin
      $display("IRQ1 doesn't match expected value!");
      $fatal;
    end
    $display("Test completed succesfully!");
    $finish;
  end
`endif

  timer_counter timer_counter_dut (
    .clk                  ( tb_clk                ),
    .rst_n                ( tb_rst_n              ),
    .i_cnt0_en            ( tb_cnt0_en            ),
    .i_cnt0_reload        ( tb_cnt0_reload        ),
    .i_cnt0_count_up      ( tb_cnt0_count_up      ),
    .i_cnt0_load_value    ( tb_cnt0_load_value    ),
    .i_cnt0_compare_value ( tb_cnt0_compare_value ),
    .i_cnt1_en            ( tb_cnt1_en            ),
    .i_cnt1_reload        ( tb_cnt1_reload        ),
    .i_cnt1_count_up      ( tb_cnt1_count_up      ),
    .i_cnt1_src           ( tb_cnt1_src           ),
    .i_cnt1_load_value    ( tb_cnt1_load_value    ),
    .i_cnt1_compare_value ( tb_cnt1_compare_value ),
    .o_cnt0_done          ( tb_cnt0_done          ),
    .o_cnt1_done          ( tb_cnt1_done          ),
    .o_cnt0_value         ( /* OPEN */            ),
    .o_cnt1_value         ( /* OPEN */            )
  );

endmodule : timer_counter_tb
