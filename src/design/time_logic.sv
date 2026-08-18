module time_logic #(parameter VENTANA=4) ( // <-- Es una ventana de 4 bits
  input logic clk,
  input logic rst,
  input logic inicio,
  input logic hit, // <-- Viene desde la FSM
  input logic nueva_partida,

  output logic UP
  );

  always_ff @(posedge clk) begin
  end

endmodule
