module tb;

import tb_env_pkg::*;

// includes (included here cause tasks use signals declared in this file)
`include "apb_tasks.svh"

//--------testcases' tasks includes---------
`ifdef REGS_ACCESS_TEST
    `include "regs_access_test.svh"
`elsif EF_TCC32_TEST
    `include "ef_tcc32_test.svh"
`endif

// apb interface
APB #(.ADDR_WIDTH(APB_AW), .DATA_WIDTH(APB_DW)) s_apb_if();

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
    .s_apb           (s_apb_if.Slave  ),
    .ef_tcc32_ext_clk(ef_tcc32_ext_clk),
    .ef_tcc32_irq    (ef_tcc32_irq    ),
    .ef_tcc32_pwm    (ef_tcc32_pwm    ),
    .rtc_irq         (rtc_irq         )
);

always_comb begin
    // master drives
    s_apb_if.paddr      = PADDR;
    s_apb_if.psel       = PSEL;
    s_apb_if.penable    = PENABLE;
    s_apb_if.pwrite     = PWRITE;
    s_apb_if.pwdata     = PWDATA;
    s_apb_if.pstrb      = PSTRB;

    // slave drives
    PREADY = s_apb_if.pready;
    PRDATA = s_apb_if.prdata;
end

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

    `ifdef REGS_ACCESS_TEST
        regs_access_test();
    `elsif EF_TCC32_TEST
        ef_tcc32_test();
    `else
        err_cnt++;

        $display(">>>> There is no such test!");
        $display("Available tests:");
        for (int i = 0; i < available_tests.size(); i++) begin
            $display("%s", available_tests[i]);
        end
        $display("\n");
    `endif

    $display(">>>>TEST END");
    if (err_cnt)
        $display(">>>>FAIL\n");
    else
        $display(">>>>SUCCESS\n");
    $finish;
end

// dump the signals
initial begin
    $dumpfile("vcd/periphery_apb.vcd");
    $dumpvars(0, MUV);
end

endmodule : tb