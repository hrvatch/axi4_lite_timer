module axi_timer_counter_top #(
  parameter AXI_ADDR_BW_p = 12    // 4k boundary by default
) (
  // Clock and reset
  input logic  clk,
  input logic  rst_n,
  // AXI related signals
  input logic [AXI_ADDR_BW_p-1:0] i_axi_awaddr,
  input logic  i_axi_awvalid,
  input logic [31:0] i_axi_wdata,
  input logic i_axi_wvalid,
  input logic i_axi_bready,
  input logic [AXI_ADDR_BW_p-1:0] i_axi_araddr,
  input logic i_axi_arvalid,
  input logic i_axi_rready,
  output logic o_axi_awready,
  output logic o_axi_wready,
  output logic [1:0] o_axi_bresp,
  output logic o_axi_bvalid,
  output logic o_axi_arready,
  output logic [31:0] o_axi_rdata,
  output logic [1:0] o_axi_rresp,
  output logic o_axi_rvalid,
  output logic o_cnt0_done,
  output logic o_cnt1_done
);

  // --------------------------------------------------------------
  // Timer/counter related signals
  // --------------------------------------------------------------
  // Timer/Counter0 related signals
  logic s_cnt0_en;
  logic s_cnt0_reload;
  logic s_cnt0_count_up;
  logic [31:0] s_cnt0_load_value;
  logic [31:0] s_cnt0_compare_value;
  logic [31:0] s_cnt0_value;

  // Timer/Counter1 related signals
  logic s_cnt1_en;
  logic s_cnt1_reload;
  logic s_cnt1_count_up;
  logic s_cnt1_src;
  logic [31:0] s_cnt1_load_value;
  logic [31:0] s_cnt1_compare_value;
  logic [31:0] s_cnt1_value;

  // --------------------------------------------------------------
  // AXI interface instantiation
  // --------------------------------------------------------------
  axi_timer #(
    .AXI_ADDR_BW_p ( AXI_ADDR_BW_p )
  ) axi_timer_inst (
  // Clock and reset
    .clk                  ( clk                   ),
    .rst_n                ( rst_n                 ),
      // AXI related signals
    .i_axi_awaddr         ( i_axi_awaddr          ),
    .i_axi_awvalid        ( i_axi_awvalid         ),
    .i_axi_wdata          ( i_axi_wdata           ),
    .i_axi_wvalid         ( i_axi_wvalid          ),
    .i_axi_bready         ( i_axi_bready          ),
    .i_axi_araddr         ( i_axi_araddr          ),
    .i_axi_arvalid        ( i_axi_arvalid         ),
    .i_axi_rready         ( i_axi_rready          ),
    .o_axi_awready        ( o_axi_awready         ),
    .o_axi_wready         ( o_axi_wready          ),
    .o_axi_bresp          ( o_axi_bresp           ),
    .o_axi_bvalid         ( o_axi_bvalid          ),
    .o_axi_arready        ( o_axi_arready         ),
    .o_axi_rdata          ( o_axi_rdata           ),
    .o_axi_rresp          ( o_axi_rresp           ),
    .o_axi_rvalid         ( o_axi_rvalid          ),
      // Timer/Counter0 related signals
    .o_cnt0_en            ( s_cnt0_en             ),
    .o_cnt0_reload        ( s_cnt0_reload         ),
    .o_cnt0_count_up      ( s_cnt0_count_up       ),
    .o_cnt0_load_value    ( s_cnt0_load_value     ),
    .o_cnt0_compare_value ( s_cnt0_compare_value  ),
    .i_cnt0_value         ( s_cnt0_ value         ),
      // Timer/Counter1 related signals
    .o_cnt1_en            ( s_cnt1_en             ),
    .o_cnt1_reload        ( s_cnt1_reload         ),
    .o_cnt1_count_up      ( s_cnt1_count_up       ),
    .o_cnt1_src           ( s_cnt1_src            ),
    .o_cnt1_load_value    ( s_cnt1_load_value     ),
    .o_cnt1_compare_value ( s_cnt1_compare_value  ),
    .i_cnt1_value         ( s_cnt1_value          )
  );
  
  // --------------------------------------------------------------
  // Timer/counter instantiation
  // --------------------------------------------------------------
  timer_counter timer_counter_inst (
    // Clock and reset
    .clk                  ( clk                   ),
    .rst_n                ( rst_n                 ),
    .i_cnt0_en            ( s_cnt0_en             ),
    .i_cnt0_reload        ( s_cnt0_reload         ),
    .i_cnt0_count_up      ( s_cnt0_count_up       ),
    .i_cnt0_load_value    ( s_cnt0_load_value     ),
    .i_cnt0_compare_value ( s_cnt0_compare_value  ),
    .o_cnt0_value         ( s_cnt0_value          ),
    .i_cnt1_en            ( s_cnt1_en             ),
    .i_cnt1_reload        ( s_cnt1_reload         ),
    .i_cnt1_count_up      ( s_cnt1_count_up       ),
    .i_cnt1_src           ( s_cnt1_src            ),
    .i_cnt1_load_value    ( s_cnt1_load_value     ),
    .i_cnt1_compare_value ( s_cnt1_compare_value  ),
    .o_cnt1_value         ( s_cnt1_value          ),
    .o_cnt0_done          ( o_cnt0_done           ),
    .o_cnt1_done          ( o_cnt1_done           )
  );

endmodule : axi_timer_counter_top
