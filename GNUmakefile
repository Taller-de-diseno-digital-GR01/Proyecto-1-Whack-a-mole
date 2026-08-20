DESIGN_DIR := src/design
SIM_DIR    := src/sim
BUILD_DIR  := src/build

IVERILOG       := iverilog
IVERILOG_FLAGS := -g2012
VVP            := vvp
GTKWAVE        := gtkwave
VECDUMP        := vecdump # Programa para pasar de .vcd a .svg

DESIGN_SRCS := $(wildcard $(DESIGN_DIR)/*.sv)
TB_SRCS     := $(wildcard $(SIM_DIR)/tb_*.sv)
TBS         := $(patsubst $(SIM_DIR)/tb_%.sv,%,$(TB_SRCS))

TB ?= $(firstword $(TBS))

VVP_OUT := $(BUILD_DIR)/tb_$(TB).vvp
VCD_OUT := $(BUILD_DIR)/tb_$(TB).vcd
SVG_OUT := $(BUILD_DIR)/tb_$(TB).svg

.PHONY: all help list sim wave dump test clean check-tb

all: help

help:
	@echo "make list              lista los testbenches disponibles"
	@echo "make sim  TB=<modulo>  compila y corre src/sim/tb_<modulo>.sv"
	@echo "make wave TB=<modulo>  corre la simulación y abre GTKWave"
	@echo "make dump TB=<modulo> SIGS=sig1,sig2,...  corre la simulación y exporta un SVG con vecdump"
	@echo "make test"
	@echo "make clean"
	@echo ""
	@echo "Testbenches disponibles, $(TBS)"
	@echo "TB por defecto si no se indica, $(TB)"

list:
	@echo "Testbenches disponibles, $(TBS)"

# Falla si no hay ningún testbench para correr (TB vacío)
check-tb:
ifeq ($(strip $(TB)),)
	$(error No se encontró ningún testbench en $(SIM_DIR)/tb_*.sv)
endif

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(VVP_OUT): $(DESIGN_SRCS) $(SIM_DIR)/tb_$(TB).sv | $(BUILD_DIR) check-tb
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

test: check-tb # <-- Esto corre make sim para cada testbench en $(TBS), uno por uno
	@estado=0; \
	for modulo in $(TBS); do \
		echo "--> $$modulo"; \
		$(MAKE) --no-print-directory sim TB=$$modulo || estado=1; \
	done; \
	exit $$estado

clean:
	rm -rf $(BUILD_DIR)
