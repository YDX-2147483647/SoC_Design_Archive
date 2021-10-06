`include "uart_tx.v"
`include "uart_rx.v"

`timescale 1ns/1ps
`default_nettype none

module tb_uart_both();

    reg clock = 1'b0, clock_en = 1'b0;
    always #10 clock = ~clock;
    always #(7680/16) clock_en = ~clock_en;
    
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire connect;
    
    reg reset, shoot;
    wire busy, is_valid;
    
    uart_tx transmitter(
        .clock (clock),
        .clock_en (clock_en),
        .reset (reset),
        .shoot (shoot),
        .data (data_in),
        .tx (connect),
        .busy (busy)
    );
    uart_rx receiver(
        .clock (clock),
        .clock_en (clock_en),
        .reset (reset),
        .rx (connect),
        .is_valid (is_valid),
        .data (data_out)
    );

    initial begin
        data_in <= 8'b10101010;
        reset = 1'b0;
        #200;

        shoot = 1'b1;
        @(posedge busy);
        shoot = 1'b0;
        @(negedge busy);
        #123;

        data_in <= 8'b10101100;
        shoot = 1'b1;
        @(posedge busy);
        shoot = 1'b0;
        @(negedge busy);
        #234;
    end
    
endmodule
