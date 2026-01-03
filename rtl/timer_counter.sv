module timer_counter (
  // Clock and reset
  input logic clk,
  input logic rst_n,

  // Timer/Counter0 related signals
  input logic i_cnt0_en,
  input logic i_cnt0_reload,
  input logic i_cnt0_count_up,
  input logic [31:0] i_cnt0_load_value,
  input logic [31:0] i_cnt0_compare_value,

  // Timer/Counter1 related signals
  input logic i_cnt1_en,
  input logic i_cnt1_reload,
  input logic i_cnt1_count_up,
  input logic i_cnt1_src,
  input logic [31:0] i_cnt1_load_value,
  input logic [31:0] i_cnt1_compare_value,

  // Current Timer/counter value
  output logic [31:0] o_cnt0_value,
  output logic [31:0] o_cnt1_value,

  // Timer/Counter interrupt
  output logic o_cnt0_done,
  output logic o_cnt1_done
);
  
  logic [31:0] s_cnt0_value;
  logic s_cnt0_done;
  logic [31:0] s_cnt1_value;
  logic s_cnt1_done;

  assign o_cnt0_done = s_cnt0_done & i_cnt0_en;
  assign o_cnt1_done = s_cnt1_done & i_cnt1_en; 
  assign o_cnt0_value = s_cnt0_value;
  assign o_cnt1_value = s_cnt1_value;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_cnt0_done <= 1'b0;
      s_cnt0_value <= '0;
    end else begin
      s_cnt0_done <= 1'b0;
      if (i_cnt0_en) begin
        if (i_cnt0_count_up) begin
          s_cnt0_value <= s_cnt0_value + 1;
        end else begin
          s_cnt0_value <= s_cnt0_value - 1;
        end

        if (s_cnt0_value == i_cnt0_compare_value) begin
          s_cnt0_done <= 1'b1;
          if (i_cnt0_reload) begin
            s_cnt0_value <= i_cnt0_load_value;
          end
        end
      end else begin
        s_cnt0_value <= i_cnt0_load_value;
      end
    end
  end
  
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_cnt1_done <= 1'b0;
      s_cnt1_value <= '0;
    end else begin
      s_cnt1_done <= 1'b0;
      if (i_cnt1_en) begin
        if (!i_cnt1_src || (i_cnt1_src && s_cnt0_done)) begin
          if (i_cnt1_count_up) begin
            s_cnt1_value <= s_cnt1_value + 1;
          end else begin
            s_cnt1_value <= s_cnt1_value - 1;
          end
        end

        if (s_cnt1_value == i_cnt1_compare_value) begin
          s_cnt1_done <= 1'b1;
          if (i_cnt1_reload) begin
            s_cnt1_value <= i_cnt1_load_value;
          end
        end
      end else begin
        s_cnt1_value <= i_cnt1_load_value;
      end
    end
  end

endmodule : timer_counter
