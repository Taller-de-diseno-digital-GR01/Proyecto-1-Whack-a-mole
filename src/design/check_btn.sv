module check_btn (
    input logic [2:0] enc_btn_in,
    input logic [2:0] pos_topo,
    input logic       valid_in,
    output logic valid
);
    //Usaré dos señales que me permite verificar si funcionan las señales de entrada de los botones.
    //Asigno hit que solo será 1 si se selecciono un botón y es igual a ala posición
    //Asigno fail que solo será 1 si se falla la posición pero si existe un botón presionado.
    always_comb begin
        hit = valid_in && (enc_btn_in == pos_topo);
        miss = valid_in && (enc_btn_in != pos_topo);
    end


endmodule