/**
 * @file Comparer.v
 * @author Y.D.X.
 * @brief 信号比较器
 * @version 0.1
 * @date 2021-10-9
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
localparam S_Idle = 0, S_Pending = 1, S_Reject = 2, S_Resolve = 3;
/// FSM 的状态
reg [3:0] is, next_is;

/// 当前位是否匹配
wire is_current_match;
assign is_current_match = Ref[match_count +:B] == data;

/// 已经匹配的长度
reg [B-1: 0] match_count;

/// 设置`is`
always @(posedge clk, posedge restart) begin
    if (restart) begin
        is <= 4'b00001;
    end else begin
        is <= next_is;
    end
end

/// 设置`next_is`
always @(*) begin
    next_is[S_Idle] = is[S_Reject] | is[S_Resolve];
    if (load) begin
        next_is[S_Pending] = is[S_Idle] | (is[S_Pending] & is_current_match & match_count<L);
        next_is[S_Reject] = is[S_Pending] & ~is_current_match;
        next_is[S_Resolve] = is[S_Pending] & match_count==L;
    end else begin
        next_is[S_Pending] = is[S_Pending];
        next_is[S_Reject] = 1'b0;
        next_is[S_Resolve] = 1'b0;
    end
end

/// Output
assign
    reject = is[S_Reject],
    resolve = is[S_Resolve];

/// 更新`match_count`
always @(posedge clk) begin
    if (is[S_Idle]) begin
        match_count <= 0;
    end else begin
        match_count <= match_count + is_current_match;
    end
end
    
endmodule