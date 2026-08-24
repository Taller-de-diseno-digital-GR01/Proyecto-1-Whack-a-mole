module check_btn (
    input logic [2:0] enc_btn_in,
    input logic [2:0] pos_topo,
    input logic       valid_in,
    output logic valid,
    output logic miss
);
    //Usaré dos señales que me permite verificar si funcionan las señales de entrada de los botones.
    //btn_valid: verifica que la señal calza con la posición asignada al topo
    //right_btn: proviene del encoder después de verificar si se presionó o no un botón
    //miss: se presionó un botón válido (valid_in) pero que NO corresponde a la posición del topo
    always_comb begin
        if (valid_in && (enc_btn_in == pos_topo)) begin
            valid = 1'b1;
            miss  = 1'b0;
        end else if (valid_in && (enc_btn_in != pos_topo)) begin
            valid = 1'b0;
            miss  = 1'b1;
        end else begin
            valid = 1'b0;
            miss  = 1'b0;
        end
    end


endmodule