

module top(
    input clk,
    input rst,
    input start,
    input cpol ,
    input cpha,
    input [7:0] data_in,
    output MOSI,
    output ss,
    output finish,
    output SCLK,
    input MISO ,
    output [7:0] data_out 
);

 wire spi_clk_enable;
wire leading_tick ;
wire trailing_tick ;

clk_gen u_clk (
    .clk(clk),
    .rst(rst),
    .leading_tick (leading_tick) ,
    .trailing_tick(trailing_tick) ,
    .enable(spi_clk_enable),
     .SCLK(SCLK),
     .cpol(cpol)
);

spi_master u_spi (
    .clk(clk),
 .leading_tick (leading_tick) ,
    .trailing_tick(trailing_tick) ,
        .rst(rst),
    .data_in(data_in),
    .start(start),
    .ss(ss),
    .finish(finish),
    .MOSI(MOSI),
    .spi_clk_enable(spi_clk_enable),
    .MISO(MISO) , 
    .data_out(data_out),
    .cpha(cpha)
 );

endmodule