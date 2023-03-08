`default_nettype none

module light_shift #
(
    parameter OUT_WIDTH = 8
)
(
    input                     clk,
    input                     reset,
    input                     next_pos,
    input                     pwm_enable,
    output [OUT_WIDTH-1:0]    leds
);

    localparam LEFT       = 1'b1;
    localparam RIGHT      = 1'b0;
    localparam LEFT_END   = 2'b10;
    localparam RIGHT_END  = 2'b01;

    // LED shift register
    reg [OUT_WIDTH-1:0]  led_shr;

    // This shift register is responsible
    // for moving the active bit to left and right.
    always @(posedge clk) begin
        if (reset) begin
            led_shr <= 1;
        end
        else begin
            if (next_pos) begin // Move active bit
                if (dir == LEFT) begin // Move active bit to the left by one
                    led_shr <= {led_shr[OUT_WIDTH-2:0] , 1'b0 };
                end
                else begin // Move active bit to the right by one
                    led_shr <= {1'b0 ,led_shr[OUT_WIDTH-1:1]  };
                end
            end
        end
    end


    // Direction bit
    reg dir;

    // Setting the direction bit
    always @(posedge clk) begin
        if (reset) begin
            dir <= LEFT;

        end
        else begin
            if (led_shr[OUT_WIDTH-1:OUT_WIDTH-2] == LEFT_END) begin // Active bit is at the left most position
                dir <= RIGHT;
            end
            else if (led_shr[1:0] == RIGHT_END) begin // Active bit is at the right most position
                dir <= LEFT;
            end
        end
    end


    for (genvar i = 0; i < OUT_WIDTH; i = i + 1 ) begin
        assign leds[i] = led_shr[i] & pwm_enable;
    end

endmodule
