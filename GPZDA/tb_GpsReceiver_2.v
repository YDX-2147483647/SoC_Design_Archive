/**
 * @file tb_GpsReceiver_2.v
 * @author Y.D.X.
 * @version 0.1
 * @date 2021-10-10
 * @description `run 3 us`。主要测试`load`。
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
wire load;

GpsReceiver receiver(
    .clock (clock),
    .reset (reset),
    .load (load),
    .data (data)
    // 反正也要进模块内部看，外面干脆就不要了
);

reg set_signal;
reg [34*B-1:0] signal;
GpsSimpleSender_2 #(.L(34)) sender (
    .clock (clock),
    .set (set_signal),
    .signal (signal),
    .data (data),
    .valid_out (load)
);

initial begin
    reset <= 1'b1;
    set_signal <= 1'b1;
    signal <= "$GPZDA,143042.00,25,08,2005,,*6E\r\n";

    #40 reset <= 1'b0; set_signal <= 1'b0;
    #700;
end

endmodule

module GpsSimpleSender_2 #(
    parameter B = 8,
    parameter L = 34
) (
    input wire clock,
    input wire set,
    input wire [L*B-1:0] signal,
    output wire [B-1:0] data,
    output reg valid_out
);
    reg [L*B-1:0] _signal;
    
    assign data = _signal[L*B-1 -:B];

    
    always @(posedge clock) begin
        if (set) begin
            _signal <= signal;
            valid_out <= 1'b0;
        end else begin
            valid_out <= ~valid_out;
            if (~valid_out) begin
                _signal <= {_signal[0 +: (L-1)*B], data};
            end
        end
    end
    
endmodule