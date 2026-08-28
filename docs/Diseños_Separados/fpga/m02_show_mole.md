
### M2: Show_Mole



## f) Relación con otros módulos

El módulo recibe la señal pos_topo[2:0] desde el registro UART despues de haber sido generado. Luego, la máquina de estados (FSM) se encarga de indicar cuando se puede encender la matriz de leds, mediante la señal en_topo. 

## g) Explicación de funcionamiento

El módulo Show_Mole opera como un decodificador combinacional de 3 a 8 bits con entrada de habilitación (Enable). Su función principal es traducir la posición codificada en binario pos_topo[2:0] a una representación en bus de 8 bits donde un solo bit se encuentra activo (one-hot), permitiendo encender un único LED de la matriz 4x2 a la vez.

## h) Diseño

El diseño de este módulo se puede subdividir fácilmente en una parte de control que activan o desactiva la matriz de leds que muestran la posición del topo, y por otro lado se tiene un decodificador 3 a 8 que convierte la información dada por pos_topo[2:0] en una señal que activa el led correspondiente. Los leds están distribuidos de la siguiente forma:


#### Mapeo Físico de la Matriz

| | Columna 0 | Columna 1 |
| :---: | :---: | :---: |
| **Fila 0** | **LED 0** (`000`) | **LED 1** (`001`) |
| **Fila 1** | **LED 2** (`010`) | **LED 3** (`011`) |
| **Fila 2** | **LED 4** (`100`) | **LED 5** (`101`) |
| **Fila 3** | **LED 6** (`110`) | **LED 7** (`111`) |

---



La siguiente tabla detalla la lógica de decodificación tipo one-hot con activación por señal de enable. 

**Nota:** L# indica el led que se enciende. 


| **en_topo** | **pos_topo[2]** | **pos_topo[1]** | **pos_topo[0]** | **L7** | **L6** | **L5**| **L4** | **L3** | **L2** | **L1** | **L0** | **Estado** |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **0** | X | X | X | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | Apagados (Sin topo) |
| **1** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **1** | LED 0 encendido |
| **1** | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | **1** | 0 | LED 1 encendido |
| **1** | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | **1** | 0 | 0 | LED 2 encendido |
| **1** | 0 | 1 | 1 | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | LED 3 encendido |
| **1** | 1 | 0 | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | 0 | LED 4 encendido |
| **1** | 1 | 0 | 1 | 0 | 0 | **1** | 0 | 0 | 0 | 0 | 0 | LED 5 encendido |
| **1** | 1 | 1 | 0 | 0 | **1** | 0 | 0 | 0 | 0 | 0 | 0 | LED 6 encendido |
| **1** | 1 | 1 | 1 | **1** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | LED 7 encendido |

## i) Diagrama detallado del diseño

```mermaid
flowchart LR
    %% Entradas
    pos["pos_topo[2:0]"]
    en["en_topo"]

    subgraph Logica_Combinacional ["Lógica Combinacional (always_comb)"]
        direction TB
        DEC["Decodificador 3 a 8 bits<br/>(One-Hot)"]
        DEFAULT["Asignación por defecto:<br/>leds = 8'b0000_0000"]
    end

    %% Salidas
    out_leds["leds_topo[7:0]"]

    %% Conexiones
    pos --> DEC
    en -->|Habilita (si es 1)| DEC
    en -->|Apaga (si es 0)| DEFAULT
    
    DEC --> out_leds
    DEFAULT --> out_leds
```