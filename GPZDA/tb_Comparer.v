`timescale 1ns/1ps

`include "Comparer.v"

module tb_Comparer ();

reg clock = 1'b0;
always #10 clock = ~clock;

reg restart, load;
reg [7:0] data;
wire resolve, reject;

Comparer dut #(
    .L (3),
    .Ref("ABC")
) (
    .clock(clock), .restart(restart), .load(load), .data(data),
    .resolve(resolve), .reject(reject)
);

initial begin
    restart <= 1'b0;
    load <= 1'b0;
    
    #40;
    load <= 1'b1;
    data <= "O";
    #20 data <= "A";
    #20 data <= "B";
    #20 data <= "C";
    #20 data <= "D";
    #20;
end

endmodule