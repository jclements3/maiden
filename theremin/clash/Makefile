# Clash port of the fpga-theremin DSP blocks.
#
# GHDL/Yosys/nextpnr come from the pinned OSS CAD Suite; source its
# environment before any of the hdl targets:
#     source ~/tools/oss-cad-suite/environment

BUILD    := build

# The clash binary from the project's own build plan (built via
# build-tool-depends). A globally installed clash cannot be used: it refuses
# to run against any clash-prelude instance other than its own.
CLASH := $(shell ls -td $$HOME/.cabal/store/ghc-9.6.7/clash-ghc-1.8.5-e-clash-*/bin/clash 2>/dev/null | head -1)
TOP      ?= Theremin.IirNStage
ENTITY   ?= iir_nstage_pow2k

VHDL_DIR := $(BUILD)/vhdl
VLOG_DIR := $(BUILD)/verilog

# --- Target part -------------------------------------------------------
# MAIDEN's recommended board is the ULX3S 85F (hardware/BOM.md Note A):
# Lattice ECP5 LFE5U-85F, 85k LUT4s. The iCEstick/HX8K are bring-up boards
# only and are too small for the FFT datapath, so ECP5 is what resource
# numbers here are measured against.
DEVICE   ?= 85k
PACKAGE  ?= CABGA381
FREQ_MHZ ?= 100

# GHDL on Ubuntu 22.04 (glibc < 2.38) needs the __isoc23_* shim during
# elaboration; same workaround as the VHDL project's Makefile.
comma := ,
SHIM := $(HOME)/tools/glibc-isoc23-shim.o
GHDL_ELAB_FLAGS := $(if $(wildcard $(SHIM)),-Wl$(comma)$(SHIM),)
GHDL_FLAGS := --std=08 --workdir=$(BUILD)/work -fsynopsys

.PHONY: all build test vhdl verilog sim synth pnr report clean

all: test sim report

## Compile the library and test suite.
build:
	cabal build all

## Haskell-side behavioural tests (fast feedback loop).
test:
	cabal test --test-show-details=direct

## Generate VHDL (used for GHDL simulation and co-sim against the original).
vhdl:
	@mkdir -p $(VHDL_DIR)
	cabal exec -- $(CLASH) -isrc $(TOP) --vhdl -outputdir $(BUILD)/clash-out \
		-fclash-hdldir $(VHDL_DIR)

## Generate Verilog (used for the ECP5 open synthesis flow).
verilog:
	@mkdir -p $(VLOG_DIR)
	cabal exec -- $(CLASH) -isrc $(TOP) --verilog -outputdir $(BUILD)/clash-out \
		-fclash-hdldir $(VLOG_DIR)

## Analyse + elaborate the generated VHDL under GHDL: proves the output is
## valid, elaboratable VHDL-2008 before it reaches synthesis.
sim: vhdl
	@mkdir -p $(BUILD)/work
	ghdl -a $(GHDL_FLAGS) $$(find $(VHDL_DIR) -name '*_types.vhdl' | sort) \
	                      $$(find $(VHDL_DIR) \( -name '*.vhdl' -o -name '*.vhd' \) ! -name '*_types.vhdl' | sort)
	ghdl -e $(GHDL_FLAGS) $(GHDL_ELAB_FLAGS) $(ENTITY)
	@echo "GHDL elaborated $(ENTITY) from Clash-generated VHDL."

## Synthesise to ECP5 and report cell usage.
synth: verilog
	yosys -p 'read_verilog -sv $$(find $(VLOG_DIR) -name "*.v" | sort | tr "\n" " "); \
	          synth_ecp5 -top $(ENTITY) -json $(BUILD)/$(ENTITY).json' \
	    | tee $(BUILD)/$(ENTITY).synth.log

## Place and route for the real part: this is the number that matters when
## judging whether a Clash datapath fits the MAIDEN board.
pnr: synth
	nextpnr-ecp5 --$(DEVICE) --package $(PACKAGE) --freq $(FREQ_MHZ) \
	    --json $(BUILD)/$(ENTITY).json --textcfg $(BUILD)/$(ENTITY).config \
	    2>&1 | tee $(BUILD)/$(ENTITY).pnr.log

## Summarise LUT/FF/DSP/BRAM usage and achieved Fmax.
report: pnr
	@echo "=== $(ENTITY) on ECP5 $(DEVICE) $(PACKAGE) ==="
	@grep -E 'TRELLIS_(FF|COMB)|MULT18X18|DP16KD|Max frequency' \
	    $(BUILD)/$(ENTITY).pnr.log || true

clean:
	rm -rf $(BUILD) dist-newstyle
