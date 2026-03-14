
module top_pwm(
  input clk,
  input reset,
  input wr,
  input high,
  input per,
  input [7:0]di,
  
  output [7:0]di_switch,  
  output  pwm_out,
  output  error_out
  );
    assign di_switch = di;
 // wire high_sync;
  wire wr_sync;
  //wire per_sync;  
  
  reg [25:0] count_div;
  reg slow_clock;
  
  always @(posedge clk) begin
    if(count_div >=5000000) begin
        count_div<=0;
        slow_clock<=~slow_clock;
    end else begin
        count_div<=count_div+1;
    end
  end
  
  
  one_period high_sync_inst(
  .clk(slow_clock),
  .reset(reset),
  .din(high),
  .dout(high_sync)
);

one_period per_sync_inst(
  .clk(slow_clock),
  .reset(reset),
  .din(per),
  .dout(per_sync)
);

  pwm pwm_inst(
  .clk(slow_clock),
  .reset(reset),
  .wr(wr_sync),
  .high(high),
  .per(per),
  .di(di),
  .di_switch(di_switch),
  .error_out(error_out),
  .pwm_out(pwm_out)
  );
endmodule
