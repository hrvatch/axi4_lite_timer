module axi_timer #(
  parameter int AXI_DATA_BW_p = 32,
  parameter int AXI_ADDR_BW_p = 12    // 4k boundary by default
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
  // Timer/Counter0 related signals
  output logic [AXI_DATA_BW_p-1:0] o_threshold_value,
  output logic [AXI_DATA_BW_p-1:0] o_prescaler_value,
  output logic                     o_counter_reset,
  input  logic                     i_threshold,
  input  logic [AXI_DATA_BW_p-1:0] i_counter_value,
  // Interrupt
  output logic o_irq
);

  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_EXOKAY = 2'b01;
  localparam logic [1:0] RESP_SLVERR = 2'b10;
  localparam logic [1:0] RESP_DECERR = 2'b11;
 
  // --------------------------------------------------------------
  // Timer/counter related logic
  // --------------------------------------------------------------
  logic s_status_reg;
  logic s_threshold_clear;
  logic s_interrupt_enable;
  logic s_threshold;
  logic s_counter_reset;
  logic [AXI_DATA_BW_p-1:0] s_threshold_value;
  logic [AXI_DATA_BW_p-1:0] s_prescaler_value;
  logic [AXI_DATA_BW_p-1:0] s_counter_value;

  assign o_threshold_value = s_threshold_value;
  assign o_prescaler_value = s_prescaler_value;
  assign o_counter_reset = s_counter_reset;

  // Register inputs
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_counter_value <= '0;
      s_threshold <= 1'b0;
    end else begin
      s_counter_value <= i_counter_value;
      s_threshold <= i_threshold;
    end
  end
 
  // Clear threshold
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_status_reg <= 1'b0;
    end else begin
      s_status_reg <= (s_status_reg | s_threshold) & ~s_threshold_clear;
    end
  end

  // Interrupt generation
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      o_irq <= 1'b0;
    end else begin
      o_irq <= s_status_reg && s_interrupt_enable;
    end
  end

  // --------------------------------------------------------------
  // Write address, write data and write wresponse
  // --------------------------------------------------------------
  logic [1:0]  c_axi_wresp;
  logic [AXI_DATA_BW_p-1:0] c_axi_wdata;
  logic s_axi_wdata_buf_used;
  logic [AXI_DATA_BW_p-1:0] s_axi_wdata_buf;
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
      s_prescaler_value <= '0;
      s_threshold_value <= '1;
      s_counter_reset <= 1'b1;
      s_interrupt_enable <= 1'b0;
    end else begin
      // If there is write address and write data in the buffer
      if (valid_write_address && valid_write_data && (!o_axi_bvalid || i_axi_bready)) begin
        s_axi_bresp <= RESP_OKAY;
        s_axi_bvalid <= 1'b1;
        
        case (c_axi_awaddr[AXI_ADDR_BW_p-1:2])

          'd1 : begin // CTRL register
            s_interrupt_enable <= c_axi_wdata[1];
            s_counter_reset <= c_axi_wdata[0];
          end

          'd3 : begin // PRESCALER_VALUE register
            s_prescaler_value <= c_axi_wdata;
          end

          'd4 : begin // THRESHOLD_VALUE register
            s_threshold_value <= c_axi_wdata;
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
  logic [AXI_DATA_BW_p-1:0] s_axi_rdata;
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
      s_threshold_clear <= 1'b0;
    end else begin
      s_threshold_clear <= 1'b0;
      
      // Generate response when address is available (buffer or direct)
      if ((s_araddr_buf_used || (i_axi_arvalid && o_axi_arready)) && (!o_axi_rvalid || i_axi_rready)) begin
        s_axi_rresp <= RESP_OKAY;
        s_axi_rvalid <= 1'b1;
        s_axi_rdata <= '0;

        case (c_axi_araddr[AXI_ADDR_BW_p-1:2])
          'd0 : begin
            s_axi_rdata <= s_status_reg;
            s_threshold_clear <= 1'b1;
          end

          'd1 : begin
            s_axi_rdata[1] <= s_interrupt_enable;
            s_axi_rdata[0] <= s_counter_reset;
          end

          'd2 : begin
            s_axi_rdata <= s_counter_value;
          end

          'd3 : begin
            s_axi_rdata <= s_prescaler_value;
          end

          'd4 : begin
            s_axi_rdata <= s_threshold_value;
          end

          default: begin
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
