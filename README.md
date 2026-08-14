# Proyecto 1: Whack-a-mole híbrido FPGA / lógica discreta

**Curso:** EL3313 Taller de Diseño Digital
**Semestre:** II Semestre 2026
**Profesores:** Dr.-Ing. Jeferson González-Gómez, Ing. Rolen Coto Calderón
**Integrantes:**
- Carlos Castro Villegas
- Jefferson Chinchilla Quesada
- Mattio Coghi Quirós
- Nicolás Mena Valerio

## Descripción del sistema

El juego se implementa con dos subsistemas de reloj independiente. Un circuito en protoboard, construido
con lógica discreta 74xx y un oscilador 555, decide de forma pseudoaleatoria (LFSR) cuál de 8 posiciones
corresponde al topo y la indica con un LED. Esa posición se envía a la FPGA mediante un enlace serial UART
(8N1, 9600 baudios). La FPGA concentra toda la lógica de control del juego: turnos, ventana de tiempo con
dificultad progresiva, conteo de aciertos y fallos, y despliegue del marcador en displays de 7 segmentos.

## Documentación de diseño

### Nivel 1 - Descripción general
[Objetivos, entradas y salidas del sistema](docs/diseño/objetivos_descripciones.md#nivel-1)
[Diagrama de flujo general del juego](docs/diseño/Diagrama_de_flujo_proyecto1.drawio.png)

### Nivel 2 - Subdivisión en bloques
[Subsistema discreto y subsistema FPGA](docs/diseño/objetivos_descripciones.md#nivel-2)

### Nivel 3 - Diagrama de tercer nivel
- [Subsistema FPGA: objetivo, entradas, salidas y módulos](<docs/diseño/Descripción_3er Nivel.md>)
  - [Diagrama de módulos FPGA (fuente Mermaid)](docs/diseño/diagrama_FPGA.mermaid) · [imagen](docs/diseño/diagrama_FPGA.png)
  - [Vista alterna del mismo diagrama](docs/diseño/uart_fpga_system.png)
- [Subsistema discreto (diagrama preliminar)](docs/diseño/diagrama_lvl_3.md)
  - [Diagrama LFSR + registro UART (fuente Mermaid)](docs/diseño/diagrama_lfsr_uart.mermaid)

### Nivel 4 - Desarrollo modular
- [Subsistema discreto: M1 a M5](docs/diseño/diagrama_lvl_4.md)
- Subsistema FPGA, por módulo:
  - [M1. Receptor UART](docs/diseño/fpga/m01_receptor_uart.md)
  - [M2. Show_Mole](docs/diseño/fpga/m02_show_mole.md)
  - [M3. Press_btn](docs/diseño/fpga/m03_press_btn.md)
  - [M4. Time_Logic](docs/diseño/fpga/m04_time_logic.md)
  - [M5. Hit_Counter](docs/diseño/fpga/m05_hit_counter.md)
  - [M6. Fail_Counter](docs/diseño/fpga/m06_fail_counter.md)
  - [M7. Estado de juego](docs/diseño/fpga/m07_estado_juego.md)
  - [M8. FSM (máquina de estados central)](docs/diseño/fpga/m08_FSM.md)
    · diagrama de estados: [fuente draw.io](docs/diseño/fpga/FSM_proyecto1.drawio) · [imagen](docs/diseño/fpga/FSM_proyecto1.drawio.png)

### Nivel 5 - Esquemático total
Pendiente. Aún no hay un documento de nivel 5 que integre el esquemático eléctrico completo de ambos
subsistemas. El esquemático Multisim del subsistema discreto ya existe, ver
[Subsistema discreto](#subsistema-discreto-protoboard) más abajo.

## Investigación previa

Pendiente. Aún no se ha agregado documentación de investigación previa a este repositorio.

## Informe técnico

Pendiente. Ver [docs/informe/](docs/informe/README.md).

## Código SystemVerilog

Pendiente. Aún no se ha subido código SystemVerilog (fuentes ni testbenches) a este repositorio.

## Simulaciones

Pendiente. Aún no hay simulaciones ni waveforms de la FPGA en este repositorio.

## Subsistema discreto (protoboard)

- [Esquemático Multisim del bloque discreto](discreto/Simulacion_bloque_discreto.ms14) (formato `.ms14`, requiere
  NI Multisim o Multisim Live para abrirse)

## Estructura del repositorio

```
.
├── README.md
├── Proyectos_EL3313_proyecto1_2S2026.pdf   # enunciado del proyecto
├── docs/
│   ├── diseño/
│   │   ├── objetivos_descripciones.md      # Nivel 1 + Nivel 2
│   │   ├── Diagrama_de_flujo_proyecto1(.drawio.png)
│   │   ├── Descripción_3er Nivel.md        # Nivel 3, lado FPGA
│   │   ├── diagrama_FPGA.mermaid / .png    # Nivel 3, lado FPGA
│   │   ├── uart_fpga_system.png            # Nivel 3, lado FPGA (vista alterna)
│   │   ├── diagrama_lvl_3.md               # Nivel 3, lado discreto
│   │   ├── diagrama_lfsr_uart.mermaid      # Nivel 3, lado discreto
│   │   ├── diagrama_lvl_4.md               # Nivel 4, lado discreto
│   │   ├── fpga/                           # Nivel 4, lado FPGA (M1-M8)
│   │   └── img/                            # imágenes de esquemáticos del Nivel 4 discreto
│   └── informe/                            # informe técnico (pendiente)
├── discreto/
│   └── Simulacion_bloque_discreto.ms14     # esquemático Multisim del subsistema discreto
```

## Compilación y simulación

Este repositorio todavía no contiene código SystemVerilog, por lo que no hay un flujo de síntesis o
simulación que documentar. Cuando se agreguen fuentes y testbenches, deberían ubicarse en `rtl/src/` y
`rtl/tb/` respectivamente, con las simulaciones en `sim/` y las restricciones de la tarjeta en `constraints/`,
siguiendo la estructura de este README.
