/**
 * @file ComparerSync.v
 * @author Y.D.X.
 * @brief 信号比较器（同步）
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
 * @input restart 从这个clock重新开始比较（等待`load`）
 * @input load 是否应该读取此时的`data`
 * @input data 
 * @output reject 是否确定不匹配
 * @output resolve 是否确定完全匹配
 */
module ComparerSync #(
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

/// 这轮之前已经匹配的长度
reg [B-1: 0] prev_match_count;
/// 现在已经匹配的长度
wire [B-1:0] match_count;

/// 现在这轮是否匹配
wire is_match;
assign is_match = Ref[(L-1-prev_match_count) * B +:B] == data;

/// 更新`match_count`
assign match_count = prev_match_count + load & is_match;

/// 为下一轮做准备，更新`prev_match_count`
always @(posedge clk) begin
    if (restart) begin
        prev_match_count <= 0;
    end else begin
        prev_match_count <= match_count<L ? match_count : 0;
    end
end


/// Output
assign
    resolve = match_count == L,
    reject = ~is_match;
    
endmodule