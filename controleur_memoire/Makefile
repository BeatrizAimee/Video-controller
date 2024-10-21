#
.PHONY: clean all simu_batch compile simu_gui info syn

export PATH:=/comelec/softs/bin:$(PATH)

VLOG = vlog
VSIM = vsim

TOPDIR = $(shell pwd)
TB_TOP = testbench_top
WORK_DIR = work

OPTVLOG=+acc
OPTSIM=-t ps -msgmode wlf -displaymsgmode both


# Avalon interface sources
AVALONSRCDIR  = $(TOPDIR)/../avalon_if
AVALONSRC     = $(AVALONSRCDIR)/avalon_if.sv
DEP           = $(patsubst $(AVALONSRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${AVALONSRC})

# Avalon testbench sources
AVALONTBSRCDIR  = $(TOPDIR)/avalon_bram_tb_src
AVALONTBSRC     = verbosity_pkg.sv avalon_mm_pkg.sv avalon_utilities_pkg.sv packet.sv altera_avalon_mm_master_bfm.sv tpt_altera_avalon_mm_monitor_assertion.sv testbench_top.sv
DEP          += $(patsubst %.sv,$(WORK_DIR)/.%.compiled,${AVALONTBSRC})

# Module sources
SRCDIR    = $(TOPDIR)/avalon_bram
SRC       = $(SRCDIR)/avalon_bram.sv
DEP      += $(patsubst $(SRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${SRC})

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

exam_packets: $(WORK_DIR)/packets.log
	less $(WORK_DIR)/packets.log

simu_batch: $(WORK_DIR)/packets.log

$(WORK_DIR)/packets.log: compile
	cd $(WORK_DIR) ; $(VSIM)  $(OPTSIM) -batch -lib work $(TB_TOP) -do "run -all ; quit" 2> packets.log

simu_gui: compile
	cd $(WORK_DIR); $(VSIM)  $(OPTSIM)  -lib work $(TB_TOP)

compile: $(DEP)

$(WORK_DIR)/.%.compiled: $(AVALONTBSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  $(OPTVLOG) $<
	touch $@

$(WORK_DIR)/.%.compiled: $(AVALONSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  $(OPTVLOG) $<
	touch $@

$(WORK_DIR)/.%.compiled: $(SRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

syn: $(WORK_DIR)/$(AREA_FILE)

$(WORK_DIR)/$(AREA_FILE): $(AVALONSRC) $(SRC) $(WORK_DIR)
	cd $(WORK_DIR) && TOP_MODULE=wrapper HDL_FILES="$(AVALONSRC) $(SYNSRC) $(SRC)" make -f ../Makefile_syn pr

$(WORK_DIR):
	mkdir $(WORK_DIR)

$(WORK_DIR)/work: $(WORK_DIR)
	cd $(WORK_DIR) ; vlib work

clean:
	rm -rf $(WORK_DIR)

