
module pwm(
  input clk,
  input reset,
  input wr,
  input high,
  input per,
  input [7:0]di,
  
  output [7:0]di_switch,  
  output reg pwm_out,
  output reg error_out
    );
 
 //registre de interfata -- pt atc cand scriem
 reg [7:0]reg_per;
 reg [7:0]reg_high;
     assign di_switch = di;

 //regisrele active -- valorile curente
  reg [7:0]reg_per_current;
  reg [7:0]reg_high_current;
  
  reg [7:0]pwm_counter;
  reg[7:0]error_counter;
  
 always@(posedge clk) begin
    if(reset) begin
        reg_per<=0;
        reg_high<=0;
        reg_per_current<=0;
        reg_high_current<=0;
        pwm_counter<=0;
        error_counter<=0;
        pwm_out<=0;
        error_out<=0;
    end else begin //end de reset
    
        if(wr)begin//logica de scriere
            if(per && !high) begin
                //wr*per=1
                reg_per<=di;
            end else if (!per &&high) begin
                reg_high<=di;
            end 
         end
         
       if(reg_per_current == 0) begin
            if(reg_per != 0) begin
                reg_per_current  <= reg_per;
                reg_high_current <= reg_high;
            end
        end else if(pwm_counter >= (reg_per_current-1) ) begin
            //inseamna ca perioada semnalului s-a terminat
            pwm_counter <= 0;
            reg_per_current<=reg_per;
            reg_high_current<=reg_high;   
            if(reg_high_current > reg_per_current) begin
                error_counter <= reg_per_current - 1; 
            end
        end else begin
            pwm_counter<=pwm_counter+1;
         end
         
       pwm_out<=(pwm_counter<reg_high_current);

         
         if(error_counter>0) begin
            error_out<=1'b1;
            error_counter<=error_counter-1;
         end else begin
            error_out<=1'b0;
         end
    end
 end 
endmodule
