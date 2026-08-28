# Flujo de Vivado no-project (batch) para el Basys3 (xc7a35tcpg236-1).
# Pensado para correr en una máquina con Vivado instalado.
# Uso: vivado -mode batch -source src/fpga/build_bitstream.tcl
#
# Corre desde la raíz del repo (rutas relativas asumen eso).

set part      xc7a35tcpg236-1
set design_top top
set build_dir src/build

file mkdir $build_dir

read_verilog -sv [glob src/design/*.sv]
read_xdc src/fpga/basys3.xdc

synth_design -top $design_top -part $part

opt_design
place_design
route_design

write_checkpoint -force $build_dir/${design_top}_routed.dcp
report_timing_summary -file $build_dir/${design_top}_timing.rpt
report_utilization -file $build_dir/${design_top}_utilization.rpt

write_bitstream -force $build_dir/${design_top}.bit
