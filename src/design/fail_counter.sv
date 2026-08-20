module fail_counter #(parameter MAX_FALLOS = 99) (
  input logic clk,
  input logic rst,
  input logic miss,
  input logic hit,
  input logic nueva_partida,

  output logic [7:0] fallo,
  output logic fin_partida
  );

  // La idea es hacer dos contadores independientes como dice el .md para este diseño en las secciones g) & h)
  // 1. Acumulado en BCD, es la misma idea a lo que ya hice en hit_counter, entonces nada más le voy a cambiar lo que no quiero con miss
  // 2. fin_partida, esto es solo la tabla del punto h) pero implementada

  // 1. De aquí hasta 'FIN' es exáctamente lo mismo que en hit_counter pero con fallo en vez de acierto
  localparam MAX_UNIDADES = MAX_FALLOS % 10; // dígito de unidades del techo, Ej: 99%10 =9
  localparam MAX_DECENAS  = MAX_FALLOS / 10; // dígito de decenas del techo, Ej: 99/10 = 9

  logic [3:0] unidades, decenas;

  always_ff @(posedge clk) begin
    if (rst || nueva_partida) begin // reset gana aunque llegue hit el mismo ciclo
      unidades <= 0;
      decenas  <= 0;
    end
    // Acarreo
    else if (miss && unidades == MAX_UNIDADES && decenas != MAX_DECENAS) begin // acierto y unidades llegó al tope, pero decenas todavía no hay acarreo
      unidades <= 0; // acarreo, las unidades a 0, las decenas suben
      decenas  <= decenas + 1;
    end
    // Incremento normal
    else if (miss && unidades != MAX_UNIDADES) begin // acierto y unidades todavía no llega al límite
      unidades <= unidades + 1;
    end
  end

  assign fallo[3:0] = unidades;
  assign fallo[7:4] = decenas;
  // FIN


  // 2.
  logic [1:0] consecutivos; // <-- Sirve para fallos consecutivos, es interno. 2 bits porque llega hasta el valor '3'

  always_ff @(posedge clk) begin
    if(rst || nueva_partida || hit) begin // Se lee como: "Si hay reset O nueva partida O un hit"
      consecutivos <= 0; // significa que se acabó la racha de fallos o todavía no existe
      fin_partida <= 0; // si la r acha se rompió o la partida está recién arrancada
    end
    else if(miss) begin
      if(consecutivos == 2 || consecutivos == 3) begin // Se lee como: "¿La racha ya estaba a un fallo de terminar, o ya había terminado?"
        consecutivos <= 3; // Deja la racha fija como el máximo 3
        fin_partida <= 1; // 1: True ==> se acabó la partida
      end
      else begin
        consecutivos <= consecutivos + 1; // racha todavía corta (0 o 1), sube uno más
        fin_partida <= 0; // todavía no se llega a 3, la partida sigue
      end
    end
  end

endmodule
