# Proyecto 1: Whack-a-mole

 EL3313 Taller de Diseño Digital

 II Semestre 2026

 Dr.-Ing. Jeferson González-Gómez, Ing. Rolen Coto Calderón

**Integrantes:**


- Jefferson Chinchilla Quesada 2023152266
- Carlos Castro Villegas 2023149025
- Mattio Coghi Quirós 2023056023
- Nicolás Mena Valerio 2022327473

## Descripción del sistema
El juego se implementa con dos subsistemas de reloj independiente. Un circuito en protoboard, construido
con lógica discreta 74xx y un oscilador 555, decide de forma pseudoaleatoria (LFSR) cuál de 8 posiciones
corresponde al topo y la indica con un LED. El transmisor UART discreto (74xx + reloj 555) no resultó
confiable, así que esa posición llega a la FPGA por 3 líneas paralelas directas desde el LFSR; la FPGA arma
la trama 8N1 (9600 baudios) internamente, en loopback, para conservar el formato de comunicación acordado
entre módulos (ver `src/design/t_uart.sv`). La FPGA concentra toda la lógica de control del juego: turnos,
ventana de tiempo con dificultad progresiva, conteo de aciertos y fallos, y despliegue del marcador en
displays de 7 segmentos.

## Documentación de docs/Diseños_Separados
### Nivel 1 - Descripción general
[Objetivos, entradas y salidas del sistema](docs/Diseños_Separadosobjetivos_descripciones.md#nivel-1)
[Diagrama de flujo general del juego](docs/Diseños_SeparadosDiagrama_de_flujo_proyecto1.drawio.png)

### Nivel 2 - Subdivisión en bloques
[Subsistema discreto y subsistema FPGA](docs/Diseños_Separadosobjetivos_descripciones.md#nivel-2)

### Nivel 3 - Diagrama de tercer nivel
- [Subsistema FPGA: objetivo, entradas, salidas y módulos](<docs/Diseños_SeparadosDescripción_3er Nivel.md>)
  - [Diagrama de módulos FPGA (fuente Mermaid)](docs/Diseños_Separados/diagrama_FPGA.mermaid)  [imagen](docs/Diseños_Separados/diagrama_FPGA.png)
  - [Vista alterna del mismo diagrama](docs/Diseños_Separados/uart_fpga_system.png)
- [Subsistema discreto (diagrama preliminar)](docs/Diseños_Separados/diagrama_lvl_3.md)
  - [Diagrama LFSR + registro UART (fuente Mermaid)](docs/Diseños_Separados/diagrama_lfsr_uart.mermaid)

### Nivel 4 - Desarrollo modular
- [Subsistema discreto: M1 a M5](docs/Diseños_Separadosdiagrama_lvl_4.md)
- Subsistema FPGA, por módulo:
  - [M1. Receptor UART](docs/Diseños_Separados/fpga/m01_receptor_uart.md)
  - [M2. Show_Mole](docs/Diseños_Separados/fpga/m02_show_mole.md)
  - [M3. Press_btn](docs/Diseños_Separados/fpga/m03_press_btn.md)
  - [M4. Time_Logic](docs/Diseños_Separados/fpga/m04_time_logic.md)
  - [M5. Hit_Counter](docs/Diseños_Separados/fpga/m05_hit_counter.md)
  - [M6. Fail_Counter](docs/Diseños_Separados/fpga/m06_fail_counter.md)
  - [M7. Estado de juego](docs/Diseños_Separados/fpga/m07_estado_juego.md)
  - [M8. FSM (máquina de estados central)](docs/Diseños_Separados/fpga/m08_FSM.md)
    * diagrama de estados: [imagen](docs/Diseños_Separados/fpga/FSM_proyecto1.drawio.png)
  - [M9. Transmisor_UART](docs/Diseños_Separados/fpga/m09_transmisor_uart.md)

### Nivel 5 - Esquemático total

- Esquemático de nivel 5 para la FPGA
![alt text](docs/Diseños_Separadosimg/schematic_lvl5.jpg)

- El esquemático Multisim del subsistema discreto ya existe, ver
[Subsistema discreto](#subsistema-discreto-protoboard) más abajo.

## Investigación previa

Completa - Ver Informe

## Informe técnico

 Ver [docs/informe/](docs/Informe.md).

## Código SystemVerilog

Ver en [src/desing]

## Simulaciones

Ver en [src/sim]

## Subsistema discreto (protoboard)

- [Esquemático Multisim del bloque discreto](discreto/Simulacion_bloque_discreto.ms14) (formato `.ms14`, requiere
  NI Multisim o Multisim Live para abrirse)

## Estructura del repositorio

```
.
├── README.md
├── Proyectos_EL3313_proyecto1_2S2026.pdf # enunciado del proyecto
├── docs/
│   ├── docs/Diseños_Separados
│   │   ├── objetivos_descripciones.md # Nivel 1 + Nivel 2
│   │   ├── Diagrama_de_flujo_proyecto1(.drawio.png)
│   │   ├── Descripción_3er Nivel.md # Nivel 3, lado FPGA
│   │   ├── diagrama_FPGA.mermaid/.png # Nivel 3, lado FPGA
│   │   ├── uart_fpga_system.png # Nivel 3, lado FPGA (vista alterna)
│   │   ├── diagrama_lvl_3.md # Nivel 3, lado discreto
│   │   ├── diagrama_lfsr_uart.mermaid # Nivel 3, lado discreto
│   │   ├── diagrama_lvl_4.md   # Nivel 4, lado discreto
│   │   ├── fpga/            # Nivel 4, lado FPGA (M1-M8)
│   │   └── img/       # imágenes de esquemáticos del Nivel 4 discreto
│   ├── informe/ # informe técnico
|   └── Diseno/ #Diseños de 1er a 5to nivel del proyecto
├── discreto/
│   └── Simulacion_bloque_discreto.ms14 # esquemático Multisim del subsistema discreto
├── src/
│   ├── build/ # Resultados de las simulaciones
│   ├── desing/ # Códigos de los módulos en System Verilog
│   ├── fpga/ # Constraints para la Basys3
│   ├── sim/ # Tesbenchs de simulación de los módulos en System Verilog
```

