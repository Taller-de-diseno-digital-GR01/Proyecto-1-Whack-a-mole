// Recibe acierto[7:0] y fallo[7:0] crudos de hit_counter y fail_counter (ver m05 y m06) y los saca por 4 displays de 7 segmentos multiplexados, como trae la Basys3 seg y an son activo bajo porque así los maneja la tarjeta
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

  // Selector de dígito, avanza uno con cada tick de refresco y da la vuelta solo
  logic [1:0] sel;

  always_ff @(posedge clk) begin
    if (rst)
      sel <= 0;
    else if (tick)
      sel <= sel + 1;
    else
      sel <= sel;
  end

  // an3 an2 muestran acierto (decenas, unidades), an1 an0 muestran fallo (decenas, unidades)
  logic [3:0] digito;

  always_comb begin
    case (sel)
      2'd0: digito = fallo[3:0];
      2'd1: digito = fallo[7:4];
      2'd2: digito = acierto[3:0];
      2'd3: digito = acierto[7:4];
    endcase
  end

  always_comb begin
    case (sel)
      2'd0: an = 4'b1110;
      2'd1: an = 4'b1101;
      2'd2: an = 4'b1011;
      2'd3: an = 4'b0111;
    endcase
  end

  // decodificador BCD a 7 seg
  always_comb begin // TODO: Revisar que esto esté bien asignado
    case (digito)
      4'd0: seg = 7'b1000000;
      4'd1: seg = 7'b1111001;
      4'd2: seg = 7'b0100100;
      4'd3: seg = 7'b0110000;
      4'd4: seg = 7'b0011001;
      4'd5: seg = 7'b0010010;
      4'd6: seg = 7'b0000010;
      4'd7: seg = 7'b1111000;
      4'd8: seg = 7'b0000000;
      4'd9: seg = 7'b0010000;
      default: seg = 7'b1111111; // apagado, digito bcd solo debería llegar de 0 a 9
    endcase
  end

endmodule
