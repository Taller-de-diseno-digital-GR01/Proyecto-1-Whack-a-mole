`timescale 1ns/1ps

module tb_hit_counter;

  localparam MAX_ACIERTO_TB = 99; // <-- techo real de la tarjeta

  logic clk_tb;
  logic rst_tb;
  logic nueva_partida_tb;
  logic hit_tb;

  logic [7:0] acierto_tb;
  int hits_T; // cuenta cuantos hit_pulso se han mandado, para los $display (hits TOTALES)

  hit_counter #(
    .MAX_ACIERTO(MAX_ACIERTO_TB)
  ) dut_hit_counter (
    .clk(clk_tb),
    .rst(rst_tb),
    .nueva_partida(nueva_partida_tb),
    .hit(hit_tb),
    .acierto(acierto_tb)
  );

  always #5 clk_tb = ~clk_tb;

  task automatic hit_pulso; // El pulto es un hit cada ciclo
    begin
      hit_tb = 1;
      #10;
      hit_tb = 0;
      #10;
      hits_T = hits_T + 1;
    end
  endtask

  initial begin
    $dumpfile("tb_hit_counter.vcd");
    $dumpvars(0, tb_hit_counter);

    // Todas en reposo, rst arranca en 1 para forzar el reset inicial
    clk_tb = 0;
    rst_tb = 1;
    nueva_partida_tb = 0;
    hit_tb = 0;

    #20;
    rst_tb = 0;

    #10; // <-- tiempo despues soltar el rst
    $display("RESET: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    repeat (9) hit_pulso(); // incremento normal hasta justo antes del acarreo
    $display("%0d hits: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", hits_T, acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    hit_pulso(); // este hit hace el acarreo, unidades vuelve a 0 y decenas sube
    $display("%0d hits ( primer & único acarreo): acierto=%0d (decenas=%0d unidades=%0d) t=%0t", hits_T, acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    repeat (MAX_ACIERTO_TB - hits_T - 1) hit_pulso(); // sigue subiendo normal hasta casi llegar a MAX_ACIERTO_TB
    $display("%0d hits: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", hits_T, acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    hit_pulso(); // este hit llega exacto al techo
    $display("%0d hits (máx): acierto=%0d (decenas=%0d unidades=%0d) t=%0t", hits_T, acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    hit_pulso(); // un hit de más, ya saturado, no debe subir
    $display("%0d hits (máx): acierto=%0d (decenas=%0d unidades=%0d) t=%0t", hits_T, acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    // nueva_partida y hit a la vez: el reset debe ganar
    #10;
    nueva_partida_tb = 1;
    hit_tb           = 1;
    #10;
    nueva_partida_tb = 0;
    hit_tb           = 0;
    #10;
    $display("NUEVA_PARTIDA + HIT simultáneo: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    hit_pulso(); // <-- Vuelve a subir para probar que rst también gana sobre un hit simultáneo
    $display("HIT tras nueva_partida: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    #10;
    rst_tb = 1;
    hit_tb = 1;
    #10;
    rst_tb = 0;
    hit_tb = 0;
    #10;
    $display("RST + HIT simultáneo: acierto=%0d (decenas=%0d unidades=%0d) t=%0t", acierto_tb, dut_hit_counter.decenas, dut_hit_counter.unidades, $time);

    #20; // <-- margen final antes de terminar
    $finish;
  end

endmodule

// Los resultados tienen sentido. El acarreo pasa justo en el hit 10, cuando unidades ya
// había llegado a 9. En el hit 99 el contador llega exacto al techo con decenas=9 y
// unidades=9, y en el hit 100 se queda igual porque ya está saturado.
