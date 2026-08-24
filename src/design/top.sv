module top (
    input logic clk,
    input logic rst,

    //Entradas Externas de press_btn
    input logic       btn_0,
    input logic       btn_1,
    input logic       btn_2,
    input logic       btn_3,
    input logic       btn_4,
    input logic       btn_5,
    input logic       btn_6,
    input logic       btn_7,



    //Entrada Externa de UART
    input logic       pos,    //serial

    //Salidas State
    output logic led_state,

    //Salida show_mole
    output logic [7:0] leds_topo,

    //Salida Externa fsm (flags)
    output logic        f_state_play,
    output logic        f_state_gameover,

    //Salida Externas a 7 segmentosd
    output logic [6:0]  sev_seg_failures,
    output logic [6:0]  sev_seg_hits_dec, //decenas del hit
    output logic [6:0]  sev_seg_hits_uni, //unidades del hit

    //Salida al circuito discreto:
    output logic        en_numRandom //Señal que activa el circuito discreto

);
    // Señales internas

    //state a fsm
    logic       w_fin_espera;

    // r_uart al resto
    logic [2:0] w_pos_topo;
    logic       w_valid_pos;

    // press_btn a fsm
    logic       w_hit_press;   // "valid" de press_btn: botón correcto
    logic       w_miss_press;  // botón incorrecto

    // fsm -a control
    logic       w_rst_dificulty;
    logic       w_rst_hits;
    logic       w_rst_failures;
    logic       w_rst_window;
    logic       w_en_save_pos;
    logic       w_add_hit;
    logic       w_add_failure;
    logic       w_inc_dificulty;  // quizás no hace falta, debido a hit...
    logic [2:0] w_current_state;  // no expuesto en los puertos del top

    // time_logic a fsm
    logic       w_window_exp;

    // fail_counter a fsm
    logic       w_fin_partida;


    //Agregpo estas para cuando se implemente el modulo
    // contadores BCD
    logic [7:0] w_acierto; // [3:0]=unidades, [7:4]=decenas
    logic [7:0] w_fallo;   // [3:0]=unidades, [7:4]=decenas

//TODO: Falta hacer el módulo de BCD!!!
    // M1: Receptor UART -> entrega pos_topo y valid_pos
    r_uart u_r_uart (
        .clk         (clk),
        .rst         (rst),
        .pos         (pos),
        .en_save_pos (w_en_save_pos),
        .pos_topo    (w_pos_topo),
        .valid_pos   (w_valid_pos)
    );

    
    // M2: Botones (debounce + encoder + check_btn) -> hit / miss
    press_btn u_press_btn (
        .clk      (clk),
        .rst      (rst),
        .btn_0    (btn_0),
        .btn_1    (btn_1),
        .btn_2    (btn_2),
        .btn_3    (btn_3),
        .btn_4    (btn_4),
        .btn_5    (btn_5),
        .btn_6    (btn_6),
        .btn_7    (btn_7),
        .pos_topo (w_pos_topo),
        .valid    (w_hit_press),
        .miss     (w_miss_press)
    );

    // M3: FSM principal
    fsm u_fsm (
        .clk               (clk),
        .rst               (rst),
        .valid_pos         (w_valid_pos), //da el valor de posición
        .hit               (w_hit_press), //le dió al top
        .miss              (w_miss_press), //NO le dió al top
        .window_exp        (w_window_exp), //avisa que paso el tiempo
        .cont_failure      (w_fin_partida), //psa a gameover al llegar a 3 fallso
        .fin_espera        (w_fin_espera), //Es para pasar a START de nuevo

        .rst_dificulty     (w_rst_dificulty), //resetea la ventana de tiempo
        .rst_hits          (w_rst_hits), //resetea ek contador
        .rst_failures      (w_rst_failures), //resetea los fallos
        .en_numRandom      (en_numRandom), //este activa el circuito discreto
        .en_save_pos       (w_en_save_pos), //almacena el valor
        .add_hit           (w_add_hit), //añade el acierto
        .add_failure       (w_add_failure), //añade el fallo
        .rst_window        (w_rst_window), //resetea el tiempo ?
        .inc_dificulty     (w_inc_dificulty), //no se si se usa...
        .current_state_out (w_current_state), 

        .f_state_play      (f_state_play),
        .f_state_gameover  (f_state_gameover)
    );


    // M4: Lógica de tiempo / ventana de reacción
    time_logic u_time_logic (
    .clk           (clk),
    .rst_dificulty (w_rst_dificulty),
    .rst_window    (w_rst_window),
    .inicio        (w_valid_pos),
    .hit           (w_add_hit),
    .nueva_partida (1'b0),
    .UP            (w_window_exp)
);

    
    // M5: Contador de aciertos (BCD)

    hit_counter u_hit_counter (
        .clk           (clk),
        .rst           (w_rst_hits),
        .nueva_partida (1'b0), //no lo estamos usando
        .hit           (w_add_hit),
        .acierto       (w_acierto)
    );

    
    // M6: Contador de fallos (BCD) + detección de fin de partida

    fail_counter u_fail_counter (
        .clk           (clk),
        .rst           (w_rst_failures),
        .miss          (w_add_failure),
        .hit           (w_add_hit),
        .nueva_partida (1'b0), //no lo estamos usasndo
        .fallo         (w_fallo),
        .fin_partida   (w_fin_partida)
    );

    // M7: Despliegue del topo en LEDs (Reutilizé el flag f_state_play solo marca ekl topo en PLAY)

    show_mole u_show_mole (
        .pos_topo  (w_pos_topo),
        .en_topo   (f_state_play),
        .leds_topo (leds_topo)
    );

    state u_state (
        .clk(clk),
        .rst(rst),
        .f_state_play(f_state_play),
        .f_state_gameover(f_state_gameover),
        .led_state(led_state),
        .fin_espera(w_fin_espera)


    );

endmodule