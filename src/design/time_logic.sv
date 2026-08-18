module time_logic #(parameter WIDTH=32, parameter CLK_FREQ = 100_000_000, parameter TICK = 100, parameter UNI_TIEMPO=1000) ( // <-- TODO: Revisar que CLK_FREQ esté bien
  input logic clk,
  input logic rst,
  input logic inicio,
  input logic hit, // <-- Viene desde la FSM
  input logic nueva_partida,

  output logic UP
  );

  localparam [WIDTH-1:0] N_PRESC = (CLK_FREQ / UNI_TIEMPO) * TICK; // <-- Completamente dinámico

  localparam PRESC_WIDTH = $clog2(N_PRESC); // <-- Cantidad de bits para esto

  logic [PRESC_WIDTH-1:0] contador_presc;

  logic tick;
  assign tick = contador_presc == (N_PRESC - 1);

  // Cosas pendientes
  // 1. Prescalador: Genera el tick de 100ms []
  // 2. Registro para dificultad             []
  // 3. Contador de ventana                  []

  //1. Prescalador
  always_ff @(posedge clk) begin
    if(rst || nueva_partida) contador_presc <= 0;
    else if (inicio || (contador_presc == N_PRESC-1)) contador_presc <= 0;
    else contador_presc <= contador_presc + 1;
  end

endmodule
