# Nivel 1
## Objetivos
- Implementación del juego tipo _whack a mole_ con 8 posibles posiciones. En cada turno se seleccionará de forma pseudoaleatoria una posición activa y al jugador se le
dará una ventana de tiempo para reaccionar y presionar el botón correspondiente en la matriz de botones. Se llevará
el conteo de aciertos y fallos con el fin de que la dificultad pueda escalar de manera progresiva. La partida termina
una vez el jugador se equivoque tres veces consecutivas
- La ventana de tiempo arranca en 1.5 s y baja 100 ms por cada acierto consecutivo, con un piso de 500 ms. Un fallo no la devuelve a su valor inicial.
- Los contadores de aciertos y fallos van de 00 a 99 y se muestran al mismo tiempo.
- El jugador tiene 3 fallos consecutivos por partida. Un acierto reinicia esa cuenta.

## Descripciones
### Entradas:
1. `clk` (100 MHz, viene de la tarjeta)
2. Pulsaciones de los 8 botones externos, uno por cada posición
3. `rst` (botón central de la tarjeta)

### Salidas:
1. Posición del topo (en alguno de los 8 LEDs)
2. Marcador de aciertos y fallos (disp. 7 segmentos)
3. Estado de la partida (1 LED)

El jugador observa cuál de los 8 LEDs está encendido y tiene que presionar el botón asignado a esa posición antes
de que se acabe el tiempo en ese turno. Si el jugador acierta, sube el marcador **y** se reduce la ventana de tiempo para el turno siguiente.
En el caso de que el jugador falle o simplemente no haya ninguna pulsación a un botón, incrementa el contador de fallos.
Tres fallos consecutivos terminan la partida.

Se señalará que la partida está finalizada mediante un solo LED de estado y el juego se reiniciará automáticamente después
de un intervalo de tiempo.

En este nivel no se muestra nada de lo que pasa por dentro. Ni el enlace serial, ni la solicitud de topo,
ni las bases de tiempo internas aparecen acá, porque son parte de la solución y no de lo que el jugador ve.

# Nivel 2
## Objetivos
- Subdividir el bloque único del primer nivel en los módulos generales que conforman la solución.
- Establecer que cada subsistema genera su propia base de tiempo.

### Bloque 1: Subsistema discreto
- Decidir de forma pseudoaleatoria cuál de las ocho posiciones corresponde al topo en cada turno.
- Indicar visualmente la posición generada.
- Transmitir dicha posición al subsistema de control mediante un enlace serial (TX).

### Bloque 2: Subsistema de control (FPGA)
- Administrar la lógica del juego como turnos, ventana de tiempo, dificultad progresiva, conteo de aciertos/fallos, vidas y reinicio.
- Desplegar el marcador.


## Descripciones
### Bloque 1: Subsistema discreto
Genera una nueva posición pseudoaleatoria de 3 bits para cada solicitud recibida, la muestra
mediante un LED individual y la transmite en formato serial al subsistema de control.

**Entradas**
- `solicitud_topo`: Viene de FPGA; Pulso que ordena avanzar a una nueva posición.
- `VCC`: Viene de la fuente; Alimentación de 5 V de la fuente.

**Salidas**
- `pos_topo[7:0]`: Va al jugador; Son 8 bits porque son 8 LEDs. Un LED encendido significa que esa es la posición.
- `TX`: Va hacia la FPGA; Línea serial que contiene la posición generada.

`clk` NO aparece como una entrada porque el enunciado dice que no se pueden compartir relojes entre estos dos subsistemas.
El bloque tiene que avanzar una sola vez por cada solicitud y no de forma continua. Como la solicitud llega
asíncrona respecto a la base de tiempo local, hace falta lógica de control interna que la convierta en un
único evento de avance.

Una vez que se genera la posición, se entrega a dos lados. Por un lado a la indicación visual,
que enciende el LED que toca. Por el otro al transmisor serial, que la empaqueta en una trama y la manda a la FPGA.
El LED activo se queda encendido hasta que llegue la siguiente solicitud, así que siempre hay exactamente
una posición visible. El subsistema discreto nunca se entera de si el jugador acertó o falló, y tampoco lo necesita.

### Bloque 2: Subsistema de control (FPGA)
Implementa toda la lógica del juego a partir de la posición recibida y de las
pulsaciones del jugador, y presenta el marcador y el estado de la partida.

**Entradas**
- `clk`: Viene de la Tarjeta; Reloj único de 100 MHz, referencia de tiempo de todo el subsistema.
- `rst`: Viene del botón en la FPGA; Reinicia el juego de forma manual en cualquier momento.
- `btn_golpe[7:0]`: Viene del jugador; Son 8 bits porque son 8 pulsadores externos, uno por posición, conectados por GPIO en líneas independientes.
- `TX`: Viene de la protoboard; Línea serial que trae la posición del topo.

**Salidas**
- `solicitud_topo`: Va hacia la protoboard; Pulso que pide una nueva posición al inicio de cada turno.
- `display[3:0]`: Va hacia el jugador; Son 4 displays de 7 seg, dos dígitos para los aciertos acumulados y dos para los fallos acumulados. Debería de ir desde 0 a 99.
- `led_estado`: Va hacia el jugador; Indica si la partida está activa o terminada (1 bit).

Este subsistema es el que coordina la secuencia del juego. Ninguna otra parte decide cuándo pedir un topo
ni qué cuenta como acierto. Sus entradas externas, o sea los pulsadores y el botón de reinicio, vienen de
fuentes que no tienen relación con el reloj de 100 MHz, así que antes de usarlas hay que pasarlas por una
etapa de acondicionamiento que resuelva la metaestabilidad y los rebotes.


### Interfaz

- `TX`: Protoboard -> FPGA; Trama UART 8N1 de 1 bit de inicio, 8 bits de datos y 1 bit de parada. La posición del topo va en los 3 bits menos significativos y los 5 restantes se fijan en cero.
- `solicitud_topo`: FPGA -> Protoboard; Pulso simple en línea dedicada que indica el evento de siguiente topo. No es una trama serial.

El enlace serial no es como tal un tercer subsistema. El transmisor se implementa con lógica
discreta dentro del protoboard y el receptor se describe en SystemVerilog dentro de la FPGA.
