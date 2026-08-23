//NOTA: Deberíamos eliminar este módulo, lo podemos sacar directamente de la FSM.

module state (
    input   logic f_state_play,
    input   logic f_state_gameover,
    output  logic state_play,
    output  logic state_gameover
);
//No hace falta un if ya que tendrá el valor que tenga en las banderas...


assign state_play = f_state_play; //si estoy en play será un 1
assign state_gameover = f_state_gameover; //si estoy en gameover será un 1

endmodule