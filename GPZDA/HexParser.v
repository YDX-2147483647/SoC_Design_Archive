/**
 * @file HexParser.v
 * @author Y.D.X.
 * @brief 解析十六进制数
 * @version 0.1
 * @date 2021-10-10
 * 我不太清楚这是否能综合，反正 https://hdlbits.01xz.net/wiki/Popcount255 的答案是这么写的。
 *
 */

`default_nettype none

/**
 * @brief 十六进制数解析器
 * @param B 每字节位数
 * @param L 结果的字节数
 * @input str 字符形式的十六进制数，例如"7F"，缺位时用0x0或"0"补齐。
 * @output num 二进制格式的数
 */
module HexParser #(
    parameter B = 8,
    parameter L = 1
) (
    input wire [2*L*B-1 : 0] str,
    output wire [L*B-1 : 0] num
);
    always @(*) begin
        num = '0;
        for (int i = 2*L-1; i >= 0; i--) begin
            num = 16 * num + (
                str[i*B +:B] <= "9" ?
                (str[i*B +:B] - "0") :
                (str[i*B +:B] - "A" + 10));
        end
    end
endmodule
