// AXI4-Lite module containing registers for timer/counter control 
//  Offsets:
//  0x0: TIMER0 control register
//  0x1: TIMER0 load value register
//  0x2: TIMER0 compare value register
//  0x3: TIMER1 control register
//  0x4: TIMER1 load value register
//  0x5: TIMER1 compare value register

module axi_timer #(
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
  // Timer/Counter0 related signals
  output logic o_cnt0_en,
  output logic o_cnt0_reload,
  output logic o_cnt0_count_up,
  output logic [31:0] o_cnt0_load_value,
  output logic [31:0] o_cnt0_compare_value,
  input  logic [31:0] i_cnt0_value,
  // Timer/Counter1 related signals
  output logic o_cnt1_en,
  output logic o_cnt1_reload,
  output logic o_cnt1_count_up,
  output logic o_cnt1_src,
  output logic [31:0] o_cnt1_load_value,
  output logic [31:0] o_cnt1_compare_value,
  input  logic [31:0] i_cnt1_value
);

  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_EXOKAY = 2'b01;
  localparam logic [1:0] RESP_SLVERR = 2'b10;
  localparam logic [1:0] RESP_DECERR = 2'b11;
 
  // --------------------------------------------------------------
  // Timer/counter related logic
  // --------------------------------------------------------------
  // Timer/Counter0 related signals
  logic s_cnt0_en;
  logic s_cnt0_reload;
  logic s_cnt0_count_up;
  logic [31:0] s_cnt0_load_value;
  logic [31:0] s_cnt0_compare_value;

  // Timer/Counter1 related signals
  logic s_cnt1_en;
  logic s_cnt1_reload;
  logic s_cnt1_count_up;
  logic s_cnt1_src;
  logic [31:0] s_cnt1_load_value;
  logic [31:0] s_cnt1_compare_value;
  
  // Drive outputs
  assign o_cnt0_en = s_cnt0_en;
  assign o_cnt0_reload = s_cnt0_reload;
  assign o_cnt0_count_up = s_cnt0_count_up;
  assign o_cnt0_load_value = s_cnt0_load_value;
  assign o_cnt0_compare_value = s_cnt0_compare_value;

  // Timer/Counter1 related signals
  assign o_cnt1_en = s_cnt1_en;
  assign o_cnt1_reload = s_cnt1_reload;
  assign o_cnt1_count_up = s_cnt1_count_up;
  assign o_cnt1_src = s_cnt1_src;
  assign o_cnt1_load_value = s_cnt1_load_value;
  assign o_cnt1_compare_value = s_cnt1_compare_value;

  // --------------------------------------------------------------
  // Write address, write data and write wresponse
  // --------------------------------------------------------------
  logic [1:0]  c_axi_wresp;
  logic [3:0]  c_axi_wstrb;
  logic [31:0] c_axi_wdata;
  logic s_axi_wdata_buf_used;
  logic [31:0] s_axi_wdata_buf;
  logic [3:0]  s_axi_wstrb_buf;
  logic [1:0]  s_axi_bresp;
  logic [AXI_ADDR_BW_p-1:0] s_axi_awaddr_buf;
  logic [AXI_ADDR_BW_p-1:0] c_axi_awaddr;
  logic s_axi_awaddr_buf_used;
  logic s_axi_awvalid;
  logic s_axi_wvalid;
  // Internal signals
  logic s_axi_bvalid;
  logic s_axi_awready;
  logic s_axi_wready;
  logic s_awaddr_done;
  logic [AXI_ADDR_BW_p-1:0] s_axi_awaddr;
 
  // We want to stall the address write if either we received write request without write data
  // or if the write address buffer is full and master is stalling write response channel
  assign o_axi_awready = !s_axi_awaddr_buf_used & s_axi_awvalid;

  // We want to stall the data write if either we received write data without a write request
  // or if the write data buffer is full and master is stalling write response channel
  assign o_axi_wready  = !s_axi_wdata_buf_used & s_axi_wvalid;

  logic write_response_stalled;
  logic valid_write_address;
  logic valid_write_data;

  assign write_response_stalled = o_axi_bvalid & ~i_axi_bready;
  assign valid_write_address = s_axi_awaddr_buf_used | (i_axi_awvalid & o_axi_awready);
  assign valid_write_data = s_axi_wdata_buf_used | (i_axi_wvalid & o_axi_wready);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axi_awvalid <= 1'b0;
      s_axi_awaddr_buf_used <= 1'b0;
    end else begin
      s_axi_awvalid <= 1'b1;
      // When master is stalling on the response channel or if we didn't receive
      // write data, we need to buffer the address
      if (i_axi_awvalid && o_axi_awready && (write_response_stalled || !valid_write_data)) begin
        s_axi_awaddr_buf <= i_axi_awaddr;
        s_axi_awaddr_buf_used <= 1'b1;
      end else if (s_axi_awaddr_buf_used && valid_write_data && (!o_axi_bvalid || i_axi_bready)) begin
        s_axi_awaddr_buf_used <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axi_wdata_buf_used <= 1'b0;
      s_axi_wvalid <= 1'b0;
    end else begin
      s_axi_wvalid <= 1'b1;
      // We want to fill the buffer if either we're getting a response stall, or we 
      // get a write data without a write address
      if (i_axi_wvalid && o_axi_wready && (write_response_stalled || !valid_write_address)) begin
        s_axi_wdata_buf <= i_axi_wdata;
        s_axi_wdata_buf_used <= 1'b1;
      end else if (s_axi_wdata_buf_used && valid_write_address && (!o_axi_bvalid || i_axi_bready)) begin
        s_axi_wdata_buf_used <= 1'b0;
      end
    end
  end

  // Muxes to select write address and write data either from the buffer or from the AXI bus
  assign c_axi_awaddr = s_axi_awaddr_buf_used ? s_axi_awaddr_buf : i_axi_awaddr;
  assign c_axi_wdata  = s_axi_wdata_buf_used  ? s_axi_wdata_buf : i_axi_wdata;

  // Store write data to the correct register and generate a response
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axi_bvalid <= 1'b0;
      s_cnt0_en <= 1'b0;
      s_cnt0_reload <= 1'b0;
      s_cnt0_count_up <= 1'b0;
      s_cnt0_load_value <= '0;
      s_cnt0_compare_value <= '0;
      s_cnt1_en <= 1'b0;
      s_cnt1_reload <= 1'b0;
      s_cnt1_count_up <= 1'b0;
      s_cnt1_src <= 1'b0;
      s_cnt1_load_value <= '0;
      s_cnt1_compare_value <= '0;
    end else begin
      // If there is write address and write data in the buffer
      if (valid_write_address && valid_write_data && (!o_axi_bvalid || i_axi_bready)) begin
        s_axi_bresp <= RESP_OKAY;
        s_axi_bvalid <= 1'b1;
        
        case (c_axi_awaddr[AXI_ADDR_BW_p-1:2])
          'd0 : begin
            s_cnt0_en <= c_axi_wdata[0];
            s_cnt0_reload <= c_axi_wdata[1];
            s_cnt0_count_up <= c_axi_wdata[2];
          end

          'd1 : begin
            s_cnt0_load_value <= c_axi_wdata;
          end

          'd2 : begin
            s_cnt0_compare_value <= c_axi_wdata;
          end

          'd4 : begin
            s_cnt1_en <= c_axi_wdata[0];
            s_cnt1_reload <= c_axi_wdata[1];
            s_cnt1_count_up <= c_axi_wdata[2];
            s_cnt1_src <= c_axi_wdata[3]; 
          end

          'd5 : begin
            s_cnt1_load_value <= c_axi_wdata;
          end

          'd6 : begin
            s_cnt1_compare_value <= c_axi_wdata;
          end

          default: begin
            s_axi_bresp <= RESP_SLVERR;
          end
        endcase
      end else if (o_axi_bvalid && i_axi_bready && !(valid_write_address && valid_write_data)) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end
  

  // Assign intermediate signals to outputs 
  assign o_axi_bresp = s_axi_bresp;
  assign o_axi_bvalid = s_axi_bvalid;
  
  // --------------------------------------------------------------
  // Read address and read response
  // --------------------------------------------------------------
  logic s_axi_rvalid;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_arready;

  // Read address buffer
  logic [AXI_ADDR_BW_p-1:0] s_araddr_buf;
  logic s_araddr_buf_used;
  logic [AXI_ADDR_BW_p-1:0] c_axi_araddr;

  // Address buffer management
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_araddr_buf_used <= 1'b0;
      s_axi_arready <= 1'b0;
    end else begin
      s_axi_arready <= 1'b1;

      // Fill buffer when response is stalled
      if (i_axi_arvalid && o_axi_arready && o_axi_rvalid && !i_axi_rready) begin
        s_araddr_buf <= i_axi_araddr;
        s_araddr_buf_used <= 1'b1;
      end 
      // Clear buffer when address is consumed
      else if (s_araddr_buf_used && (!o_axi_rvalid || i_axi_rready)) begin
        s_araddr_buf_used <= 1'b0;
      end
    end
  end

  // Mux to select address 
  assign c_axi_araddr = s_araddr_buf_used ? s_araddr_buf : i_axi_araddr;

  // Ready signal blocks when buffer full
  assign o_axi_arready = !s_araddr_buf_used & s_axi_arready;

  // Response generation
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axi_rvalid <= 1'b0;
    end else begin
      // Generate response when address is available (buffer or direct)
      if ((s_araddr_buf_used || (i_axi_arvalid && o_axi_arready)) && (!o_axi_rvalid || i_axi_rready)) begin
        s_axi_rresp <= RESP_OKAY;
        s_axi_rvalid <= 1'b1;
        s_axi_rdata <= '0;

        case (c_axi_araddr[AXI_ADDR_BW_p-1:2])
          'd0 : begin
            s_axi_rdata[0] <= s_cnt0_en;
            s_axi_rdata[1] <= s_cnt0_reload;
            s_axi_rdata[2] <= s_cnt0_count_up;
          end

          'd1 : begin
            s_axi_rdata <= s_cnt0_load_value;
          end

          'd2 : begin
            s_axi_rdata <= s_cnt0_compare_value;
          end

          'd3 : begin
            s_axi_rdata <= i_cnt0_value;
          end

          'd4 : begin
            s_axi_rdata[0] <= s_cnt1_en;
            s_axi_rdata[1] <= s_cnt1_reload; 
            s_axi_rdata[2] <= s_cnt1_count_up;
            s_axi_rdata[3] <= s_cnt1_src; 
          end

          'd5 : begin
            s_axi_rdata <= s_cnt1_load_value;
          end

          'd6 : begin
            s_axi_rdata <= s_cnt1_compare_value;
          end

          'd7 : begin
            s_axi_rdata <= i_cnt1_value;
          end
          
          default: begin
            s_axi_rdata <= 32'hdeaddead;
            s_axi_rresp <= RESP_SLVERR;
          end
        endcase
      // Clear response when handshake completes and no new transaction
      end else if (o_axi_rvalid && i_axi_rready && !s_araddr_buf_used && !(i_axi_arvalid && o_axi_arready)) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  assign o_axi_rdata = s_axi_rdata;
  assign o_axi_rresp = s_axi_rresp;
  assign o_axi_rvalid = s_axi_rvalid;

endmodule : axi_timer
