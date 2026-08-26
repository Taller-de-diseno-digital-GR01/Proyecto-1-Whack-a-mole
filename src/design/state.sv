module state #(
    parameter int N_PRESC   = 10_000_000, // ciclos por tick de 100ms (100e6 * 0.1)
    parameter int WAIT_COUNT = 20         // ticks de 100ms a esperar en GAME_OVER (20*100ms=2s)
) (
    input  logic clk,              // 100 MHz
    input  logic rst,              // reset síncrono, activo en alto
    input  logic f_state_play,     // partida activa
    input  logic f_state_gameover, // fin de partida

    output logic led_state,        // salida única al LED físico
    output logic fin_espera        // pulso de un ciclo hacia la FSM
);

    // ------------------------------------------------------------
    // Prescalador: genera una habilitación de un ciclo cada 100 ms
    // Por defecto N = 100e6 * 0.1 = 10_000_000 -> requiere 24 bits
    // ------------------------------------------------------------
    logic [$clog2(N_PRESC)-1:0] presc_cnt;
    logic        tick_100ms;

    // Se reinicia con la misma condición que wait_cnt (reposo o partida
    // activa): si corriera libre, el primer tick tras entrar a
    // GAME_OVER podría caer casi de inmediato según la fase en que
    // haya quedado, acortando la espera real por debajo del mínimo de
    // 2s exigido. Al reiniciarlo junto con wait_cnt, cada espera de fin
    // de partida arranca su propio conteo de 100ms desde cero.
    always_ff @(posedge clk) begin
        if (rst) begin
            presc_cnt <= '0;
        end else if (f_state_play || (!f_state_play && !f_state_gameover)) begin
            presc_cnt <= '0;
        end else if (presc_cnt == N_PRESC - 1) begin
            presc_cnt <= '0;
        end else begin
            presc_cnt <= presc_cnt + 1'b1;
        end
    end

    assign tick_100ms = (presc_cnt == N_PRESC - 1);

    // ------------------------------------------------------------
    // Contador de espera: cuenta hasta WAIT_COUNT habilitaciones de
    // 100ms (por defecto 20*100ms=2s) mientras f_state_gameover esté
    // activo
    // ------------------------------------------------------------
    logic [4:0] wait_cnt;   // 5 bits, hasta 20 (ajustar si WAIT_COUNT>31)
    logic       wait_done;  // cuenta == 20

    assign wait_done = (wait_cnt == WAIT_COUNT);

    always_ff @(posedge clk) begin
        if (rst) begin
            wait_cnt <= 5'd0;
        end else if (f_state_play || (!f_state_play && !f_state_gameover)) begin
            // reposo o partida activa -> contador en cero
            wait_cnt <= 5'd0;
        end else if (f_state_gameover && !f_state_play) begin
            if (tick_100ms && !wait_done) begin
                wait_cnt <= wait_cnt + 5'd1;
            end
            // si wait_done, se mantiene sin cambio (saturado en 20)
        end
    end

    assign fin_espera = (f_state_gameover && !f_state_play) && tick_100ms && wait_done;

    // ------------------------------------------------------------
    // Biestable de parpadeo: conmuta cada 2 habilitaciones de 100ms
    // (periodo de 400ms -> 2.5 Hz)
    // ------------------------------------------------------------
    logic blink_toggle;

    always_ff @(posedge clk) begin
        if (rst) begin
            blink_toggle <= 1'b0;
        end else if (f_state_gameover && !f_state_play) begin
            if (tick_100ms) begin
                blink_toggle <= ~blink_toggle;
            end
        end else begin
            blink_toggle <= 1'b0;
        end
    end
    
    // ------------------------------------------------------------
    // Selector de nivel del LED
    // ------------------------------------------------------------
    always_comb begin
        if (f_state_play && !f_state_gameover) begin
            led_state = 1'b1;              // partida activa: encendido fijo
        end else if (!f_state_play && f_state_gameover) begin
            led_state = blink_toggle;      // fin de partida: parpadeo
        end else begin
            led_state = 1'b0;              // reposo, o caso inválido: apagado
        end
    end
endmodule