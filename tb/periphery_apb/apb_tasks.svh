import tb_env_pkg::*;

task apb_write(input logic [31:0] address, input logic [31:0] data);
    begin
        @(posedge pclk);
        PSEL = 1;
        PWRITE = 1;
        PWDATA = data;
        PENABLE = 0;
        PADDR = address;
        PSTRB = '1;
        @(posedge pclk);
        PENABLE = 1;
        @(posedge pclk);
        PSEL = 0;
        PWRITE = 0;
        PENABLE = 0;
    end
endtask
        
task apb_read(input logic [31:0] address, output logic [31:0] data);
    begin
        @(posedge pclk);
        PSEL = 1;
        PWRITE = 0;
        PENABLE = 0;
        PADDR = address;
        PSTRB = '1;
        @(posedge pclk);
        PENABLE = 1;
        //@(posedge PREADY);
        wait(PREADY == 1)
        @(posedge pclk) data = PRDATA;
        PSEL = 0;
        PWRITE = 0;
        PENABLE = 0;
    end
endtask

// task apb_write (input logic [31:0] address, input logic [31:0] data);
//     begin
//         @(posedge pclk);
//         psel = 1;
//         pwrite = 1;
//         pwdata = data;
//         penable = 0;
//         paddr = address;
//         pstrb = '1;
//         @(posedge pclk);
//         penable = 1;
//         @(posedge pclk);
//         psel = 0;
//         pwrite = 0;
//         penable = 0;
//     end
// endtask
        
// task apb_read(input logic [31:0] address, output logic [31:0] data);
//     begin
//         @(posedge pclk);
//         psel = 1;
//         pwrite = 0;
//         penable = 0;
//         paddr = address;
//         pstrb = '1;
//         @(posedge pclk);
//         penable = 1;
//         //@(posedge PREADY);
//         wait(PREADY == 1)
//         @(posedge pclk) data = PRDATA;
//         psel = 0;
//         pwrite = 0;
//         penable = 0;
//     end
// endtask 