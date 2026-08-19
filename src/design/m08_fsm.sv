module fsm (

//Entradas:
    input logic clk,
    input logic req_sent,
    input logic valid_pos,
    input logic btn_pos,
    input logic window_exp,
    input logic cont_failure,
    input logic rst,
//Salidas:
    output logic rst_dificulty,
    output logic rst_hits,
    output logic rst_failures,
    output logic en_numRandom,
    output logic en_save_pos,
    output logic add_hit,
    output logic add_failure,
    output logic rst_window,
    output logic inc_dificulty,
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
}state_type;

state_type state, next_state;

assign current_state_out = state; 

always @(posedge clk or posedge rst) begin //REVISAR hoja de datos FPGA (Rst negativo o positivo)?
    if (rst) begin
        state <= START;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    next_state      = state;
    rst_dificulty   = 1'b0;
    rst_hits        = 1'b0;
    rst_failures    = 1'b0;
    rst_window      = 1'b0;
    en_numRandom    = 1'b0;
    en_save_pos     = 1'b0;
    add_hit         = 1'b0;
    add_failure     = 1'b0;
    inc_dificulty   = 1'b0;

    case(state)
        
        START: begin
            rst_dificulty   = 1'b1;
            rst_hits        = 1'b1;
            rst_failures    = 1'b1;
            rst_window      = 1'b1;
            en_numRandom    = 1'b0;
            en_save_pos     = 1'b0;
            add_hit         = 1'b0;
            add_failure     = 1'b0;
            inc_dificulty   = 1'b0;

            if (req_sent) begin
                next_state = REQ_POS;
            end
        end

        REQ_POS: begin
            en_numRandom    = 1'b1;

            if (valid_pos) begin
                next_state = WAIT_UART;
            end
        end

        WAIT_UART: begin
            en_save_pos     = 1'b1;

            if (btn_pos) begin
                next_state = PLAY;
            end
        end

        PLAY: begin
            if (window_exp) begin
                next_state = FAILURE;
            end else if (cont_failure) begin
                next_state = GAME_OVER;
            end else if (btn_pos) begin
                next_state = HIT;
            end
        end

        FAILURE: begin
            add_failure     = 1'b1;

            if (cont_failure) begin
                next_state = GAME_OVER;
            end else if (btn_pos) begin
                next_state = HIT;
            end else if (window_exp) begin
                next_state = FAILURE; 
            end else begin
                next_state = PLAY; 
            end
        end

        HIT: begin
            add_hit         = 1'b1;

            if (cont_failure) begin
                next_state = GAME_OVER;
            end else if (window_exp) begin
                next_state = FAILURE;
            end else begin
                inc_dificulty   = 1'b1; 
                next_state      = PLAY; 
            end
        end

        GAME_OVER: begin
            rst_dificulty   = 1'b1; 
            rst_hits        = 1'b1; 
            rst_failures    = 1'b1; 
            rst_window      = 1'b1;    
        end

    endcase


end
endmodule