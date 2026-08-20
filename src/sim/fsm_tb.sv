`timescale 1ns/1ps

//Todo: Falta realizar la prueba!

module tb_fsm;

    logic clk;
    logic rst;

    // Entradas hacia el DUT
    logic req_sent;
    logic valid_pos;
    logic btn_pos;
    logic window_exp;
    logic cont_failure;

    // Salidas desde el DUT
    logic rst_dificulty;
    logic rst_hits;
    logic rst_failures;
    logic en_numRandom;
    logic en_save_pos;
    logic add_hit;
    logic add_failure;
    logic rst_window;
    logic inc_dificulty;
    logic [2:0] current_state_out;

    // Variable auxiliar para mostrar el nombre del estado en la consola
    string state_name;

    fsm dut (
        .clk             (clk),
        .rst             (rst),
        .req_sent        (req_sent),
        .valid_pos       (valid_pos),
        .btn_pos         (btn_pos),
        .window_exp      (window_exp),
        .cont_failure    (cont_failure),

        .rst_dificulty   (rst_dificulty),
        .rst_hits        (rst_hits),
        .rst_failures    (rst_failures),
        .en_numRandom    (en_numRandom),
        .en_save_pos     (en_save_pos),
        .add_hit         (add_hit),
        .add_failure     (add_failure),
        .rst_window      (rst_window),
        .inc_dificulty   (inc_dificulty),
        .current_state_out(current_state_out)
    );


    always #5 clk = ~clk;

    always_comb begin
        case (current_state_out)
            3'b000: state_name = "START";
            3'b001: state_name = "REQ_POS";
            3'b010: state_name = "WAIT_UART";
            3'b011: state_name = "PLAY";
            3'b100: state_name = "FAILURE";
            3'b101: state_name = "HIT";
            3'b110: state_name = "GAME_OVER";
            default: state_name = "UNKNOWN";
        endcase
    end


    initial begin
        // Generación de archivo VCD para ver las ondas en GTKWave
        $dumpfile("tb_fsm.vcd");
        $dumpvars(0, tb_fsm);

        // Inicialización de señales
        clk          = 0;
        rst          = 1'b1; // Se inicia en Reset
        req_sent     = 1'b0;
        valid_pos    = 1'b0;
        btn_pos      = 1'b0;
        window_exp   = 1'b0;
        cont_failure = 1'b0;

        // --- TEST 0: APLICAR Y LIBERAR RESET ---
        $display("\n[TB] ---> Aplicando Reset al sistema...");
        repeat (2) @(posedge clk);
        #1;
        rst = 1'b0; // Se libera el reset
        $display("[TB] Reset liberado. Estado actual: %s (%b)", state_name, current_state_out);

        // --- TEST 1: Transición START -> REQ_POS ---
        $display("\n[TB] --- Test 1: Solicitud de Posición (req_sent) ---");
        @(posedge clk);
        req_sent = 1'b1;
        @(posedge clk);
        #1;
        req_sent = 1'b0;
        $display("[TB] Estado: %s | en_numRandom = %b", state_name, en_numRandom);

        // --- TEST 2: Transición REQ_POS -> WAIT_UART ---
        $display("\n[TB] --- Test 2: Validación de Posición (valid_pos) ---");
        @(posedge clk);
        valid_pos = 1'b1;
        @(posedge clk);
        #1;
        valid_pos = 1'b0;
        $display("[TB] Estado: %s | en_save_pos = %b", state_name, en_save_pos);

        // --- TEST 3: Transición WAIT_UART -> PLAY ---
        $display("\n[TB] --- Test 3: Entrada a Modo de Juego ---");
        @(posedge clk);
        btn_pos = 1'b1;
        @(posedge clk);
        #1;
        btn_pos = 1'b0;
        $display("[TB] Estado: %s (En espera de acción del jugador)", state_name);

        // --- TEST 4: Escenario de Acierto (PLAY -> HIT -> PLAY) ---
        $display("\n[TB] --- Test 4: Pulsación Correcta (Acierto) ---");
        @(posedge clk);
        btn_pos = 1'b1; // El jugador presiona el botón correcto
        @(posedge clk);
        #1;
        btn_pos = 1'b0;
        $display("[TB] Estado tras pulsar botón: %s | add_hit = %b", state_name, add_hit);

        // Siguiente ciclo evaluación en HIT
        @(posedge clk);
        #1;
        $display("[TB] Transición tras HIT: %s | inc_dificulty = %b", state_name, inc_dificulty);

        // --- TEST 5: Escenario de Fallo por Tiempo Expirado (PLAY -> FAILURE) ---
        $display("\n[TB] --- Test 5: Ventana de Tiempo Expirada (Fallo) ---");
        @(posedge clk);
        window_exp = 1'b1; // Se termina el tiempo de reacción
        @(posedge clk);
        #1;
        window_exp = 1'b0;
        $display("[TB] Estado tras expiración: %s | add_failure = %b", state_name, add_failure);

        // --- TEST 6: Escenario de Game Over (3 Fallos Acumulados) ---
        $display("\n[TB] --- Test 6: Condición de Fin de Juego (GAME_OVER) ---");
        @(posedge clk);
        cont_failure = 1'b1;
        @(posedge clk);
        #1;
        $display("[TB] Estado con 3 fallos: %s | rst_hits = %b, rst_failures = %b",
                 state_name, rst_hits, rst_failures);

        // Final de la simulación
        #40;
        $display("\n[TB] === Pruebas completadas exitosamente ===");
        $finish;
    end

endmodule
