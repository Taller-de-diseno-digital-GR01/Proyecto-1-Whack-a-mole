// Todo esto está basado en m04_time_logic.md
module time_logic #(
  parameter CLK_FREQ = 100_000_000, // <-- TODO: Revisar que CLK_FREQ esté bien
  parameter TICK = 100,
  parameter UNI_TIEMPO=1000,
  parameter VENTANA_INICIAL = 3000,
  parameter VENTANA_MINIMA = 500
  ) (
  input logic clk,
  input logic rst_dificulty, // Reset de la dificultad (ventana_ticks): solo en partida nueva
  input logic rst_window,    // Reset del contador de ventana (contador_ventana): cada ronda + partida nueva
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
    contador_presc <= (rst_dificulty | rst_window | nueva_partida | inicio | (contador_presc == N_PRESC-1)) ? 0 : contador_presc + 1; // TODO: Revisar este warning + situación ternária
  end


  // 2. Registro para dificultad
  localparam VENTANA_TICKS_INICIAL = VENTANA_INICIAL / TICK; // <-- Son los 1.5s que el enunciado menciona
  localparam VENTANA_TICKS_MINIMA = VENTANA_MINIMA / TICK; // <-- Dificultad máxima de solo 500ms
  localparam VENTANA_TICKS_WIDTH = $clog2(VENTANA_TICKS_INICIAL+1);

  logic [VENTANA_TICKS_WIDTH-1:0] ventana_ticks; // 4 bits, da espacio para 15  niveles de dificultad

  always_ff @(posedge clk) begin // TODO: Pasar esto a un operador ternário
    if(rst_dificulty | nueva_partida) ventana_ticks <= VENTANA_TICKS_INICIAL;
    else if(hit & (ventana_ticks > VENTANA_TICKS_MINIMA)) ventana_ticks <= ventana_ticks - 1;
    else ventana_ticks <= ventana_ticks;
  end


  // 3. Contador de ventana
  logic [VENTANA_TICKS_WIDTH-1:0] contador_ventana;

  always_ff @(posedge clk) begin
    if(rst_dificulty | nueva_partida | rst_window) contador_ventana <= 0;
    else if(inicio) contador_ventana <= ventana_ticks;
    else if(hit) contador_ventana <= contador_ventana;
    else if(tick & (contador_ventana != 0)) contador_ventana <= contador_ventana - 1;
    else contador_ventana <= contador_ventana;
  end

  assign UP = tick & (contador_ventana == 0) & !hit & !inicio & !(rst_dificulty | nueva_partida | rst_window); // TODO: Revisar que esto esté bien

endmodule