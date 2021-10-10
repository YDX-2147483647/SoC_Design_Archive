/**
 * @file tb_Comparer.v
 * @author Y.D.X.
 * @version 0.2
 * @date 2021-10-9
 * @description `run 1.2 us`。同时适用于`Comparer`和`ComparerSync`。
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



reg __ref_resolve;
wire __mismatch_resolve;
assign __mismatch_resolve = __ref_resolve ^ resolve;


initial begin
    restart <= 1'b1;
    load <= 1'b0;
    
    #40;
    restart <= 1'b0;
    data <= "O";
    __ref_resolve <= 1'b0;
    
    #20;
    load <= 1'b1;
    data <= "A";
    #20 data <= "B";
    #20 data <= "C";
    __ref_resolve <= 1'b1;
    #20 data <= "D";
    __ref_resolve <= 1'b0;
    
    #20 load <= 1'b0;
    
    #20 load <= 1'b1; data <= "A";
    #20 load <= 1'b0; data <= "a";
    #20 load <= 1'b1; data <= "B";
    #20 load <= 1'b0; data <= "b";
    #20 load <= 1'b1; data <= "C"; __ref_resolve <= 1'b1;
    #20 load <= 1'b0; data <= "c"; __ref_resolve <= 1'b0;

    #40;
    load <= 1'b1;
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "X";
    #20 data <= "C";
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "C"; __ref_resolve <= 1'b1;
    #20 data <= "A"; __ref_resolve <= 1'b0;
    #20 data <= "B";
    #20 data <= "C"; __ref_resolve <= 1'b1;
    #20 data <= "A"; __ref_resolve <= 1'b0;
    #20 data <= "B";
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "C"; __ref_resolve <= 1'b1;
    #20; __ref_resolve <= 1'b0;

    #40;
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "C"; restart <= 1'b1;
    #20 data <= "A"; restart <= 1'b0;
    #20 data <= "B"; restart <= 1'b1;
    #20 data <= "C"; restart <= 1'b0;
    #20 data <= "A"; restart <= 1'b1;
    #20 data <= "B"; restart <= 1'b0;
    #20 data <= "C"; __ref_resolve <= 1'b1;
    #20 data <= "A"; __ref_resolve <= 1'b0;

    #40 data <= "B";
    #20 data <= "C"; __ref_resolve <= 1'b1;
    #20 __ref_resolve <= 1'b0;
end

endmodule