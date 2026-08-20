//Para el presente código se utilizó como referencia el siguiente código de Tony Storey, 
//el cual fue modificado para cumplir con los requerimientos del proyecto. Link: https://www.edaplayground.com/x/CtM4

module debounce(
    input logic clk,
    input logic rst, //Revisar rst de la FPGA
    input logic btn_in,

    output logic db_out

);

    parameter N = 21; //Quizás afecte el tiempo de simulación.

    reg [N-1:0] q_reg;
    reg [N-1:0] q_next;
    reg dff1, dff2;
    wire q_add;
    wire q_reset;

    assign q_reset = (dff1 ^ dff2); //Revisa si cambia el estado del boton de un ciclo a otro
    assign q_add = ~(q_reg[N-1]); //Le asigna 1 si el contador no ha llegado a su valor maximo


    always_comb begin
        case ({q_reset, q_add})
            2'b00: q_next = q_reg + 1; // q_reset = 0 - No hay cambios, q_add = 0 - no ha llegado al máximo
            2'b01: q_next = 0;// q_reset = 0 - No hay cambios, q_add = 1 - ha llegado al máximo
            default: q_next = {N{1'b0}}; //si ocurre un cambio en el estado del boton, se reinicia el contador a 0
        endcase 
    end

    //FFs de Entrada - Sincronizador de dos etapas
    always_ff @(posedge clk) begin
        if (rst == 1'b0) begin
            dff1 <= 1'b0;
            dff2 <= 1'b0;
            q_reg <= {N{1'b0}};
        end else begin
            dff1 <= btn_in;
            dff2 <= dff1;
            q_reg <= q_next;
        end
    end

    always_ff @(posedge clk) begin
        if(q_reg[N-1] == 1'b1) begin //Si el contador ha llegado a su valor maximo, se actualiza la salida del debounce
            db_out <= dff2;
        end
        else begin
            db_out <= db_out; //Mantiene el valor anterior
        end
    end
endmodule

module encoder_8_to_1 (
    input logic         btn_0,
    input logic         btn_1,
    input logic         btn_2,
    input logic         btn_3,
    input logic         btn_4,
    input logic         btn_5,
    input logic         btn_6,
    input logic         btn_7,
    output logic [2:0]  btn_out,
    output logic        valid

);
    logic [7:0] btn_in;
    assign btn_in = {btn_7, btn_6, btn_5, btn_4, btn_3, btn_2, btn_1, btn_0};

    always_comb begin
        valid = |btn_in; //aquí revisamoes si algun boton está activado
        case (btn_in)
            8'b00000001: btn_out = 3'b000;
            8'b00000010: btn_out = 3'b001;
            8'b00000100: btn_out = 3'b010;
            8'b00001000: btn_out = 3'b011;
            8'b00010000: btn_out = 3'b100;
            8'b00100000: btn_out = 3'b101;
            8'b01000000: btn_out = 3'b110;
            8'b10000000: btn_out = 3'b111;
            default: btn_out = 3'b000; //tenemos que revisar esto
        endcase
    end

endmodule

module check_btn (
    input logic [2:0] enc_btn_in;
    input logic [2:0] pos_topo; 
    input logic       valid;

    output logic right_btn;
);



    always_comb begin
        if (enc_btn_in == pos_topo) begin
            if(valid == 1'b1) begin
                right_btn = 1'b1;
            end else begin
                right_btn = 1'b0;
            end
            btn_valid = 1'b1;
        end else begin
            btn_valid = 1'b0;
        end
    end

endmodule

module press_btn ( //módulo principal
    input logic clk;
    input logic rst;
    input logic [2:0] btn_0;
    input logic [2:0] btn_1;
    input logic [2:0] btn_2;
    input logic [2:0] btn_3;
    input logic [2:0] btn_4;
    input logic [2:0] btn_5;
    input logic [2:0] btn_6;
    input logic [2:0] btn_7;
    input logic [2:0] pos_topo;

    output logic right_btn;
);
    wire db_btn_0;
    wire db_btn_1;
    wire db_btn_2;
    wire db_btn_3;
    wire db_btn_4;
    wire db_btn_5;
    wire db_btn_6;
    wire db_btn_7;
    
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
        .btn_out(enc_btn_out),
        .valid(valid)
    );


    check_btn cb (
        .btn_in(enc_btn_out),
        .pos_topo(pos_topo),
        .valid(valid),
        .right_btn(right_btn)
    );

endmodule