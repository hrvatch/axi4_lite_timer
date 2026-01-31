module timer_counter #(
  parameter int COUNTER_BW_p,
  parameter int PRESCALER_BW_p
) (
  // Clock and reset
  input  logic clk,
  input  logic rst_n,

  // Counter related signals
  input  logic [COUNTER_BW_p-1:0]    i_threshold_value,
  input  logic [PRESCALER_BW_p-1:0]  i_prescale_value,
  input  logic                       i_counter_reset,
  output logic                       o_threshold,
  output logic [COUNTER_BW_p-1:0]    o_counter_value
);
  
  logic [COUNTER_BW_p-1:0]   s_counter;
  logic [PRESCALER_BW_p-1:0] s_prescaler;
  logic                      s_cnt_en;

  // Prescaler
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_cnt_en <= 1'b0;
      s_prescaler <= '0;
    end else begin
      if (i_counter_reset) begin
        s_prescaler <= '0;
        s_cnt_en <= 1'b0;
      end else begin
        if (s_prescaler == {PRESCALER_BW_p{1'b0}}) begin
          s_cnt_en <= 1'b1;
          s_prescaler <= i_prescale_value;
        end else begin
          s_cnt_en <= 1'b0;
          s_prescaler <= s_prescaler - 1'b1;
        end
      end
    end
  end

  // Counter
  assign o_counter_value = s_counter;
  
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_counter <= '0;
      o_threshold <= 1'b0;
    end else begin
      if (i_counter_reset) begin
        s_counter <= '0;
        o_threshold <= 1'b0;
      end else begin
        if (s_counter >= i_threshold_value) begin
          s_counter <= '0;
          o_threshold <= 1'b1;
        end else begin
          s_counter <= s_counter + 1'b1;
          o_threshold <= 1'b0;
        end
      end
    end
  end

endmodule : timer_counter
