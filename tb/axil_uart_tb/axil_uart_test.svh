task axil_uart_test;
    logic [31:0] write_data;
    logic [31:0] read_data;
    logic [7:0]  test_byte = 8'hA5;
    int          timeout;
    
    begin
        $display(">>>> Start UART test | time: %1d", $time);
        
        //------------------ UART Configuration ------------------
        $display("Configuring UART...");
        
        // 1. Set DLAB=1 to access DLL/DLM
        write_data = (1 << LCR_DLAB); // Set DLAB bit
        axi_lite_write(UART_LCR_ADDR+UART_BASE_ADDR, write_data);
        
        // 2. Set divisor for 115200 baud (assuming 50MHz clock)
        // divisor = 50,000,000 / (16 * 115200) ≈ 27
        write_data = 27; // DLL
        axi_lite_write(UART_RBR_THR_DLL_ADDR+UART_BASE_ADDR, write_data);
        write_data = 0;  // DLM
        axi_lite_write(UART_IER_DLM_ADDR+UART_BASE_ADDR, write_data);
        
        // 3. Set 8N1 format and clear DLAB
        write_data = (3 << LCR_WLS0) | (0 << LCR_STB) | (0 << LCR_PEN); // 8 bits, 1 stop, no parity
        axi_lite_write(UART_LCR_ADDR+UART_BASE_ADDR, write_data);
        
        // 4. Enable FIFOs
        write_data = (1 << 0); // Enable FIFOs
        axi_lite_write(UART_IIR_FCR_ADDR+UART_BASE_ADDR, write_data);
        
        // 5. Enable interrupts (optional)
        write_data = (1 << IER_RDA); // Enable Received Data Available interrupt
        axi_lite_write(UART_IER_DLM_ADDR+UART_BASE_ADDR, write_data);
        
        //------------------ UART Transmission Test ------------------
        $display("Testing UART transmission...");
        
        // 1. Check that transmitter is ready (THRE bit in LSR)
        axi_lite_read(UART_LSR_ADDR+UART_BASE_ADDR, read_data);
        if (!(read_data & (1 << LSR_THRE))) begin
            $error("UART transmitter not ready!");
            err_cnt++;
        end
        
        // 2. Send test byte
        write_data = test_byte;
        axi_lite_write(UART_RBR_THR_DLL_ADDR+UART_BASE_ADDR, write_data);
        
        // 3. Verify transmission completion (TEMT bit in LSR)
        timeout = 1000;
        while (!(read_data & (1 << LSR_TEMT))) begin
            axi_lite_read(UART_LSR_ADDR+UART_BASE_ADDR, read_data);
            timeout--;
            if (timeout == 0) begin
                $error("UART transmission timeout!");
                err_cnt++;
                break;
            end
            repeat (10) @(posedge pclk);
        end
        
        $display("Transmission completed successfully");
        
        //------------------ UART Reception Test ------------------
        $display("Testing UART reception...");
        
        // 1. Wait for received data (DR bit in LSR)
        timeout = 10000;
        axi_lite_read(UART_LSR_ADDR+UART_BASE_ADDR, read_data);
        while (!(read_data & (1 << LSR_DR))) begin
            axi_lite_read(UART_LSR_ADDR+UART_BASE_ADDR, read_data);
            timeout--;
            if (timeout == 0) begin
                $error("UART reception timeout!");
                err_cnt++;
                break;
            end
            repeat (10) @(posedge pclk);
        end
        
        // 2. Read received data
        
        axi_lite_read(UART_RBR_THR_DLL_ADDR+UART_BASE_ADDR, read_data);
        axi_lite_read(UART_RBR_THR_DLL_ADDR+UART_BASE_ADDR, read_data);
        
        
        // 3. Verify received data
        if (read_data[7:0] != test_byte) begin
            $error("Received data mismatch! Expected: %h, Got: %h", test_byte, read_data);
            err_cnt++;
        end else begin
            $display("Reception test passed - Correct byte received: %h", test_byte);
        end
    end  
endtask : axil_uart_test