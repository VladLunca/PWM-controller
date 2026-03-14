

module one_period(
    input clk,
    input reset,
    input din,
    output dout
    );
    
    reg din_prev;
    
    always @(posedge clk)
        if(reset)
            din_prev <= 1'b0;
        else 
            din_prev <= din;
            
    assign dout = din&(~din_prev);
        
endmodule