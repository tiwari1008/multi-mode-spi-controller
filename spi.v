`timescale 1ns/1ps 

module spi_master (
input clk ,
input trailing_tick ,
input rst , 
input [7:0] data_in ,
input cpha,
 input start ,
 output reg ss ,
  output  reg finish , 
  output reg spi_clk_enable ,
  output  MOSI,
  input MISO,
  input leading_tick ,
  output reg [7:0] data_out 
 );
 
reg [7:0] shift_reg ,rx_shift_reg ;
 reg [3:0] bit_counter ;
reg [1:0] state , next_state ;
reg   start_prev;
reg skip_first_shift;

assign MOSI = shift_reg[7];
 
parameter idle = 2'b00 ;
parameter load = 2'b01 ;
parameter tx = 2'b10 ;
parameter done = 2'b11 ;

wire sample_tick = (cpha == 0 )?leading_tick:trailing_tick;
wire shift_tick = (cpha==0 )? trailing_tick :leading_tick;

always @(posedge clk  or posedge rst ) begin 
  if(rst) begin 
state<= idle ;
start_prev<= 0 ;
     end
 else begin 
state <= next_state ;
 start_prev<= start;
end 
end 
 
 
 
 always @(*) begin 
  case(state) 
 idle:    next_state= (start_prev==0 && start==1 ) ?load:idle;
   load: next_state = tx; 
    tx:next_state = (bit_counter == 4'd7 )?done : tx;  
     done : next_state= idle;  
     default: next_state= idle;
  endcase
  end 
  
  
  
 always @(posedge clk  or posedge rst) begin 
 
  if(rst) begin
        shift_reg  <= 0;
        bit_counter <= 0;
        rx_shift_reg <=0 ;
        data_out<= 0 ;
        skip_first_shift <= 0 ;
    end
    else begin 
 case(state)  
    load: begin  shift_reg<= data_in ;
    rx_shift_reg <= 0 ;
    bit_counter <= 0 ; 
    skip_first_shift<= 0 ;
    end 
   tx:
    begin
   if(sample_tick && bit_counter <8) begin 
   rx_shift_reg <= {rx_shift_reg[6:0],MISO};
   end 
   
   if(shift_tick && bit_counter <8) begin 
   if(cpha==1 && skip_first_shift == 0)begin 
   skip_first_shift<= 1 ;
   
   end else begin 
   shift_reg <= {shift_reg [6:0] , 1'b0 } ;
   bit_counter <= bit_counter +1;
   
   end 
   end 
  end
  done : data_out<= rx_shift_reg ;
  default: ;
 
     endcase
     end
 end 
 
 
 
 always @(posedge clk  or posedge rst ) begin
 if(rst) begin
        ss <= 1;
        finish <= 0;
    end
    else begin 
 case(state ) 
 idle : begin ss<= 1 ; finish<= 0 ; spi_clk_enable<= 0 ;end 
   load : begin ss<=  0 ; finish<=  0 ; spi_clk_enable<= 0 ;end 
  tx : begin ss<= 0 ; finish <= 0 ; spi_clk_enable<= 1 ;end 
  done : begin ss<=  1 ; finish <=  1 ; spi_clk_enable<= 0 ;end 
  default:  begin ss<= 1 ; finish<= 0 ; spi_clk_enable<= 0 ;end 
   endcase  
 end 
 end 
 
 endmodule 