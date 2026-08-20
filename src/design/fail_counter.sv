module fail_hit #(parameter MAX_FALLOS = 99) (
  input logic clk,
  input logic rst,
  input logic miss,
  input logic hit,
  input logic nueva_partida,

  output logic [7:0] fallo
  output logic fin_partida
  );

  always_ff @(posedge clk) begin
    if(rst || nueva_partida) begin
      hit <= 'x;
      miss <= 'x;
    end
  end

endmodule
