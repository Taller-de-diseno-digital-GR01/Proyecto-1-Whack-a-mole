# Subsistema FPGA

## Objetivo

 Se encarga de controlar la lógica del juego por medio de la máquima de estado para comunicar cada modulo entre sí.

## Entradas

- `clk`: frecuencia de reloj a 100MHz que controla los flancos de las señales que utiliza todo el sistema.
- `rst`: señal que reinicia la partida y la FSM, así como volver cada módulo a sus valores iniciales.
- `Botones[7:0]`: señal de los 8 botones físicos que actúan como pulsadores para golpear al topo.
- `pos_topo_lfsr[2:0]`: Señal paralela de 3 bits que proviene directamente del LFSR del subsistema discreto, la cual reemplaza a la entrada serial externa original debido a la inestabilidad del reloj 555 del protoboard[cite: 17, 21, 22].

## Salidas

- `LEDs topos [7:0]`: Muestra mediante la matriz LED 4x2 al topo en la posición indicada de acuerdo al número generado por la LSFR, muestra un LED encendido a la vez.
- `led_state`: Un LED que muestra el estado de la partida, si se encuentra en medio de un juego (encendido) o si finalizó la partida (parpadeando).
- `acierto[7:0]`: valor numérico de 0 a 99 en BCD que muestra la cantidad de veces que el jugador acertó, el cual va directamente a los displays.
- `fallo[7:0]`: valor numérico de 0 a 99 en BCD que acumula la cantidad de veces que el jugador falló, el cual va directamente a los displays.
- 
## Explicación General

La señal paralela `pos_topo_lfsr[2:0]` ingresa al módulo `t_uart` (M9) que la empaqueta y transmite como una trama serial en un *loopback* interno para evadir la inestabilidad del hardware discreto. Esta trama se recibe y decodifica por medio del módulo `Receptor_UART` (M1) en una señal retenida `pos_topo[2:0]`. La FSM verifica la posición y la muestra con LEDs mediante el módulo `Show_Mole`. La FSM en cada turno toma la señal de los botones mediante el módulo `Press_btn` y compara si se presionó el botón correcto dentro de la ventana de tiempo estipulada por el módulo `Time_Logic`. 

En caso de que sea correcto, la FSM emite `hit`, lo que hace que `Time_Logic` decrezca la ventana de tiempo en 100ms (hasta un piso de 500ms) y que `Hit_Counter` aumente el valor del contador mostrado. En caso de fallar o agotarse el tiempo, la FSM emite `miss`, lo que hace que `Fail_Counter` aumente el valor de fallos acumulados y evalúe internamente si se llegó a 3 fallos consecutivos para emitir `fin_partida`. Si ocurre un acierto, el contador interno de consecutivos se reinicia. 
Durante toda la partida, se muestra el estado de la misma con el módulo de Estado de juego (`State`), que indica si la partida está activa (`f_state_play`) o finalizada (`f_state_gameover`) con una ventana de 2 segundos de espera antes del reinicio automático.

## Módulos

- M1. Módulo Receptor_UART
- M2. Módulo Show_Mole
- M3. Módulo Press_btn
- M4. Módulo Time_Logic
- M5. Módulo Hit_Counter
- M6. Módulo Fail_Counter
- M7. Módulo State
### M1: Receptor UART
**a) Objetivo:** Recibir la trama serial interna enviada por `t_uart` para entregarla decodificada a la FSM y al visualizador cuando se solicita.
**b) Entradas:** `pos(8)_sync` / `rx` (Línea serial en loopback), `rst`, y `en_save_pos` (habilitador para retener la posición decodificada).
**c) Salidas:** `pos_topo[2:0]` (posición retenida) y `valid_pos` (pulso de confirmación de trama).
**d) Funcionamiento y Diseño:** Emplea un sincronizador de dos etapas y cuenta intervalos de baudios a partir del bit de inicio, capturando a la mitad del pulso (`N/2 - 1`) para evitar metaestabilidad. Si la trama 8N1 es válida, emite el pulso y guarda los 3 LSB.

### M2: Show_Mole
**a) Objetivo:** Mostrar en la matriz LED 4x2 al topo activo.
**b) Entradas:** `pos_topo[2:0]` (desde M1) y `en_topo` (habilitación de FSM).
**c) Salidas:** `leds_topo[7:0]` (señal one-hot física).
**d) Funcionamiento y Diseño:** Actúa como decodificador combinacional puro de 3 a 8 bits. Si `en_topo` es 0, todo se apaga.

### M3: press_btn
**a) Objetivo:** Filtrar rebotes de los pulsadores físicos y entregar la posición presionada para validarla.
**b) Entradas:** `Botones[7:0]`, `clk`, `rst`, y `pos_topo[2:0]`.
**c) Salidas:** `valid` (acierto) y `miss` (fallo).
**d) Funcionamiento y Diseño:** Pasa cada botón por un sincronizador de 2 etapas y un filtro anti-rebote (contador de ~10ms). Un codificador 8:3 de prioridad extrae la posición y la compara internamente con `pos_topo`.

### M4: Time_Logic
**a) Objetivo:** Controlar la cuenta regresiva del turno y reducir la ventana por cada acierto consecutivo.
**b) Entradas:** `clk`, `rst`, `inicio` (abre ventana), `hit` (reduce ventana), `rst_window`, `rst_dificulty`, `nueva_partida`.
**c) Salidas:** `UP` (bandera de expiración).
**d) Funcionamiento y Diseño:** Usa un prescalador a 100ms. La dificultad empieza en 1.5s y baja monótonamente hasta 500ms al recibir `hit`. Si llega a 0 emite `UP` durante un ciclo.

### M5: Hit_Counter
**a) Objetivo:** Contabilizar los aciertos acumulados en formato BCD.
**b) Entradas:** `clk`, `rst`, `hit`, y `nueva_partida`.
**c) Salidas:** `acierto[7:0]`.
**d) Funcionamiento y Diseño:** Contador de dos dígitos BCD que incrementa unidades y acarrea decenas al desbordarse en 9. Se satura en el tope configurado (ej. 99).

### M6: fail_counter
**a) Objetivo:** Contar los fallos para el marcador y evaluar la condición de fin de partida (3 consecutivos).
**b) Entradas:** `clk`, `rst`, `miss`, `hit`, `nueva_partida`.
**c) Salidas:** `fallo[7:0]` y `fin_partida`.
**d) Funcionamiento y Diseño:** Mantienen una cuenta BCD acumulada (que se incrementa con `miss`) y una cuenta binaria interna consecutiva. `fin_partida` es un cálculo combinacional que se activa asíncronamente al 3er fallo.

### M7: estado_juego
**a) Objetivo:** Indicar el estado visual y temporizar los 2 segundos de fin de partida.
**b) Entradas:** `clk`, `rst`, `f_state_play`, `f_state_gameover`.
**c) Salidas:** `led_state` y `fin_espera`.
**d) Funcionamiento y Diseño:** Si es *play*, LED fijo. Si es *gameover*, activa un prescalador de 100ms que hace parpadear el LED y cuenta hasta 20 (2 segundos) para emitir el pulso `fin_espera`.

### M8: Máquina de Estados FSM
**a) Objetivo:** Orquestar todos los módulos mediante una máquina de estados de Moore.
**b) Estados Principales:** 
- **INICIO (000):** Emite resets a tiempos y dificultades.
- **SOL_POS (001):** Dispara `en_numAleatorios` (para M9).
- **ESP_UART (010):** Espera trama; al recibirla activa `en_save_pos`.
- **JUGAR (011):** Emite `inicio`. Transita a ACIERTO si `valid`, o a FALLO si `miss`/`UP`.
- **ACIERTO (100):** Emite `hit`.
- **FALLO (101):** Emite `miss`. Evalúa si debe ir a FIN o retornar.
- **FIN (110):** Espera 2s (`fin_espera`) y emite `nueva_partida`.

### M9: t_uart (Transmisor interno)
**a) Objetivo:** Recibir los 3 bits paralelos del LFSR discreto y convertirlos en trama UART 8N1 emulando al hardware discreto inestable.
**b) Entradas:** `pos_topo_lfsr[2:0]`, `start`, `clk`, `rst`.
**c) Salidas:** `tx` (hacia `Receptor_UART`) y `busy`.
**d) Funcionamiento y Diseño:** Almacena la petición en un flip-flop de reserva (pending). Desplaza la trama (5 bits en 0 y 3 LSB de posición) a 9600 baudios usando una base de tiempo propia.