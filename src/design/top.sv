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
    //Salidas:

    //Salida show_mole
    output logic [7:0] leds_topo,

    //Salida Externa fsm (flags)
    output logic        f_state_play,
    output logic        f_state_gameover,

    //Salida Externas a 7 segmentosd
    output logic [6:0]  sev_seg_failures,
    output logic [6:0]  sev_seg_hits_dec,
    output logic [6:0]  sev_seg_hits_uni

);
    // Señales internas

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
    logic       w_en_numRandom;   // sin pin de salida en este top: habilita al subsistema
                                   // discreto que genera la posición (no incluido en estos
                                   // archivos). Se deja como wire interno.
    logic       w_en_save_pos;
    logic       w_add_hit;
    logic       w_add_failure;
    logic       w_inc_dificulty;  // informativo, no lo consume ningún módulo de este set
    logic [2:0] w_current_state;  // no expuesto en los puertos del top

    // time_logic a fsm
    logic       w_window_exp;

    // fail_counter a fsm
    logic       w_fin_partida;

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
        .valid_pos         (w_valid_pos),
        .hit               (w_hit_press),
        .miss              (w_miss_press),
        .window_exp        (w_window_exp),
        .cont_failure      (w_fin_partida),

        .rst_dificulty     (w_rst_dificulty),
        .rst_hits          (w_rst_hits),
        .rst_failures      (w_rst_failures),
        .en_numRandom      (w_en_numRandom),
        .en_save_pos       (w_en_save_pos),
        .add_hit           (w_add_hit),
        .add_failure       (w_add_failure),
        .rst_window        (w_rst_window),
        .inc_dificulty     (w_inc_dificulty),
        .current_state_out (w_current_state),

        .f_state_play      (f_state_play),
        .f_state_gameover  (f_state_gameover)
    );


    // M4: Lógica de tiempo / ventana de reacción
    time_logic u_time_logic (
        .clk           (clk),
        .rst           (w_rst_window),
        .inicio        (w_valid_pos),
        .hit           (w_add_hit),
        .nueva_partida (1'b0),
        .UP            (w_window_exp)
    );

    
    // M5: Contador de aciertos (BCD)

    hit_counter u_hit_counter (
        .clk           (clk),
        .rst           (w_rst_hits),
        .nueva_partida (1'b0),
        .hit           (w_add_hit),
        .acierto       (w_acierto)
    );

    
    // M6: Contador de fallos (BCD) + detección de fin de partida

    fail_counter u_fail_counter (
        .clk           (clk),
        .rst           (w_rst_failures),
        .miss          (w_add_failure),
        .hit           (w_add_hit),
        .nueva_partida (1'b0),
        .fallo         (w_fallo),
        .fin_partida   (w_fin_partida)
    );

    // M7: Despliegue del topo en LEDs (solo visible durante PLAY)

    show_mole u_show_mole (
        .pos_topo  (w_pos_topo),
        .en_topo   (f_state_play),
        .leds_topo (leds_topo)
    );

endmodule