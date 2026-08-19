`timescale 1ns/1ps

module tb_time_logic;

  localparam CLK_FREQ_TB    = 1000;
  localparam UNI_TIEMPO_TB  = 1000;
  localparam TICK_TB        = 4;
  localparam VENTANA_INI_TB = 12; // 3 ticks
  localparam VENTANA_MIN_TB = 4;  // 1 tick

  logic clk_tb;
  logic rst_tb;
  logic inicio_tb;
  logic hit_tb;
  logic nueva_partida_tb;

  logic UP_tb;

  time_logic #(
    .CLK_FREQ(CLK_FREQ_TB),
    .TICK(TICK_TB),
    .UNI_TIEMPO(UNI_TIEMPO_TB),
    .VENTANA_INICIAL(VENTANA_INI_TB),
    .VENTANA_MINIMA(VENTANA_MIN_TB)
  ) dut_time_logic (
    .clk(clk_tb),
    .rst(rst_tb),
    .inicio(inicio_tb),
    .hit(hit_tb),
    .nueva_partida(nueva_partida_tb),
    .UP(UP_tb)
  );

  always #5 clk_tb = ~clk_tb;

  initial begin
    $dumpfile("tb_time_logic.vcd");
    $dumpvars(0, tb_time_logic);

    // Todas en reposo, rst arranca en 1 para forzar el reset inicial
    clk_tb           = 0;
    rst_tb           = 1;
    inicio_tb        = 0;
    hit_tb           = 0;
    nueva_partida_tb = 0;

    #20;
    rst_tb = 0;

    #10; // <-- Un ciclo de margen despues de soltar el rst
    inicio_tb = 1;
    #10;
    inicio_tb = 0;

    #155; // <-- 3 ticks completos (3*4*10=120) mas el tick donde se activa UP, con margen para caer dentro de esos 10ns
    $display("SIN HIT: UP=%b ventana_ticks=%0d t=%0t", UP_tb, dut_time_logic.ventana_ticks, $time);

    #10;
    nueva_partida_tb = 1;
    #10;
    nueva_partida_tb = 0;

    #10;
    inicio_tb = 1;
    #10;
    inicio_tb = 0;

    #10;
    hit_tb = 1;
    #10;
    hit_tb = 0;

    #10; // <-- Deja que el ff termine de actualizar antes de leer los registros
    $display("HIT 1: ventana_ticks=%0d contador_ventana=%0d t=%0t", dut_time_logic.ventana_ticks, dut_time_logic.contador_ventana, $time);

    #10;
    hit_tb = 1;
    #10;
    hit_tb = 0;

    #10;
    $display("HIT 2: ventana_ticks=%0d t=%0t", dut_time_logic.ventana_ticks, $time);

    #10;
    hit_tb = 1;
    #10; // <-- hit dura un ciclo, este es el que prueba que no baje del minimo
    hit_tb = 0;

    #10; // <-- Deja que el ff termine de actualizar
    $display("HIT 3: ventana_ticks=%0d t=%0t", dut_time_logic.ventana_ticks, $time);

    #20; // <-- Margen final antes de terminar
    $finish;
  end

endmodule
