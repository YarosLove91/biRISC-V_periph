# Periphery for birisc-v project

Originally intended to connect this periphery wrapper to birisc-v processor. But it is self-sufficient so can be used in other applications.

## Structure

Sources of rtl are contained in /src folder.
There are submodules:

apb_pulp        - our fork of apb modules and interfaces from pulp_platform
axi             - submodule of axi modules and interfaces from pulp_platform
common_cells    - submodule of common small modules from pulp_platform
EF_TCC32        - submodule of ef_tcc32 timer with pwm channels etc.
rtc             - submodule of our fork of rtc timer
wb2axip         - submodule of ZipCPU repo with axi(l) modules

And periphery wrappers itself:

periphery.sv              - apb wrapper of ef_tcc32 and rtc timers; easily modifiable for adding new periphery and increasing quantities of currently added periphery.
axil_periphery_wrapper.sv - axil wrapper for apb periphery (basically axil to apb bridge from wb2axip + periphery.sv)

Tests are contained in /tb folder. Folder /common is for files needed by all tests, /file_lists contains file_lists for every test.
Other folders in /tb are for separate test each.

## Tests
periphery_apb - SystemVerilog based testbench for periphery.sv apb wrapper. Contains 2 tests: simple registers access demonstration and ef_tcc32 test, which basically does the same as test for EF_TCC32 in it's repo but adapted for apb periphery wrapper.
rtc_apb - C++ based testbench, same as test in rtc repo but adapted for apb periphery wrapper.
rtc_axi - C++ based testbench, same as test in rtc repo but adapted for axil periphery wrapper.