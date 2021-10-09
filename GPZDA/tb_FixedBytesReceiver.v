/**
 * @file tb_FixedBytesReceiver.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-9
 * @description `run 500 ns`
 *
 */

`timescale 1ns/1ps

`include "FixedBytesReceiver.v"

module tb_FixedBytesReceiver ();

localparam L = 3, B = 8;

reg clock = 1'b1;
always #10 clock = ~clock;

reg start, load;
reg [B-1:0] data;
wire resolve;
wire [L*B-1:0] result;

FixedBytesReceiver #(
    .L(L)
) dut(
    .clock(clock), .start(start), .load(load), .data(data),
    .resolve(resolve), .result(result)
);



reg __ref_resolve;
reg [L*B-1:0] __ref_result;
wire __mismatch_resolve, __mismatch_result;
assign
    __mismatch_resolve = __ref_resolve ^ resolve,
    __mismatch_result = __ref_result ^ result;



initial begin
    start <= 1'b1;
    load <= 1'b1;
    data <= "H";
    __ref_resolve <= 1'b0;
    __ref_result <= 'x;
    
    #40
    start <= 1'b0;
    #20 data <= "e";
    #20 data <= "l"; __ref_resolve <= 1'b1; __ref_result <= "Hel";
    #20 data <= "l"; __ref_resolve <= 1'b0; __ref_result <= 'x;
    #20 data <= "o";
    #20 data <= "?"; __ref_resolve <= 1'b1; __ref_result <= "lo?";
    #20 __ref_resolve <= 1'b0; __ref_result <= 'x;
    load <= 1'b0;

    #20 data <= "O"; load <= 1'b1;
    #20 data <= "n"; start <= 1'b1;
    #20 data <= "c"; start <= 1'b0; load <= 1'b0;
    #20 data <= "e"; load <= 1'b1;
    #20 data <= " "; load <= 1'b0;
    #20 data <= "A";
    #20 data <= "g"; load <= 1'b1;
    #20 data <= "a"; __ref_resolve <= 1'b1; __ref_result <= "ega";
    #20 data <= "i"; __ref_resolve <= 1'b0; __ref_result <= 'x;
    #20 data <= "n";
    #20 data <= "."; load <= 1'b0;

end


endmodule