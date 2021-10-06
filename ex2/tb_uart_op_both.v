`include "uart_tx_op.v"
`include "uart_rx_op.v"

`timescale 1ns/1ps
`default_nettype none

module tb_uart_op_both();

    reg clock = 1'b0, clock_en = 1'b0;
    always #10 clock = ~clock;
    always #(7680/16) clock_en = ~clock_en;
    
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire connect;
    
    reg reset, shoot;
    wire busy, is_valid;
    
    uart_tx_op transmitter(
        .clk (clock),
        .clk_en (clock_en),
        .reset (reset),
        .shoot (shoot),
        .datain (data_in),
        .uart_tx (connect),
        .uart_busy (busy)
    );
    uart_rx_op receiver(
        .clk (clock),
        .clk_en (clock_en),
        .reset (reset),
        .uart_rx (connect),
        .dataout_valid (is_valid),
        .dataout (data_out)
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
