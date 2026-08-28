`timescale 1ns/1ps

module fsm_tb;

    localparam logic [2:0] START=0, REQ_POS=1, WAIT_UART=2, PLAY=3,
                            FAILURE=4, HIT=5, GAME_OVER=6;

    logic clk, rst, req_sent, valid_pos, hit, miss, window_exp, cont_failure, fin_espera;
    logic rst_dificulty, rst_hits, rst_failures, en_numRandom, en_save_pos;
    logic add_hit, add_failure, rst_window, inc_dificulty;
    logic [2:0] current_state_out;
    logic f_state_play, f_state_gameover;

    int errors = 0;

    fsm dut (.*);

    always #5 clk = ~clk;
    initial clk = 0;

    task automatic tick();
        @(posedge clk); #1;
    endtask

    task automatic check(logic [2:0] exp, string msg);
        if (current_state_out !== exp) begin
            errors++;
            $display("FAIL: %s (esperado %0d, obtenido %0d)", msg, exp, current_state_out);
        end
    endtask

    initial begin
        $dumpfile("tb_fsm.vcd");
        $dumpvars(0, fsm_tb);

        rst=1; req_sent=0; valid_pos=0; hit=0; miss=0; window_exp=0; cont_failure=0; fin_espera=0;
        tick(); tick();
        rst=0; tick();
        check(REQ_POS, "reset->REQ_POS");

        // camino feliz -> HIT
        req_sent=1; tick(); req_sent=0;
        check(WAIT_UART, "REQ_POS->WAIT_UART");

        valid_pos=1; tick(); valid_pos=0;
        check(PLAY, "WAIT_UART->PLAY");

        hit=1; tick(); hit=0;
        check(HIT, "PLAY(hit)->HIT");
        tick();
        check(REQ_POS, "HIT->REQ_POS");

        // miss -> FAILURE -> REQ_POS
        req_sent=1; tick(); req_sent=0;
        valid_pos=1; tick(); valid_pos=0;
        miss=1; tick(); miss=0;
        check(FAILURE, "PLAY(miss)->FAILURE");
        tick();
        check(REQ_POS, "FAILURE->REQ_POS");

        // window_exp -> FAILURE
        req_sent=1; tick(); req_sent=0;
        valid_pos=1; tick(); valid_pos=0;
        window_exp=1; tick(); window_exp=0;
        check(FAILURE, "PLAY(window_exp)->FAILURE");

        // hit y miss simultaneos -> prioridad hit
        cont_failure=0; tick();
        req_sent=1; tick(); req_sent=0;
        valid_pos=1; tick(); valid_pos=0;
        hit=1; miss=1; tick(); hit=0; miss=0;
        check(HIT, "hit+miss->HIT (prioridad)");
        tick();

        // cont_failure -> GAME_OVER -> START -> REQ_POS
        req_sent=1; tick(); req_sent=0;
        valid_pos=1; tick(); valid_pos=0;
        miss=1; cont_failure=1; tick(); miss=0;
        check(FAILURE, "PLAY(miss)->FAILURE");
        tick();
        check(GAME_OVER, "FAILURE(cont_failure)->GAME_OVER");
        cont_failure=0; tick();
        check(GAME_OVER, "GAME_OVER se mantiene sin fin_espera");
        fin_espera=1; tick(); fin_espera=0;
        check(START, "GAME_OVER->START (fin_espera)");
        tick();
        check(REQ_POS, "START->REQ_POS");

        // reset (fsm.sv lo tiene sincrono, solo aplica en el flanco de clk)
        req_sent=1; tick(); req_sent=0;
        rst=1; tick();
        check(START, "reset sincrono->START");
        rst=0; tick();
        check(REQ_POS, "START->REQ_POS");

        if (errors == 0) $display("PASS: todos los tests OK");
        else $display("FAIL: %0d test(s) fallaron", errors);
        $finish;
    end

    initial begin
        #2000;
        $display("TIMEOUT");
        $finish;
    end

endmodule