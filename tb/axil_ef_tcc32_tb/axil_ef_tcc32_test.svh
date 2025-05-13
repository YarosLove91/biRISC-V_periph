task tmr_wait_to();
logic [31:0] ris;
    begin
        ris = 0;
        while (ris == 0) begin
            axi_lite_read(EF_TCC32_RIS_REG_ADDR, ris);
            repeat (1) @ (posedge pclk);
        end 
    end
endtask

task axil_ef_tcc32_test;

logic [31:0] write_data;

begin
    //------------------Test case 1------------------
    $display(">>>> Start test case 1 | time: %1d", $time);
    // period = 20
    write_data = 'd20;
    axi_lite_write(EF_TCC32_PERIOD_REG_ADDR, write_data);

    // Clear all flags before enabling the Timer
    write_data = (INT_TO_FLAG | INT_MATCH_FLAG | INT_CP_FLAG);
    axi_lite_write(EF_TCC32_RIS_REG_ADDR, write_data);

    // Down Counter, One Shot, Timer is Enabled and IP is enabled
    write_data = (CTRL_EN | CTRL_TMR_EN | CTRL_MODE_ONESHOT);
    axi_lite_write(EF_TCC32_CONTROL_REG_ADDR, write_data);

    $display("Wait irq | time: %1d", $time);
    tmr_wait_to();
    $display("Test 1: Passed");

    //------------------Test case 2------------------
    $display(">>>> Start test case 2 | time: %1d", $time);
    // Disable the timer before reconfiguring it.
    write_data = 32'h0;
    axi_lite_write(EF_TCC32_CONTROL_REG_ADDR, write_data);

    // Period = 20
    write_data = 32'd20;
    axi_lite_write(EF_TCC32_PERIOD_REG_ADDR, write_data);

    // Clear all flags before enabling the Timer
    write_data = 32'h7;
    axi_lite_write(EF_TCC32_RIS_REG_ADDR, write_data);

    // Down Counter, Periodic, Timer is Enabled and IP is enabled
    write_data = 32'h3;
    axi_lite_write(EF_TCC32_CONTROL_REG_ADDR, write_data);
    repeat(3) tmr_wait_to();
    $display("Test 2: Passed");

    //------------------Test case 3------------------
    $display(">>>> Start test case 3 | time: %1d", $time);
    // Disable the timer before reconfiguring it.
    write_data = 32'h0;
    axi_lite_write(EF_TCC32_CONTROL_REG_ADDR, write_data);

    // Period = 20
    write_data = 32'd20;
    axi_lite_write(EF_TCC32_PERIOD_REG_ADDR, write_data);

    // Clear all flags before enabling the Timer (write to ICR)
    write_data = 32'h7;
    axi_lite_write(EF_TCC32_RIS_REG_ADDR, write_data);

    // Enable TO IRQ by writing to the IM Register
    write_data = 32'h1;
    axi_lite_write(EF_TCC32_IM_REG_ADDR, write_data);

    // Down Counter, Periodic, Timer is Enabled and IP is enabled
    write_data = 32'h3;
    axi_lite_write(EF_TCC32_CONTROL_REG_ADDR, write_data);

    // Wait for the irq to fire
    @(posedge ef_tcc32_irq);

    // Clear all the flags
    write_data = 32'h7;
    axi_lite_write(EF_TCC32_RIS_REG_ADDR, write_data);

    $display("Test 3: Passed");
end

endtask : axil_ef_tcc32_test