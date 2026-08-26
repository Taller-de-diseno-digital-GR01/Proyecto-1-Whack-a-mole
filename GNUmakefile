DESIGN_DIR := src/design
SIM_DIR    := src/sim
BUILD_DIR  := src/build

IVERILOG       := iverilog
IVERILOG_FLAGS := -g2012
VVP            := vvp
GTKWAVE        := gtkwave
VECDUMP        := vecdump # Programa para pasar de .vcd a .svg
YOSYS          := yosys
OPENFPGALOADER := openFPGALoader
BOARD          := basys3

# Toolchain openXC7 (yosys + nextpnr-xilinx + prjxray), sin Vivado.
# Requiere /opt/openxc7/bin en el PATH -- correr antes: source /opt/openxc7/export.sh
NEXTPNR_XILINX  := nextpnr-xilinx
FASM2FRAMES     := python3 /opt/openxc7/bin/fasm2frames.py
XC7FRAMES2BIT   := xc7frames2bit
PART            := xc7a35tcpg236-1
PRJXRAY_DB_ROOT := /opt/openxc7/share/nextpnr/prjxray-db/artix7
CHIPDB          := /opt/openxc7/share/nextpnr-xilinx/chipdb/xc7a35tcpg236.bin
XDC             := src/fpga/basys3.xdc

DESIGN_SRCS := $(wildcard $(DESIGN_DIR)/*.sv)
TB_SRCS     := $(wildcard $(SIM_DIR)/tb_*.sv)
TBS         := $(patsubst $(SIM_DIR)/tb_%.sv,%,$(TB_SRCS))

TB ?= $(firstword $(TBS))
SYNTH_TOP ?= top

VVP_OUT := $(BUILD_DIR)/tb_$(TB).vvp
VCD_OUT := $(BUILD_DIR)/tb_$(TB).vcd
SVG_OUT := $(BUILD_DIR)/tb_$(TB).svg

NETLIST_OUT := $(BUILD_DIR)/$(SYNTH_TOP)_synth.v
SYNTH_LOG   := $(BUILD_DIR)/$(SYNTH_TOP)_synth.log

JSON_OUT   := $(BUILD_DIR)/$(SYNTH_TOP).json
ROUTED_OUT := $(BUILD_DIR)/$(SYNTH_TOP)_routed.json
FASM_OUT   := $(BUILD_DIR)/$(SYNTH_TOP).fasm
FRAMES_OUT := $(BUILD_DIR)/$(SYNTH_TOP).frames
BIT_OUT    := $(BUILD_DIR)/$(SYNTH_TOP).bit
BIT        ?= $(BIT_OUT)

# Identifica el toolchain (ruta + versión de iverilog/yosys/nextpnr-xilinx) para invalidar
# el build si src/build/ quedó con binarios de otra máquina
TOOLCHAIN_STAMP := $(BUILD_DIR)/.toolchain

.PHONY: all help list sim wave dump test synth bitstream program clean check-tb check-fpga-toolchain

all: bitstream program

help:
	@echo "make all                genera el bitstream y lo carga a la FPGA (bitstream + program)"
	@echo "make list              lista los testbenches disponibles"
	@echo "make sim  TB=<modulo>  compila y corre src/sim/tb_<modulo>.sv"
	@echo "make wave TB=<modulo>  corre la simulación y abre GTKWave"
	@echo "make dump TB=<modulo> SIGS=sig1,sig2,...  corre la simulación y exporta un SVG con vecdump"
	@echo "make test"
	@echo "make synth SYNTH_TOP=<modulo>  sintetiza con yosys (genérico) y revisa que no haya latches inferidos"
	@echo "make bitstream          genera $(BIT_OUT) con yosys + nextpnr-xilinx + prjxray (openXC7, sin Vivado)"
	@echo "                        requiere /opt/openxc7/bin en el PATH (source /opt/openxc7/export.sh)"
	@echo "make program BIT=<archivo.bit>  carga un .bit al Basys3 con openFPGALoader"
	@echo "make clean"
	@echo ""
	@echo "Testbenches disponibles, $(TBS)"
	@echo "TB por defecto si no se indica, $(TB)"
	@echo "SYNTH_TOP por defecto si no se indica, $(SYNTH_TOP)"

list:
	@echo "Testbenches disponibles, $(TBS)"

# Falla si no hay ningún testbench para correr (TB vacío)
check-tb:
ifeq ($(strip $(TB)),)
	$(error No se encontró ningún testbench en $(SIM_DIR)/tb_*.sv)
endif

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TOOLCHAIN_STAMP): | $(BUILD_DIR)
	@{ echo "$$($(IVERILOG) -V | head -1)|$$(command -v $(IVERILOG))"; \
	   echo "$$($(YOSYS) -V)|$$(command -v $(YOSYS))"; \
	   echo "$$(command -v $(NEXTPNR_XILINX))"; } > $@.tmp
	@cmp -s $@.tmp $@ 2>/dev/null && rm -f $@.tmp || mv $@.tmp $@

$(VVP_OUT): $(DESIGN_SRCS) $(SIM_DIR)/tb_$(TB).sv $(TOOLCHAIN_STAMP) | $(BUILD_DIR) check-tb
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(DESIGN_SRCS) $(SIM_DIR)/tb_$(TB).sv

sim: check-tb $(VVP_OUT)
	cd $(BUILD_DIR) && $(VVP) $(notdir $(VVP_OUT))

wave: sim
	$(GTKWAVE) $(VCD_OUT) &

dump: sim
ifeq ($(strip $(SIGS)),)
	$(error Uso, make dump TB=<modulo> SIGS=sig1,sig2,...  ej. make dump TB=hit_counter SIGS=clk,rst,hit,acierto)
endif
	$(VECDUMP) $(VCD_OUT) -s $(SIGS) -o $(SVG_OUT)
	@echo ".svg generado en $(SVG_OUT)"

# Ej:
# make dump TB=hit_counter SIGS=clk_tb,rst_tb,nueva_partida_tb,hit_tb,acierto_tb
# Hay que conocer las señales que se quieren ver, eso es lo único malo.

$(NETLIST_OUT): $(DESIGN_SRCS) $(TOOLCHAIN_STAMP) | $(BUILD_DIR)
	@$(YOSYS) -p " \
		read_verilog -sv $(DESIGN_SRCS); \
		hierarchy -check -top $(SYNTH_TOP); \
		proc; opt; \
		prep -top $(SYNTH_TOP); \
		opt_clean; \
		stat; \
		write_verilog $(NETLIST_OUT) \
	" > $(SYNTH_LOG) 2>&1; status=$$?; \
	if [ $$status -ne 0 ]; then \
		cat $(SYNTH_LOG); \
		echo ""; \
		echo "ERROR: yosys falló sintetizando '$(SYNTH_TOP)' (ver $(SYNTH_LOG))"; \
		exit 1; \
	fi; \
	if grep "Latch inferred" $(SYNTH_LOG) | grep -qv "^No "; then \
		echo "ERROR: yosys detectó latch(es) no intencionados en '$(SYNTH_TOP)':"; \
		grep "Latch inferred" $(SYNTH_LOG) | grep -v "^No "; \
		exit 1; \
	fi; \
	stat_line=$$(grep -n "Printing statistics" $(SYNTH_LOG) | tail -1 | cut -d: -f1); \
	tail -n +$$stat_line $(SYNTH_LOG)

# Nota: SYNTH_TOP debe ser un módulo instanciable de verdad (ej. top, o cualquier
# módulo hoja como hit_counter). No sirve para testbenches (tb_*.sv no está en DESIGN_SRCS).
synth: $(NETLIST_OUT)
	@echo "Netlist generado en $(NETLIST_OUT)"

# Falla temprano y con un mensaje claro si falta el toolchain openXC7 en el PATH
check-fpga-toolchain:
	@command -v $(YOSYS) >/dev/null 2>&1 || \
		{ echo "ERROR: '$(YOSYS)' no encontrado en PATH. Correr: source /opt/openxc7/export.sh"; exit 1; }
	@command -v $(NEXTPNR_XILINX) >/dev/null 2>&1 || \
		{ echo "ERROR: '$(NEXTPNR_XILINX)' no encontrado en PATH. Correr: source /opt/openxc7/export.sh"; exit 1; }
	@command -v $(XC7FRAMES2BIT) >/dev/null 2>&1 || \
		{ echo "ERROR: '$(XC7FRAMES2BIT)' no encontrado en PATH. Correr: source /opt/openxc7/export.sh"; exit 1; }
	@[ -f $(CHIPDB) ] || \
		{ echo "ERROR: chipdb no encontrado en $(CHIPDB) (ver docs de generación en /home/mc/Documents/CLAUDE.md)"; exit 1; }

# Bitstream para el Basys3 (XC7A35T, part $(PART)) con el toolchain openXC7 (yosys ->
# nextpnr-xilinx -> fasm2frames -> xc7frames2bit), sin Vivado. Ver src/fpga/basys3.xdc.
$(JSON_OUT): $(DESIGN_SRCS) $(TOOLCHAIN_STAMP) | $(BUILD_DIR)
	$(YOSYS) -p " \
		read_verilog -sv $(DESIGN_SRCS); \
		synth_xilinx -flatten -abc9 -nobram -arch xc7 -top $(SYNTH_TOP); \
		write_json $(JSON_OUT) \
	"

$(ROUTED_OUT) $(FASM_OUT) &: $(JSON_OUT) $(XDC) $(CHIPDB)
	$(NEXTPNR_XILINX) --chipdb $(CHIPDB) --xdc $(XDC) --json $(JSON_OUT) \
		--write $(ROUTED_OUT) --fasm $(FASM_OUT)

$(FRAMES_OUT): $(FASM_OUT)
	$(FASM2FRAMES) --part $(PART) --db-root $(PRJXRAY_DB_ROOT) $(FASM_OUT) > $(FRAMES_OUT)

$(BIT_OUT): $(FRAMES_OUT)
	$(XC7FRAMES2BIT) --part_file $(PRJXRAY_DB_ROOT)/$(PART)/part.yaml --part_name $(PART) \
		--frm_file $(FRAMES_OUT) --output_file $(BIT_OUT)

bitstream: check-fpga-toolchain $(BIT_OUT)
	@echo "Bitstream generado en $(BIT_OUT)"

program:
	$(OPENFPGALOADER) -b $(BOARD) $(BIT)

test: check-tb # <-- Esto corre make sim para cada testbench en $(TBS), uno por uno
	@estado=0; \
	for modulo in $(TBS); do \
		echo "--> $$modulo"; \
		$(MAKE) --no-print-directory sim TB=$$modulo || estado=1; \
	done; \
	exit $$estado

clean:
	rm -rf $(BUILD_DIR)
