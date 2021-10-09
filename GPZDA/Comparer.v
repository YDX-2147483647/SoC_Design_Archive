/**
 * @file Comparer.v
 * @author Y.D.X.
 * @brief 信号比较器
 * @version 0.1
 * @date 2021-10-9
 * @deprecated 请异步`ComparerSync`。
 *
 */

`default_nettype none

/**
 * 信号比较器
 * @param B 每字节位数
 * @param L 信号长度（字节数）
 * @param Ref 参考信号
 * @input clock 时钟，100 MHz / 10 ns
 * @input restart 重新开始比较（等待`load`）
 * @input load 是否应该读取此时的`data`
 * @input data 
 * @output reject 是否确定不匹配
 * @output resolve 是否确定完全匹配
 */
module Comparer #(
    parameter B = 8,
    parameter L = 6,
    parameter [L*B-1:0] Ref = "$GPZDA"
) (
    input wire clock,
    input wire restart,
    input wire load,
    input wire [B-1:0] data,
    output wire resolve,
    output wire reject
);

/// FSM 可能状态（one-hot）
localparam S_Pending = 0, S_Reject = 1, S_Resolve = 2;
/// FSM 的状态
reg [2:0] is, next_is;

/// 已经匹配的长度
reg [B-1: 0] match_count;

/// 当前位是否匹配
wire is_current_match;
assign is_current_match = Ref[(L-1-match_count) * B +:B] == data;

/// 算上这一轮，已经匹配的长度
wire [2:0] next_match_count;
assign next_match_count = match_count + is_current_match;

/// 设置`is`
always @(posedge clock, posedge restart) begin
    if (restart) begin
        is <= 3'b001;
    end else begin
        is <= next_is;
    end
end

/// 设置`next_is`
always @(*) begin
    next_is[S_Pending] = ~load |
        (load & is_current_match & next_match_count < L);
    next_is[S_Reject] = load & ~is_current_match;
    next_is[S_Resolve] = load & next_match_count == L;
end

/// Output
assign
    reject = is[S_Reject],
    resolve = is[S_Resolve];

/// 更新`match_count`
always @(posedge clock, posedge restart) begin
    if (restart) begin
        match_count <= 0;
    end else begin
        match_count <= (is[S_Pending] & next_match_count < L) ?
            next_match_count : 0;
    end
end
    
endmodule