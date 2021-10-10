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
`include "FixedBytesReceiver.v"

/**
 * GPS信号接收器
 * @param B 每字节位数
 * @param PrefixLen `Prefix`的长度
 * @param Prefix 信号前缀，包括“$”，不包括分隔符
 * @param Separator 分隔符
 * @param NoCheck 是否忽略校验部分
 * @input clock 时钟，100 MHz / 10 ns
 * @input reset 复位（异步）
 * @input load 是否应该读取此时的`data`
 * @input data
 * @output resolve 是否完成接收
 * @output utc
 * @output day
 * @output month
 * @output year
 * @output error 是否发现数据异常
 */
module GpsReceiver #(
    parameter B = 8,
    parameter PrefixLen = 6,
    parameter [PrefixLen*B-1:0] Prefix = "$GPZDA",
    parameter [B-1:0] Separator = ",",
    parameter NoCheck = 1'b1
) (
    input wire clock,
    input wire reset,
    input wire load,
    input wire [B-1:0] data,
    output wire resolve,
    output reg [7*B-1:0] utc,
    output reg [2*B-1:0] day,
    output reg [2*B-1:0] month,
    output reg [2*B-1:0] year,
    output reg error
);

/// FSM 状态编码长度
localparam S_Size = 3;
/// FSM 的可能状态
localparam [S_Size-1:0] S_Prefix = 0,
    S_UTC = 1, S_Day = 2, S_Month = 3, S_Year = 4,
    S_Check = 5, S_Output = 6;
/// FSM 的状态
reg [S_Size-1:0] state, next_state;
/// `S_UTC`至`S_Check`是否发现错误
wire [5:1] _errors;



/// Prefix
wire prefix_resolve;
ComparerSync #(
    .L (PrefixLen + 1),
    .Ref ({Prefix, Separator})
) prefix_matcher (
    .clock (clock),
    .restart (state != S_Prefix),
    .load (state == S_Prefix & load),
    .data (data),
    .resolve (prefix_resolve)
);

/// UTC
wire utc_resolve;
wire [10*B-1:0] utc_result;
FixedBytesReceiver #(.L(10)) utc_receiver (
    .clock (clock),
    .start (prefix_resolve),
    .load (state == S_UTC & load),
    .data (data),
    .resolve (utc_resolve),
    .result (utc_result)
);
assign _errors[S_UTC] = utc_resolve && utc_result[0+:B] != Separator;


/// Day and Month
wire day_or_month_resolve;
wire [3*B-1:0] day_or_month_result;
FixedBytesReceiver #(.L(3)) day_or_month_receiver (
    .clock (clock),
    .start (utc_resolve | day_or_month_resolve),
    .load ((state == S_Day || state == S_Month) & load),
    .data (data),
    .resolve (day_or_month_resolve),
    .result (day_or_month_result)
);
assign _errors[S_Day] = day_or_month_resolve && day_or_month_result[0+:B] != Separator;
assign _errors[S_Month] = day_or_month_resolve && day_or_month_result[0+:B] != Separator;



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
        S_Prefix: next_state = prefix_resolve ? S_UTC : S_Prefix;
        S_UTC: next_state = utc_resolve ? S_Day : S_UTC;
        S_Day: next_state = day_or_month_resolve ? S_Month : S_Day;
        S_Month: next_state = day_or_month_resolve ? S_Year : S_Month;
        default: next_state = S_Prefix;
    endcase
end



/** Output
 * @{
 */
assign resolve = state == S_Output;

// error
always @(posedge clock or posedge reset) begin
    if (reset || state == S_Prefix) begin
        error <= '0;
    end else begin
        error <= error | (|_errors);
    end
end

// utc
always @(posedge clock) begin
    if (utc_resolve) begin
        utc <= utc_result[B +:7*B];
    end
end

/// day, month
always @(posedge clock) begin
    if (day_or_month_resolve) begin
        if (state == S_Day) begin
            day <= day_or_month_result[B +:2*B];
        end else begin
            day <= day_or_month_result[B +:2*B];
        end
    end
end

/// @}



/// `state`的文字版本，仅为方便调试，在其它部分无用
reg [6*B-1:0] state_str;
always @(*) begin
    case (state)
        S_Prefix: state_str = "Prefix";
        S_UTC: state_str = "UTC";
        S_Day: state_str = "Day";
        S_Month: state_str = "Month";
        S_Year: state_str = "Year";
        S_Check: state_str = "Check";
        S_Output: state_str = "Output";
        default: state_str = 'x;
    endcase
end

endmodule