ifneq ($(words $(CURDIR)),1)
  $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

# Add multithreading

NUM_THREADS := $(shell nproc)

ifeq ($(NUM_THREADS), 0)
    NUM_THREADS := 2
else
    NUM_THREADS := $(shell echo "$$(( $(NUM_THREADS) - 2 ))")
endif

######################################################################
# Set up variables

GENHTML = genhtml

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

###############################################################################
# Variables
###############################################################################

OUTPUT_DIR       ?= tb_output
ENABLE_COVERAGE  ?= 0
TEST_NAME 		 ?= REGS_ACCESS_TEST

VERILATOR_FLAGS ?=
# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe --main
# Generate makefile dependencies (not shown as complicates the Makefile)
#VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += --x-assign 0
# Warn about lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
ifeq ($(ENABLE_COVERAGE),1)
    VERILATOR_FLAGS += --coverage
endif

VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += -j -D
# Run make to compile model, with as many CPUs as are free
VERILATOR_FLAGS += --build -j

VERILATOR_FLAGS += -Wno-fatal
VERILATOR_FLAGS += --timing
VERILATOR_FLAGS += +incdir+../src/common_cells/include
VERILATOR_FLAGS += +incdir+../src/apb_pulp/include
VERILATOR_FLAGS += --top tb

# Run Verilator in debug mode
# VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

VERILATOR_INPUT ?=
# Input files for Verilator
ifeq ($(MAKECMDGOALS), rtc_apb_tb)
    VERILATOR_INPUT = -f tb/file_lists/rtc_apb.f
else ifeq ($(MAKECMDGOALS), rtc_axi_tb)
    VERILATOR_INPUT = -f tb/file_lists/rtc_axi.f
else ifeq ($(MAKECMDGOALS), periphery_apb_tb)
	# add test define
	VERILATOR_FLAGS += +define+$(TEST_NAME)
    VERILATOR_INPUT = -f tb/file_lists/periphery_apb.f
else ifeq ($(MAKECMDGOALS), clean)
else ifneq ($(MAKECMDGOALS), )
    $(error Unknown target: $(MAKECMDGOALS). Use 'make rtc_apb_tb', 'make periphery_apb_tb' or 'make rtc_axi_tb')
else
    $(error ERROR. Use 'make rtc_apb_tb', 'make periphery_apb_tb' or 'make rtc_axi_tb')
endif

######################################################################
# Create annotated source
ifeq ($(ENABLE_COVERAGE),1)
    VERILATOR_COV_FLAGS += --annotate logs/annotated
    # A single coverage hit is considered good enough
    VERILATOR_COV_FLAGS += --annotate-min 1
    # Create LCOV info
    VERILATOR_COV_FLAGS += --write-info logs/coverage.info
    # Input file from Verilator
    VERILATOR_COV_FLAGS += logs/coverage.dat
endif

######################################################################
default: run
rtc_apb_tb:run
periphery_apb_tb:run
rtc_axi_tb: run

run:
	@echo

	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) --version
	$(VERILATOR) --Mdir $(OUTPUT_DIR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

	@echo
	@echo "-- RUN ---------------------"
	@rm -rf logs
	@mkdir -p logs
	$(OUTPUT_DIR)/Vtb

ifeq ($(ENABLE_COVERAGE),1)
	@echo
	@echo "-- COVERAGE ----------------"
	@rm -rf logs/annotated
	$(VERILATOR_COVERAGE) $(VERILATOR_COV_FLAGS)
endif

	@echo
	@echo "-- DONE --------------------"


######################################################################
# Other targets

show-config:
	$(VERILATOR) -V

genhtml:
ifeq ($(ENABLE_COVERAGE),1)
	@echo "-- GENHTML --------------------"
	@echo "-- Note not installed by default, so not in default rule"
	$(GENHTML) logs/coverage.info --output-directory logs/html
else
	@echo "Coverage is disabled. Skipping GENHTML."
endif

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf $(OUTPUT_DIR) logs *.log *.dmp *.vpd core
	-rm -rf *.vcd coverage.dat