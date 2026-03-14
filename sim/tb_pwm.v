`timescale 1ns / 1ps

module tb_pwm;

    // semnale TB
    reg clk;
    reg reset;
    reg wr;
    reg high;
    reg per;
    reg [7:0] di;

    wire [7:0] di_switch;
    wire pwm_out;
    wire error_out;
    wire high_led;
    wire wr_led;
    wire per_led;
    wire reset_led;

    // instanțiere DUT
    pwm dut (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .high(high),
        .per(per),
        .di(di),
        .di_switch(di_switch),
        .pwm_out(pwm_out),
        .error_out(error_out)
    );

    // clock 100 MHz (10 ns)
    always #5 clk = ~clk;

    // task pentru scriere registru
    task write_reg;
        input is_per;
        input [7:0] value;
        begin
            @(posedge clk);
            wr   = 1;
            per  = is_per;
            high = ~is_per;
            di   = value;
            @(posedge clk);
            wr   = 0;
            per  = 0;
            high = 0;
        end
    endtask

    initial begin
        // init
        clk   = 0;
        reset = 1;
        wr    = 0;
        per   = 0;
        high  = 0;
        di    = 0;

        // reset
        #20;
        reset = 0;
        write_reg(1, 8'd10); // per
        write_reg(0, 8'd4);  // high

        repeat (25) @(posedge clk);

        write_reg(0, 8'd7);

        repeat (25) @(posedge clk);
        write_reg(1, 8'd8);  // per
        write_reg(0, 8'd12); // high > per

        repeat (20) @(posedge clk);
    end

endmodule
