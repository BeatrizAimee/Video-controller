# @file  Makefile
# @note  This Makefile is intended to be launched via a master Makefile
SHELL := /bin/bash
export SYN_DIR = $(shell pwd)
export PATH := /comelec/softs/bin:${PATH}

# source files directory
SRC_DIR ?= $(SYN_DIR)/../src

# source files for synthesis
# add the path to source files ex:MCE.sv
# separated with spaces
SOURCE_FILES ?= XXX.v

# Top module for synthesis
# add the top modle for synthesis ex:MCE
export TOP_MODULE  ?= XXX

# The exact list of files with their exact path
export HDL_FILES ?= $(patsubst %,$(SRC_DIR)/%,$(SOURCE_FILES))

# End of SOURCE_FILES
.PHONY : all syn clean pr show

# For colored messages
cyan = /bin/echo -e "\n\x1b[36m\#\# $1\x1b[0m"

# The list of phony targets
help:
	@echo "make syn  : launch synthesis"
	@echo "make show : show elaborated generic schematic"
	@echo "make pr   : launch place and route phase for FPGA target"
	@echo "make clean: clean the current directory"

# Part 1 : Yosys synthesis
syn:$(TOP_MODULE)_syn.json

# Run quietly, print a sumary of the cell used
$(TOP_MODULE)_prep.json $(TOP_MODULE)_syn.json: $(HDL_FILES)
	@$(call cyan,"Synthesis phase")
	@yosys -m slang -q ../synthesis.tcl -L $(TOP_MODULE)_syn.log
	@$(call cyan,"Synthesis stats")
	@awk -f ../stats.awk $(TOP_MODULE)_syn.log

# Part 2 : Place and Route
# What is the kind of FPGA
DEVICE = hx8k
PACKAGE = ct256
# Add definition of positions of dummy I/Os
PIN_DEF = ../avalon_bram_syn_src/$(TOP_MODULE).pcf
# Target frequency (MHz)
FREQ?=50

pr:$(TOP_MODULE)_pr.v

$(TOP_MODULE)_pr.v: $(TOP_MODULE)_pr.json
	@yosys -q -p "read_json $< ; rename top $(TOP_MODULE); write_verilog $@" -l $(TOP_MODULE)_conv_pr.log

# Place an route for max frequency evaluation
$(TOP_MODULE)_pr.json: $(TOP_MODULE)_syn.json $(QSF)
	@$(call cyan,"Place and route phase")
	@nextpnr-ice40 --quiet  --top $(TOP_MODULE) --$(DEVICE) --package $(PACKAGE) --freq $(FREQ) --json $< --write $@\
		--pcf $(PIN_DEF) --sdf $(TOP_MODULE)_pr.sdf --sdf-cvc --detailed-timing-report --log $(TOP_MODULE)_pr.log
	@echo "============="; awk '/MHz/ {nb=nb+1; if(nb==2) {print;printf("\n")}}' $(TOP_MODULE)_pr.log; echo "============="


# Part 2 :  Creates a svg representation of the design
show: show_$(TOP_MODULE)
show_%: %_syn.svg
	inkview $<

%.svg: %.json
	netlistsvg $< -o $@

view_pr_%: %_pr.json
	@nextpnr-ice40 --gui --$(DEVICE) --package $(PACKAGE) --json $<

clean:
	@rm -fr *.svg
	@rm -fr *.log
	@rm -fr *.v
	@rm -fr *.json
	@rm -fr *.sdf
