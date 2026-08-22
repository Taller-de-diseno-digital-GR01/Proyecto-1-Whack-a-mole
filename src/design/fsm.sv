module fsm (
    // Entradas
    input  logic       clk,
    input  logic       rst,
    input  logic       req_sent,
    input  logic       valid_value,
    input  logic       valid,
    input  logic       window_exp,
    input  logic       cont_failure, // Flag: se alcanzaron los fallos máximos
    
    // Salidas
    output logic       rst_dificulty,
    output logic       rst_hits,
    output logic       rst_failures,
    output logic       en_numRandom,
    output logic       en_save_pos,
    output logic       add_hit,
    output logic       add_failure,
    output logic       rst_window,
    output logic       inc_dificulty,
    output logic [2:0] current_state_out
);

    typedef enum logic [2:0] {    
        START       = 3'b000, 
        REQ_POS     = 3'b001,
        WAIT_UART   = 3'b010, 
        PLAY        = 3'b011, 
        FAILURE     = 3'b100, 
        HIT         = 3'b101, 
        GAME_OVER   = 3'b110
    } state_type;

    state_type state, next_state;

    assign current_state_out = state; 

    // Bloque Secuencial
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= START;
        end else begin
            state <= next_state;
        end
    end

    // Bloque Combinacional
    always_comb begin
        // Valores por defecto para evitar latches
        next_state    = state;
        rst_dificulty = 1'b0;
        rst_hits      = 1'b0;
        rst_failures  = 1'b0;
        rst_window    = 1'b0;
        en_numRandom  = 1'b0;
        en_save_pos   = 1'b0;
        add_hit       = 1'b0;
        add_failure   = 1'b0;
        inc_dificulty = 1'b0;

        case (state)
            
            START: begin
                rst_dificulty = 1'b1;
                rst_hits      = 1'b1;
                rst_failures  = 1'b1;
                rst_window    = 1'b1;
                next_state = REQ_POS;

                //REVISAR
                //if (req_sent) begin
                //    next_state = REQ_POS;
                //end
            end

            REQ_POS: begin
                en_numRandom = 1'b1;
                if (req_sent) begin
                    next_state = WAIT_UART;
                end
                //REVISAR
                //if (valid_value) begin
                //   next_state = WAIT_UART;
                //end
            end

            WAIT_UART: begin
                en_save_pos = 1'b1;
                //valid pos es el nombre correcto?
                if (valid_value) begin
                    next_state = PLAY;
                end
            end


            PLAY: begin
                // Prioridad: Acierto > Tiempo expirado
                //valid debe ser valid del press_btn
                if (valid) begin
                    next_state = HIT;
                end else if (window_exp || (~valid)) begin
                    next_state = FAILURE;
                end
            end

            FAILURE: begin
                add_failure = 1'b1;
                rst_window  = 1'b1; // Reinicia el temporizador de ventana
                
                // Transición inmediata tras el pulso de fallo
                if (cont_failure) begin
                    next_state = GAME_OVER;
                end else begin
                    next_state = REQ_POS; // Solicita una nueva posición para continuar
                end
            end

            HIT: begin
                add_hit       = 1'b1;
                inc_dificulty = 1'b1;
                rst_window    = 1'b1; // Reinicia el temporizador de ventana
                
                // Transición inmediata a solicitar nueva posición
                next_state = REQ_POS;
            end

            GAME_OVER: begin
                rst_dificulty = 1'b1; 
                rst_hits      = 1'b1; 
                rst_failures  = 1'b1; 
                rst_window    = 1'b1;

                // Permite reiniciar el juego si se presiona req_sent o rst
                if (req_sent) begin
                    next_state = REQ_POS;
                end
            end

            default: next_state = START;
        endcase
    end

endmodule