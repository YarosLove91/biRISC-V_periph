+incdir+./src/common_cells/include
+incdir+./src/apb_pulp/include
+incdir+./tb/common
+incdir+./tb/periphery_apb

./src/common_cells/src/cf_math_pkg.sv
./src/common_cells/src/addr_decode_dync.sv
./src/common_cells/src/addr_decode.sv

./src/apb_pulp/src/apb_pkg.sv
./src/apb_pulp/src/apb_regs.sv
./src/apb_pulp/src/apb_intf.sv
./src/apb_pulp/src/apb_demux.sv

./src/rtc/rtl/rtc_date.sv
./src/rtc/rtl/rtc_clock.sv
./src/rtc/rtl/rtc_top.sv
./src/rtc/rtl/bus_wrappers/rtc_apb.sv

./src/EF_TCC32/hdl/rtl/EF_TCC32.v
./src/EF_TCC32/hdl/rtl/bus_wrappers/EF_TCC32_apb.sv
./src/periphery.sv
./tb/common/tb_env_pkg.sv
./tb/periphery_apb/tb.sv
./tb/periphery_apb/apb_tasks.svh
./tb/periphery_apb/regs_access_test.svh