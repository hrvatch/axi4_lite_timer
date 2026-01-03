module axi_timer_formal_tb #(
  parameter int AXI_ADDR_BW_p = 4
) (
  input logic  clk,
  input logic  rst_n,
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
  output logic o_axi_rvalid
);

  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_EXOKAY = 2'b10;
  localparam logic [1:0] RESP_SLVERR = 2'b10;
  localparam logic [1:0] RESP_DECERR = 2'b11;
  
  // Default clock
  default clocking cb @(posedge clk);
  endclocking

  // Default reset
  default disable iff (!rst_n);

  // Valid-ready handshake
  property valid_ready_handshake(valid, ready, data);
    valid && !ready |=> valid && $stable(data)
  endproperty : valid_ready_handshake

  // ------------------------
  // Assumptions
  // ------------------------
  // Handshake
  assume_araddr_valid_ready_handshake : assume property(valid_ready_handshake(i_axi_arvalid, o_axi_arready, i_axi_araddr));
  assume_awaddr_valid_ready_handshake : assume property(valid_ready_handshake(i_axi_awvalid, o_axi_awready, i_axi_awaddr));
  assume_wdata_valid_ready_handshake  : assume property(valid_ready_handshake(i_axi_wvalid, o_axi_wready, i_axi_wdata));

  // 4-byte aligned
  assume_araddr_4_byte_aligned : assume property(i_axi_araddr[1:0] == 2'b0);
  assume_awaddr_4_byte_aligned : assume property(i_axi_awaddr[1:0] == 2'b0);

  // ------------------------
  // Assertions
  // ------------------------
  // Handshake
  assert_rdata_valid_ready_handshake : assert property(valid_ready_handshake(o_axi_rvalid, i_axi_rready, o_axi_rdata));
  assert_rresp_valid_ready_handshake : assert property(valid_ready_handshake(o_axi_rvalid, i_axi_rready, o_axi_rresp));
  assert_bresp_valid_ready_handshake : assert property(valid_ready_handshake(o_axi_bvalid, i_axi_bready, o_axi_bresp));

  // Auxilliary logic for read requests
  int read_request_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_request_cnt <= '0;
    end else begin
      // If we get immediate response for the read request
      if (!(i_axi_arvalid && o_axi_arready && o_axi_rvalid && i_axi_rready)) begin
        if (i_axi_arvalid && o_axi_arready) begin
          read_request_cnt++;
        end else if (i_axi_rready && o_axi_rvalid) begin
          read_request_cnt--;
        end
      end
    end
  end

  // There should be at most one read request being served and one in the buffer - two in total
  assert_valid_number_of_read_requests : assert property ( read_request_cnt >= 0 && read_request_cnt <= 2);

  // Auxilliary logic for write requests and write data
  int write_request_cnt;
  int write_data_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_request_cnt <= '0;
      write_data_cnt <= '0;
    end else begin
      // If we get immediate response for the write request
      if (!(i_axi_awvalid && o_axi_awready && o_axi_bvalid && i_axi_bready)) begin
        if (i_axi_awvalid && o_axi_awready) begin
          write_request_cnt++;
        end else if (i_axi_bready && o_axi_bvalid) begin
          write_request_cnt--;
        end
      end
      
      // If we get immediate response for the write data
      if (!(i_axi_wvalid && o_axi_wready && o_axi_bvalid && i_axi_bready)) begin
        if (i_axi_wvalid && o_axi_wready) begin
          write_data_cnt++;
        end else if (i_axi_bready && o_axi_bvalid) begin
          write_data_cnt--;
        end
      end
    end
  end
  
  // There should be at most one write request being served and one in the buffer - two in total
  assert_valid_number_of_write_requests : assert property ( write_request_cnt >= 0 && write_request_cnt <= 2);
  assert_valid_number_of_write_data : assert property ( write_data_cnt >= 0 && write_data_cnt <= 2);

  // ------------------------
  // Covers
  // ------------------------
  // Cover 5 consecutive read requests
  cov_5_consecutive_read_requests : cover property (
    (i_axi_arvalid && o_axi_arready)[*5]
  );

  // Cover buffer filling and emptying
  cover_read_buffer_empty_full_empty : cover property (
    read_request_cnt == 0 ##1 read_request_cnt == 1 ##1 read_request_cnt == 2 ##1
    read_request_cnt == 1 ##1 read_request_cnt == 0
  );

  // Cover 5 consecutive write requests
  cov_5_consecutive_write_requests : cover property (
    (i_axi_awvalid && o_axi_awready)[*5]
  );

  // Cover buffer filling and emptying
  cover_write_request_buffer_empty_full_empty : cover property (
    write_request_cnt == 0 ##1 write_request_cnt == 1 ##1 write_request_cnt == 2 ##1
    write_request_cnt == 1 ##1 write_request_cnt == 0
  );
  cover_write_data_buffer_empty_full_empty : cover property (
    write_data_cnt == 0 ##1 write_data_cnt == 1 ##1 write_data_cnt == 2 ##1
    write_data_cnt == 1 ##1 write_data_cnt == 0
  );
  
  // ------------------------
  // Instantiate DUT
  // ------------------------
  axi_timer #(
    .AXI_ADDR_BW_p(AXI_ADDR_BW_p)
  ) axi_timer_dut (
    .clk ( clk ),
    .rst_n ( rst_n ),
    .i_axi_awaddr ( i_axi_awaddr ),
    .i_axi_awvalid ( i_axi_awvalid ),
    .i_axi_wdata ( i_axi_wdata ),
    .i_axi_wvalid ( i_axi_wvalid ),
    .i_axi_bready ( i_axi_bready ),
    .i_axi_araddr ( i_axi_araddr ),
    .i_axi_arvalid ( i_axi_arvalid ),
    .i_axi_rready ( i_axi_rready ),
    .o_axi_awready ( o_axi_awready ),
    .o_axi_wready ( o_axi_wready ),
    .o_axi_bresp ( o_axi_bresp ),
    .o_axi_bvalid ( o_axi_bvalid ),
    .o_axi_arready ( o_axi_arready ),
    .o_axi_rdata ( o_axi_rdata ),
    .o_axi_rresp ( o_axi_rresp ),
    .o_axi_rvalid ( o_axi_rvalid ),
    .o_cnt0_en ( /* OPEN */ ),
    .o_cnt0_reload ( /* OPEN */ ),
    .o_cnt0_count_up ( /* OPEN */ ),
    .o_cnt0_load_value ( /* OPEN */ ),
    .o_cnt0_compare_value ( /* OPEN */ ),
    .o_cnt1_en ( /* OPEN */ ),
    .o_cnt1_reload ( /* OPEN */ ),
    .o_cnt1_count_up ( /* OPEN */ ),
    .o_cnt1_src ( /* OPEN */ ),
    .o_cnt1_load_value ( /* OPEN */ ),
    .o_cnt1_compare_value ( /* OPEN */ )
  );

endmodule : axi_timer_formal_tb
