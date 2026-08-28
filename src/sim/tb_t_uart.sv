// =============================================================
// Testbench: t_uart
// Dispara transmisiones con 'start' sobre un dato paralelo
// (pos_topo) y verifica que 'tx' arme la trama 8N1 esperada
// (bit de inicio, 8 bits de datos LSB primero con los 5 bits
// altos en cero, bit de parada), igual formato que espera r_uart.
//
// Para EDA Playground:
//   - Testbench: este archivo (tb_t_uart.sv)
//   - Design   : t_uart.sv
//   - Simulador sugerido: Icarus Verilog o Questa
// =============================================================

`timescale 1ns/1ps

module tb_t_uart;

    // -----------------------------------------------------------
    // Parámetros (iguales a los reales, ver r_uart)
    // -----------------------------------------------------------
    localparam int  CLK_FREQ   = 100_000_000;
    localparam int  BAUD_RATE  = 9600;
    localparam int  N          = CLK_FREQ / BAUD_RATE;   // 10417
    localparam time CLK_PERIOD = 10ns;                   // 100 MHz
    localparam time BIT_PERIOD = N * CLK_PERIOD;         // ~104.17 us

    // -----------------------------------------------------------
    // Señales de conexión al DUT
    // -----------------------------------------------------------
    logic       clk;
    logic       rst;
    logic [2:0] pos_topo;
    logic       start;
    logic       tx;
    logic       busy;

    int errors = 0;
    int checks = 0;

    // -----------------------------------------------------------
    // DUT
    // -----------------------------------------------------------
    t_uart #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .pos_topo (pos_topo),
        .start    (start),
        .tx       (tx),
        .busy     (busy)
    );

    // -----------------------------------------------------------
    // Generador de reloj: 100 MHz
    // -----------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------
    // Task: dispara una transmisión y verifica la trama completa
    // sobre 'tx', muestreando en el centro de cada periodo de bit
    // -----------------------------------------------------------
    task automatic check_tx_frame(input string label, input logic [2:0] posicion);
        logic [7:0] esperado;
        int i;
        begin
            esperado = {5'b0, posicion};

            // Espera a que el DUT este realmente en reposo: si 'start'
            // llega mientras aun arma/envia la trama anterior, t_uart la
            // encola (pending) y la dispara mas tarde de lo que asumiria
            // el muestreo de tiempo fijo de este task.
            wait (busy === 1'b0);

            // pos_topo debe estar estable con margen suficiente para que
            // el sincronizador de dos etapas de t_uart converja antes de
            // que 'start' dispare la carga del registro de desplazamiento
            pos_topo = posicion;
            repeat (3) @(posedge clk);

            // Los '#1' corren la asignacion un poco despues del flanco,
            // para no competir con el muestreo interno del DUT justo en
            // el mismo flanco (si no, 'start' puede quedar visible un
            // ciclo de mas o de menos segun el orden de eventos del
            // simulador)
            @(posedge clk); #1;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;

            // bit de inicio: centro del primer periodo de bit
            #(BIT_PERIOD/2);
            checks++;
            if (tx !== 1'b0) begin
                $display("[FALLO] %s: bit de inicio, tx=%0b esperado=0", label, tx);
                errors++;
            end

            for (i = 0; i < 8; i++) begin
                #(BIT_PERIOD);
                checks++;
                if (tx !== esperado[i]) begin
                    $display("[FALLO] %s: bit de dato %0d, tx=%0b esperado=%0b", label, i, tx, esperado[i]);
                    errors++;
                end
            end

            // bit de parada
            #(BIT_PERIOD);
            checks++;
            if (tx !== 1'b1) begin
                $display("[FALLO] %s: bit de parada, tx=%0b esperado=1", label, tx);
                errors++;
            end else begin
                $display("[OK]    %s: trama completa correcta (dato=8'h%0h)", label, esperado);
            end

            // deja que el DUT vuelva a IDLE antes de la siguiente trama
            #(BIT_PERIOD/2);
        end
    endtask

    // -----------------------------------------------------------
    // Secuencia principal de prueba
    // -----------------------------------------------------------
    initial begin
        $dumpfile("tb_t_uart.vcd");
        $dumpvars(0, tb_t_uart);
    end

    initial begin
        rst      = 1'b1;
        pos_topo = 3'b0;
        start    = 1'b0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        $display("\n--- Reposo inicial ---");
        checks++;
        if (tx !== 1'b1) begin
            $display("[FALLO] Reposo inicial: tx=%0b, esperado=1", tx);
            errors++;
        end else begin
            $display("[OK]    Reposo inicial: tx=1");
        end

        checks++;
        if (busy !== 1'b0) begin
            $display("[FALLO] Reposo inicial: busy=%0b, esperado=0", busy);
            errors++;
        end else begin
            $display("[OK]    Reposo inicial: busy=0");
        end

        // -------------------------------------------------------
        // Caso 1: pos_topo = 3'd5 -> trama 8'b0000_0101
        // -------------------------------------------------------
        $display("\n--- Caso 1: transmite posicion 5 ---");
        check_tx_frame("Caso1", 3'd5);

        // -------------------------------------------------------
        // Caso 2: pos_topo = 3'd2 -> trama 8'b0000_0010
        // -------------------------------------------------------
        $display("\n--- Caso 2: transmite posicion 2 ---");
        check_tx_frame("Caso2", 3'd2);

        // -------------------------------------------------------
        // Caso 3: pos_topo = 3'd7 -> trama 8'b0000_0111 (todos los
        // bits utiles en 1)
        // -------------------------------------------------------
        $display("\n--- Caso 3: transmite posicion 7 ---");
        check_tx_frame("Caso3", 3'd7);

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

endmodule
