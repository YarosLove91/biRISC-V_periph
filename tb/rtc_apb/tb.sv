module tb(
    input  logic        pclk         ,
    input  logic        prst_n       ,
    input  logic [31:0] s_apb_paddr  ,
    input  logic        s_apb_psel   ,
    input  logic        s_apb_penable,
    input  logic        s_apb_pwrite ,
    input  logic [31:0] s_apb_pwdata ,
    input  logic [ 3:0] s_apb_pstrb  ,
    output logic        s_apb_pready ,
    output logic [31:0] s_apb_prdata ,
    output logic        s_apb_pslverr,
    output logic        irq
);

import tb_env_pkg::*;

// apb interface
APB #(.ADDR_WIDTH(APB_AW), .DATA_WIDTH(APB_DW)) s_apb();

// modules' instances
periphery #(
    .APB_AW      (APB_AW      ),
    .APB_DW      (APB_DW      ),
    .PERIPH_BA   (PERIPH_BA   ),
    .EF_TCC32_QTY(EF_TCC32_QTY),
    .RTC_QTY     (RTC_QTY     )
) dut_periphery (
    .pclk            (pclk            ),
    .prst_n          (prst_n          ),
    .s_apb           (s_apb.Slave  ),
    .ef_tcc32_ext_clk(ef_tcc32_ext_clk),
    .ef_tcc32_irq    (ef_tcc32_irq    ),
    .ef_tcc32_pwm    (ef_tcc32_pwm    ),
    .rtc_irq         (rtc_irq         )
);

always_comb begin
    s_apb.paddr     = s_apb_paddr;
    s_apb.psel      = s_apb_psel;
    s_apb.penable   = s_apb_penable;
    s_apb.pwrite    = s_apb_pwrite;
    s_apb.pwdata    = s_apb_pwdata;
    s_apb.pstrb     = s_apb_pstrb;
    s_apb_pready    = s_apb.pready;
    s_apb_prdata    = s_apb.prdata;
    s_apb_pslverr   = s_apb.pslverr;
end

endmodule