/**
 * @file GpsParser.v
 * @author Y.D.X.
 * @brief GPS（GPZDA）信号解析
 * @version 0.0
 * @date 2021-10-9
 *
 */

`default_nettype none

/**
 * @param B 一个字节的位数
 * @param Prefix 信号前缀，包括“$”，不包括“,”
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
module GpsParser #(
    parameter B = 8,
    parameter [6*B-1:0] Prefix = "$GPZDA",
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
localparam [S_Size-1:0] S_Idle = 0, S_Prefix = 1, S_Split = 2, S_Check = 3, S_Output = 4;
/// FSM 的状态
reg [S_Size-1:0] state, next_state;

/// 设置`state`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= S_Idle;
    end else begin
        state <= next_state;
    end
end

// 状态转移逻辑，设置`next_state`
always @(*) begin
    // TODO
end

assign valid_out = state == S_Output;



/// `state`的文字版本，仅为方便调试，在其它部分无用
reg [7*B-1:0] state_str;
always @(*) begin
    case (state)
        S_Idle: state_str = "Idle   ";
        S_Prefix: state_str = "Prefix ";
        S_Split: state_str = "Split  ";
        S_Check: state_str = "Check  ";
        S_Output: state_str = "Output ";
        default: state_str = "Unknown";
    endcase
end

endmodule