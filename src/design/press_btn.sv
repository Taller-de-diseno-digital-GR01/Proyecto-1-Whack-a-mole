module press_btn ( //módulo principal
    input logic       clk,
    input logic       rst,
    input logic       btn_0,
    input logic       btn_1,
    input logic       btn_2,
    input logic       btn_3,
    input logic       btn_4,
    input logic       btn_5,
    input logic       btn_6,
    input logic       btn_7,
    input logic [2:0] pos_topo,

    output logic      valid,
    output logic      miss
);


    logic db_btn_0;
    logic db_btn_1;
    logic db_btn_2;
    logic db_btn_3;
    logic db_btn_4;
    logic db_btn_5;
    logic db_btn_6;
    logic db_btn_7;
    
    logic [2:0] enc_btn_in;
    logic       valid_enc;

    // Flanco de subida de valid_enc: un pulso de un ciclo justo cuando el
    // botón queda presionado (post-debounce), sin importar cuánto tiempo
    // se mantenga abajo después. Antes check_btn se re-evaluaba en cada
    // ciclo mientras el botón seguía abajo (valid_in=valid_enc, en nivel),
    // así que si pos_topo cambiaba mientras el dedo todavía estaba sobre
    // el botón -- cosa que pasa seguido, la FSM pide/recibe la posición
    // siguiente en ~1ms de UART, mucho antes de que sueltes el botón --
    // la comparación se repetía contra el topo NUEVO y disparaba un miss
    // fantasma inmediatamente después de un hit correcto.
    logic       valid_enc_prev;
    logic       press_pulse;

    always_ff @(posedge clk) begin
        if (rst) valid_enc_prev <= 1'b0;
        else     valid_enc_prev <= valid_enc;
    end

    assign press_pulse = valid_enc & ~valid_enc_prev;

    debounce db0 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_0),
        .db_out(db_btn_0)
    );
    debounce db1 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_1),
        .db_out(db_btn_1)
    );
    debounce db2 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_2),
        .db_out(db_btn_2)
    );
    debounce db3 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_3),
        .db_out(db_btn_3)
    );
    debounce db4 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_4),
        .db_out(db_btn_4)
    );
    debounce db5 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_5),
        .db_out(db_btn_5)
    );
    debounce db6 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_6),
        .db_out(db_btn_6)
    );
    debounce db7 (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_7),
        .db_out(db_btn_7)
    );

    encoder_8_to_1 enc (
        .btn_0(db_btn_0),
        .btn_1(db_btn_1),
        .btn_2(db_btn_2),
        .btn_3(db_btn_3),
        .btn_4(db_btn_4),
        .btn_5(db_btn_5),
        .btn_6(db_btn_6),
        .btn_7(db_btn_7),
        .btn_out(enc_btn_in),
        .valid_out(valid_enc)
    );


    // valid_in ya es un pulso de un ciclo (press_pulse), así que check_btn
    // compara enc_btn_in contra el pos_topo vigente en ese único ciclo y
    // valid/miss salen directo como pulsos -- no hace falta otro detector
    // de flanco después, y pos_topo ya no puede cambiar "debajo" de un
    // botón que sigue presionado porque solo se mira una vez, al inicio.
    check_btn cb (
        .enc_btn_in(enc_btn_in),
        .pos_topo(pos_topo),
        .valid_in(press_pulse),
        .valid(valid),
        .miss(miss)
    );

endmodule