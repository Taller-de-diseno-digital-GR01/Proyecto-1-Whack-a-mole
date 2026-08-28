// =============================================================
// M1: Receptor UART
// Proyecto Whack-a-Mole
// clk    = 100 MHz
// baud   = 9600, formato 8N1
// N      = f_clk / baudrate = 100_000_000 / 9600 = 10417
// =============================================================

module r_uart #(
    parameter int CLK_FREQ   = 100_000_000,
    parameter int BAUD_RATE  = 9600,
    parameter int N          = CLK_FREQ / BAUD_RATE   // 10417
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       pos,           // pos(8): línea serial proveniente del subsistema discreto
    input  logic       en_save_pos,   // habilitación de captura, desde la FSM del sistema (M8)
    output logic [2:0] pos_topo,      // posición retenida del topo
    output logic       valid_pos      // pulso: trama nueva decodificada y válida
);

    // -----------------------------------------------------------
    // Codificación de estados
    // -----------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATO  = 2'b10,
        STOP  = 2'b11
    } state_t;

    state_t state, next_state;

    // -----------------------------------------------------------
    // 1. Sincronizador de dos etapas
    // -----------------------------------------------------------
    logic pos_ff1, pos_sync;

    always_ff @(posedge clk) begin
        if (rst) begin
            pos_ff1  <= 1'b1;   // línea en reposo = 1
            pos_sync <= 1'b1;
        end else begin
            pos_ff1  <= pos;
            pos_sync <= pos_ff1;
        end
    end

    // -----------------------------------------------------------
    // 2. Detector de flanco de bajada (start_bit)
    // -----------------------------------------------------------
    logic pos_sync_prev;

    always_ff @(posedge clk) begin
        if (rst)
            pos_sync_prev <= 1'b1;
        else
            pos_sync_prev <= pos_sync;
    end

    logic start_bit;
    assign start_bit = pos_sync_prev & ~pos_sync;

    // -----------------------------------------------------------
    // 3. Contador de tiempo (time_cntr) con mux de umbral
    // -----------------------------------------------------------
    localparam int HALF_N = (N / 2) - 1;
    localparam int FULL_N = N - 1;
    localparam int CNT_W  = $clog2(N);

    logic [CNT_W-1:0] time_cntr;
    logic             load;
    logic             flag_cont;
    logic [CNT_W-1:0] umbral;

    // mux 2:1 de umbral, seleccionado por el estado actual
    assign umbral = (state == IDLE) ? HALF_N[CNT_W-1:0] : FULL_N[CNT_W-1:0];

    always_ff @(posedge clk) begin
        if (rst)
            time_cntr <= '0;
        else if (load)
            time_cntr <= umbral;
        else if (time_cntr != 0)
            time_cntr <= time_cntr - 1'b1;
    end

    assign flag_cont = (time_cntr == 0);

    // -----------------------------------------------------------
    // 4. Contador de bits (0 a 7) y bandera cont_8
    // -----------------------------------------------------------
    logic [2:0] bit_cnt;
    logic       shift_en;
    logic       cont_8;

    always_ff @(posedge clk) begin
        if (rst)
            bit_cnt <= 3'b0;
        else if (state == START && next_state == DATO)
            bit_cnt <= 3'b0;
        else if (shift_en)
            bit_cnt <= bit_cnt + 1'b1;
    end

    assign cont_8 = shift_en & (bit_cnt == 3'd7);

    // -----------------------------------------------------------
    // 5. Registro de desplazamiento (8 bits, LSB primero)
    // -----------------------------------------------------------
    logic [7:0] shift_reg;

    always_ff @(posedge clk) begin
        if (rst)
            shift_reg <= 8'b0;
        else if (shift_en)
            shift_reg <= {pos_sync, shift_reg[7:1]};
    end

    // -----------------------------------------------------------
    // 6. FSM de control — Bloque 1: registro de estado
    // -----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -----------------------------------------------------------
    // 6. FSM de control — Bloque 2: lógica de siguiente estado
    // -----------------------------------------------------------
    always_comb begin
        next_state = state;   // valor por defecto, evita latches
        load       = 1'b0;

        unique case (state)
            IDLE: begin
                if (start_bit) begin
                    next_state = START;
                    load       = 1'b1;
                end
            end

            START: begin
                if (flag_cont) begin
                    if (!pos_sync) begin
                        next_state = DATO;
                        load       = 1'b1;
                    end else begin
                        next_state = IDLE;   // glitch, descarta
                    end
                end
            end

            DATO: begin
                if (flag_cont) begin
                    load = 1'b1;
                    if (cont_8)
                        next_state = STOP;
                end
            end

            STOP: begin
                if (flag_cont)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------
    // 6. FSM de control — Bloque 3: lógica de salidas
    // -----------------------------------------------------------
    logic valid_pos_int;

    always_comb begin
        shift_en      = (state == DATO) && flag_cont;
        valid_pos_int = (state == STOP) && flag_cont && pos_sync;
    end

    assign valid_pos = valid_pos_int;

    // -----------------------------------------------------------
    // 7. Registro de salida (pos_topo), con captura combinada
    //    valid_pos AND en_save_pos
    // -----------------------------------------------------------
    logic captura;
    assign captura = valid_pos_int & en_save_pos;

    always_ff @(posedge clk) begin
        if (rst)
            pos_topo <= 3'b0;
        else if (captura)
            pos_topo <= shift_reg[2:0];
    end

endmodule
