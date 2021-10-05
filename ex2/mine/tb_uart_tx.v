`include "uart_tx.v"

`timescale 1ns/1ps
`default_nettype none

module tb_uart_tx();

    reg clock = 1'b0, clock_en = 1'b0;
    always #10 clock = ~clock;
    always #(7680/16) clock_en = ~clock_en;
    
    reg reset, shoot;
    reg [7:0] data;
    wire tx, busy;
    
    uart_tx transmitter(
        .clock (clock),
        .clock_en (clock_en),
        .reset (reset),
        .shoot (shoot),
        .data (data),
        .tx (tx),
        .busy (busy)
    );

    initial begin
        data <= 8'hAA;
        reset = 1'b1;
        #23;
        reset = 1'b0;
        #200;

        shoot = 1'b1;
        @(posedge busy);
        shoot = 1'b0;
        @(negedge busy);
        #123;

        data <= 8'b10101100;
        shoot = 1'b1;
        @(posedge busy);
        shoot = 1'b0;
        @(negedge busy);
        #234;
    end
    
endmodule
