# @file  Makefile
# @brief The project source files
# @note  This file can be edited by the user to adapt it to its project

export SYN_DIR = $(shell pwd)
export PATH := /comelec/softs/bin:${PATH}

# source files directory
SRC_DIR = $(SYN_DIR)/../src

# source files for synthesis
# add the path to source files ex:MCE.sv
# separated with spaces
SOURCE_FILES =	MCE.sv MED.sv MEDIAN.sv

# Top module for synthesis
# add the top modle for synthesis ex:MCE
export TOP_MODULE  ?= MEDIAN

export HDL_FILES = $(patsubst %,$(SRC_DIR)/%,$(SOURCE_FILES))

# End of SOURCE_FILES
.PHONY : all syn clean pr show

all:
	@echo "make syn  : launch synthesis"
	@echo "make show : show elaborated generic schematic"
	@echo "make pr   : launch place and route phase for FPGA target"
	@echo "make clean: clean the current directory"


# Partie 1 : synthèse
syn:$(TOP_MODULE)_syn.json

$(TOP_MODULE)_prep.json $(TOP_MODULE)_syn.json: $(HDL_FILES)
ifeq ($(TOP_MODULE),xxxx)
	@echo "You have to define the TOP MODULE !!!"
else
ifeq ($(SOURCE_FILES),xxxx.sv)
	@echo "You have to define the SOURCE FILES !!!"
else
	@echo "==> TOP LEVEL MODULE  : $(TOP_MODULE)"
	@echo "==> FILES : $(SOURCE_FILES)"
	yosys -c synthesis.tcl -L $(TOP_MODULE)_syn.log
endif
endif

# Partie 2 : affichage du schéma "RTL"
show: $(TOP_MODULE)_prep.svg
	inkview $<

%.svg: %.json
	netlistsvg $< -o $@

# Partie 3: Placement / Routage
# Quelle marque/type de fpga
# ATTENTION: a n'utiliser que pour la dernière phase (MEDIAN)
DEVICE = hx8k
PACKAGE = cb132
# Ou sont les entrées/sorties du chip
PIN_DEF = alchitrycu.pcf
# Quelle est la fréquence de fonctionnement désirée (MHz)
FREQ?=50

pr:$(TOP_MODULE)_pr.v

$(TOP_MODULE)_pr.json:$(TOP_MODULE)_syn.json
ifeq ($(TOP_MODULE),MEDIAN)
	nextpnr-ice40 --quiet  --top $(TOP_MODULE) --$(DEVICE) --package $(PACKAGE) --freq $(FREQ) --json $< --write $@ --pcf $(PIN_DEF) --sdf $(TOP_MODULE)_pr.sdf --sdf-cvc --detailed-timing-report --log $(TOP_MODULE)_pr.log
else
	@echo "The Place and Route phase is only for MEDIAN module"
endif

$(TOP_MODULE)_pr.v: $(TOP_MODULE)_pr.json
	yosys -p "read_json $< ; rename top $(TOP_MODULE); write_verilog $@" -l $(TOP_MODULE)_conv_pr.log

pr_view:$(TOP_MODULE)_pr.json
	nextpnr-ice40 --gui --$(DEVICE) --package $(PACKAGE) --freq $(FREQ) --json $<


clean:
	@rm -fr *.svg
	@rm -fr *.log
	@rm -fr *.v
	@rm -fr *.json
	@rm -fr *.sdf
