/**
 * @file tb_IntParser.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-9
 * @description `run 30 ns`
 *
 */

`timescale 1ns/1ps

`include "IntParser.v"

module tb_IntParser ();

localparam B = 8;

reg [4*B-1:0] str;
wire [2*B-1:0] num;

IntParser dut(.str(str), .num(num));

initial begin
    str <= "2333";
    #5 str <= "0016";
    #5 str <= {8'b0, "511"};
    #5 str <= "64";
end

endmodule