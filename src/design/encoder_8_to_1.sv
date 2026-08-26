
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
    output logic        valid_out

);
    logic [7:0] btn_in;
    assign btn_in = {btn_7, btn_6, btn_5, btn_4, btn_3, btn_2, btn_1, btn_0};

    always_comb begin
        // valid_out solo se activa con exactamente un botón presionado.
        // Antes se calculaba como |btn_in (cualquier botón activo), así
        // que si dos botones caían presionados al mismo tiempo (o se
        // solapaba el rebote de dos líneas), btn_out caía en el default
        // (3'b000) pero valid_out igual quedaba en 1 -- registrando un
        // intento fantasma sobre la posición 0.
        valid_out = 1'b1;
        case(btn_in)
            8'b00000001: btn_out = 3'b000;
            8'b00000010: btn_out = 3'b001;
            8'b00000100: btn_out = 3'b010;
            8'b00001000: btn_out = 3'b011;
            8'b00010000: btn_out = 3'b100;
            8'b00100000: btn_out = 3'b101;
            8'b01000000: btn_out = 3'b110;
            8'b10000000: btn_out = 3'b111;
        default: begin
            btn_out   = 3'b000; // ningún botón, o más de uno a la vez
            valid_out = 1'b0;
        end
        endcase
    end
    
        
endmodule