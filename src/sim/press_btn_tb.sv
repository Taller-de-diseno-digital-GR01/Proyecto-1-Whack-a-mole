`timescale 1ns/1ps

module press_btn_tb;

    localparam N_SIM = 4;

    logic       clk, rst;
    logic       btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7;
    logic [2:0] pos_topo;
    logic       valid;

    press_btn dut (
        .clk(clk), .rst(rst),
        .btn_0(btn_0), .btn_1(btn_1), .btn_2(btn_2), .btn_3(btn_3),
        .btn_4(btn_4), .btn_5(btn_5), .btn_6(btn_6), .btn_7(btn_7),
        .pos_topo(pos_topo), .valid(valid)
    );

    defparam dut.db0.N = N_SIM;
    defparam dut.db1.N = N_SIM;
    defparam dut.db2.N = N_SIM;
    defparam dut.db3.N = N_SIM;
    defparam dut.db4.N = N_SIM;
    defparam dut.db5.N = N_SIM;
    defparam dut.db6.N = N_SIM;
    defparam dut.db7.N = N_SIM;

    always #5 clk = ~clk;

    task clear_btns();
        {btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7} = 8'b0;
    endtask

    task press_button(input integer idx);
        clear_btns();
        case (idx)
            0: btn_0 = 1'b1;  1: btn_1 = 1'b1;  2: btn_2 = 1'b1;  3: btn_3 = 1'b1;
            4: btn_4 = 1'b1;  5: btn_5 = 1'b1;  6: btn_6 = 1'b1;  7: btn_7 = 1'b1;
        endcase
        repeat (2*(2**N_SIM)) @(posedge clk);
        clear_btns();
        repeat (2*(2**N_SIM)) @(posedge clk);
    endtask

    task check(input [8*20:1] name, input expected);
        if (valid !== expected)
            $display("FAIL %0s: valid=%b expected=%b @%0t", name, valid, expected, $time);
        else
            $display("PASS %0s", name);
    endtask

    initial begin
        clk = 0; rst = 0;
        clear_btns();
        pos_topo = 3'b000;

        repeat (5) @(posedge clk);
        rst = 1;
        repeat (5) @(posedge clk);

        pos_topo = 3'b000; press_button(0); check("btn correcto",   1'b1);
        pos_topo = 3'b011; press_button(1); check("btn incorrecto", 1'b0);

        pos_topo = 3'b000; clear_btns();
        repeat (2*(2**N_SIM)) @(posedge clk);
        check("sin boton", 1'b0);

        pos_topo = 3'b101; press_button(5); check("btn correcto pos5", 1'b1);

        $finish;
    end

endmodule