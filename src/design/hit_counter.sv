module hit_counter #(
  parameter CLK_FREQ = 100_000_000, // <-- TODO: Revisar que CLK_FREQ esté bien
  parameter TICK = 100,
  parameter UNI_TIEMPO=1000,
  parameter VENTANA_INICIAL = 1500,
  parameter VENTANA_MINIMA = 500
  ) (
  input logic clk,
  input logic rst,
  input logic nueva_partida,
  input logic hit,

  output logic [7:0] acierto
  );
endmodule
