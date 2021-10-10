/**
 * @file tb_HexParser.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-10
 * @description `run 30 ns`
 *
 */

`timescale 1ns/1ps

`include "HexParser.v"

module tb_HexParser ();

localparam B = 8;

reg [4*B-1:0] str;
wire [2*B-1:0] num;

HexParser #(.L(2)) dut(.str(str), .num(num));

initial begin
    str <= "7F7C";
    #5 str <= "7070";
    #5 str <= "FFFF";
    #5 str <= "0000";
    #5 str <= "6A9C";
end

endmodule