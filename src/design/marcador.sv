// Recibe acierto[7:0] y fallo[7:0] crudos de hit_counter y fail_counter (ver m05 y m06) y los saca por 4 displays de 7 segmentos multiplexados, como trae la Basys3
// seg y an son activo bajo porque así los maneja la tarjeta
module marcador #(
  parameter CLK_FREQ = 100_000_000, // <-- TODO: Revisar que CLK_FREQ esté bien
  parameter REFRESH_HZ = 1000 // <-- tasa de refresco del dígito actual, con 4 dígitos el ciclo completo queda en 250 Hz, no se nota parpadeo
  ) (
  input logic clk,
  input logic rst,
  input logic [7:0] acierto, // bcd de hit_counter, [7:4] decenas [3:0] unidades
  input logic [7:0] fallo, // bcd de fail_counter, [7:4] decenas [3:0] unidades

  output logic [6:0] seg, // segmentos gfedcba, compartidos entre los 4 dígitos
  output logic [3:0] an // selector de dígito encendido, uno a la vez
  );

  // Prescalador para el refresco de displays, mismo patrón que el de time_logic
  localparam int N_PRESC = CLK_FREQ / REFRESH_HZ;
  localparam PRESC_WIDTH = $clog2(N_PRESC);

  logic [PRESC_WIDTH-1:0] contador_presc;
  logic tick;
  assign tick = (contador_presc == N_PRESC - 1); // 1 cada vez que el prescalador completa una vuelta

  always_ff @(posedge clk) begin
    contador_presc <= (rst | tick) ? 0 : contador_presc + 1;
  end

endmodule
