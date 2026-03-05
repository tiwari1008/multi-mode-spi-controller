`timescale 1ns/1ps
 

module clk_gen (
    input clk,
    input enable,  
    input rst ,  
    input cpol,     
    output wire  leading_tick,//for rx_tick
     output wire   trailing_tick  ,//for tx_tick
         output   SCLK

);

reg [5:0] counter;
reg sclk_base ;

assign SCLK = (enable )? (sclk_base ^ cpol):cpol;

assign leading_tick = (enable && counter == 24) ;
assign trailing_tick = (enable && counter == 49);

always @(posedge clk) begin

if(rst)  begin
        counter <= 0;
      sclk_base <= 1'b0 ;
    end
 

   else  if(enable) begin
        if(counter == 49) begin
            counter <= 0;
           sclk_base<= 1'b0 ;
         end
        else  begin
            counter <= counter + 1;
                if(counter == 24) begin 
                sclk_base<= 1'b1;
                end
                  
        end
    end
    else begin 
      counter <= 0;
         sclk_base<= 1'b0; 
         end
    end

endmodule