/**
 * @file HexParser.v
 * @author Y.D.X.
 * @brief 解析十六进制数
 * @version 0.1
 * @date 2021-10-10
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

    wire [2*L * B - 1 : 0] bin_coded_hex;
    wire [2*L * L*B - 1 : 0] partial_sum;

    assign num = partial_sum[0 +: L*B];

    genvar i, j;
    generate
        for (i = 0; i < 2*L*B; i = i+B ) begin
            assign bin_coded_hex[i +:B] =
                str[i +:B] <= "9" ?
                (str[i +:B] - "0") :
                (str[i +:B] - "A" + 10);
        end
        
        assign partial_sum[2*L * L*B - 1 -: L*B] = bin_coded_hex[2*L * B - 1 -: B];
        for (j = 0; j < 2*L*B - B; j = j + B) begin
            assign partial_sum[L*j +: L*B] =
                partial_sum[L*(j+B) +: L*B] * 16 + bin_coded_hex[j +: B];
        end
    endgenerate
endmodule
