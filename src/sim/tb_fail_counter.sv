`timescale 1ns/1ps

module tb_fail_counter;

  localparam MAX_FALLOS_TB = 99; // <-- techo real de la tarjeta

  logic clk_tb;
  logic rst_tb;
  logic nueva_partida_tb;
  logic miss_tb;
  logic hit_tb;

  logic [7:0] fallo_tb;
  logic fin_partida_tb;
  int misses_T; // cuenta cuantos miss_pulso se han mandado, para los $display (misses TOTALES)

  fail_counter #(
    .MAX_FALLOS(MAX_FALLOS_TB)
  ) dut_fail_counter (
    .clk(clk_tb),
    .rst(rst_tb),
    .miss(miss_tb),
    .hit(hit_tb),
    .nueva_partida(nueva_partida_tb),
    .fallo(fallo_tb),
    .fin_partida(fin_partida_tb)
  );

  always #5 clk_tb = ~clk_tb;

  task automatic miss_pulso; // El pulso es un miss cada ciclo
    begin
      miss_tb = 1;
      #10;
      miss_tb = 0;
      #10;
      misses_T = misses_T + 1;
    end
  endtask

  task automatic hit_pulso; // El pulso es un hit cada ciclo, sirve para romper la racha de consecutivos
    begin
      hit_tb = 1;
      #10;
      hit_tb = 0;
      #10;
    end
  endtask

  initial begin
    $dumpfile("tb_fail_counter.vcd");
    $dumpvars(0, tb_fail_counter);

    // Todas en reposo, rst arranca en 1 para forzar el reset inicial
    clk_tb = 0;
    rst_tb = 1;
    nueva_partida_tb = 0;
    miss_tb = 0;
    hit_tb = 0;
    misses_T = 0;

    #20;
    rst_tb = 0;

    #10; // <-- tiempo despues soltar el rst
    $display("\n\nRESET: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    // Parte 1, acumulado BCD igual que tb_hit_counter pero con miss, fin_partida queda en 1 desde el tercer miss porque nada la limpia aca
    repeat (9) miss_pulso(); // incremento normal hasta justo antes del acarreo
    $display("\nParte 1");
    $display("%0d misses: fallo=%0d (decenas=%0d unidades=%0d) consecutivos=%0d fin_partida=%b t=%0t", misses_T, fallo_tb, dut_fail_counter.decenas, dut_fail_counter.unidades, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    miss_pulso(); // este miss hace el acarreo, unidades vuelve a 0 y decenas sube
    $display("%0d misses (primer & único acarreo): fallo=%0d (decenas=%0d unidades=%0d) consecutivos=%0d fin_partida=%b t=%0t", misses_T, fallo_tb, dut_fail_counter.decenas, dut_fail_counter.unidades, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    repeat (MAX_FALLOS_TB - misses_T - 1) miss_pulso(); // sigue subiendo normal hasta casi llegar a MAX_FALLOS_TB
    $display("%0d misses: fallo=%0d (decenas=%0d unidades=%0d) consecutivos=%0d fin_partida=%b t=%0t", misses_T, fallo_tb, dut_fail_counter.decenas, dut_fail_counter.unidades, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    miss_pulso(); // este miss llega exacto al techo
    $display("%0d misses (máx): fallo=%0d (decenas=%0d unidades=%0d) consecutivos=%0d fin_partida=%b t=%0t", misses_T, fallo_tb, dut_fail_counter.decenas, dut_fail_counter.unidades, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    miss_pulso(); // un miss de más, ya en el máx, no debe subir
    $display("%0d misses (máx): fallo=%0d (decenas=%0d unidades=%0d) consecutivos=%0d fin_partida=%b t=%0t", misses_T, fallo_tb, dut_fail_counter.decenas, dut_fail_counter.unidades, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    // Parte 2, racha de consecutivos y fin_partida
    #10;
    nueva_partida_tb = 1; // limpia fallo, consecutivos y fin_partida, arranca partida nueva
    #10;
    nueva_partida_tb = 0;
    #10;
    $display("\nParte 2: Racha de consecutivos & fin_partida");
    $display("NUEVA_PARTIDA: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    repeat (2) miss_pulso(); // dos fallos seguidos, racha a punto de terminar la partida
    $display("2 misses seguidos: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    hit_pulso(); // el hit rompe la racha, pero NO debe tocar el acumulado fallo
    $display("HIT rompe la racha: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    repeat (3) miss_pulso(); // tres fallos seguidos, ahora sí se cumple la condición de fin de partida
    $display("3 misses seguidos: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    miss_pulso(); // un cuarto miss seguido, consecutivos y fin_partida ya en el máx 3/1
    $display("4to miss seguido (máx): fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    hit_pulso(); // el hit limpia la racha y fin_partida aunque la partida ya "había terminado" para este módulo
    $display("HIT tras fin_partida: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    // Parte 3, reset simultáneo con miss
    #10;
    nueva_partida_tb = 1;
    miss_tb = 1;
    #10;
    nueva_partida_tb = 0;
    miss_tb = 0;
    #10;
    $display("\nParte 3: Reset simultáneo con miss");
    $display("NUEVA_PARTIDA + MISS simultáneo: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    #10;
    rst_tb = 1;
    miss_tb = 1;
    #10;
    rst_tb = 0;
    miss_tb = 0;
    #10;
    $display("RST + MISS simultáneo: fallo=%0d consecutivos=%0d fin_partida=%b t=%0t", fallo_tb, dut_fail_counter.consecutivos, fin_partida_tb, $time);

    #20; // <-- margen final antes de terminar
    $finish;
  end

endmodule

// Parte 1, acarreo justo en el miss 10, techo exacto en el miss 99, en el máx desde el miss 100, consecutivos/fin_partida en 3/1 desde el miss 3
// Parte 2, un hit limpia consecutivos y fin_partida sin bajar fallo, y 3 miss seguidos sí activan fin_partida
// Parte 3, nueva_partida+miss y rst+miss simultáneos terminan en todo cero, el reset gana sobre el miss
