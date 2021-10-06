/**
 * @file uart_rx.v
 * @author Y.D.X.
 * @brief UART接收器
 * @version 0.1
 * @date 2021-10-06
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
 * @input rx receiver
 * @output is_valid 此时`data`是否有效
 * @output {[7:0]} data 一个字节
 */
module uart_rx #(parameter VERIFY_ON = 1'b0,
                 parameter VERIFY_EVEN = 1'b0)
                (input wire clock,
                 input wire clock_en,
                 input wire reset,
                 input wire rx,
                 output reg is_valid,
                 output reg [7:0] data);

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

/// rx of recent clocks，0 代表最新的
reg [2:0] _rx_recent = 3'b0;

/// 已接收数据的位数
reg [2:0] already_received_count = 3'h0;

reg [1:0] _sample_accumulator = 2'h0;
reg current_bit = 1'b0;

reg verify_ok = 1'b0;


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
            if (~_rx_recent[1] && _rx_recent[2]) begin // real negedge
                next_state = STATE_start;
            end
        STATE_start: 
            if (finish_one_bit) begin
                if (current_bit) begin
                    next_state = STATE_idle;
                end else begin
                    next_state = STATE_data;
                end
            end
        STATE_data: 
            if (finish_one_bit && already_received_count == 3'h7) begin
                if (VERIFY_ON) begin
                    next_state = STATE_verify;
                end else begin
                    next_state = STATE_stop;
                end
            end
        STATE_verify:
            if (finish_one_bit) begin
                if (verify_ok) begin
                    next_state = STATE_stop;
                end else begin
                    next_state = STATE_idle;
                end
            end
        STATE_stop:
            if (finish_one_bit) begin
                next_state = STATE_idle;
            end
        default:
            next_state = STATE_idle;
    endcase
end



/// Set `verify_ok`
always @(posedge clock or posedge reset) begin
    if (reset || state != STATE_verify) begin
        verify_ok <= 1'b0;
    end else begin
        verify_ok <= (^data) ^ VERIFY_EVEN ^ ~current_bit;
    end
end

/// Save `data`
always @(posedge clock) begin
    case (state)
    STATE_idle: data <= 8'h0;
    STATE_data:
        if (finish_one_bit) begin
            data <= {current_bit, data[7:1]};
        end
    default: data <= data;
    endcase
end

/// Set `is_valid`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        is_valid <= 1'b0;
    end else begin
        is_valid <= state == STATE_stop && finish_one_bit;
    end
end



/// Maintain `_rx_recent`
always @(posedge clock) begin
    _rx_recent <= {_rx_recent[1:0], rx};
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
        if (finish_one_bit) begin
            _clock_en_count <= 4'h0;
        end
    end
end

/// Maintain `already_received_count`
always @(posedge clock or posedge reset) begin
    if (reset || state != STATE_data) begin
        already_received_count <= 3'h0;
    end else begin
        if (clock_en) begin
            already_received_count <= already_received_count + 3'h1;
        end
    end
end

/// Maintain `current_bit`, `_sample_accumulator`
always @(posedge clock or posedge reset) begin
    if (reset) begin
        _sample_accumulator <= 2'h0;
        current_bit <= 1'b0;
    end else begin
        if (_clock_en_count == 4'h0) begin
            _sample_accumulator <= 2'h0;
        end else if (5 < _clock_en_count && _clock_en_count < 10) begin
            _sample_accumulator <= _sample_accumulator + _rx_recent[2];
        end

        if (_clock_en_count == 4'h9) begin
            current_bit <= _sample_accumulator > 2'h1;
        end
    end
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
