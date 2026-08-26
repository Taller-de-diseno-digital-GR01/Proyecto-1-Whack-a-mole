`timescale 1ns/1ps
// =============================================================
// tb_top: testbench del módulo top (whack-a-mole)
//
// Cubre:
//   1. Acierto normal (hit) -> sube hit_counter, baja la dificultad,
//      en_numRandom se activa al pedir la siguiente posición
//   2. Fallo por botón equivocado (miss)
//   3. 3 fallos consecutivos -> GAME_OVER. El marcador debe MANTENER
//      el puntaje final durante la espera de 2s (fin_espera), y solo
//      resetearse al volver a START. led_state debe parpadear durante
//      GAME_OVER y quedar fijo en alto durante PLAY.
//   4. Se acaba el tiempo sin presionar nada (window_exp) -> FAILURE
//   5. marcador multiplexa los 4 dígitos (an rota 1110->1101->1011->0111)
//
// NOTA sobre los "defparam": aceleran SOLO tiempos de simulación
// (debounce, UART, ventana de tiempo, espera de game over, refresco
// del display). No cambian ninguna lógica funcional del diseño.
// =============================================================

module tb_top;

    localparam CLK_PERIOD = 10; // 100 MHz

    // Códigos de estado de la fsm (deben coincidir con fsm.sv)
    localparam logic [2:0] ST_START     = 3'b000;
    localparam logic [2:0] ST_REQ_POS   = 3'b001;
    localparam logic [2:0] ST_WAIT_UART = 3'b010;
    localparam logic [2:0] ST_PLAY      = 3'b011;
    localparam logic [2:0] ST_FAILURE   = 3'b100;
    localparam logic [2:0] ST_HIT       = 3'b101;
    localparam logic [2:0] ST_GAME_OVER = 3'b110;

    logic clk, rst;
    logic btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7;
    logic [2:0] pos_topo_lfsr;
    logic led_state;
    logic [7:0] leds_topo;
    logic [6:0] seg;
    logic [3:0] an;
    logic en_numRandom;

    int errores = 0;

    top dut (
        .clk               (clk),
        .rst               (rst),
        .btn_0             (btn_0),
        .btn_1             (btn_1),
        .btn_2             (btn_2),
        .btn_3             (btn_3),
        .btn_4             (btn_4),
        .btn_5             (btn_5),
        .btn_6             (btn_6),
        .btn_7             (btn_7),
        .pos_topo_lfsr     (pos_topo_lfsr),
        .led_state         (led_state),
        .leds_topo         (leds_topo),
        .seg               (seg),
        .an                (an),
        .en_numRandom      (en_numRandom)
    );

    // ---------------------------------------------------------
    // SOLO para velocidad de simulación (ver nota arriba)
    // ---------------------------------------------------------
    defparam dut.u_r_uart.BAUD_RATE    = 1_000_000; // 100 ciclos/bit en vez de 10417
    defparam dut.u_t_uart.BAUD_RATE    = 1_000_000; // debe coincidir con u_r_uart (mismo N en el loopback)
    defparam dut.u_time_logic.CLK_FREQ = 10_000;     // ~1000 ciclos/tick en vez de 10_000_000
    defparam dut.u_state.N_PRESC       = 50;         // tick de "100ms" cada 50 ciclos
    defparam dut.u_state.WAIT_COUNT    = 4;          // espera de game over: 4 ticks en vez de 20
    defparam dut.u_marcador.CLK_FREQ   = 4_000;       // refresco de display cada 4 ciclos
    defparam dut.u_press_btn.db0.N = 6;              // ~32 ciclos para pasar el debounce
    defparam dut.u_press_btn.db1.N = 6;
    defparam dut.u_press_btn.db2.N = 6;
    defparam dut.u_press_btn.db3.N = 6;
    defparam dut.u_press_btn.db4.N = 6;
    defparam dut.u_press_btn.db5.N = 6;
    defparam dut.u_press_btn.db6.N = 6;
    defparam dut.u_press_btn.db7.N = 6;

    // ---------------------------------------------------------
    // Reloj
    // ---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------
    // Tareas auxiliares
    // ---------------------------------------------------------

    // El LFSR discreto (funcional) mantiene su valor en pos_topo_lfsr de
    // forma continua; el transmisor UART discreto es el que estaba roto,
    // así que aquí simulamos solo el dato paralelo. La FPGA (t_uart)
    // arma la trama sola en cuanto ve el pulso en_numRandom -- no hace
    // falta bit-banging desde el testbench.
    task automatic enviar_pos(input logic [2:0] posicion);
        begin
            pos_topo_lfsr = posicion;
        end
    endtask

    task automatic presionar_boton(input int idx);
        begin
            case (idx)
                0: btn_0 = 1'b1;
                1: btn_1 = 1'b1;
                2: btn_2 = 1'b1;
                3: btn_3 = 1'b1;
                4: btn_4 = 1'b1;
                5: btn_5 = 1'b1;
                6: btn_6 = 1'b1;
                7: btn_7 = 1'b1;
            endcase
            repeat (50) @(posedge clk);
            case (idx)
                0: btn_0 = 1'b0;
                1: btn_1 = 1'b0;
                2: btn_2 = 1'b0;
                3: btn_3 = 1'b0;
                4: btn_4 = 1'b0;
                5: btn_5 = 1'b0;
                6: btn_6 = 1'b0;
                7: btn_7 = 1'b0;
            endcase
            repeat (50) @(posedge clk);
        end
    endtask

    task automatic check(input logic cond, input string msg);
        begin
            if (cond) $display("[PASS] %s", msg);
            else begin
                $display("[FAIL] %s", msg);
                errores++;
            end
        end
    endtask

    task automatic esperar_estado(input logic [2:0] estado, input int timeout_ciclos);
        int c;
        begin
            c = 0;
            while (dut.w_current_state !== estado && c < timeout_ciclos) begin
                @(posedge clk);
                c++;
            end
            if (dut.w_current_state !== estado)
                $display("[WARN] Timeout esperando estado %0d (quedo en %0d, %0d ciclos)",
                          estado, dut.w_current_state, c);
        end
    endtask

    // ---------------------------------------------------------
    // Secuencia principal
    // ---------------------------------------------------------
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        rst = 1'b1;
        pos_topo_lfsr = 3'd3; // primera posicion (caso 1), lista antes del primer REQ_POS
        {btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7} = 8'b0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // -------------------------------------------------
        // Caso 1: acierto normal
        // -------------------------------------------------
        $display("\n--- Caso 1: acierto en la posicion 3 ---");
        esperar_estado(ST_REQ_POS, 20);
        check(en_numRandom === 1'b1, "en_numRandom se activa al pedir una posicion nueva");

        esperar_estado(ST_PLAY, 1200); // cubre la trama t_uart -> r_uart en loopback (~10*N ciclos)
        check(leds_topo === 8'b0000_1000, "leds_topo muestra la posicion 3 durante PLAY");
        check(led_state === 1'b1, "led_state fijo en alto durante PLAY");

        enviar_pos(3'd5); // deja lista la siguiente posicion antes del proximo REQ_POS
        presionar_boton(3);
        esperar_estado(ST_REQ_POS, 20);
        check(dut.w_acierto[3:0] === 4'd1, "hit_counter subio a 1 acierto");
        check(dut.u_time_logic.ventana_ticks === 4'd14,
              "la dificultad bajo de 15 a 14 ticks tras el primer acierto");

        // -------------------------------------------------
        // Caso 2: fallo por boton equivocado
        // -------------------------------------------------
        $display("\n--- Caso 2: fallo por boton incorrecto ---");
        esperar_estado(ST_PLAY, 1200);

        enviar_pos(3'd1); // deja lista la siguiente posicion antes del proximo REQ_POS
        presionar_boton(2); // deberia ser el 5
        esperar_estado(ST_REQ_POS, 20);
        check(dut.w_fallo[3:0] === 4'd1, "fail_counter subio a 1 fallo");

        // -------------------------------------------------
        // Caso 3: dos fallos consecutivos mas -> game over
        // -------------------------------------------------
        $display("\n--- Caso 3: fallos consecutivos hasta game over ---");
        esperar_estado(ST_PLAY, 1200);

        enviar_pos(3'd1); // misma posicion, lista antes del proximo REQ_POS
        presionar_boton(0); // incorrecto (2do fallo consecutivo)
        esperar_estado(ST_REQ_POS, 20);

        esperar_estado(ST_PLAY, 1200);
        presionar_boton(0); // incorrecto (3er fallo consecutivo -> game over)
        esperar_estado(ST_GAME_OVER, 20);
        check(dut.w_current_state === ST_GAME_OVER, "fsm llego a GAME_OVER tras 3 fallos consecutivos");
        check(dut.f_state_gameover === 1'b1, "f_state_gameover se activo");
        check(dut.w_acierto[3:0] === 4'd1 && dut.w_fallo[3:0] === 4'd3,
              "el marcador mantiene el puntaje final (1 acierto, 3 fallos) al ENTRAR a GAME_OVER");

        enviar_pos(3'd7); // deja lista la posicion del caso 4 antes de que la FSM vuelva a pedir (nueva partida)

        // Debe parpadear: muestreamos led_state dos veces separadas por
        // un tick completo de state (N_PRESC=50 ciclos) y verificamos
        // que cambia al menos una vez en varios ticks.
        begin
            logic vistos_en_alto, vistos_en_bajo;
            int k;
            vistos_en_alto = 1'b0;
            vistos_en_bajo = 1'b0;
            for (k = 0; k < 8; k++) begin
                repeat (55) @(posedge clk);
                if (led_state) vistos_en_alto = 1'b1;
                else vistos_en_bajo = 1'b1;
            end
            check(vistos_en_alto && vistos_en_bajo, "led_state parpadea (se vio en alto y en bajo) durante GAME_OVER");
        end

        // Esperamos a que termine la espera de 2s (aca acelerada) y
        // la fsm vuelva a REQ_POS via START
        esperar_estado(ST_REQ_POS, 2000);
        check(dut.w_acierto === 8'd0, "hit_counter se reinicio al salir de GAME_OVER (via START)");
        check(dut.w_fallo   === 8'd0, "fail_counter se reinicio al salir de GAME_OVER (via START)");
        check(dut.u_time_logic.ventana_ticks === 4'd15,
              "la dificultad volvio al valor inicial (15) en la partida nueva");

        // -------------------------------------------------
        // Caso 4: se acaba la ventana de tiempo sin presionar nada
        // -------------------------------------------------
        $display("\n--- Caso 4: expira la ventana de tiempo (window_exp) ---");
        esperar_estado(ST_PLAY, 1200);
        esperar_estado(ST_FAILURE, 25000);
        check(dut.w_current_state === ST_FAILURE, "la ventana expiro y disparo FAILURE sin presionar boton");

        // -------------------------------------------------
        // Caso 5: marcador multiplexa los 4 digitos
        // -------------------------------------------------
        $display("\n--- Caso 5: marcador multiplexa an (0->fallo uni, 1->fallo dec, 2->acierto uni, 3->acierto dec) ---");
        begin
            logic visto_an0, visto_an1, visto_an2, visto_an3;
            int k;
            visto_an0 = 1'b0; visto_an1 = 1'b0; visto_an2 = 1'b0; visto_an3 = 1'b0;
            for (k = 0; k < 40; k++) begin
                @(posedge clk);
                case (an)
                    4'b1110: visto_an0 = 1'b1;
                    4'b1101: visto_an1 = 1'b1;
                    4'b1011: visto_an2 = 1'b1;
                    4'b0111: visto_an3 = 1'b1;
                    default: ;
                endcase
            end
            check(visto_an0 && visto_an1 && visto_an2 && visto_an3,
                  "an roto por los 4 digitos (fallo uni/dec, acierto uni/dec)");
        end

        $display("\n=== Resumen: %0d error(es) ===", errores);
        if (errores == 0)
            $display(">>> TODOS LOS CASOS PASARON <<<");
        else
            $display(">>> HAY CASOS QUE FALLARON, revisar el log arriba <<<");

        $finish;
    end

endmodule