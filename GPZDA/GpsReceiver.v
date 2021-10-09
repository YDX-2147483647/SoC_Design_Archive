/**
 * @file GpsReceiver.v
 * @author Y.D.X.
 * @brief 接收GPS（GPZDA）信号并解析
 * @version 0.0
 * @date 2021-10-9
 *
 */

`default_nettype none

`include "ComparerSync.v"

/**
 * @param B 每字节位数
 * @param PrefixLen `Prefix`的长度
 * @param Prefix 信号前缀，包括“$”，不包括分隔符
 * @param Separator 分隔符
 * @param NoCheck 是否忽略校验部分
 * @input clock 时钟，100 MHz / 10 ns
 * @input reset 复位（异步）
 * @input load 是否应该读取此时的`data`
 * @input data
 * @output valid_out `year`、`month`、`day`是否有效
 * @output year
 * @output month
 * @output day
 */
module GpsReceiver #(
    parameter B = 8,
    parameter PrefixLen = 6;
    parameter [PrefixLen*B-1:0] Prefix = "$GPZDA",
    parameter [B-1:0] Separator = ",",
    parameter NoCheck = 1'b1
) (
    input wire clock,
    input wire reset,
    input wire load,
    input wire [B-1:0] data,
    output wire valid_out,
    output reg [2*B-1:0] year,
    output reg [2*B-1:0] month,
    output reg [2*B-1:0] day
);

/// FSM 状态编码长度
localparam S_Size = 3;
/// FSM 的可能状态
localparam [S_Size-1:0] S_Prefix = 0, S_Split = 1, S_Check = 2, S_Output = 3;
/// FSM 的状态
reg [S_Size-1:0] state, next_state;



wire prefix_resolve, prefix_reject;
ComparerSync #(
    .L (PrefixLen + 1),
    .Ref ({Prefix, Separator})
) prefix_matcher (
    .clock (clock),
    .restart (state != S_Prefix),
    .load (state == S_Prefix & load),
    .data (data),
    .resolve (prefix_resolve),
    .reject (prefix_reject)
);


/** 在当前状态停留的时长
 * @note 会溢出。
 */
reg [B-1:0] stay_count;



/// 设置`state`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= S_Prefix;
    end else begin
        state <= next_state;
    end
end

// TODO 状态转移逻辑，设置`next_state`
always @(*) begin
    case (state)
        S_Prefix: next_state = prefix_resolve ? S_Split : S_Prefix;
        default: next_state = S_Prefix;
    endcase
end

/// 更新`stay_count`
always @(posedge clock or posedge reset) begin
    if (reset || state != next_state) begin
        stay_count <= '0;
    end else begin
        stay_count <= stay_count + 1;
    end
end


assign valid_out = state == S_Output;



/// `state`的文字版本，仅为方便调试，在其它部分无用
reg [7*B-1:0] state_str;
always @(*) begin
    case (state)
        S_Prefix: state_str = "Prefix ";
        S_Split: state_str = "Split  ";
        S_Check: state_str = "Check  ";
        S_Output: state_str = "Output ";
        default: state_str = "Unknown";
    endcase
end

endmodule