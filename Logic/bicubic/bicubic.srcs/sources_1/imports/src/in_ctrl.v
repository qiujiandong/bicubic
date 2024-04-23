`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/06 10:39:52
// Design Name: 
// Module Name: input_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module in_ctrl(

    input aclk,
    input aresetn,

    input start,
    input enable,

// pixel output
    output [16 * 24 - 1 : 0] pixel,
    output pixel_valid, // indicate data is loaded from ddr
// end of pixel output

// s_axis interface
    input [31:0] s_axis_tdata,   // Transfer Data (optional)
    input [3:0] s_axis_tstrb,   // Transfer Data Byte Strobes (optional)
    input [3:0] s_axis_tkeep,   // Transfer Null Byte Indicators (optional)
    input s_axis_tlast,         // Packet Boundary Indicator (optional)
    input s_axis_tvalid,        // Transfer valid (required)
    output s_axis_tready        // Transfer ready (optional)
//  end of s_axis interface

    );

// state
    localparam S_IDLE = 3'b000;
    localparam S_LOAD = 3'b001;
    localparam S_READ = 3'b011;
    localparam S_UPDATE = 3'b010;
    localparam S_REMAIN = 3'b110;
    localparam S_TAIL = 3'b111;

    reg [2:0] cstate;
    reg [2:0] nstate;
// end of state

    reg [23:0] buffer [0 : 4 * 1024 - 1];
    reg [11:0] write_line;

    reg [47:0] rx_buf;
    reg [2:0] rx_index;

    reg [9:0] col_cnt; // 0-959
    reg [9:0] row_cnt; // 0-539pixel_valid_reg_q

    // reg [9:0] buf_col; // 0-962
    // reg [1:0] buf_row; // 0-3

    reg [18:0] out_cnt;

    reg [9:0] out_index [0:15];

// output
    reg [23:0] pixel_reg [0:15];
    reg pixel_valid_req;
    reg pixel_valid_req_ex;
    reg pixel_valid_reg;

    assign pixel_valid = pixel_valid_reg;
    assign pixel = {
        pixel_reg[15],
        pixel_reg[14],
        pixel_reg[13],
        pixel_reg[12],
        pixel_reg[11],
        pixel_reg[10],
        pixel_reg[9],
        pixel_reg[8],
        pixel_reg[7],
        pixel_reg[6],
        pixel_reg[5],
        pixel_reg[4],
        pixel_reg[3],
        pixel_reg[2],
        pixel_reg[1],
        pixel_reg[0]
    };
// end of output

    reg buf_write_ready;
    reg buf_write_ready_reg;
    wire buf_write_valid;
    wire handshake_buf_write;
    wire pixel_canout;
    // assign buf_write_ready = ((cstate == S_LOAD))? 1'b1: 1'b0;
    assign buf_write_valid = (rx_index > 3'd2)? 1'b1: 1'b0;
    assign handshake_buf_write = buf_write_valid & buf_write_ready;

    reg axis_tready;
    wire handshake_axis;
    assign s_axis_tready = axis_tready & enable;
    assign handshake_axis = s_axis_tvalid & s_axis_tready;

    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            buf_write_ready_reg = 1'b0;
        end
        else begin
            if(cstate == S_UPDATE && pixel_valid_reg) begin
                buf_write_ready_reg <= 1'b1;
            end
            else if(handshake_buf_write) begin
                buf_write_ready_reg <= 1'b0;
            end
        end
    end

    always @(*) begin
        buf_write_ready = 1'b0;
        if(cstate == S_LOAD || buf_write_ready_reg) begin
            buf_write_ready = 1'b1;
        end
    end

// row and col count in source picture
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            row_cnt <= 'b0;
            col_cnt <= 'b0;
        end
        else begin
            if(handshake_buf_write || (cstate == S_REMAIN && pixel_valid_req)) begin
                if(col_cnt == 10'd959) begin
                    if(row_cnt == 10'd539) begin
                        row_cnt <= 'b0;
                    end
                    else begin
                        row_cnt <= row_cnt + 10'd1;
                    end
                    col_cnt <= 'b0;
                end
                else begin
                    col_cnt <= col_cnt + 10'd1;
                end
            end
        end
    end

    // reg [9:0] buf_col; // 0-962
    // reg [1:0] buf_row; // 0-3
    // always@(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         buf_col <= 'b0;
    //         buf_row <= 'b0;
    //     end
    //     else begin
    //         if(pixel_valid) begin
    //             if(col_cnt == 10'd959) begin
    //                 if(row_cnt == 2'd3) begin
    //                     row_cnt <= 2'b0;
    //                 end
    //                 else begin
    //                     row_cnt <= row_cnt + 2'd1;
    //                 end
    //                 col_cnt <= 'b0;
    //             end
    //             else begin
    //                 col_cnt <= col_cnt + 10'd1;
    //             end
    //         end
    //     end
    // end
// end of row and col count in source picture

// write data into buf
    always@(*) begin
        write_line = 12'b00;
        if(cstate == S_LOAD) begin
            write_line = ({2'b00, row_cnt[1:0]} + 12'd1) << 10;
        end
        else if(cstate == S_UPDATE) begin
            write_line = 12'hC00;
        end
    end

    integer i;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<1024 * 4; i = i + 1) begin
                buffer[i] <= 'b0;
            end
        end
        else begin
            if(handshake_buf_write) begin
                buffer[write_line + {2'b00, col_cnt} + 12'b1] <= rx_buf[31:0];

                if(col_cnt == 10'b1) begin
                    buffer[write_line] <= rx_buf[31:0];
                    if(cstate == S_UPDATE) begin
                        buffer[12'h000] <= buffer[12'h400];
                        buffer[12'h400] <= buffer[12'h800];
                        buffer[12'h800] <= buffer[12'hC00];
                    end
                end
                if(col_cnt == 10'd957) begin
                    buffer[write_line + {2'b00, 10'd962}] <= rx_buf[31:0];
                    if(cstate == S_UPDATE) begin
                        buffer[12'h000 + {2'b00, 10'd962}] <= buffer[12'h400 + {2'b00, 10'd962}];
                        buffer[12'h400 + {2'b00, 10'd962}] <= buffer[12'h800 + {2'b00, 10'd962}];
                        buffer[12'h800 + {2'b00, 10'd962}] <= buffer[12'hC00 + {2'b00, 10'd962}];
                    end
                end
                if(col_cnt == 10'd958) begin
                    buffer[write_line + {2'b00, 10'd961}] <= rx_buf[31:0];
                    if(cstate == S_UPDATE) begin
                        buffer[12'h000 + {2'b00, 10'd961}] <= buffer[12'h400 + {2'b00, 10'd961}];
                        buffer[12'h400 + {2'b00, 10'd961}] <= buffer[12'h800 + {2'b00, 10'd961}];
                        buffer[12'h800 + {2'b00, 10'd961}] <= buffer[12'hC00 + {2'b00, 10'd961}];
                    end
                end

                if(row_cnt == 10'd2 && col_cnt == 10'd0) begin
                    for(i = 0; i<963; i = i + 1) begin
                        buffer[i] <= buffer[12'h800 + i];
                    end
                end

                if(cstate == S_UPDATE) begin
                    buffer[12'h000 + {2'b00, col_cnt} + 12'b1] <= buffer[12'h400 + {2'b00, col_cnt} + 12'b1];
                    buffer[12'h400 + {2'b00, col_cnt} + 12'b1] <= buffer[12'h800 + {2'b00, col_cnt} + 12'b1];
                    buffer[12'h800 + {2'b00, col_cnt} + 12'b1] <= buffer[12'hC00 + {2'b00, col_cnt} + 12'b1];
                end
            end
            // write data to buffer
        end
    end
// end of write data into buf

    always@(*) begin
        axis_tready = 1'b0;
        if(cstate != S_IDLE && rx_index < 2'b11) begin
            axis_tready = 1'b1;
        end
    end

    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rx_buf <= 'b0;
            rx_index <= 3'b0;
        end
        else begin
            if(handshake_axis) begin
                case (rx_index)
                    3'b00: rx_buf[31:0] <= s_axis_tdata;
                    3'b01: rx_buf[39:8] <= s_axis_tdata;
                    3'b10: rx_buf[47:16] <= s_axis_tdata; 
                    default: rx_buf <= 'b0;
                endcase
                rx_index <= rx_index + 3'd4;
            end
            else if(handshake_buf_write) begin
                rx_buf <= rx_buf >> 24;
                rx_index <= rx_index - 3'd3;
            end
        end
    end

// state machine
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cstate <= S_IDLE;
        end
        else begin
            cstate <= nstate;
        end
    end

    always @(*) begin
        nstate = cstate;
        case (cstate)
            S_IDLE:
                if(start) begin
                    nstate = S_LOAD;
                end
            S_LOAD:
                if(row_cnt == 10'd2 && col_cnt == 10'd959 && handshake_buf_write) begin
                    nstate = S_READ;
                end
            S_READ:
                if(out_cnt == 19'd13 && pixel_valid) begin
                    nstate = S_UPDATE;
                end
            S_UPDATE:
                if(row_cnt == 10'd539 && col_cnt == 10'd959 && handshake_buf_write) begin
                    nstate = S_REMAIN;
                end
            S_REMAIN:
                if(out_cnt == 19'h7E900 - 19'd1 && pixel_valid) begin
                    nstate = S_TAIL;
                end
            S_TAIL:
                if(out_cnt == 19'h7E90E && pixel_valid) begin
                    nstate = S_IDLE;
                end
            default: 
                nstate = S_IDLE;
        endcase
    end
// end of state machine

    // reg [23:0] pixel_reg [0:15];
    // reg pixel_valid_req;
    // reg [18:0] out_cnt;

// data output
    // reg [9:0] out_index [0:15];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 1; i<16; i = i + 1) begin
                out_index[i] <= 10'd1023;
            end
            out_index[0] <= 10'd0;
        end
        else begin
            if(cstate == S_IDLE) begin
                out_index[0] <= 10'd0;
            end
            // generate output index
            if(pixel_valid_reg) begin
                for(i = 0; i<16; i = i + 1) begin
                    if(out_index[i] < 10'd959 + i % 4) begin
                        out_index[i] <= out_index[i] + 10'd1;
                    end
                    else if(out_index[i] == 10'd959 + i % 4) begin
                        if(nstate != S_TAIL && nstate != S_IDLE) begin
                            out_index[i] <= 10'd0 + i % 4;
                        end
                        else begin
                            out_index[i] <= 10'd1023;
                        end
                    end
                end
                for(i = 1; i<16; i = i + 1) begin
                    if(out_cnt == i - 1) begin
                        out_index[i] <= i % 4;
                    end
                end
            end
        end
    end

    // the count of out_cnt is ahead of real send data
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            out_cnt <= 'b0;
        end
        else begin
            if(pixel_valid_reg) begin
                out_cnt <= out_cnt + 19'b1;
            end
        end
    end

    assign pixel_canout = (cstate == S_READ || cstate == S_REMAIN || cstate == S_TAIL || (cstate == S_UPDATE && handshake_buf_write))?1'b1:1'b0;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            pixel_valid_req <= 1'b0;
            pixel_valid_reg <= 1'b0;
            pixel_valid_req_ex <= 1'b0;
        end
        else begin
            if(pixel_valid_req_ex & enable) begin
                pixel_valid_req_ex <= 1'b0;
            end

            if(pixel_valid_req) begin
                pixel_valid_req <= 1'b0;
            end
            else if(!pixel_valid_req_ex && pixel_canout && nstate != S_IDLE) begin
                pixel_valid_req <= 1'b1;
                pixel_valid_req_ex <= 1'b1;
            end

            pixel_valid_reg <= pixel_valid_req_ex & enable;
        end
    end

    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<16; i = i + 1) begin
                pixel_reg[i] <= 'b0;
            end
        end
        else begin
            if(pixel_valid_req) begin
                // for(i = 0; i < 16; i = i + 1) begin
                //     pixel_reg[i] <= buffer[((i/4) << 10) + {2'b00, out_index[i]}];
                // end
                for(i = 0; i<4; i = i + 1) begin
                    // pixel_reg[i] <= buffer[((i/4) << 10) + {2'b00, out_index[i]}];
                    if(out_cnt < 19'd516480 + i) begin
                        pixel_reg[i] <= buffer[{2'b00, out_index[i]}];
                    end
                    else if(out_cnt < 19'd517440 + i) begin
                        pixel_reg[i] <= buffer[{2'b01, out_index[i]}];
                    end
                    else begin
                        pixel_reg[i] <= buffer[{2'b10, out_index[i]}];
                    end
                end

                for(i = 0; i<4; i = i + 1) begin
                    // pixel_reg[i] <= buffer[((i/4) << 10) + {2'b00, out_index[i]}];
                    if(out_cnt < 19'd516484 + i) begin
                        pixel_reg[i + 4] <= buffer[{2'b01, out_index[i + 4]}];
                    end
                    else if(out_cnt < 19'd517444 + i) begin
                        pixel_reg[i + 4] <= buffer[{2'b10, out_index[i + 4]}];
                    end
                    else begin
                        pixel_reg[i + 4] <= buffer[{2'b11, out_index[i + 4]}];
                    end
                end

                for(i = 0; i<4; i = i + 1) begin
                    // pixel_reg[i] <= buffer[((i/4) << 10) + {2'b00, out_index[i]}];
                    if(out_cnt < 19'd516488 + i) begin
                        pixel_reg[i + 8] <= buffer[{2'b10, out_index[i + 8]}];
                    end
                    else if(out_cnt < 19'd517448 + i) begin
                        pixel_reg[i + 8] <= buffer[{2'b11, out_index[i + 8]}];
                    end
                    else begin
                        pixel_reg[i + 8] <= buffer[{2'b10, out_index[i + 8]}];
                    end
                end

                for(i = 0; i<4; i = i + 1) begin
                    // pixel_reg[i] <= buffer[((i/4) << 10) + {2'b00, out_index[i]}];
                    if(out_cnt < 19'd516492 + i) begin
                        pixel_reg[i + 12] <= buffer[{2'b11, out_index[i + 12]}];
                    end
                    else if(out_cnt < 19'd517452 + i) begin
                        pixel_reg[i + 12] <= buffer[{2'b10, out_index[i + 12]}];
                    end
                    else begin
                        pixel_reg[i + 12] <= buffer[{2'b01, out_index[i + 12]}];
                    end
                end

            end
        end
    end
// end of data output

endmodule
