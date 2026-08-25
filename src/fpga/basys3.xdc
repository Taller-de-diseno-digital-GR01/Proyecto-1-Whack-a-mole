# Constraints para Basys3 (Digilent, XC7A35T-1CPG236C).
#
# ADVERTENCIA: los pines de recursos onboard (reloj, botones, switches, leds,
# display de 7 segmentos) los puse de memoria a partir del pinout público y
# muy estandarizado del Basys3 -- VERIFICAR contra el "Basys3 Master XDC"
# oficial de Digilent antes de programar la tarjeta de verdad. Un IOSTANDARD
# o pin mal puesto puede dañar hardware.
#
# Los pines de btn_0..btn_7, pos y en_numRandom son conexiones externas hacia
# el subsistema discreto (protoboard) por Pmod/GPIO -- dependen de cómo lo
# cablearon físicamente y NO los puedo inventar. Quedan comentados como TODO.

## Reloj del sistema, 100 MHz
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## rst -- botón central (BTNC), reinicia todo manualmente según docs/diseño/Diseños_Separados/fpga/m08_FSM.md
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## --- TODO: botones externos del subsistema discreto (8), por Pmod ---
## Confirmar en qué header/pin físico están cableados antes de descomentar.
# set_property PACKAGE_PIN <PIN> [get_ports btn_0]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_0]
# set_property PACKAGE_PIN <PIN> [get_ports btn_1]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_1]
# set_property PACKAGE_PIN <PIN> [get_ports btn_2]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_2]
# set_property PACKAGE_PIN <PIN> [get_ports btn_3]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_3]
# set_property PACKAGE_PIN <PIN> [get_ports btn_4]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_4]
# set_property PACKAGE_PIN <PIN> [get_ports btn_5]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_5]
# set_property PACKAGE_PIN <PIN> [get_ports btn_6]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_6]
# set_property PACKAGE_PIN <PIN> [get_ports btn_7]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_7]

## --- TODO: entrada serial UART (pos) desde el subsistema discreto ---
# set_property PACKAGE_PIN <PIN> [get_ports pos]
# set_property IOSTANDARD LVCMOS33 [get_ports pos]

## --- TODO: salida en_numRandom hacia el subsistema discreto (solicitud_topo) ---
# set_property PACKAGE_PIN <PIN> [get_ports en_numRandom]
# set_property IOSTANDARD LVCMOS33 [get_ports en_numRandom]

## --- TODO: salidas de estado/juego (led_state, f_state_play, f_state_gameover) ---
## Se pueden mapear a LEDs onboard (LD0..LD15) si no van hacia el subsistema
## discreto -- confirmar antes de descomentar.
# set_property PACKAGE_PIN U16 [get_ports led_state]
# set_property IOSTANDARD LVCMOS33 [get_ports led_state]
# set_property PACKAGE_PIN E19 [get_ports f_state_play]
# set_property IOSTANDARD LVCMOS33 [get_ports f_state_play]
# set_property PACKAGE_PIN U19 [get_ports f_state_gameover]
# set_property IOSTANDARD LVCMOS33 [get_ports f_state_gameover]

## --- TODO: leds_topo[7:0] -- ¿LEDs onboard o hacia el subsistema discreto? ---
# set_property PACKAGE_PIN V19 [get_ports {leds_topo[0]}]
# set_property PACKAGE_PIN W18 [get_ports {leds_topo[1]}]
# set_property PACKAGE_PIN U15 [get_ports {leds_topo[2]}]
# set_property PACKAGE_PIN U14 [get_ports {leds_topo[3]}]
# set_property PACKAGE_PIN V14 [get_ports {leds_topo[4]}]
# set_property PACKAGE_PIN V13 [get_ports {leds_topo[5]}]
# set_property PACKAGE_PIN V3  [get_ports {leds_topo[6]}]
# set_property PACKAGE_PIN W3  [get_ports {leds_topo[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {leds_topo[*]}]

## Display de 7 segmentos onboard (4 dígitos multiplexados, cátodo común)
## seg = {ca,cb,cc,cd,ce,cf,cg} , an = selector de dígito activo-bajo
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]
