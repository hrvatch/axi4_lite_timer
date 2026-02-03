module axi_timer_counter_top #(
  parameter AXI_DATA_BW_p = 32,
  parameter AXI_ADDR_BW_p = 12    // 4k boundary by default
) (
  // Clock and reset
  input logic  clk,
  input logic  rst_n,
  // AXI related signals
  input logic [AXI_ADDR_BW_p-1:0] i_axi_awaddr,
  input logic  i_axi_awvalid,
  input logic [AXI_DATA_BW_p-1:0] i_axi_wdata,
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
  output logic [AXI_DATA_BW_p-1:0] o_axi_rdata,
  output logic [1:0] o_axi_rresp,
  output logic o_axi_rvalid,
  output logic o_irq
);

  // --------------------------------------------------------------
  // Timer/counter related signals
  // --------------------------------------------------------------
  logic [AXI_DATA_BW_p-1:0] s_threshold_value;
  logic [AXI_DATA_BW_p-1:0] s_prescaler_value;
  logic [AXI_DATA_BW_p-1:0] s_counter_value;
  logic s_threshold;
  logic s_counter_reset;

  // --------------------------------------------------------------
  // AXI interface instantiation
  // --------------------------------------------------------------
  axi_timer #(
    .AXI_DATA_BW_p ( AXI_DATA_BW_p ),
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
    .o_counter_reset      ( s_counter_reset       ),
    .o_prescaler_value    ( s_prescaler_value     ),
    .o_threshold_value    ( s_threshold_value     ),
    .i_threshold          ( s_threshold           ),
    .i_counter_value      ( s_counter_value       ),
    .o_irq                ( o_irq                 )
  );
  
  // --------------------------------------------------------------
  // Timer/counter instantiation
  // --------------------------------------------------------------
  timer_counter #(
    .COUNTER_BW_p   ( AXI_DATA_BW_p  ),
    .PRESCALER_BW_p ( AXI_DATA_BW_p )
  ) timer_counter_inst (
    // Clock and reset
    .clk                  ( clk                   ),
    .rst_n                ( rst_n                 ),
    .i_counter_reset      ( s_counter_reset       ),
    .i_prescaler_value    ( s_prescaler_value     ),
    .i_threshold_value    ( s_threshold_value     ),
    .o_threshold          ( s_threshold           ),
    .o_counter_value      ( s_counter_value       )
  );

endmodule : axi_timer_counter_top
