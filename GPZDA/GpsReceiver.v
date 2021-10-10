/**
 * @file GpsReceiver.v
 * @author Y.D.X.
 * @brief 接收GPS（GPZDA）信号并解析
 * @version 0.1
 * @date 2021-10-9
 *
 */

`default_nettype none

`include "ComparerSync.v"
`include "FixedBytesReceiver.v"
`include "HexParser.v"
`include "IntParser.v"

/**
 * GPS信号接收器
 * @param B 每字节位数
 * @param PrefixLen `Prefix`的长度
 * @param Prefix 信号前缀，不包括“$”和分隔符
 * @param Separator 分隔符
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
    parameter PrefixLen = 5,
    parameter [PrefixLen*B-1:0] Prefix = "GPZDA",
    parameter [B-1:0] Separator = ","
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
    S_Locale = 5, S_Check = 6, S_Output = 7;
/// FSM 的状态
reg [S_Size-1:0] state, next_state;
/// `S_UTC`至`S_Check`是否发现错误
wire [6:1] _errors;



/// Prefix
wire prefix_resolve;
ComparerSync #(
    .L (PrefixLen + 2),
    .Ref ({"$", Prefix, Separator})
) prefix_matcher (
    .clock (clock),
    .restart (state != S_Prefix),
    .load (state == S_Prefix & load),
    .data (data),
    .resolve (prefix_resolve)
);



/** Receivers: UTC, …
 * @notes 现在这里有一堆重复的元件，但我没想好怎么改……
 * @{
 */
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

    /// Day
    wire day_resolve;
    wire [3*B-1:0] day_result_str;
    FixedBytesReceiver #(.L(3)) day_receiver (
        .clock (clock),
        .start (utc_resolve),
        .load (state == S_Day & load),
        .data (data),
        .resolve (day_resolve),
        .result (day_result_str)
    );
    assign _errors[S_Day] = day_resolve && day_result_str[0+:B] != Separator;

    /// Month
    wire month_resolve;
    wire [3*B-1:0] month_result_str;
    FixedBytesReceiver #(.L(3)) month_receiver (
        .clock (clock),
        .start (day_resolve),
        .load (state == S_Month & load),
        .data (data),
        .resolve (month_resolve),
        .result (month_result_str)
    );
    assign _errors[S_Month] = month_resolve && month_result_str[0+:B] != Separator;

    /// Year
    wire year_resolve;
    wire [5*B-1:0] year_result_str;
    FixedBytesReceiver #(.L(5)) year_receiver (
        .clock (clock),
        .start (month_resolve),
        .load (state == S_Year & load),
        .data (data),
        .resolve (year_resolve),
        .result (year_result_str)
    );
    assign _errors[S_Year] = year_resolve && year_result_str[0+:B] != Separator;

    /// Locale
    wire locale_resolve;
    wire [2*B-1:0] locale_result;
    FixedBytesReceiver #(.L(2)) locale_receiver (
        .clock (clock),
        .start (year_resolve),
        .load (state == S_Locale & load),
        .data (data),
        .resolve (locale_resolve),
        .result (locale_result)
    );
    assign _errors[S_Locale] = locale_resolve && (locale_result[0+:B] != "*" || locale_result[B+:B] != Separator);

/// @}



/** Check
 * @{
 */
    /// 计算`check_sum`
    reg [B-1:0] check_sum;
    always @(posedge clock) begin
        if (state == S_Prefix) begin
            check_sum <= (^Prefix) ^ "," ^ "*";
        end else if (load && state != S_Check) begin
            check_sum <= check_sum ^ data;
        end
    end

    /// 接收校验位
    wire check_resolve;
    wire [2*B-1:0] check_result_str;
    FixedBytesReceiver #(.L(2)) check_receiver (
        .clock (clock),
        .start (locale_resolve),
        .load (state == S_Check & load),
        .data (data),
        .resolve (check_resolve),
        .result (check_result_str)
    );
    wire [B-1:0] check_result;
    HexParser #(.L(1)) check_result_parser (
        .str (check_result_str),
        .num (check_result)
    );

    assign _errors[S_Check] = check_resolve && check_result != check_sum;
/// @}



/// 设置`state`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= S_Prefix;
    end else begin
        state <= next_state;
    end
end

// 状态转移逻辑，设置`next_state`
always @(*) begin
    case (state)
        S_Prefix: next_state = prefix_resolve ? S_UTC : S_Prefix;
        S_UTC: next_state = utc_resolve ? S_Day : S_UTC;
        S_Day: next_state = day_resolve ? S_Month : S_Day;
        S_Month: next_state = month_resolve ? S_Year : S_Month;
        S_Year: next_state = year_resolve ? S_Locale : S_Year;
        S_Locale: next_state = locale_resolve ? S_Check : S_Locale;
        S_Check: next_state = S_Output;
        S_Output: next_state = S_Prefix;
        default: next_state = S_Prefix;
    endcase
end



/** Int parser
 * Day、Month、Year 分时共用。
 * @{
 */
    reg [4*B-1:0] int_parser_str;
    wire [2*B-1:0] int_parser_num;
    IntParser int_parser(.str(int_parser_str), .num(int_parser_num));

    always @(*) begin
        case (state)
            S_Day: int_parser_str = day_result_str[B +: 2*B];
            S_Month: int_parser_str = month_result_str[B +: 2*B];
            S_Year: int_parser_str = year_result_str[B +: 4*B];
            default: int_parser_str = "0000";
        endcase
    end
/// @}



/** Outputs
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
            utc <= utc_result[B +:9*B];
        end
    end

    /// day, month, year
    always @(posedge clock) begin
        if (day_resolve) begin
            day <= int_parser_num;
        end else if (month_resolve) begin
            month <= int_parser_num;
        end else if (year_resolve) begin
            year <= int_parser_num;
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
        S_Locale: state_str = "Locale";
        S_Check: state_str = "Check";
        S_Output: state_str = "Output";
        default: state_str = 'x;
    endcase
end

endmodule