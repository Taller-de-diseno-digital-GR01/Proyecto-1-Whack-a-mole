// =============================================================
// Transmisor UART (t_uart)
// Proyecto Whack-a-Mole
//
// El transmisor UART del subsistema discreto (74xx + reloj 555) no
// es confiable, así que la posición generada por el LFSR discreto
// (sí funcional) se conecta directo a la FPGA por 3 líneas paralelas
// en vez de un enlace serie. Este módulo arma la trama 8N1 dentro de
// la FPGA a partir de ese dato paralelo y la entrega en loopback
// interno a r_uart (M1), que no cambia, para conservar el formato de
// trama acordado (8N1, 9600 baudios) entre módulos.
//
// clk    = 100 MHz
// baud   = 9600, formato 8N1
// N      = f_clk / baudrate = 100_000_000 / 9600 = 10417
// =============================================================

module t_uart #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 9600,
    parameter int N         = CLK_FREQ / BAUD_RATE   // 10417
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] pos_topo,   // dato paralelo, proveniente del LFSR discreto (asíncrono)
    input  logic       start,      // pulso: inicia una transmisión (en_numRandom de la FSM, M8)
    output logic       tx,         // línea serial de salida, hacia r_uart (M1) en loopback interno
    output logic       busy        // en 1 mientras se arma/envía la trama
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state, next_state;

    // -----------------------------------------------------------
    // 1. Sincronizador de dos etapas para el dato paralelo, que
    //    llega de un reloj independiente al de la FPGA
    // -----------------------------------------------------------
    logic [2:0] pos_ff1, pos_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            pos_ff1  <= 3'b0;
            pos_sync <= 3'b0;
        end else begin
            pos_ff1  <= pos_topo;
            pos_sync <= pos_ff1;
        end
    end

    // Registro "pending": retiene cualquier pulso de 'start' hasta que
    // realmente se consume (arranca la trama), en vez de reaccionar de
    // inmediato. Esto resuelve dos escenarios a la vez, con la misma
    // señal, sin duplicar lógica:
    //   1. 'start' puede llegar apenas un ciclo después de liberar 'rst'
    //      (la FSM entra a REQ_POS de inmediato) -- antes de que el
    //      sincronizador de dos etapas de arriba haya tenido tiempo de
    //      reflejar el valor real de pos_topo. Al retener la solicitud
    //      un ciclo, pos_sync ya está asentado para cuando se consume.
    //   2. 'start' puede llegar mientras todavía se arma/envía la trama
    //      anterior (nueva solicitud antes de volver a IDLE); en vez de
    //      perderla, se dispara en cuanto el módulo vuelve a IDLE, en
    //      lugar de dejar a la FSM del sistema esperando valid_pos para
    //      siempre.
    logic pending;

    always_ff @(posedge clk) begin
        if (rst)
            pending <= 1'b0;
        else if (start)
            pending <= 1'b1;
        else if (state == IDLE && pending)
            pending <= 1'b0;
    end

    // -----------------------------------------------------------
    // 2. Contador de baudios (tick cada N ciclos, sin recentrado
    //    porque el transmisor no necesita muestrear, solo mantener
    //    cada bit N ciclos)
    // -----------------------------------------------------------
    localparam int CNT_W = $clog2(N);

    logic [CNT_W-1:0] baud_cntr;
    logic             tick;

    assign tick = (baud_cntr == N[CNT_W-1:0] - 1'b1);

    always_ff @(posedge clk) begin
        if (rst)
            baud_cntr <= '0;
        else if (state == IDLE)
            baud_cntr <= '0;
        else if (tick)
            baud_cntr <= '0;
        else
            baud_cntr <= baud_cntr + 1'b1;
    end

    // -----------------------------------------------------------
    // 3. Contador de bits de datos (0 a 7)
    // -----------------------------------------------------------
    logic [2:0] bit_cntr;

    always_ff @(posedge clk) begin
        if (rst)
            bit_cntr <= 3'b0;
        else if (state == START && next_state == DATA)
            bit_cntr <= 3'b0;
        else if (state == DATA && tick)
            bit_cntr <= bit_cntr + 1'b1;
    end

    // -----------------------------------------------------------
    // 4. Registro de desplazamiento: se carga al salir de IDLE con
    //    el dato ya sincronizado, empacado en una trama de 8 bits
    //    (5 ceros + pos_sync[2:0]) igual que espera r_uart; se
    //    desplaza un bit por cada tick en DATA, LSB primero
    // -----------------------------------------------------------
    logic [7:0] shift_reg;

    always_ff @(posedge clk) begin
        if (rst)
            shift_reg <= 8'b0;
        else if (state == IDLE && pending)
            shift_reg <= {5'b0, pos_sync};
        else if (state == DATA && tick)
            shift_reg <= {1'b0, shift_reg[7:1]};
    end

    // -----------------------------------------------------------
    // 5. FSM de control — registro de estado
    // -----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -----------------------------------------------------------
    // 5. FSM de control — lógica de siguiente estado
    // -----------------------------------------------------------
    always_comb begin
        next_state = state;   // valor por defecto, evita latches

        unique case (state)
            IDLE:  if (pending) next_state = START;
            START: if (tick)  next_state = DATA;
            DATA:  if (tick && bit_cntr == 3'd7) next_state = STOP;
            STOP:  if (tick)  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------
    // 5. FSM de control — lógica de salidas (Moore: solo depende
    //    del estado y del bit actual del registro de desplazamiento)
    // -----------------------------------------------------------
    always_comb begin
        unique case (state)
            START:   tx = 1'b0;             // bit de inicio
            DATA:    tx = shift_reg[0];     // bit de dato actual
            default: tx = 1'b1;             // IDLE / STOP: línea en reposo o bit de parada
        endcase
    end

    assign busy = (state != IDLE);

endmodule
