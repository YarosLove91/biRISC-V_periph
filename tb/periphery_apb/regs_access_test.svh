task regs_access_test();
logic [31:0] addr;
logic [31:0] read_data;
logic [31:0] write_data;
    begin
        read_data = '0;

        // this reg is read-only - let's check that it ignores writing
        $display("EF_TCC32_TIMER_REG_ADDR (r/o):",);
        addr = EF_TCC32_TIMER_REG_ADDR;
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h", addr, read_data);

        addr = EF_TCC32_TIMER_REG_ADDR;
        write_data = '1;
        $display("Write | Addr: %8h | Value: %8h", addr, write_data);
        apb_write(addr, write_data);
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h\n", addr, read_data);

        // this reg is r/w - let's try to write something
        $display("EF_TCC32_PERIOD_REG_ADDR (r/w):",);
        addr = EF_TCC32_PERIOD_REG_ADDR;
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h", addr, read_data);

        addr = EF_TCC32_PERIOD_REG_ADDR;
        write_data = 'hDEADBEEF;
        $display("Write | Addr: %8h | Value: %8h", addr, write_data);
        apb_write(addr, write_data);
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h\n", addr, read_data);

        // now let's try to write into RTC module
        $display("RTC_INIT_SEC_CNT_ADDR (r/w):",);
        addr = RTC_BASE_ADDR + RTC_INIT_SEC_CNT_ADDR;
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h", addr, read_data);

        addr = RTC_BASE_ADDR + RTC_INIT_SEC_CNT_ADDR;
        write_data = 'hDEDABABA;
        $display("Write | Addr: %8h | Value: %8h", addr, write_data);
        apb_write(addr, write_data);
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h\n", addr, read_data);

        // there is also w1u type of reg - it resets after setting to '1' with 1 cycle latency
        $display("RTC_UPDATE_ADDR (w1u):",);
        addr = RTC_BASE_ADDR + RTC_UPDATE_ADDR;
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h", addr, read_data);

        addr = RTC_BASE_ADDR + RTC_UPDATE_ADDR;
        write_data = 'hDEDABABA;
        $display("Write | Addr: %8h | Value: %8h", addr, write_data);
        apb_write(addr, write_data);

        // NOTE: verilator acts strange - registers are written right awa (no 1 clock delay).
        //       therefore this delay is commented for now.
        // repeat(1) @ (posedge pclk);
        // checking with absolute path cause otherwise not sure that we will catch the written value
        $display("Value of update reg: %h", tb.dut_periphery.i_rtc_apb.all_regs.update);

        // checking that now this reg equals zero
        apb_read(addr, read_data);
        $display("Read  | Addr: %8h | Value: %8h", addr, read_data);
    end
endtask : regs_access_test