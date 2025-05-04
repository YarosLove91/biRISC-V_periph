module periphery 
#(
    parameter int   APB_AW          = 32,
                    APB_DW          = 32,
                    PERIPH_BA       = 0, // periphery base address
                    EF_TCC32_QTY    = 1,
                    RTC_QTY         = 1

) (
    // apb slave intf
    input  logic pclk            ,
    input  logic prst_n          ,

    APB.Slave    s_apb           ,
    // block specific inputs
    input  logic ef_tcc32_ext_clk,

    // outputs
    output logic ef_tcc32_irq    ,
    output logic ef_tcc32_pwm    ,
    output logic rtc_irq         
);

localparam EF_TCC32_IDX = 0                           ;
localparam RTC_IDX      = EF_TCC32_IDX  + EF_TCC32_QTY;
localparam SLAVES_QTY   = RTC_IDX       + RTC_QTY     ;

localparam EF_TCC32_REGS_QTY = 1024; // 1024 - 963 = 61 reserved | 0x0000 - 0x0FFC (if qty == 1)
localparam RTC_REGS_QTY      = 16  ; // 16 - 13 = 3 reserved     | 0x1000 - 0x103C (if qty == 1)

localparam EF_TCC32_BA  = 0;
localparam RTC_BA       = EF_TCC32_QTY * EF_TCC32_REGS_QTY * 4;

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
    int ef_tcc32_idx, rtc_idx;

    for (int rule_idx = 0; rule_idx < EF_TCC32_QTY; rule_idx++) begin
        ef_tcc32_idx = rule_idx;
        addr_map[rule_idx] = rule_t'{
            idx:        unsigned'(rule_idx),
            start_addr: PERIPH_BA + ( ef_tcc32_idx    * EF_TCC32_REGS_QTY * 4),
            end_addr:   PERIPH_BA + ((ef_tcc32_idx+1) * EF_TCC32_REGS_QTY * 4)
        };
    end

    rtc_idx = 0;
    for (int rule_idx = EF_TCC32_QTY; rule_idx < (EF_TCC32_QTY + RTC_QTY); rule_idx++) begin
        addr_map[rule_idx] = rule_t'{
            idx:        unsigned'(rule_idx),
            start_addr: RTC_BA + ( rtc_idx    * RTC_REGS_QTY * 4),
            end_addr:   RTC_BA + ((rtc_idx+1) * RTC_REGS_QTY * 4)
        };
        rtc_idx++;
    end

    return addr_map;
endfunction : get_addr_map

addr_map_t periph_addr_map = get_addr_map();

`ifndef SYNTHESIS
initial begin
    $display("PERIPHERY SLAVES ADDR MAP:",);
    for (int i = 0; i < SLAVES_QTY; i++) begin
        $display("N: %1d | Slave %1d | Start addr: %8h | End addr: %8h", i, periph_addr_map[i].idx, 
            periph_addr_map[i].start_addr, periph_addr_map[i].end_addr);
    end
end
`endif

APB #(.ADDR_WIDTH(APB_AW), .DATA_WIDTH(APB_DW)) s_apb_selected[SLAVES_QTY - 1:0]();

localparam SLV_SEL_W = cf_math_pkg::idx_width(SLAVES_QTY);
logic [SLV_SEL_W - 1:0] periph_slv_sel;
logic                   periph_addr_valid;

addr_decode #(
    .NoIndices(SLAVES_QTY),
    .NoRules  (SLAVES_QTY),
    .addr_t   (addr_t    ),
    .rule_t   (rule_t    )
) i_addr_decode (
    .addr_i          (s_apb.paddr      ),
    .addr_map_i      (periph_addr_map  ),
    .idx_o           (periph_slv_sel   ),
    .dec_valid_o     (periph_addr_valid), // TODO: clarify whether we need to do smth in case of false address
    .dec_error_o     (/*not used*/     ),
    .en_default_idx_i('0               ),
    .default_idx_i   ('0               )
);

apb_demux_intf #(
    .APB_ADDR_WIDTH(APB_AW    ),
    .APB_DATA_WIDTH(APB_DW    ),
    .NoMstPorts    (SLAVES_QTY)
) i_apb_demux_intf (
    .slv     (s_apb          ),
    .mst     (s_apb_selected.Master),
    .select_i(periph_slv_sel       )
);

// TODO: add 'generate' for arbitrary number of instances depending on EF_TCC32_QTY and RTC_QTY
EF_TCC32_apb #(
    .APB_ADDR_W(APB_AW     ),
    .BASE_ADDR (EF_TCC32_BA)
) i_EF_TCC32_apb (
    .ext_clk  (ef_tcc32_ext_clk                  ),
    .PCLK     (pclk                              ),
    .PRESETn  (prst_n                            ),
    .irq      (ef_tcc32_irq                      ),
    .gpio_pwm (ef_tcc32_pwm                      ),
    .apb_slave(s_apb_selected[EF_TCC32_IDX].Slave)
);

rtc_apb #(
    .APB_ADDR_W(APB_AW),
    .BASE_ADDR (RTC_BA)
) i_rtc_apb (
    .pclk  (pclk                         ),
    .prst_n(prst_n                       ),
    .irq   (rtc_irq                      ),
    .s_apb (s_apb_selected[RTC_IDX].Slave)
);



endmodule : periphery