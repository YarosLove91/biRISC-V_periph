module tb(
    // Clock and Reset
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // AXI Lite Write Address Channel
    input  logic [31:0] axi_awaddr,   // Write Address
    input  logic [2:0]  axi_awprot,   // Write Protection type
    input  logic        axi_awvalid,  // Write Address Valid
    output logic        axi_awready,  // Write Address Ready
    
    // AXI Lite Write Data Channel
    input  logic [31:0] axi_wdata,    // Write Data
    input  logic [3:0]  axi_wstrb,    // Write Strobes
    input  logic        axi_wvalid,
    output logic        axi_wready,   // Write Ready
    
    // AXI Lite Write Response Channel
    output logic [1:0]  axi_bresp,    // Write Response
    output logic        axi_bvalid,   // Write Response Valid
    input  logic        axi_bready,   // Response Ready
    
    // AXI Lite Read Address Channel
    input  logic [31:0] axi_araddr,   // Read Address
    input  logic [2:0]  axi_arprot,   // Read Protection type
    input  logic        axi_arvalid,  // Read Address Valid
    output logic        axi_arready,  // Read Address Ready
    
    // AXI Lite Read Data Channel
    output logic [31:0] axi_rdata,    // Read Data
    output logic [1:0]  axi_rresp,    // Read Response
    output logic        axi_rvalid,   // Read Valid
    input  logic        axi_rready,   // Read Ready
    
    // Timer/Counter Interfaces
    input  logic [0:0]  ef_tcc32_ext_clk,
    output logic [0:0]  ef_tcc32_irq,
    output logic [0:0]  ef_tcc32_pwm,
    
    // RTC Interface
    output logic [0:0]  rtc_irq
);

// Parameters (should match your design)
parameter int unsigned AXI_LITE_AW = 32;
parameter int unsigned AXI_LITE_DW = 32;
parameter int unsigned APB_AW = 32;
parameter int unsigned APB_DW = 32;
parameter int unsigned PERIPH_BA = 32'h0000_0000;
parameter int unsigned EF_TCC32_QTY = 1;
parameter int unsigned RTC_QTY = 1;
// AXI Lite Interface
AXI_LITE#(
    .AXI_ADDR_WIDTH (AXI_LITE_AW),
    .AXI_DATA_WIDTH (AXI_LITE_DW)
) axi();

// Connect individual AXI Lite signals to the interface
always_comb begin
    // Write Address Channel
    axi.aw_addr   = axi_awaddr;
    axi.aw_prot   = axi_awprot;
    axi.aw_valid  = axi_awvalid;
    axi_awready   = axi.aw_ready;
    
    // Write Data Channel
    axi.w_data    = axi_wdata;
    axi.w_strb    = axi_wstrb;
    axi.w_valid   = axi_wvalid;
    axi_wready    = axi.w_ready;
    
    // Write Response Channel
    axi_bresp     = axi.b_resp;
    axi_bvalid    = axi.b_valid;
    axi.b_ready   = axi_bready;
    
    // Read Address Channel
    axi.ar_addr   = axi_araddr;
    axi.ar_prot   = axi_arprot;
    axi.ar_valid  = axi_arvalid;
    axi_arready   = axi.ar_ready;
    
    // Read Data Channel
    axi_rdata     = axi.r_data;
    axi_rresp     = axi.r_resp;
    axi_rvalid    = axi.r_valid;
    axi.r_ready   = axi_rready;
end

// DUT - AXI Lite Periphery Top
axil_periphery_wrap #(
    .AXI_LITE_AW             (AXI_LITE_AW),
    .AXI_LITE_DW             (AXI_LITE_DW),
    .APB_AW             (APB_AW),
    .APB_DW             (APB_DW),
    .PERIPH_BA          (PERIPH_BA),
    .EF_TCC32_QTY       (EF_TCC32_QTY),
    .RTC_QTY            (RTC_QTY),
    .PipelineRequest    (1'b0),
    .PipelineResponse   (1'b0)
) dut (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .axil_slave     (axi.Slave),
    .ef_tcc32_ext_clk   (ef_tcc32_ext_clk),
    .ef_tcc32_irq       (ef_tcc32_irq),
    .ef_tcc32_pwm       (ef_tcc32_pwm),
    .rtc_irq            (rtc_irq)
);

endmodule