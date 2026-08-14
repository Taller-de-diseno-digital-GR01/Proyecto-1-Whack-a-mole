# Subsistema FPGA

## Objetivo

 Se encarga de controlar la lógica del juego por medio de la máquima de estado para comunicar cada modulo entre sí.

## Entradas

- clk: frecuencia de reloj a 100MHz que controla los flancos de las señales que utiliza todo el sistema
- rst: señal que reinicia la partida y la FSM, así como volver cada módulo a sus valores iniciales
- Botones[7:0]: señal de los 8 botones físicos que actuán como pulsadores para golpear al topo
- Pos[9:0]: Señal que proviene del subsistema discreto con la posición generada aleatoriamente por la LSFR, esta señal llega emapaquetada por medio del protoco UART que debe decodificarse para obtener la posición del topo

## Salidas

- LED´s topos [7:0]: Muestra mediante la matriz LED 4x2 al topo en la posición indicada de acuerdo al número generado por la LSFR, muestra un LED encedido a la vez.
- LED estado: Un LED que muestra el estado de la partida, si se encuentra en medio de un juego o si finalizó la partida.
- Acierto [6:0]: valor númerico de 0 a 99 que muestra la cantidad de veces que el jugador acertó al presionar el botón correspondiente al topo dentro de la ventana de tiempo.
- Fallo[1:0]: Valor numérico de 0 a 3 que muestra la cantidad de veces que el jugador falló al presionar le botón del topo, ya sea por errar la posición o no acertar dentro de la ventada de tiempo.

## Explicación General

La señal Pos[9:0] se decodifica por medio del módulo Deco_UART en una señal Pos_Topo[2:0] que es solicitada por la FSM en cada turno, la FSM verifica la posición y la muestra con LED´s mediante el módulo Show_Mole. La FSM en cada turno toma la señal de los botones mediante el módulo Press_btn y compara si se presionó el botón correcto dentro de la ventada de tiempo estipulada por el módulo Time_Logic.
En caso de que ambos valores sean iguales, el módulo Time_Logic decrece la ventana de tiempo en 100ms hasta llegar a los 500ms de tiempo para acertar y el módulo Hit_Counter aunmenta el valor del contador que se muestra en el Marcador con la señal acierto[6:0]. En caso de fallar, el módulo Fail_Counter aumenta el valor con un límite de 3 equivocaciones y lo muestra en Marcador con fallo[1:0], si ocurre un acierto este contador se reinicia.
Durante toda la partida, se muestra el estado de la misma con el módulo Estado de juego (State), que muestra mediante un LED si se está en medio juego o si finalizó, con una ventada de 2 segundos entre una partida y otra que inicia automáticamente.

## Módulos

- M1. Módulo Deco_UART
- M2. Módulo Show_Mole
- M3. Módulo Press_btn
- M4. Módulo Time_Logic
- M5. Módulo Hit_Counter
- M6. Módulo Fail_Counter
- M7. Módulo State

### M1: Deco_UART

#### a) Objetivo

Decodificar la señal recibida por medio de la UART para entregarla a la FSM cuando esta la solicita.

#### b) Entradas

- Pos[9:0]: Señal que proviene del subsistema discreto con la posición generada aleatoriamente por la LSFR, esta señal llega emapaquetada por medio del protoco UART que debe decodificarse para obtener la posición del topo
- rst: Señal de reinicio síncrono del sistema.

#### c) Salidas

- pos_topo[2:0]: posición del topo de 3 bits que va al modulo Show_Mole y 

#### d) Explicación General

La señal Pos[9:0] se decodifica por medio del módulo Deco_UART en una señal Pos_Topo[2:0] que es solicitada por la FSM en cada turno

### M2: módulo Show_Mole

#### a) Objetivo

- Mostrar en la matriz LED 4x2 al topo generado en una posición aleatoria generada por la LFSR.

#### b) Entradas

- pos_topo[2:0]: posición del topo de 3 bits que proviene del registro del Receptor UART
- en_topo: señal enabler para encender el LED correspondiente

#### c) Salidas

- pos_topo[7:0]: es la señal que viaja a los LED´s para enceder el LED correspondiente

#### d) Explicación General
Este módulo recibe tanto la posición del topo pos_topo[2:0] del registro del Recptor UART, como una señal de control de la FSM. Este módulo se encarga de decodificar con un deco 3:8 para enceder el LED correspondiente al topo generado.
Este LED se activa cuando la FSM solicita al módulo la posición y lo autoriza a mostrarlo

### M3: Press_btn

#### a) Objetivo

- 

#### b) Entradas
- s

#### c) Salidas

- 

#### d) Explicación General

### M4: Time_Logic

#### a) Objetivo

- 

#### b) Entradas

- 
#### c) Salidas

- 

#### d) Explicación General

### M5: Hit_Counter

#### a) Objetivo

- 

#### b) Entradas

- 
#### c) Salidas

- 

#### d) Explicación General

### M6: Fail_Counter

#### a) Objetivo

- 

#### b) Entradas

- 
#### c) Salidas

- 

#### d) Explicación General

### M7: Estado de juego

#### a) Objetivo

- 

#### b) Entradas

- 
#### c) Salidas

- 

#### d) Explicación General
