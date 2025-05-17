`timescale 1ns/1ps
module tb;

import tb_env_pkg::*;

// includes (included here cause tasks use signals declared in this file)
`include "axil_tasks.svh"

//--------testcases' tasks includes---------
`include "axil_uart_test.svh"

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
    axi.aw_addr   = AWADDR;
    axi.aw_prot   = AWPROT;
    axi.aw_valid  = AWVALID;
    AWREADY   = axi.aw_ready;
    
    // Write Data Channel
    axi.w_data    = WDATA;
    axi.w_strb    = WSTRB;
    axi.w_valid   = WVALID;
    WREADY    = axi.w_ready;
    
    // Write Response Channel
    BRESP     = axi.b_resp;
    BVALID    = axi.b_valid;
    axi.b_ready   = BREADY;
    
    // Read Address Channel
    axi.ar_addr   = ARADDR;
    axi.ar_prot   = ARPROT;
    axi.ar_valid  = ARVALID;
    ARREADY   = axi.ar_ready;
    
    // Read Data Channel
    RDATA     = axi.r_data;
    RRESP     = axi.r_resp;
    RVALID    = axi.r_valid;
    axi.r_ready   = RREADY;
end


    

// DUT - AXI Lite Periphery Top
axil_periphery_wrap #(
    .AXI_LITE_AW             (AXI_LITE_AW),
    .AXI_LITE_DW             (AXI_LITE_DW),
    .APB_AW                  (APB_AW),
    .APB_DW                  (APB_DW),
    .PERIPH_BA               (PERIPH_BA),
    .EF_TCC32_QTY            (EF_TCC32_QTY),
    .RTC_QTY                 (RTC_QTY)
 
) dut (
    .clk_i              (pclk),
    .rst_ni             (prst_n),
    .axil_slave         (axi.Slave),
    .ef_tcc32_ext_clk   (ef_tcc32_ext_clk),
    .ef_tcc32_irq       (ef_tcc32_irq),
    .ef_tcc32_pwm       (ef_tcc32_pwm),
    .rtc_irq            (rtc_irq),
    .uart_rx   (uart_tx),      
    .uart_tx   (uart_tx),      
    .uart_interrupt(uart_interrupt) 
);
// clock generation
initial begin
    pclk = 0;
    forever begin
        #1 pclk = ~pclk;
    end
end

// reset generation
initial begin
    prst_n <= 1;
    repeat (2) @ (posedge pclk);
    prst_n <= 0;
    repeat (2) @ (posedge pclk);
    prst_n <= 1;
end


// tests start process
initial begin
    err_cnt = 0;
    repeat (20) @ (posedge pclk);
    axil_uart_test();
    $finish;
end

// dump the signals
initial begin
    $dumpfile("periphery_test.vcd");
    $dumpvars(0, MUV);
end

endmodule : tb