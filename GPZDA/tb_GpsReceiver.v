/**
 * @file tb_GpsReceiver.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-10
 * @description `run 1 us`。
 *
 */

`timescale 1ns/1ps

`include "GpsReceiver.v"

module tb_GpsReceiver ();

localparam B = 8;

reg clock = 1'b1;
always #10 clock = ~clock;

reg reset;
wire [B-1:0] data;

GpsReceiver receiver(
    .clock (clock),
    .reset (reset),
    .load (1'b1),
    .data (data)
    // 反正也要进模块内部看，外面干脆就不要了
);

reg set_signal;
reg [32*B-1:0] signal;
GpsSimpleSender #(.L(32)) sender (
    .clock (clock),
    .set (set_signal),
    .signal (signal),
    .data (data)
);

initial begin
    reset <= 1'b1;
    set_signal <= 1'b1;
    signal <= "$GPZDA,143042.00,25,08,2005,,*6E";

    #20
    reset <= 1'b0;
    set_signal <= 1'b0;
end

endmodule

module GpsSimpleSender #(
    parameter B = 8,
    parameter L = 32
) (
    input wire clock,
    input wire set,
    input wire [L*B-1:0] signal,
    output wire [B-1:0] data
);
    reg [L*B-1:0] _signal;
    
    assign data = _signal[L*B-1 -:B];

    
    always @(posedge clock) begin
        if (set) begin
            _signal <= signal;
        end else begin
            _signal <= {_signal[0 +: (L-1)*B], data};
        end
    end
    
endmodule