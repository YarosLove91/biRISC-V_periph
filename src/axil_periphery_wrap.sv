`include "common_cells/registers.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "apb/typedef.svh"
`include "apb/assign.svh"

module axil_periphery_wrap #(
  parameter int unsigned AXI_LITE_AW       = 32,       // AXI Address width
  parameter int unsigned AXI_LITE_DW       = 32,       // AXI Data width

  
  parameter int unsigned APB_AW       = 32,       // APB Address width
  parameter int unsigned APB_DW       = 32,       // APB Data width
  
  parameter int unsigned PERIPH_BA    = 32'h0000_0000, // Peripheral base address
  parameter int unsigned EF_TCC32_QTY = 1,        // Number of timer/counter modules
  parameter int unsigned RTC_QTY      = 1,        // Number of RTC modules
  
  parameter bit PipelineRequest       = 1'b0,     // Pipeline request path
  parameter bit PipelineResponse      = 1'b0      // Pipeline response path
) (
  
  input  logic                     clk_i,
  input  logic                     rst_ni,
  
  AXI_LITE.Slave                    axil_slave,

  input  logic [EF_TCC32_QTY-1:0]  ef_tcc32_ext_clk,
  output logic [EF_TCC32_QTY-1:0]  ef_tcc32_irq,
  output logic [EF_TCC32_QTY-1:0]  ef_tcc32_pwm,
  output logic [RTC_QTY-1:0]       rtc_irq
);

localparam EF_TCC32_IDX = 0                           ;
localparam RTC_IDX      = EF_TCC32_IDX  + EF_TCC32_QTY;
localparam SLAVES_QTY   = RTC_IDX       + RTC_QTY     ;
localparam EF_TCC32_REGS_QTY = 1024; // 1024 - 963 = 61 reserved | 0x0000 - 0x0FFC (if qty == 1)
localparam RTC_REGS_QTY      = 16  ; // 16 - 13 = 3 reserved     | 0x1000 - 0x103C (if qty == 1)

localparam EF_TCC32_BA  = 0;
localparam RTC_BA       = EF_TCC32_QTY * EF_TCC32_REGS_QTY * 4;

  logic                     pclk;
  logic                     prst_n;
  logic [APB_AW-1:0]        paddr;
  logic [2:0]               pprot;
  logic                     psel;
  logic                     penable;
  logic                     pwrite;
  logic [APB_DW-1:0]        pwdata;
  logic [APB_DW/8-1:0]      pstrb;
  logic                     pready;
  logic [APB_DW-1:0]        prdata;
  logic                     pslverr;


  APB #(
    .ADDR_WIDTH (APB_AW),
    .DATA_WIDTH (APB_DW)
  ) s_apb_if ();


  assign pclk = clk_i;
  assign prst_n = rst_ni;


  typedef struct packed {
    int unsigned        idx;
    logic [APB_AW-1:0]  start_addr;
    logic [APB_AW-1:0]  end_addr;
} rule_t;

typedef logic [APB_AW - 1:0] addr_t;
typedef rule_t [SLAVES_QTY - 2:0] addr_map_t;

function addr_map_t get_addr_map();
    addr_map_t addr_map;
    int ef_tcc32_idx, rtc_idx;

    for (int rule_idx = 0; rule_idx < EF_TCC32_QTY; rule_idx++) begin
        ef_tcc32_idx = rule_idx;
        rtc_idx = ef_tcc32_idx+1;
        addr_map[rule_idx] = rule_t'{
            idx:        unsigned'(rule_idx),
            start_addr: PERIPH_BA + ( ef_tcc32_idx    * EF_TCC32_REGS_QTY * 4),
            end_addr:   PERIPH_BA + ((ef_tcc32_idx+1) * EF_TCC32_REGS_QTY * 4) + ((rtc_idx+1) * RTC_REGS_QTY * 4)
        };
    end


    return addr_map;
endfunction : get_addr_map

addr_map_t periph_addr_map = get_addr_map();

`ifndef SYNTHESIS
initial begin
    $display("PERIPHERY SLAVES ADDR MAP:",);
    for (int i = 0; i < SLAVES_QTY-1; i++) begin
        $display("N: %1d | Slave %1d | Start addr: %8h | End addr: %8h", i, periph_addr_map[i].idx, 
            periph_addr_map[i].start_addr, periph_addr_map[i].end_addr);
    end
end
`endif


  axil2apb #(
    .C_AXI_ADDR_WIDTH        (AXI_LITE_AW),
    .C_AXI_DATA_WIDTH        (AXI_LITE_DW),
    .OPT_OUTGOING_SKIDBUFFER  (0)
  ) i_axi_to_apb (
    .S_AXI_ACLK       (clk_i),
    .S_AXI_ARESETN    (rst_ni),

    .S_AXI_AWVALID  (axil_slave.aw_valid),
    .S_AXI_AWREADY  (axil_slave.aw_ready),
    .S_AXI_AWADDR   (axil_slave.aw_addr),
    .S_AXI_AWPROT   (axil_slave.aw_prot),
    .S_AXI_WVALID   (axil_slave.w_valid),
    .S_AXI_WREADY   (axil_slave.w_ready),
    .S_AXI_WDATA    (axil_slave.w_data),
    .S_AXI_WSTRB    (axil_slave.w_strb),
    .S_AXI_BVALID   (axil_slave.b_valid),
    .S_AXI_BREADY   (axil_slave.b_ready),
    .S_AXI_BRESP    (axil_slave.b_resp),
    .S_AXI_ARVALID  (axil_slave.ar_valid),
    .S_AXI_ARREADY  (axil_slave.ar_ready),
    .S_AXI_ARADDR   (axil_slave.ar_addr),
    .S_AXI_ARPROT   (axil_slave.ar_prot),
    .S_AXI_RVALID   (axil_slave.r_valid),
    .S_AXI_RREADY   (axil_slave.r_ready),
    .S_AXI_RDATA    (axil_slave.r_data),
    .S_AXI_RRESP    (axil_slave.r_resp),

    .M_APB_PADDR      (paddr),
    .M_APB_PPROT      (pprot),
    .M_APB_PSEL       (psel),
    .M_APB_PENABLE    (penable),
    .M_APB_PWRITE     (pwrite),
    .M_APB_PWDATA     (pwdata),
    .M_APB_PWSTRB     (pstrb),
    .M_APB_PREADY     (pready),
    .M_APB_PRDATA     (prdata),
    .M_APB_PSLVERR    (pslverr)
    
  );


  assign s_apb_if.paddr   = paddr;
  assign s_apb_if.psel    = psel;
  assign s_apb_if.penable = penable;
  assign s_apb_if.pwrite  = pwrite;
  assign s_apb_if.pwdata  = pwdata;
  assign s_apb_if.pstrb   = pstrb;
  assign pready           = s_apb_if.pready;
  assign prdata           = s_apb_if.prdata;
  assign pslverr          = s_apb_if.pslverr;

  periphery #(
    .APB_AW       (APB_AW),
    .APB_DW       (APB_DW),
    .PERIPH_BA    (PERIPH_BA),
    .EF_TCC32_QTY (EF_TCC32_QTY),
    .RTC_QTY      (RTC_QTY)
  ) dut_periphery (
    .pclk             (pclk),
    .prst_n           (prst_n),
    .s_apb            (s_apb_if.Slave),
    .ef_tcc32_ext_clk (ef_tcc32_ext_clk),
    .ef_tcc32_irq     (ef_tcc32_irq),
    .ef_tcc32_pwm     (ef_tcc32_pwm),
    .rtc_irq          (rtc_irq)
  );

  initial begin : parameter_checks
    assert (AXI_LITE_AW == APB_AW) else $error("AXI and APB address widths must match");
    assert (AXI_LITE_DW == APB_DW) else $error("AXI and APB data widths must match");
  end

endmodule