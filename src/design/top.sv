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



endmodule