# Icarus Verilog Makefile
# Change SOURCES, TESTBENCH, TOP_LEVEL_MODULE, and TOP_EXECUTABLE to match project

# Should include all the source files
SOURCES ?= eth_mac_core.sv eth_mac_pkg.sv tx_fifo.sv tx_control.sv crc_generator.sv rx_fifo.sv rx_control.sv crc_checker.sv rgmii_control.sv config_stats.sv mdio_master.sv clock_gen.sv

# Should include the testbench file
TESTBENCH ?= eth_mac_core_tb.sv

# Name of the top level module
TOP_LEVEL_MODULE ?= eth_mac_core_tb

# Name of the top level executable (.out extension automatically appended)
TOP_EXECUTABLE ?= eth_mac_core

# Default target
all: $(TOP_EXECUTABLE)

# Compilation command
$(TOP_EXECUTABLE): $(SOURCES) $(TESTBENCH)
	iverilog -g2012 -o $(TOP_EXECUTABLE).out -s $(TOP_LEVEL_MODULE) $(TESTBENCH) $(SOURCES)

# Simulation command
sim: $(TOP_EXECUTABLE)
	vvp ./$(TOP_EXECUTABLE).out

# Clean up all .out and .vcd files
clean:
	rm -f *.out
	rm -f *.vcd

# Phony targets
.PHONY: all clean