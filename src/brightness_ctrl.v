`default_nettype none

module brightness_ctrl #
(
    parameter CLK_FREQ
)
(
    input               clk,
    input               reset,
    input               change_brightness,
    output              pwm_enable
);
    localparam RISING_EDGE  = 2'b10;

    localparam PWM_RATE   = (CLK_FREQ    / 50  ) - 1; // Active lead blinks on and off 50 times per second
    localparam PWM_25     = (PWM_RATE    * 1 / 4) - 1; // Active lead is on in  25% of the PWM period
    localparam PWM_50     = (PWM_RATE    * 2 / 4) - 1; // Active lead is on in  50% of the PWM period
    localparam PWM_75     = (PWM_RATE    * 3 / 4) - 1; // Active lead is on in  75% of the PWM period
    localparam PWM_100    = (PWM_RATE    * 4 / 4) - 1; // Active lead is on in 100% of the PWM period

    localparam PWM_CNTR_WIDTH = 7; // Depends on the ratio of CLK_FREQ and PWM frequency)

    // Input sync and edge detection
    reg [3:0]  brightness_shr;
    wire       next_brightness;

    // This shift register performs cdc syncronizations
    // 2 stages for syncing inputs to clk and
    // 2 stages for edge detection
    always @(posedge clk) begin
        if (reset) begin
            brightness_shr  <= 0;
        end
        else begin
            brightness_shr  <= {brightness_shr  [2:0] , change_brightness };
        end
    end

    // Rising edge detection
    assign next_brightness = (brightness_shr  [3:2] == RISING_EDGE) ? 1'b1 : 1'b0 ;


    // This variable defines the PWM periods.
    reg [PWM_CNTR_WIDTH-1:0] pwm_cntr;

    // PWM counter incremented here
    always @(posedge clk) begin
        if (reset) begin
            pwm_cntr <= 0;
        end
        else begin
            if (pwm_cntr >= PWM_RATE) begin // Reset the counter if max value reached
                pwm_cntr <= 0;
            end
            else begin // Increment the counter
                pwm_cntr <= pwm_cntr + 1;
            end
        end
    end

    // This varaible controls how bright the active LED is.
    reg [1:0]  brightness_sel; //Select 1 of the 4 possible brightness levels.

    // Brightness control
    always @(posedge clk) begin
        if (reset) begin
            brightness_sel <= 3; // Max brightness
        end
        else begin
            if (next_brightness) begin // Change brightness
                if (brightness_sel >= 3) begin
                    brightness_sel <= 0; // Max brightness can not be increased. Set minimum.
                end
                else begin
                    brightness_sel <= brightness_sel + 1; // Increase brightness by one.
                end
            end
        end
    end


    logic [PWM_CNTR_WIDTH-1:0] brightness_level; // This variable contains how long should be
                                                // the active LED switched on in a PWM period.

    // Rate control mux
    always @(*) begin
        case (brightness_sel)
            0 : brightness_level = PWM_25;
            1 : brightness_level = PWM_50;
            2 : brightness_level = PWM_75;
            3 : brightness_level = PWM_100;
            default : brightness_level = PWM_100;
        endcase
    end

    assign pwm_enable = (pwm_cntr <= brightness_level) ? 1'b1 : 1'b0; // This variable enables the active LED.

endmodule
