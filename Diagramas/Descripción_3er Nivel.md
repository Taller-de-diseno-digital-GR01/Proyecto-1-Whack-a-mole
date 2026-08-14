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

Filtrar el rebote (bounce) de los 8 pulsadores físicos y sincronizarlos con el reloj del sistema, entregando a la FSM la posición del botón presionado durante el turno activo.

#### b) Entradas

- Botones[7:0]: señal cruda proveniente de los 8 pulsadores físicos conectados por GPIO, una línea por cada posición del topo.
- clk: reloj de sistema a 100MHz utilizado para el muestreo y el filtrado de rebotes.
- rst: señal de reinicio síncrono que limpia los registros internos del debouncer.

#### c) Salidas

- btn[2:0]: posición codificada del botón presionado, ya filtrada de rebotes y sincronizada, que se entrega a la FSM para comparar contra la posición activa del topo.

#### d) Explicación General

Cada una de las 8 líneas de Botones[7:0] se sincroniza primero mediante un sincronizador de dos etapas para evitar problemas de metaestabilidad, ya que la pulsación del usuario es asíncrona respecto al reloj de la FPGA. Posteriormente, cada línea sincronizada pasa por un filtro de rebotes basado en un contador temporizador: la salida solo se considera válida si el nivel de la señal se mantiene estable durante una ventana mínima de tiempo (por ejemplo, unos pocos milisegundos), descartando así los rebotes mecánicos del pulsador. Una vez filtradas las 8 líneas, un codificador de prioridad las convierte en la señal btn[2:0], que la FSM solicita en cada turno para verificar si el botón presionado coincide con la posición activa del topo dentro de la ventana de tiempo definida por Time_Logic.

#### M4: Time_Logic

#### a) Objetivo

- Controlar la ventana de tiempo durante la cual el topo activo puede ser golpeado, aplicando la reducción progresiva de dicha ventana conforme se acumulan aciertos consecutivos.

#### b) Entradas

- clk: reloj de sistema a 100MHz, base para la generación de los clock enables internos del temporizador.
- rst: señal de reinicio síncrono que restablece la ventana de tiempo a su valor inicial de 1,5s.
- hit: señal proveniente de la FSM que indica que el turno actual terminó en acierto, utilizada para reducir la ventana en 100ms de cara al siguiente turno.

#### c) Salidas

- UP: señal que indica a la FSM que la ventana de tiempo del turno actual expiró sin que el jugador presionara el botón correcto.

#### d) Explicación General

Time_Logic implementa un temporizador descendente mediante clock enables derivados del reloj principal de 100MHz, sin generar relojes derivados adicionales. Al iniciar cada turno, el módulo carga la duración vigente de la ventana (1,5s por defecto) y la decrementa hasta llegar a cero, momento en el cual activa la señal UP para notificar a la FSM que el turno se perdió por tiempo. Cada vez que la FSM señaliza hit (acierto dentro de la ventana), Time_Logic reduce en 100ms el valor que se cargará en el siguiente turno, hasta un mínimo de 500ms; alcanzado ese mínimo, la ventana se mantiene constante mientras el jugador continúe acertando. Un fallo no restablece la ventana a su valor inicial: la dificultad alcanzada se conserva mientras la partida continúe, y solo se reinicia a 1,5s ante un rst o el fin de partida.

### M5: Hit_Counter

#### a) Objetivo

- Contabilizar la cantidad de aciertos acumulados durante la partida y entregar dicho valor codificado en BCD para su despliegue en el Marcador.

#### b) Entradas

- clk: reloj de sistema a 100MHz.
- rst: señal de reinicio síncrono que pone en cero el contador de aciertos.
- en_hit: señal habilitadora proveniente de la FSM que indica que ocurrió un acierto y que el contador debe incrementarse.

#### c) Salidas

- acierto[6:0]: valor de 0 a 99 codificado en BCD (dos dígitos) que se envía al Marcador para su despliegue en los displays de 7 segmentos.
- acierto: bandera hacia la FSM que indica que el contador alcanzó su valor máximo (99), utilizada para detener el conteo y evitar el desbordamiento.

#### d) Explicación General

El bloque Contador es un contador binario que se incrementa en cada pulso de en_hit proveniente de la FSM. Un comparador contrasta permanentemente el valor del contador contra 99; al alcanzar dicho límite, genera la señal acierto hacia la FSM para que esta deje de habilitar nuevos incrementos, evitando que el contador se desborde. En paralelo, el bloque Deco_BCD traduce el valor binario del contador a su representación en BCD de dos dígitos, entregando la señal acierto[6:0] al Marcador para su despliegue continuo en los displays de 7 segmentos, independientemente del estado de la partida.

### M6: Fail_Counter

#### a) Objetivo

- Contabilizar los fallos del jugador, entregar dicho valor codificado en BCD al Marcador, y notificar a la FSM cuando se alcanza el límite de 3 fallos para finalizar la partida.

#### b) Entradas

- clk: reloj de sistema a 100MHz.
- rst: señal de reinicio síncrono que pone en cero el contador de fallos; también se activa ante cada acierto para reiniciar el conteo de fallos consecutivos.
- en_fail: señal habilitadora proveniente de la FSM que indica que ocurrió un fallo (botón incorrecto o ventana de tiempo expirada) y que el contador debe incrementarse.

#### c) Salidas

- fallo[1:0]: valor de 0 a 3 codificado en BCD que se envía al Marcador para su despliegue.
- fallo: bandera hacia la FSM que indica que el contador alcanzó el límite de 3 fallos, utilizada para finalizar la partida.

#### d) Explicación General

El bloque CONT es un contador binario que se incrementa en cada pulso de en_fail proveniente de la FSM. Un comparador contrasta el valor del contador contra 3; al alcanzarlo, genera la señal fallo hacia la FSM para que esta transicione al estado de fin de partida. A diferencia de Hit_Counter, este contador se reinicia cada vez que ocurre un acierto, de modo que solo cuenta fallos consecutivos y no un acumulado histórico de la partida. El bloque Decode BCD traduce el valor binario a BCD para su despliegue en el Marcador mediante la señal fallo[1:0].

### M7: Estado de juego

#### a) Objetivo

- Indicar visualmente, mediante un LED de la tarjeta, si la partida se encuentra en curso o si finalizó.

#### b) Entradas

- clk: reloj de sistema a 100MHz.
- rst: señal de reinicio síncrono que restablece el estado a "partida en curso".
- estado: señal proveniente de la FSM que indica el estado actual de la partida (en curso o finalizada).

#### c) Salidas

- LED estado: LED de la tarjeta que refleja el estado de la partida: una condición (por ejemplo, encendido fijo) mientras la partida está en curso, y otra claramente distinguible (por ejemplo, parpadeo o apagado) durante los 2s de estado de fin de partida antes del reinicio automático.

#### d) Explicación General

Este módulo traduce la señal de estado[código binario] entregada por la FSM en un patrón visual sobre el LED de estado de la tarjeta. Mientras la FSM permanece en el estado de juego activo, el LED se mantiene en una condición fija; al detectarse el tercer fallo consecutivo, la FSM transiciona al estado de fin de partida y actualiza la señal estado, lo que hace que este módulo cambie el patrón del LED (por ejemplo, a parpadeo) durante la ventana mínima de 2s antes de que la FSM reinicie automáticamente la partida con una nueva secuencia y los contadores en cero.