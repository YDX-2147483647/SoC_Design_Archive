/**
 * @file tb_Comparer.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-9
 * @description `run 300 ns`。同时适用于`Comparer`和`ComparerSync`。
 *
 */

`timescale 1ns/1ps

`include "ComparerSync.v"

module tb_Comparer ();

reg clock = 1'b1;
always #10 clock = ~clock;

reg restart, load;
reg [7:0] data;
wire resolve, reject;

ComparerSync #(
    .L (3),
    .Ref("ABC")
) dut (
    .clock(clock), .restart(restart), .load(load), .data(data),
    .resolve(resolve), .reject(reject)
);

initial begin
    restart <= 1'b1;
    load <= 1'b0;
    
    #40;
    restart <= 1'b0;
    data <= "O";
    
    #20;
    load <= 1'b1;
    data <= "A";
    #20 data <= "B";
    #20 data <= "C";
    #20 data <= "D";
    
    #20 load <= 1'b0;
    
    #20 load <= 1'b1; data <= "A";
    #20 load <= 1'b0; data <= "a";
    #20 load <= 1'b1; data <= "B";
    #20 load <= 1'b0; data <= "b";
    #20 load <= 1'b1; data <= "C";
    #20 load <= 1'b0; data <= "c";
end

endmodule