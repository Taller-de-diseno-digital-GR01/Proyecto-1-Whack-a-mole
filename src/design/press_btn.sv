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

    logic       valid_lvl, miss_lvl; // salidas de check_btn, en nivel (dura mientras el botón está abajo)
    logic       valid_prev, miss_prev;

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


    check_btn cb (
        .enc_btn_in(enc_btn_in),
        .pos_topo(pos_topo),
        .valid_in(valid_enc),
        .valid(valid_lvl),
        .miss(miss_lvl)
    );

    // Flanco de subida: un pulso de un ciclo por presión, sin importar
    // cuánto tiempo el botón se mantenga abajo (valid_lvl/miss_lvl duran
    // todo el tiempo que el botón está físicamente presionado)
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_prev <= 1'b0;
            miss_prev  <= 1'b0;
        end else begin
            valid_prev <= valid_lvl;
            miss_prev  <= miss_lvl;
        end
    end

    assign valid = valid_lvl & ~valid_prev;
    assign miss  = miss_lvl  & ~miss_prev;

endmodule