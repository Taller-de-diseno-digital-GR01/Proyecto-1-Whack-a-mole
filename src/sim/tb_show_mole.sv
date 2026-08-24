`timescale 1ns / 1ps

module m02_show_mole_tb;

    logic [2:0] pos_topo;
    logic       en_topo;
    logic [7:0] leds_topo;

    m02_show_mole dut (
        .pos_topo  (pos_topo),
        .en_topo   (en_topo),
        .leds_topo (leds_topo)
    );

    initial begin

    
        
        // PRUEBA 1:
        // en_topo desactivado
        // Ninguna posicion debe encender LED
   

        en_topo = 0;

        for (int i = 0; i < 8; i++) begin
            pos_topo = i;
            #10;
        end


        
        // PRUEBA 2:
        // en_topo activado
        // Cada posicion debe encender su LED
        

        en_topo = 1;

        for (int i = 0; i < 8; i++) begin
            pos_topo = i;
            #10;
        end


        
        // PRUEBA 3:
        // Volvemos a desactivar
        

        en_topo = 0;
        pos_topo = 3'b111;

        #10;


        $finish;

    end

endmodule