+incdir+./src/common_cells/include
+incdir+./src/apb_pulp/include
+incdir+./src/axi/include
+incdir+./tb/common

./src/common_cells/src/cf_math_pkg.sv
./src/common_cells/src/addr_decode_dync.sv
./src/common_cells/src/addr_decode.sv
./src/common_cells/src/rr_arb_tree.sv
./src/common_cells/src/fall_through_register.sv
./src/common_cells/src/onehot_to_bin.sv
./src/common_cells/src/fifo_v3.sv
./src/common_cells/src/lzc.sv

./src/apb_pulp/src/apb_pkg.sv
./src/apb_pulp/src/apb_regs.sv
./src/apb_pulp/src/apb_intf.sv
./src/apb_pulp/src/apb_demux.sv

./src/axi/src/axi_pkg.sv
./src/axi/src/axi_intf.sv
./src/axi/src/axi_lite_to_apb.sv
./src/wb2axip/rtl/axil2apb.v
./src/wb2axip/bench/formal/faxil_slave.v
./src/wb2axip/bench/formal/fapb_master.v
./src/wb2axip/rtl/skidbuffer.v

./src/rtc/rtl/rtc_date.sv
./src/rtc/rtl/rtc_clock.sv
./src/rtc/rtl/rtc_top.sv
./src/rtc/rtl/bus_wrappers/rtc_apb.sv

./src/EF_TCC32/hdl/rtl/EF_TCC32.v
./src/EF_TCC32/hdl/rtl/bus_wrappers/EF_TCC32_apb_pulp.sv
./src/periphery.sv
./src/axil_periphery_wrap.sv

./tb/common/tb_env_pkg.sv

./tb/rtc_axi/tb.sv
./tb/rtc_axi/rtc_axi.cpp
./tb/rtc_axi/main.cpp
