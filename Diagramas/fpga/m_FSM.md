# M8: Máquina de Estados FSM

Objetivo: controlar el flujo de datos del sistema digital, entregando señales de control a los diferentes módulos dependiendo de las entradas que reciba el sistema.

## Entradas:
- reset: Reinicia el sistema al estado inicial.
- sol_pos: Solicitud de nueva posición del topo.
- valid_pos: Se recibe una nueva posición del topo.
- bot_pos: Señal que confirma que apretó el botón correspondiente a la posición del topo.
- window_exp: Señal que indica que expiró la ventana de tiempo.
- cont_fallo: Señal que indica que se llega al máximo de fallos (3 fallos).

## Salidas:
Estado 000
- rst_dificultad: Reinicia el nivel de dificultad del juego.
- rst_aciertos: Reinicia el contador de aciertos acumulados a cero.
- rst_fallos: Reinicia el contador de fallos a cero.
- rst_window: Reinicia la ventana de tiempo del juego. 
Estado 001
- en_numAleatorios: Permite activar el sistema de generación de posiciones aleatorios.
Estado 010
- en_save_pos: Habilita registrar/guardar la posición del topo que se recibe vía UART.
Estado 100
- add_acierto: Incrementa en +1 el contador de aciertos.
- rst_fallo: Reinicia el contador de fallos.
- inc_dificultad: Incrementa el nivel de dificultad, reduciendo la ventana de tiempo.
Estado 101:
- add fallo: Incrementa en +1 el contador de fallos.


## Descipción general:

Esta FSM actúa como el controlador central de un juego interactivo de velocidad y reacción con comunicación serial. Su diseño sigue una arquitectura de máquina de Moore, donde las salidas de control se activan en función del estado en el que se encuentre el sistema para gobernar la ruta de datos. El ciclo de la partida comienza en el estado de inicio, donde el controlador limpia los contadores de aciertos y fallos, restaura el nivel de dificultad base y reinicia el temporizador del sistema. A partir de ahí, la máquina avanza hacia la fase de generación del desafío: habilita un módulo que produce una nueva posición aleatoria y, tras enviar la solicitud, pasa a un estado de espera por la interfaz UART. En cuanto la posición es recibida y validada, habilita su guardado en memoria y transiciona inmediatamente al estado de juego. Durante la fase de juego, el controlador monitorea la respuesta del jugador. Si el usuario presiona la posición correcta a tiempo, el sistema avanza al estado de acierto, donde incrementa la puntuación, limpia los fallos acumulados, aumenta el nivel de dificultad para la siguiente ronda y regresa a generar un nuevo punto aleatorio. Por el contrario, si el jugador presiona un botón equivocado o si la ventana de tiempo expira, la FSM se mueve al estado de fallo e incrementa el contador de errores. En este punto de fallo, el sistema evalúa la condición de la partida: si el conteo de errores aún no alcanza el límite permitido, le da otra oportunidad al jugador retornando a la generación de posición. Sin embargo, si el contador sobrepasa el límite de errores, la máquina conmuta al estado final. En este último estado, el controlador bloquea la ejecución y detiene la partida a la espera de una señal de reinicio manual que restablezca todo el flujo desde el principio.


## Diagrama de Estados:

![alt text](image-1.png)