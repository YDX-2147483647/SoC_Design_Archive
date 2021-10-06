/**
 * @file uart_tx.v
 * @author Y.D.X.
 * @brief UART发送器
 * @version 0.1
 * @date 2021-10-05
 * @description Universal Asynchronous Receiver/Transmitter.
 *
 */

`default_nettype none

/**
 * @param VERIFY_ON 是否有校验位
 * @param VERIFY_EVEN 若有校验位，是否采用偶校验
 * @input clock 100 MHz 时钟
 * @input clock_en 16倍采样时钟，7.68/16 us，即 16 * 11.52 kHz
 * @input reset
 * @input shoot
 * @input {[7:0]} data 一个字节
 * @output tx transmitter
 * @output busy 是否正在发送数据
 */
module uart_tx #(parameter VERIFY_ON = 1'b0,
                 parameter VERIFY_EVEN = 1'b0)
                (input wire clock,
                 input wire clock_en,
                 input wire reset,
                 input wire shoot,
                 input wire [7:0] data,
                 output reg tx,
                 output reg busy);

/// enum 状态机的状态
localparam [4:0] STATE_idle = 5'b00001,
                 STATE_start = 5'b00010,
                 STATE_data = 5'b00100,
                 STATE_verify = 5'b01000,
                 STATE_stop = 5'b10000;

reg [4:0] state = STATE_idle,
    next_state = STATE_idle;

reg [3:0] _clock_en_count = 4'b0;
reg finish_one_bit = 1'b0;

/// 已发送数据的位数
reg [2:0] already_sent_count = 3'h0;



/// Set `state`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= STATE_idle;
    end else begin
        state <= next_state;
    end
end

/// Set `next_state`
always @(*) begin
    next_state = state; // default for *else* in cases

    case (state)
        STATE_idle: 
            if (shoot) begin
                next_state = STATE_start;
            end
        STATE_start: 
            if (finish_one_bit) begin
                next_state = STATE_data;
            end
        STATE_data: 
            if (finish_one_bit && already_sent_count == 3'h7) begin
                if (VERIFY_ON) begin
                    next_state = STATE_verify;
                end else begin
                    next_state = STATE_stop;
                end
            end
        STATE_verify:
            if (finish_one_bit) begin
                next_state = STATE_stop;
            end
        STATE_stop:
            if (finish_one_bit) begin
                next_state = STATE_idle;
            end
        default:
            next_state = STATE_idle;
    endcase
end



/// Maintain `busy`
always @(posedge clock or posedge reset) begin
    busy <= ~(reset || state == STATE_idle);
end

/// Maintain `_clock_en_count`, `finish_one_bit`
always @(posedge clock or posedge reset) begin
    if (reset || state == STATE_idle) begin
        _clock_en_count <= 4'h0;
        finish_one_bit <= 1'b0;
    end else begin
        if (clock_en) begin
            _clock_en_count <= _clock_en_count + 4'h1;
        end
        finish_one_bit <= clock_en && _clock_en_count == 4'hE;
    end
end

/// Maintain `already_sent_count`
always @(posedge clock or posedge reset) begin
    if (reset || state != STATE_data) begin
        already_sent_count <= 3'h0;
    end else begin
        already_sent_count <= already_sent_count + 3'h1;
    end
end



reg [7:0] _data;
// Save and Control `_data`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        _data <= 8'b0;
    end else if (state == STATE_idle && shoot) begin
        _data <= data;
    end else if (state == STATE_data) begin
        // rotate
        _data <= {_data[0], _data[7:1]};
    end
end

/// Control `tx`
always @(*) begin
    case(state)
    STATE_start:
        tx = 1'b0;
    STATE_data:
        tx = _data[0];
    STATE_verify:
        tx = (^_data) ^ (~VERIFY_EVEN);
    default:
        tx = 1'b1;
    endcase
end



/** 为方便调试，用一些变量存储可读的状态名称。
 * `state_str`,`next_state_str`在其它部分无用。
 * @{
 */
reg [79:0] state_str, next_state_str;
always @ (state) begin
    case ({state})
    STATE_idle:   state_str = "idle      ";
    STATE_start:  state_str = "start     ";
    STATE_data:   state_str = "data      ";
    STATE_verify: state_str = "verify    ";
    STATE_stop:   state_str = "stop      ";
    default:      state_str = "%Error    ";
    endcase
end
always @ (next_state) begin
    case ({next_state})
    STATE_idle:   next_state_str = "idle      ";
    STATE_start:  next_state_str = "start     ";
    STATE_data:   next_state_str = "data      ";
    STATE_verify: next_state_str = "verify    ";
    STATE_stop:   next_state_str = "stop      ";
    default:      next_state_str = "%Error    ";
    endcase
end
/// @}

endmodule
