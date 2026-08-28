`timescale 1ns/1ps

module tb_estado_juego;

    // N_PRESC pequeño para simulación: tick_100ms cada 10 ciclos
    // en vez de 10,000,000. WAIT_COUNT interno del DUT sigue en 20,
    // así que fin_espera llega a los 20*10 = 200 ciclos.
    localparam int TB_N_PRESC = 10;

    logic clk;
    logic rst;
    logic f_state_play;
    logic f_state_gameover;
    logic led_state;
    logic fin_espera;

    int errors = 0;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    state #(
        .N_PRESC(TB_N_PRESC)
    ) dut (
        .clk              (clk),
        .rst              (rst),
        .f_state_play     (f_state_play),
        .f_state_gameover (f_state_gameover),
        .led_state        (led_state),
        .fin_espera       (fin_espera)
    );

    // ------------------------------------------------------------
    // Reloj: 100 MHz -> periodo 10 ns
    // ------------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Tarea de verificación puntual
    // ------------------------------------------------------------
    task automatic check(string label, logic exp_led, logic exp_fin);
        if (led_state !== exp_led) begin
            $display("[%0t] FALLO (%s): led_state=%b esperado=%b",
                      $time, label, led_state, exp_led);
            errors++;
        end
        if (fin_espera !== exp_fin) begin
            $display("[%0t] FALLO (%s): fin_espera=%b esperado=%b",
                      $time, label, fin_espera, exp_fin);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("tb_state.vcd");
        $dumpvars(0, tb_estado_juego);

        clk = 0;
        rst = 1;
        f_state_play = 0;
        f_state_gameover = 0;
        @(posedge clk);
        @(posedge clk);
        check("reset", 1'b0, 1'b0);

        // ------------------------------------------------------------
        // Caso (0,0): reposo
        // ------------------------------------------------------------
        rst = 0;
        @(posedge clk);
        check("reposo", 1'b0, 1'b0);

        // ------------------------------------------------------------
        // Caso (1,0): partida activa -> LED fijo encendido
        // ------------------------------------------------------------
        f_state_play = 1;
        f_state_gameover = 0;
        @(posedge clk);
        check("partida activa", 1'b1, 1'b0);
        repeat (15) @(posedge clk);
        check("partida activa sostenida", 1'b1, 1'b0);

        // ------------------------------------------------------------
        // Caso (1,1): combinación inválida -> apagado seguro
        // ------------------------------------------------------------
        f_state_play = 1;
        f_state_gameover = 1;
        @(posedge clk);
        check("caso invalido", 1'b0, 1'b0);
        repeat (25) @(posedge clk);  // más que un tick completo
        check("caso invalido sostenido, sin fin_espera", 1'b0, 1'b0);

        // volver a reposo antes de probar fin de partida real
        f_state_play = 0;
        f_state_gameover = 0;
        @(posedge clk);

        // ------------------------------------------------------------
        // Caso (0,1): fin de partida -> parpadeo + fin_espera a los 2s
        // Con TB_N_PRESC=10, cada tick_100ms cae cada 10 ciclos.
        // El biestable de parpadeo conmuta cada 2 ticks (cada 20 ciclos).
        // fin_espera debe pulsar en el ciclo del tick número 20
        // (20 * 10 = 200 ciclos después de entrar a fin_espera).
        // ------------------------------------------------------------
        f_state_gameover = 1;
        @(posedge clk);
        check("entra a fin de partida, LED aun sin primer toggle", 1'b0, 1'b0);

        // Verificar el primer cambio de parpadeo tras 2 ticks (20 ciclos)
        repeat (20) @(posedge clk);
        check("primer toggle de parpadeo", 1'b1, 1'b0);

        repeat (20) @(posedge clk);
        check("segundo toggle de parpadeo", 1'b0, 1'b0);

        // Avanzar hasta justo antes del tick 20 (fin_espera)
        // ya van 40 ciclos consumidos desde que entro a gameover,
        // faltan (200 - 40 - 10) = 150 ciclos para llegar al ciclo
        // exacto del tick 20 (dejamos 10 para el ultimo @(posedge clk) del check)
        repeat (149) @(posedge clk);
        check("un ciclo antes de fin_espera", led_state, 1'b0);

        @(posedge clk);
        check("pulso de fin_espera en el tick 20", led_state, 1'b1);

        @(posedge clk);
        check("fin_espera regresa a 0 el ciclo siguiente", led_state, 1'b0);

        // Verificar que el contador satura y NO vuelve a pulsar fin_espera
        repeat (100) @(posedge clk);
        check("fin_espera no se repite tras saturar", led_state, 1'b0);

        // ------------------------------------------------------------
        // Salir de fin de partida -> vuelve a reposo, todo en cero
        // ------------------------------------------------------------
        f_state_gameover = 0;
        @(posedge clk);
        check("regreso a reposo tras fin de partida", 1'b0, 1'b0);

        // ------------------------------------------------------------
        // rst en medio de una cuenta de fin de partida
        // ------------------------------------------------------------
        f_state_gameover = 1;
        repeat (35) @(posedge clk);  // deja el contador a medio camino
        rst = 1;
        @(posedge clk);
        check("rst interrumpe fin de partida en curso", 1'b0, 1'b0);
        rst = 0;

        // ------------------------------------------------------------
        // Resumen
        // ------------------------------------------------------------
        if (errors == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON ***\n");
        else
            $display("\n*** %0d PRUEBA(S) FALLARON ***\n", errors);

        $finish;
    end

endmodule