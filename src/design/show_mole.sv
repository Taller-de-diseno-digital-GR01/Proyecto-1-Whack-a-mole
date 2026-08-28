module show_mole (
    input  logic [2:0] pos_topo,
    input  logic       en_topo,
    output logic [7:0] leds_topo
);

    always_comb begin

        leds_topo = 8'b0000_0000;

        if (en_topo) begin
            case (pos_topo)

                3'b000: leds_topo = 8'b0000_0001;
                3'b001: leds_topo = 8'b0000_0010;
                3'b010: leds_topo = 8'b0000_0100;
                3'b011: leds_topo = 8'b0000_1000;

                3'b100: leds_topo = 8'b0001_0000;
                3'b101: leds_topo = 8'b0010_0000;
                3'b110: leds_topo = 8'b0100_0000;
                3'b111: leds_topo = 8'b1000_0000;

                default: leds_topo = 8'b0000_0000;

            endcase
        end

    end

endmodule