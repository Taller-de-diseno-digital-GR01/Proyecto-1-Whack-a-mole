
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
        valid_out = |btn_in;
        case(btn_in)
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