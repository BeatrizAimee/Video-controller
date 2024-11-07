#
SHELL := /bin/bash
.PHONY: clean all simu_batch compile simu_gui info syn

export PATH:=/comelec/softs/bin:$(PATH)

VLOG = vlog
VSIM = vsim

TOPDIR = $(shell pwd)
TB_TOP = testbench_top
tmp = work

OPTVLOG=+acc
OPTSIM=-t ps -msgmode wlf -displaymsgmode both


# Avalon interface sources
AVALONSRCDIR  = $(TOPDIR)/../avalon_if
AVALONSRC     = $(AVALONSRCDIR)/avalon_if.sv
DEP           = $(patsubst $(AVALONSRCDIR)/%.sv,tmp/.%.compiled,${AVALONSRC})

# Avalon testbench sources
AVALONTBSRCDIR  = $(TOPDIR)/avalon_bram_tb_src
AVALONTBSRC     = verbosity_pkg.sv avalon_mm_pkg.sv avalon_utilities_pkg.sv packet.sv altera_avalon_mm_master_bfm.sv tpt_altera_avalon_mm_monitor_assertion.sv testbench_top.sv
DEP          += $(patsubst %.sv,tmp/.%.compiled,${AVALONTBSRC})

# Module sources
SRCDIR    = $(TOPDIR)/avalon_bram
SRC       = $(SRCDIR)/avalon_bram.sv
DEP      += $(patsubst $(SRCDIR)/%.sv,tmp/.%.compiled,${SRC})

# Auxiliary files for synthesis
SYNDIR = $(TOPDIR)/avalon_bram_syn_src
SYNSRC = $(wildcard $(SYNDIR)/*.sv)

# Repertoires et fichiers pour la synthèse
AREA_FILE   = avalon_bram_area.log
TIMING_FILE   = avalon_bram_timing.log


info:
	@echo "Les commandes possibles sont:"
	@echo "make compile       : compilation des codes (module à tester et testbenchs)"
	@echo "make simu_batch    : simulation en mode terminal, avec simple affichage des résultats des tests"
	@echo "make exam_packets  : examen détaillé des éventuelles erreurs de lectures et d'écriture"
	@echo "make simu_gui      : simulation en mode graphique pour faire un debug de votre code."
	@echo "make all           : équivalent à simu_gui"
	@echo "make syn           : test de synthèse de votre module avalon_bram"
	@echo "make info          : ce message"
	@echo "make clean         : nettoyage des fichiers inutiles"

all: simu_batch

compile: tmp/.compiled
simu_batch: tmp/packets.log

tmp/packets.log: tmp/.compiled
	@cd tmp ; $(VSIM)  $(OPTSIM) -batch -lib work $(TB_TOP) -do "run -all ; quit" 2> packets.log

exam_packets: tmp/packets.log
	@less -R tmp/packets.log

simu_gui: tmp/.compiled
	@cd tmp; $(VSIM)  $(OPTSIM)  -lib work $(TB_TOP)

tmp/.compiled: $(DEP) | tmp
	@touch $@

tmp/.%.compiled: $(AVALONTBSRCDIR)/%.sv | tmp/work
	@cd tmp ; $(VLOG)  $(OPTVLOG) $<
	@touch $@

tmp/.%.compiled: $(AVALONSRCDIR)/%.sv | tmp/work
	@cd tmp ; $(VLOG)  $(OPTVLOG) $<
	@touch $@

tmp/.%.compiled: $(SRCDIR)/%.sv | tmp/work
	@cd tmp ; $(VLOG)  $(OPTVLOG) $<
	@touch $@

syn: tmp/$(AREA_FILE)

tmp/$(AREA_FILE): $(AVALONSRC) $(SRC) | tmp
	@cd tmp ; TOP_MODULE=wrapper HDL_FILES="$(AVALONSRC) $(SYNSRC) $(SRC)" make -f ../Makefile_syn pr

tmp:
	@mkdir $@

tmp/work: | tmp
	@cd tmp ; vlib work

clean:
	@rm -rf tmp

