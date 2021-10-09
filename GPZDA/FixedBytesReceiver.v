/**
 * @file FixedBytesReceiver.v
 * @author Y.D.X.
 * @brief 接收固定字节数的信号
 * @version 0.1
 * @date 2021-10-9
 *
 */

`default_nettype none

/** 定长信号接收器
 * @param B 每字节位数
 * @param L 信号长度，不宜超过10，不能超过255
 * @input clock 时钟，100 MHz / 10 ns
 * @input start 从下一clock开始准备接收
 * @input load 是否应该读取此时的`data`
 * @input data 
 * @output resolve 是否接收完成（完成接收的同一clock为真）
 * @output result 数据，先接收的在高位
 */
module FixedBytesReceiver #(
    parameter B = 8,
    parameter L = 4,
) (
    input wire clock,
    input wire start,
    input wire load,
    input wire [B-1:0] data,
    output wire resolve,
    output reg [L*B-1:0] result
);
    /// 已接收的字节数，不含此轮，[0, L)
    reg [B-1:0] prev_count;

    /// 更新`prev_count`
    always @(posedge clock, posedge start) begin
        if (start) begin
            prev_count <= 0;
        end else if (load) begin
            prev_count <= (prev_count == L-1)? 0 : prev_count + 1;
        end
    end

    always @(posedge clock) begin
        if (load) begin
            result <= {result[L*B-1 : B], data};
        end
    end
    
    assign resolve = (prev_count == L-1) & load;
    
    
endmodule
