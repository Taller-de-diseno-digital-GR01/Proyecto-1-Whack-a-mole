module hit_counter #(parameter MAX_ACIERTO = 99) (  // máximo para el contador
  input logic clk,
  input logic rst,
  input logic nueva_partida, // fsm aquí
  input logic hit,

  output logic [7:0] acierto // bcd --> marcador
  );

  localparam MAX_UNIDADES = MAX_ACIERTO % 10; // dígito de unidades del techo, Ej: 99%10 =9
  localparam MAX_DECENAS  = MAX_ACIERTO / 10; // dígito de decenas del techo, Ej: 99/10 = 9

  logic [3:0] unidades, decenas;

  always_ff @(posedge clk) begin
    if (rst || nueva_partida) begin // reset gana aunque llegue hit el mismo ciclo
      unidades <= 0;
      decenas  <= 0;
    end
    // Acarreo
    else if (hit && unidades == MAX_UNIDADES && decenas != MAX_DECENAS) begin // acierto y unidades llegó al tope, pero decenas todavía no hay acarreo
      unidades <= 0; // acarreo, las unidades a 0, las decenas suben
      decenas  <= decenas + 1;
    end
    // Incremento normal
    else if (hit && unidades != MAX_UNIDADES) begin // acierto y unidades todavía no llega al límite
      unidades <= unidades + 1;
    end
  end

  assign acierto[3:0] = unidades;
  assign acierto[7:4] = decenas;

endmodule
