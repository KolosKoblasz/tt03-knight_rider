`default_nettype none

module rate_ctrl #
(
    parameter CLK_FREQ
)
(
    input               clk,
    input               reset,
    input               change_rate,
    output              next_pos
);
    localparam RISING_EDGE  = 2'b10;

    localparam RATE_VERY_SLOW   = (CLK_FREQ    / 0.5) - 1;
    localparam RATE_SLOW        = (CLK_FREQ    / 1  ) - 1;
    localparam RATE_NORMAL      = (CLK_FREQ    / 2  ) - 1;
    localparam RATE_FAST        = (CLK_FREQ    / 4  ) - 1;
    localparam RATE_VERY_FAST   = (CLK_FREQ    / 8  ) - 1;

    // Input sync and edge detection
    reg [3:0]  change_rate_shr;
    wire       next_rate;

    // This shift register performs cdc syncronizations
    // 2 stages for syncing inputs to clk and
    // 2 stages for edge detection
    always @(posedge clk) begin
        if (reset) begin
            change_rate_shr <= 0;

        end
        else begin
            change_rate_shr <= {change_rate_shr [2:0] , change_rate};

        end
    end

    // Rising edge detection
    assign next_rate       = (change_rate_shr [3:2] == RISING_EDGE) ? 1'b1 : 1'b0 ;

    // Rate counter
    reg [13:0]  rate_counter;

    assign      next_pos =  (rate_counter >= rc_max_value) ? 1'b1 : 1'b0; // Move active bit

    // This counter controls when the active bit will move
    always @(posedge clk) begin
        if (reset) begin
            rate_counter <= 0;
        end
        else begin
            if (rate_counter >= rc_max_value) begin // Reset the counter if max value reached
                rate_counter <= 0;
            end
            else begin // Increment the counter
                rate_counter <= rate_counter + 1;
            end
        end
    end

    // Rate control
    reg [2:0]  rate_ctrl;

    // This register controls how fast the
    // active led is moving.
    always @(posedge clk) begin
        if (reset) begin
            rate_ctrl <= 2; // Use RATE_NORMAL
        end
        else begin
            if (next_rate) begin // Change rate
                if (rate_ctrl >= 4) begin
                    rate_ctrl <= 0; // Max rate can not be increased. Move to slowest.
                end
                else begin
                    rate_ctrl <= rate_ctrl + 1; // Increase rate by one.
                end
            end
        end
    end

    logic [13:0] rc_max_value; // This variable contains the max value of the rate counter

    // Rate control mux
    always @(*) begin
        case (rate_ctrl)
            0 : rc_max_value = RATE_VERY_SLOW;
            1 : rc_max_value = RATE_SLOW;
            2 : rc_max_value = RATE_NORMAL;
            3 : rc_max_value = RATE_FAST;
            4 : rc_max_value = RATE_VERY_FAST;
            default : rc_max_value = RATE_NORMAL;
        endcase
    end

endmodule
