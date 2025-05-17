import tb_env_pkg::*;
task axi_lite_write(input logic [31:0] address, input logic [31:0] data);
    begin
        @(posedge pclk);
        AWVALID = 1;
        AWADDR = address;
        WVALID = 1;
        WDATA = data;
        WSTRB = '1;
        
        fork
            begin
                
                wait(AWREADY);
                // $display("awredt %d",AWREADY);
                // if(AWREADY) begin
                    @(posedge pclk);
                    AWVALID = 0;
                // end
            end
            begin
                wait(WREADY);
                // if(WREADY) begin
                    @(posedge pclk);
                    WVALID = 0;
                // end
            end
        join
        
        BREADY = 1;
        wait(BVALID);
        @(posedge pclk);
        BREADY = 0;
    end
endtask

task axi_lite_read(input logic [31:0] address, output logic [31:0] data);
    begin
        @(posedge pclk);
        ARVALID = 1;
        ARADDR = address;
        
        wait(ARREADY);
        @(posedge pclk);
        ARVALID = 0;
        
        RREADY = 1;
        wait(RVALID);
        data = RDATA;
        @(posedge pclk);
        RREADY = 0;
    end
endtask