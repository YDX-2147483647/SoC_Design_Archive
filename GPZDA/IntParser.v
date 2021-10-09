/**
 * @file IntParser.v
 * @author Y.D.X.
 * @brief 解析自然数
 * @version 0.1
 * @date 2021-10-9
 *
 */

`default_nettype none

/**
 * @brief 自然数解析器
 * @param B 每字节位数
 * @input str 字符形式的自然数，例如"2333"，缺位时用0x0或"0"补齐。
 * @output num 二进制格式的数
 */
module IntParser #(
    parameter B = 8;
) (
    input wire [4*B-1:0] str,
    output wire [2*B-1:0] num
);
    
endmodule