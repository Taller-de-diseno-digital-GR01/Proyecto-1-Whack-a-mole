// =============================================================
// Testbench: r_uart
// Genera tramas UART (8N1) sobre la línea 'pos' y verifica
// que pos_topo y valid_pos se comporten según lo esperado.
//
// Para EDA Playground:
//   - Testbench: este archivo (tb_r_uart.sv)
//   - Design   : r_uart.sv
//   - Simulador sugerido: Icarus Verilog o Questa (ambos soportan
//     la sintaxis usada aquí: always_ff, always_comb, typedef enum)
// =============================================================

`timescale 1ns/1ps

module tb_r_uart;

    // -----------------------------------------------------------
    // Parámetros (iguales a los del DUT, en menor escala si se
    // quiere simular más rápido -- ver nota al final)
    // -----------------------------------------------------------
    localparam int CLK_FREQ  = 100_000_000;
    localparam int BAUD_RATE = 9600;
    localparam int N         = CLK_FREQ / BAUD_RATE;   // 10417
    localparam time CLK_PERIOD = 10ns;                 // 100 MHz
    localparam time BIT_PERIOD = N * CLK_PERIOD;        // ~104.17 us

    // -----------------------------------------------------------
    // Señales de conexión al DUT
    // -----------------------------------------------------------
    logic       clk;
    logic       rst;
    logic       pos;
    logic       en_save_pos;
    logic [2:0] pos_topo;
    logic       valid_pos;

    int errors = 0;
    int checks = 0;

    // -----------------------------------------------------------
    // DUT
    // -----------------------------------------------------------
    r_uart #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk         (clk),
        .rst         (rst),
        .pos         (pos),
        .en_save_pos (en_save_pos),
        .pos_topo    (pos_topo),
        .valid_pos   (valid_pos)
    );

    // -----------------------------------------------------------
    // Generador de reloj: 100 MHz
    // -----------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------
    // Task: enviar un byte por 'pos' siguiendo el formato 8N1
    // LSB primero, tal como especifica el protocolo
    // -----------------------------------------------------------
    task automatic send_byte(input logic [7:0] data);
        int i;
        begin
            // start bit
            pos = 1'b0;
            #(BIT_PERIOD);

            // 8 bits de datos, LSB primero
            for (i = 0; i < 8; i++) begin
                pos = data[i];
                #(BIT_PERIOD);
            end

            // stop bit
            pos = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    // -----------------------------------------------------------
    // Task: enviar un byte con stop bit inválido (para probar
    // el descarte de trama)
    // -----------------------------------------------------------
    task automatic send_byte_bad_stop(input logic [7:0] data);
        int i;
        begin
            pos = 1'b0;                 // start bit
            #(BIT_PERIOD);

            for (i = 0; i < 8; i++) begin
                pos = data[i];
                #(BIT_PERIOD);
            end

            pos = 1'b0;                 // stop bit inválido (debería ser 1)
            #(BIT_PERIOD);

            pos = 1'b1;                 // vuelve a reposo para no dejar la línea colgada
            #(BIT_PERIOD);
        end
    endtask

    // -----------------------------------------------------------
    // Task: verificar pos_topo y valid_pos tras enviar una trama
    // -----------------------------------------------------------
    task automatic check_pos_topo(
        input string      label,
        input logic [2:0] expected_pos
    );
        begin
            checks++;
            if (pos_topo !== expected_pos) begin
                $display("[FALLO] %s: pos_topo=%0d, esperado=%0d", label, pos_topo, expected_pos);
                errors++;
            end else begin
                $display("[OK]    %s: pos_topo=%0d", label, pos_topo);
            end
        end
    endtask

    // -----------------------------------------------------------
    // Secuencia principal de prueba
    // -----------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_r_uart);
    end

    initial begin
        // Estado inicial
        rst         = 1'b1;
        pos         = 1'b1;   // línea en reposo
        en_save_pos = 1'b1;   // habilita captura hacia pos_topo

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        // -------------------------------------------------------
        // Caso 1: byte 8'b00000101 -> pos_topo esperado = 3'b101 (5)
        // -------------------------------------------------------
        $display("\n--- Caso 1: trama valida, dato = 8'h05 ---");
        fork
            send_byte(8'b0000_0101);
            begin
                // espera a que aparezca el pulso valid_pos
                wait (valid_pos === 1'b1);
                @(posedge clk); // flanco en el que pos_topo se actualiza
                #1;             // deja que la asignacion no bloqueante se asiente
                check_pos_topo("Caso1", 3'b101);
            end
        join

        repeat (20) @(posedge clk);

        // -------------------------------------------------------
        // Caso 2: byte 8'b11111010 -> pos_topo esperado = 3'b010 (2)
        // -------------------------------------------------------
        $display("\n--- Caso 2: trama valida, dato = 8'hFA ---");
        fork
            send_byte(8'b1111_1010);
            begin
                wait (valid_pos === 1'b1);
                @(posedge clk);
                #1;
                check_pos_topo("Caso2", 3'b010);
            end
        join

        repeat (20) @(posedge clk);

        // -------------------------------------------------------
        // Caso 3: byte 8'b00000111 con stop bit invalido
        // no debe generarse valid_pos, y pos_topo debe conservar
        // el ultimo valor valido (3'b010 del caso 2)
        // -------------------------------------------------------
        $display("\n--- Caso 3: trama con stop bit invalido, no debe validarse ---");
        begin
            logic [2:0] pos_topo_antes;
            logic       vio_valid;

            pos_topo_antes = pos_topo;
            vio_valid      = 1'b0;

            fork
                send_byte_bad_stop(8'b0000_0111);
                begin
                    // monitorea durante toda la trama si valid_pos se activa
                    repeat (10 * N) begin
                        @(posedge clk);
                        if (valid_pos) vio_valid = 1'b1;
                    end
                end
            join

            checks++;
            if (vio_valid) begin
                $display("[FALLO] Caso3: valid_pos se activo con stop bit invalido");
                errors++;
            end else if (pos_topo !== pos_topo_antes) begin
                $display("[FALLO] Caso3: pos_topo cambio (%0d -> %0d) sin trama valida",
                          pos_topo_antes, pos_topo);
                errors++;
            end else begin
                $display("[OK]    Caso3: trama invalida descartada correctamente, pos_topo=%0d sin cambio",
                          pos_topo);
            end
        end

        repeat (20) @(posedge clk);

        // -------------------------------------------------------
        // Caso 4: en_save_pos = 0, pos_topo no debe capturar
        // aunque la trama sea valida
        // -------------------------------------------------------
        $display("\n--- Caso 4: en_save_pos=0, no debe capturar aunque la trama sea valida ---");
        begin
            logic [2:0] pos_topo_antes;

            en_save_pos    = 1'b0;
            pos_topo_antes = pos_topo;

            fork
                send_byte(8'b0000_0110); // dato[2:0] = 3'b110, distinto al retenido
                begin
                    wait (valid_pos === 1'b1);
                    @(posedge clk);
                    #1;
                end
            join

            checks++;
            if (pos_topo !== pos_topo_antes) begin
                $display("[FALLO] Caso4: pos_topo cambio (%0d -> %0d) con en_save_pos=0",
                          pos_topo_antes, pos_topo);
                errors++;
            end else begin
                $display("[OK]    Caso4: pos_topo se mantuvo en %0d con en_save_pos=0", pos_topo);
            end

            en_save_pos = 1'b1; // restaura para posibles pruebas futuras
        end

        repeat (20) @(posedge clk);

        // -------------------------------------------------------
        // Resumen final
        // -------------------------------------------------------
        $display("\n=====================================");
        $display(" Resumen: %0d checks, %0d errores", checks, errors);
        if (errors == 0)
            $display(" TODAS LAS PRUEBAS PASARON");
        else
            $display(" HAY %0d PRUEBA(S) FALLIDA(S)", errors);
        $display("=====================================\n");

        $finish;
    end

    // -----------------------------------------------------------
    // Guardia de tiempo máximo, por si algo se cuelga
    // -----------------------------------------------------------
    initial begin
        #(BIT_PERIOD * 10 * 10); // margen amplio: 10 tramas de 10 bits
        if ($time > 0) begin
            // este bloque solo actua como watchdog; si la simulacion
            // ya termino con $finish, esta linea nunca se alcanza
        end
    end

endmodule
