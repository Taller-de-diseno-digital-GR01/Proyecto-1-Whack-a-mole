`timescale 1ns/1ps

module press_btn_tb;

    localparam N_SIM = 4;

    logic       clk, rst;
    logic       btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7;
    logic [2:0] pos_topo;
    logic       valid;
    logic       valid_seen; // valid es un pulso de un ciclo, esto acumula si aparecio durante la ventana

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

    // Espera n ciclos mientras acumula en valid_seen si valid se activo en alguno
    task wait_and_monitor(input integer n);
        integer i;
        for (i = 0; i < n; i = i + 1) begin
            @(posedge clk);
            if (valid) valid_seen = 1'b1;
        end
    endtask

    // Presiona el botón idx y lo MANTIENE presionado (no lo suelta),
    // esperando suficientes ciclos para que el debounce se estabilice.
    // valid_seen recoge si el pulso de valid aparecio en algun punto de esa ventana.
    task press_and_hold(input integer idx);
        clear_btns();
        case (idx)
            0: btn_0 = 1'b1;  1: btn_1 = 1'b1;  2: btn_2 = 1'b1;  3: btn_3 = 1'b1;
            4: btn_4 = 1'b1;  5: btn_5 = 1'b1;  6: btn_6 = 1'b1;  7: btn_7 = 1'b1;
        endcase
        valid_seen = 1'b0;
        wait_and_monitor(3*(2**N_SIM)); // margen amplio para que db_out se actualice
    endtask

    // Suelta todos los botones y espera a que el debounce también se
    // estabilice en el estado "soltado" antes de la siguiente prueba.
    task release_and_wait();
        clear_btns();
        repeat (3*(2**N_SIM)) @(posedge clk);
    endtask

    task check(input [8*20:1] name, input expected);
        if (valid_seen !== expected)
            $display("FAIL %0s: valid_seen=%b expected=%b @%0t", name, valid_seen, expected, $time);
        else
            $display("PASS %0s", name);
    endtask

    initial begin
        $dumpfile("tb_press_btn.vcd");
        $dumpvars(0, press_btn_tb);

        clk = 0; rst = 0;
        clear_btns();
        pos_topo = 3'b000;

        repeat (5) @(posedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        // Caso 1: botón correcto -> valid debe ser 1 MIENTRAS está presionado
        pos_topo = 3'b000;
        press_and_hold(0);
        check("btn correcto", 1'b1);
        release_and_wait();

        // Caso 2: botón incorrecto -> valid debe quedarse en 0
        pos_topo = 3'b011;
        press_and_hold(1);
        check("btn incorrecto", 1'b0);
        release_and_wait();

        // Caso 3: sin botón presionado -> valid debe ser 0 (sin falso positivo)
        pos_topo = 3'b000;
        clear_btns();
        valid_seen = 1'b0;
        wait_and_monitor(3*(2**N_SIM));
        check("sin boton", 1'b0);

        // Caso 4: botón correcto en otra posición
        pos_topo = 3'b101;
        press_and_hold(5);
        check("btn correcto pos5", 1'b1);
        release_and_wait();

        $finish;
    end

endmodule