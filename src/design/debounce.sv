module debounce(
    input logic clk,
    input logic rst, //Revisar rst de la FPGA
    input logic btn_in,

    output logic db_out

);

    parameter N = 21; //Quizás afecte el tiempo de simulación.

    reg [N-1:0] q_reg;
    reg [N-1:0] q_next;
    reg dff1, dff2;
    wire q_add;
    wire q_reset;

    assign q_reset = (dff1 ^ dff2); //Revisa si cambia el estado del boton de un ciclo a otro
    assign q_add = ~(q_reg[N-1]); //Le asigna 1 si el contador no ha llegado a su valor maximo


    always_comb begin
    case ({q_reset, q_add})
        2'b01: q_next = q_reg + 1; // no ha llegado al máximo -> incrementa
        2'b00: q_next = q_reg;     // ya llegó al máximo -> se mantiene
        default: q_next = {N{1'b0}};
    endcase 
end

    //FFs de Entrada - Sincronizador de dos etapas
    always_ff @(posedge clk) begin
        if (rst == 1'b0) begin
            db_out <= 1'b0;
            dff1   <= 1'b0;
            dff2   <= 1'b0;
            q_reg  <= {N{1'b0}};
        end else begin
            dff1 <= btn_in;
            dff2 <= dff1;
            q_reg <= q_next;
        end
    end

    always_ff @(posedge clk) begin
        if(q_reg[N-1] == 1'b1) begin //Si el contador ha llegado a su valor maximo, se actualiza la salida del debounce
            db_out <= dff2;
        end
        else begin
            db_out <= db_out; //Mantiene el valor anterior
        end
    end
endmodule