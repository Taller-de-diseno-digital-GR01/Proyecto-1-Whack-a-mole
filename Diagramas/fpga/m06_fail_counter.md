# M6: fail_counter

## f) Relación con otros módulos

El módulo recibe de la FSM el pulso `miss` cada vez que un turno se resuelve como fallo, ya sea porque el jugador presionó un botón incorrecto o porque `time_logic` reportó `UP` al agotarse la ventana, de modo que M6 no distingue entre ambas causas y solo cuenta el evento. También recibe el mismo pulso `hit` que consumen `time_logic` y `hit_counter`, con el cual pone en cero la cuenta de fallos consecutivos sin tocar el acumulado. Su salida `fallo[7:0]` alimenta los dos displays de fallos del módulo `marcador`, que solo debe decodificar cada dígito a siete segmentos, y su salida `fin_partida` avisa a la FSM que se alcanzó el tercer fallo consecutivo para que esta transite al estado de fin de partida. La FSM devuelve `nueva_partida` al arrancar una partida nueva, lo cual pone en cero ambas cuentas.

## g) Explicación de funcionamiento

El módulo mantiene dos cuentas independientes que avanzan con el mismo pulso `miss`. La primera es un contador BCD de dos dígitos que acumula los fallos de la partida y se despliega en el marcador, donde el dígito de unidades ocupa `fallo[3:0]` y el de decenas `fallo[7:4]`, con saturación en 99 para que nunca se muestre un valor fuera del ámbito especificado. La segunda es un contador de fallos consecutivos de dos bits que llega hasta tres, no se despliega y existe únicamente para determinar el final de la partida, por lo que se pone en cero ante cualquier pulso `hit` mientras el acumulado permanece intacto. Cuando esa cuenta consecutiva alcanza el valor tres se activa `fin_partida`, señal que se mantiene hasta que `rst` o `nueva_partida` reinicien el módulo, de manera que la FSM dispone de una condición estable y no de un pulso que pueda perderse.

## h) Diseño

La cuenta acumulada se lleva directamente en BCD por la misma razón que en `hit_counter`, ya que su destino son dos displays de siete segmentos independientes y una cuenta binaria obligaría a intercalar un convertidor del tipo double dabble antes del marcador. Se decide alojar el contador de fallos consecutivos en este módulo y no dentro de la FSM porque así el control path conserva únicamente la lógica de transición entre estados y todos los elementos de conteo quedan en el datapath, lo cual mantiene la FSM pequeña y verificable. Los pulsos `hit` y `miss` son mutuamente excluyentes dentro de un mismo turno porque la FSM resuelve cada turno de una sola manera, aun así se le asigna prioridad a `hit` en la descripción para que la cuenta consecutiva quede definida ante cualquier condición y no se infieran latches. Ambos contadores usan los pulsos como habilitación y no como reloj, con lo cual el módulo permanece en el dominio del reloj de 100 MHz.

Contador acumulado de fallos, transición ante un pulso `miss`:

| `fallo[7:4]` | `fallo[3:0]` | Siguiente `fallo[7:4]` | Siguiente `fallo[3:0]` |
|---|---|---|---|
| 0 a 9 | 0 a 8 | sin cambio | `fallo[3:0]` + 1 |
| 0 a 8 | 9 | `fallo[7:4]` + 1 | 0 |
| 9 | 9 | 9 | 9 |

Contador de fallos consecutivos y generación de `fin_partida`:

| `rst` o `nueva_partida` | `hit` | `miss` | Cuenta actual | Cuenta siguiente | `fin_partida` |
|---|---|---|---|---|---|
| 1 | X | X | X | 0 | 0 |
| 0 | 1 | X | X | 0 | 0 |
| 0 | 0 | 1 | 0 a 1 | cuenta + 1 | 0 |
| 0 | 0 | 1 | 2 | 3 | 1 |
| 0 | 0 | 1 | 3 | 3 | 1 |
| 0 | 0 | 0 | X | sin cambio | sin cambio |

## i) Diagrama detallado del diseño

``mermaid
flowchart LR
    miss[miss] --> E
    S["Comparador de saturación<br/>decenas = 9 y unidades = 9"] --> E
    E["Habilitación de conteo"] --> U
    U["Contador BCD<br/>unidades"] -->|unidades = 9| CY["Acarreo"]
    E --> CY
    CY --> D["Contador BCD<br/>decenas"]
    U --> S
    D --> S
    U --> ou["fallo[3:0]"]
    D --> od["fallo[7:4]"]
    miss --> K["Contador de fallos<br/>consecutivos, 2 bits"]
    hit[hit] --> K
    K --> C3["Comparador<br/>cuenta = 3"]
    C3 --> FP["Biestable de<br/>fin de partida"]
    FP --> fp[fin_partida]
    rst[rst] --> U
    rst --> D
    rst --> K
    rst --> FP
    np[nueva_partida] --> U
    np --> D
    np --> K
    np --> FP
``
