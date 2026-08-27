module edge_detector (
    input  logic clk,
    input  logic rst,
    input  logic level_in,   // señal de nivel (botón/switch debounced)
    output logic pulse_out   // pulso de 1 ciclo en el flanco de subida
);

    logic level_prev;

    always_ff @(posedge clk) begin
        if (rst)
            level_prev <= 1'b0;
        else
            level_prev <= level_in;
    end

    assign pulse_out = level_in & ~level_prev; // detecta 0->1

endmodule