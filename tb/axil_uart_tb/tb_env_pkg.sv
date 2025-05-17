package tb_env_pkg;
 
// periphery instance params
localparam APB_AW       = 32;
localparam APB_DW       = 32;
localparam PERIPH_BA    = 'h0;
localparam EF_TCC32_QTY = 1;
localparam RTC_QTY      = 1;
localparam UART_QTY     = 1; 

// periphery address map
// NOTE: basically copy-pasted from periphery modules themself,
// so may be better to move to other package, which will be
// imported both in module and test definitions
localparam EF_TCC32_IDX = 0                           ;
localparam RTC_IDX      = EF_TCC32_IDX  + EF_TCC32_QTY;
localparam UART_IDX     = RTC_IDX       + RTC_QTY     ; 
localparam SLAVES_QTY   = UART_IDX      + UART_QTY    ;

// slave address map rule
typedef struct packed {
    int unsigned        idx;
    logic [APB_AW-1:0]  start_addr;
    logic [APB_AW-1:0]  end_addr;
} rule_t;

typedef logic [APB_AW - 1:0] addr_t;
typedef rule_t [SLAVES_QTY - 1:0] addr_map_t;

function addr_map_t get_addr_map();
    addr_map_t addr_map;

    for (int i = 0; i < EF_TCC32_QTY; i++) begin
        addr_map[i] = rule_t'{
            idx:        unsigned'(i),
            start_addr: PERIPH_BA + ( i    * EF_TCC32_REGS_QTY * 4),
            end_addr:   PERIPH_BA + ((i+1) * EF_TCC32_REGS_QTY * 4)
        };
    end

    for (int i = EF_TCC32_QTY; i < (EF_TCC32_QTY + RTC_QTY); i++) begin
        addr_map[i] = rule_t'{
            idx:        unsigned'(i),
            start_addr: PERIPH_BA + ( i    * RTC_REGS_QTY * 4),
            end_addr:   PERIPH_BA + ((i+1) * RTC_REGS_QTY * 4)
        };
    end

    for (int i = EF_TCC32_QTY + RTC_QTY; i < SLAVES_QTY; i++) begin
        addr_map[i] = rule_t'{
            idx:        unsigned'(i),
            start_addr: PERIPH_BA + ( i    * UART_REGS_QTY * 4),
            end_addr:   PERIPH_BA + ((i+1) * UART_REGS_QTY * 4)
        };
    end

    return addr_map;
endfunction : get_addr_map

addr_map_t periph_addr_map = get_addr_map();

// ef_tcc32 regs map
localparam EF_TCC32_BASE_ADDR              = 0;
localparam EF_TCC32_TIMER_REG_ADDR         = 0*4    ; // r/o
localparam EF_TCC32_PERIOD_REG_ADDR        = 1*4    ; // r/w
localparam EF_TCC32_COUNTER_REG_ADDR       = 2*4    ; // r/o
localparam EF_TCC32_COUNTER_MATCH_REG_ADDR = 3*4    ; // r/w
localparam EF_TCC32_CONTROL_REG_ADDR       = 4*4    ; // r/w
localparam EF_TCC32_PWM_COMP_VAL_REG_ADDR  = 5*4    ; // r/w
localparam EF_TCC32_RIS_REG_ADDR           = 960*4  ; // w1c | irq flags, not masked
localparam EF_TCC32_IM_REG_ADDR            = 961*4  ; // r/w | irq flags mask
localparam EF_TCC32_MIS_REG_ADDR           = 962*4  ; // r/o | irq flags, masked
localparam EF_TCC32_REGS_QTY               = 1024   ; // considers reserved regs too

// ef_tcc32 regs' bits masks
localparam  CTRL_EN                     = 1,
            CTRL_TMR_EN                 = 2,
            CTRL_PWM_EN                 = 4,
            CTRL_CP_EN                  = 8,
            CTRL_COUNT_UP               = 32'h10000,
            CTRL_MODE_ONESHOT           = 32'h20000,
            CTRL_CLKSRC_EXT             = 32'h900,
            CTRL_CLKSRC_DIV1            = 32'h800,
            CTRL_CLKSRC_DIV2            = 32'h000,
            CTRL_CLKSRC_DIV4            = 32'h100,
            CTRL_CLKSRC_DIV256          = 32'h70,
            CTRL_CPEVENT_PE             = 32'h1_00_0000,
            CTRL_CPEVENT_NE             = 32'h2_00_0000,
            CTRL_CPEVENT_BE             = 32'h3_00_0000;
                
localparam  INT_TO_FLAG                 = 1,
            INT_MATCH_FLAG              = 4,
            INT_CP_FLAG                 = 2;


// rtc regs map
localparam RTC_BASE_ADDR         = EF_TCC32_BASE_ADDR + (EF_TCC32_QTY * EF_TCC32_REGS_QTY * 4);
localparam RTC_INIT_DATE_ADDR    = 0*4              ; // r/w
localparam RTC_DATE_ADDR         = 1*4              ; // r/o
localparam RTC_INIT_CLOCK_ADDR   = 2*4              ; // r/w
localparam RTC_CLOCK_ADDR        = 3*4              ; // r/o
localparam RTC_INIT_SEC_CNT_ADDR = 4*4              ; // r/w
localparam RTC_ALARM_DATE_ADDR   = 5*4              ; // r/w
localparam RTC_ALARM_CLOCK_ADDR  = 6*4              ; // r/w
localparam RTC_TIMER_CFG_ADDR    = 7*4              ; // r/w
localparam RTC_TIMER_VAL_ADDR    = 8*4              ; // r/o
localparam RTC_CALIBRE_ADDR      = 9*4              ; // r/w
localparam RTC_EVENT_FLAG_ADDR   = 10*4             ; // w1c
localparam RTC_UPDATE_ADDR       = 11*4             ; // w1u (write 1 update)
localparam RTC_APPLIED_ADDR      = 12*4             ; // r/o
localparam RTC_REGS_QTY          = 16               ; // considers reserved regs too


localparam UART_BASE_ADDR       = RTC_BASE_ADDR + (RTC_QTY * RTC_REGS_QTY * 4);
localparam UART_REGS_QTY        = 8;  // Количество регистров UART

localparam UART_RBR_THR_DLL_ADDR = 0;  // Receiver Buffer/Transmitter Holding/Divisor Latch LSB
localparam UART_IER_DLM_ADDR     = 1;  // Interrupt Enable/Divisor Latch MSB
localparam UART_IIR_FCR_ADDR     = 2;  // Interrupt Identification/FIFO Control
localparam UART_LCR_ADDR         = 3;  // Line Control
localparam UART_MCR_ADDR         = 4;  // Modem Control
localparam UART_LSR_ADDR         = 5;  // Line Status
localparam UART_MSR_ADDR         = 6;  // Modem Status
localparam UART_SCR_ADDR         = 7;  // Scratch

localparam LCR_WLS0              = 0;    // Word Length Select bit 0
localparam LCR_WLS1              = 1;    // Word Length Select bit 1
localparam LCR_STB               = 2;    // Stop Bits
localparam LCR_PEN               = 3;    // Parity Enable
localparam LCR_EPS               = 4;    // Even Parity Select
localparam LCR_SP                = 5;    // Stick Parity
localparam LCR_BC                = 6;    // Break Control
localparam LCR_DLAB              = 7;    // Divisor Latch Access Bit

localparam LSR_DR                = 0;    // Data Ready
localparam LSR_OE                = 1;    // Overrun Error
localparam LSR_PE                = 2;    // Parity Error
localparam LSR_FE                = 3;    // Framing Error
localparam LSR_BI                = 4;    // Break Interrupt
localparam LSR_THRE              = 5;    // Transmitter Holding Register Empty
localparam LSR_TEMT              = 6;    // Transmitter Empty
localparam LSR_RXFE              = 7;    // Error in RCVR FIFO

localparam IER_RDA               = 0;    // Received Data Available interrupt
localparam IER_THRE              = 1;    // Transmitter Holding Register Empty interrupt
localparam IER_RLS               = 2;    // Receiver Line Status interrupt
localparam IER_MS                = 3;    // Modem Status interrupt

localparam IIR_IP                = 0;    // Interrupt Pending (active low)
localparam IIR_IID0              = 1;    // Interrupt ID bit 0
localparam IIR_IID1              = 2;    // Interrupt ID bit 1
localparam IIR_IID2              = 3;    // Interrupt ID bit 2
localparam IIR_FIFO_EN           = 3;    // FIFOs Enabled (bits 3-6)

localparam UART_INT_NONE         = 3'b000;
localparam UART_INT_RLS          = 3'b011; // Receiver Line Status
localparam UART_INT_RDA          = 3'b010; // Received Data Available
localparam UART_INT_CTI          = 3'b110; // Character Timeout Indicator
localparam UART_INT_THRE         = 3'b001; // THRE Interrupt
localparam UART_INT_MODEM        = 3'b000; // Modem Status Interrupt


logic pclk;
logic prst_n;
logic ef_tcc32_ext_clk;
logic ef_tcc32_irq;
logic ef_tcc32_pwm;
logic rtc_irq;
logic uart_irq;                   
logic uart_rx;                    
logic uart_tx;                    

int err_cnt;


localparam PSTRB_W = APB_DW/8;

logic [31:0] AWADDR;   // Write Address
logic [2:0]  AWPROT;   // Write Protection type
logic        AWVALID;  // Write Address Valid
logic        AWREADY;  // Write Address Ready
logic [31:0] WDATA;    // Write Data
logic [3:0]  WSTRB;    // Write Strobes
logic        WVALID;
logic        WREADY;   // Write Ready
logic [1:0]  BRESP;    // Write Response
logic        BVALID;   // Write Response Valid
logic        BREADY;   // Response Ready
logic [31:0] ARADDR;   // Read Address
logic [2:0]  ARPROT;   // Read Protection type
logic        ARVALID;  // Read Address Valid
logic        ARREADY;  // Read Address Ready
logic [31:0] RDATA;    // Read Data
logic [1:0]  RRESP;    // Read Response
logic        RVALID;   // Read Valid
logic        RREADY;   // Read Ready
    

endpackage : tb_env_pkg