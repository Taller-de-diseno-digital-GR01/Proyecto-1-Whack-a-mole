// Todo esto está basado en m04_time_logic.md
module time_logic #(
  parameter CLK_FREQ = 100_000_000, // <-- TODO: Revisar que CLK_FREQ esté bien
  parameter TICK = 100,
  parameter UNI_TIEMPO=1000,
  parameter VENTANA_INICIAL = 1500,
  parameter VENTANA_MINIMA = 500
  ) (
  input logic clk,
  input logic rst,
  input logic inicio,
  input logic hit, // <-- Viene desde la FSM
  input logic nueva_partida,

  output logic UP
  );

  // Cosas pendientes
  // 1. Prescalador: Genera el tick de 100ms [x]
  // 2. Registro para dificultad             [x]
  // 3. Contador de ventana                  []

  //1. Prescalador
  localparam int N_PRESC = (CLK_FREQ / UNI_TIEMPO) * TICK; // <-- Completamente dinámico, tiempo para llegar a 100ms
  localparam PRESC_WIDTH = $clog2(N_PRESC); // <-- Cantidad de bits para esto

  logic [PRESC_WIDTH-1:0] contador_presc;
  logic tick;
  assign tick = (contador_presc == (N_PRESC - 1)); // TODO: Revisar este warning
  // La idea de tick es que es 1 cuando contador_presc (que se actualiza por el ff) sea igual al máximo que se puede llegar (100ms)
  // O sea, hay un tick cada 100ms

  always_ff @(posedge clk) begin
    if(rst | nueva_partida) contador_presc <= 0;
    else if (inicio | (contador_presc == N_PRESC-1)) contador_presc <= 0; // TODO: Revisar este warning
    else contador_presc <= contador_presc + 1;
  end


  // 2. Registro para dificultad
  localparam DIFICULTAD_INICIAL = VENTANA_INICIAL / TICK; // <-- Son los 1.5s que el enunciado menciona
  localparam DIFICULTAD_MINIMA = VENTANA_MINIMA / TICK; // <-- Dificultad máxima de solo 500ms
  localparam NIVS_DIFICULTAD = $clog2(DIFICULTAD_INICIAL+1);

  logic [NIVS_DIFICULTAD-1:0] dificultad; // 4 bits, da espacio para 15  niveles de dificultad

  always_ff @(posedge clk) begin
    if(rst | nueva_partida) dificultad <= DIFICULTAD_INICIAL;
    else if(hit & (dificultad > DIFICULTAD_MINIMA)) dificultad <= dificultad - 1;
    else dificultad <= dificultad;
  end


  // 3. Contador de ventana

endmodule
