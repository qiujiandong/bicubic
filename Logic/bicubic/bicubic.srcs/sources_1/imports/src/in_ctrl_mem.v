`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/11 08:34:00
// Design Name: 
// Module Name: in_ctrl_men
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


module in_ctrl_mem(

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

    reg [47:0] rx_buf;
    reg [2:0] rx_index;

    (* mark_debug = "true" *) reg [9:0] w_col_cnt; // 0-959
    (* mark_debug = "true" *) reg [9:0] w_row_cnt; // 0-539

    (* mark_debug = "true" *) reg [18:0] out_cnt;
    // reg [9:0] out_index [0:15];

    reg axis_tready;
    wire handshake_axis;

    // (* mark_debug = "true" *) reg buf_write_ready;
    (* mark_debug = "true" *) reg buf_write_ready_reg;
    (* mark_debug = "true" *) wire buf_write_req;
    (* mark_debug = "true" *) wire handshake_mem_write;

    // reg [1:0] rst_sf;
    // wire rst_busy_or;
    wire rst_done;

    // reg pixel_ready;
    reg rd_times;
    reg rd_cnt;
    reg rd_cnt_q;
    reg rd_cnt_qq;
    // reg [1:0] rd_ltcy_cnt;
    reg enb_q;
    reg enb_qq;

    (* mark_debug = "true" *) reg [23:0] rdback_data [0:2];
    (* mark_debug = "true" *) wire rdback_ready;
    (* mark_debug = "true" *) reg wr_ready;

    reg wr_times;
    reg wr_cnt;

    (* mark_debug = "true" *) reg load_done;

    (* mark_debug = "true" *) reg [10:0] padding_cnt;
    (* mark_debug = "true" *) reg wea_hold;
    (* mark_debug = "true" *) reg rdback_hold;

    (* mark_debug = "true" *) wire start_en;
    reg [1:0] start_q;

    integer i;

// state
    localparam [2:0] S_IDLE =     3'b000;
    localparam [2:0] S_RSTMEM =   3'b001;
    localparam [2:0] S_LOAD =     3'b011;
    localparam [2:0] S_PREPARE =  3'b010;
    localparam [2:0] S_TX =       3'b110;
    localparam [2:0] S_RDBACK =   3'b111;
    localparam [2:0] S_UPDATE =   3'b101;
    localparam [2:0] S_LAST   =   3'b100;
    // localparam S_PADDING =  3'b100;
    // localparam S_TAIL =         3'b100;

    (* mark_debug = "true" *) reg [2:0] cstate;
    (* mark_debug = "true" *) reg [2:0] nstate;
// end of state

// buf_mem
    (* mark_debug = "true" *) reg [3:0] wea;
    (* mark_debug = "true" *) reg [9:0] addra;
    reg [23:0] dina [0:3];

    reg rstb;
    reg [3:0] rst_cnt;
    (* mark_debug = "true" *) reg enb;
    (* mark_debug = "true" *) reg [9:0] addrb [0:3];
    reg [9:0] addrb_shadow [0:3];
    (* mark_debug = "true" *) reg [9:0] addrb_cnt [0:3];
    // reg [9:0] addrb_alt [0:3];
    wire [23:0] doutb [0:3];
    wire [3:0] rsta_busy;
    wire [3:0] rstb_busy;
    wire wea_or;
    // wire enb_or;
// end of buf_mem

// output
    reg [23:0] pixel_reg [0:15];
    reg pixel_valid_req;
    reg pixel_valid_req_ex;
    reg pixel_valid_reg;
    reg pixel_valid_req_q;

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

// assignment
    assign s_axis_tready = axis_tready & enable;
    assign handshake_axis = s_axis_tvalid & s_axis_tready;

    assign buf_write_req = (rx_index > 3'd2)? 1'b1: 1'b0;
    assign handshake_mem_write = |wea;

    // assign rst_busy_or = |rsta_busy | |rstb_busy;
    assign rst_done = (rst_cnt == 4'd10)? 1'b1: 1'b0;

    // assign enb_or = |enb;
    assign wea_or = |wea;

    assign rdback_ready = (cstate == S_RDBACK && enb_q && enb_qq)? 1'b1: 1'b0;

    assign start_en = (start_q == 2'b01)? 1'b1: 1'b0;

// end of assignment

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
                if(start_en) begin
                    nstate = S_RSTMEM;
                end
            S_RSTMEM:
                if(rst_done) begin
                    nstate = S_LOAD;
                end
            S_LOAD:
                if(w_row_cnt == 10'd2 && w_col_cnt == 10'd959 && handshake_mem_write) begin
                    nstate = S_PREPARE;
                end
            S_PREPARE:
                if(pixel_valid_req) begin
                    nstate = S_TX;
                end
            S_TX:
                if(pixel_valid) begin
                    if(out_cnt < 19'd17) begin
                        nstate = S_PREPARE;
                    end
                    else if(padding_cnt < 11'd1920) begin
                        nstate = S_RDBACK;
                    end
                    else if(out_cnt < 19'h7E900 + 19'd14) begin
                        nstate = S_PREPARE;
                    end
                    else if(out_cnt == 19'h7E900 + 19'd14) begin
                        nstate = S_LAST;
                    end
                end
            S_LAST: 
                if(out_cnt == 19'h7E900 + 19'd29) begin
                    nstate = S_IDLE;
                end
            S_RDBACK:
                if(rdback_ready) begin
                    nstate = S_UPDATE;
                end
            S_UPDATE:
                if(|wea) begin
                    if(!(addra == 10'd0 || addra == 10'd958 || addra == 10'd959)) begin
                        nstate = S_PREPARE;
                    end
                end
                else if(wea_hold) begin
                    nstate = S_RDBACK;
                end
            default: 
                nstate = S_IDLE;
        endcase
    end
// end of state machine

    // reg rst_sf
    // always @(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         rst_sf <= 2'b00;
    //     end
    //     else begin
    //         if(cstate == S_IDLE && nstate == S_RSTMEM) begin
    //             rst_sf <= 2'b11;
    //         end
    //         else if(cstate == S_RSTMEM) begin
    //             rst_sf <= {rst_sf[0], rst_busy_or};
    //         end
    //     end
    // end

    // reg axis_tready
    always@(*) begin
        axis_tready = 1'b0;
        if(cstate != S_IDLE && rx_index < 2'b11) begin
            axis_tready = 1'b1;
        end
    end

    // reg buf_write_ready_reg;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            buf_write_ready_reg = 1'b0;
        end
        else begin
            if(cstate == S_UPDATE && pixel_valid_reg) begin
                buf_write_ready_reg <= 1'b1;
            end
            else if(handshake_mem_write) begin
                buf_write_ready_reg <= 1'b0;
            end
        end
    end

    // reg buf_write_ready
    // always @(*) begin
        // buf_write_ready = 1'b0;
        // if(cstate == S_LOAD || buf_write_ready_reg) begin
        //     buf_write_ready = 1'b1;
        // end

    // end

    // row and col count in source picture
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            w_row_cnt <= 'b0;
            w_col_cnt <= 'b0;
            load_done <= 'b0;
        end
        else begin
            if(cstate == S_IDLE) begin
                w_col_cnt <= 'b0;
                w_row_cnt <= 'b0;
            end
            else if(handshake_mem_write && wr_cnt == wr_times) begin
                if(w_col_cnt == 10'd959) begin
                    if(w_row_cnt == 10'd539) begin
                        w_row_cnt <= 'b0;
                    end
                    else begin
                        w_row_cnt <= w_row_cnt + 10'd1;
                    end
                    w_col_cnt <= 'b0;
                end
                else begin
                    w_col_cnt <= w_col_cnt + 10'd1;
                end
            end

            if(w_row_cnt == 10'd539 && w_col_cnt == 10'd959 && handshake_mem_write && wr_cnt == wr_times ) begin
                load_done <= 1'b1;
            end
            else if(cstate == S_IDLE) begin
                load_done <= 1'b0;
            end
        end
    end

    // reg [47:0] rx_buf;
    // reg [2:0] rx_index;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rx_buf <= 'b0;
            rx_index <= 3'b0;
        end
        else begin
            if(cstate == S_IDLE) begin
                rx_buf <= 'b0;
                rx_index <= 3'b0;
            end
            else if(handshake_axis) begin
                case (rx_index)
                    3'b00: rx_buf[31:0] <= s_axis_tdata;
                    3'b01: rx_buf[39:8] <= s_axis_tdata;
                    3'b10: rx_buf[47:16] <= s_axis_tdata; 
                    default: rx_buf <= 'b0;
                endcase
                rx_index <= rx_index + 3'd4;
            end
            else if(handshake_mem_write && wr_cnt == wr_times) begin
                rx_buf <= rx_buf >> 24;
                rx_index <= rx_index - 3'd3;
            end
        end
    end

    // the count of out_cnt is ahead of real send data
    // reg [18:0] out_cnt;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            out_cnt <= 'b0;
        end
        else begin
            if(cstate == S_IDLE) begin
                out_cnt <= 'b0;
            end
            else if(pixel_valid_reg) begin
                out_cnt <= out_cnt + 19'b1;
            end
        end
    end

    // reg rd_times;
    always@(*) begin
        if(out_cnt > 19'd15 && (addrb_cnt[0] < 10'd3 || addrb_cnt[1] < 10'd3 || addrb_cnt[2] < 10'd3 || addrb_cnt[3] < 10'd3)) begin
            rd_times = 1'b1;
        end
        else begin
            rd_times = 1'b0;
        end
    end

    // reg rd_cnt;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rd_cnt <= 1'b0;
            rd_cnt_q <= 1'b0;
            rd_cnt_qq <= 1'b0;    
        end
        else begin
            if(!enb_qq && enb_q && cstate == S_PREPARE && rd_cnt < rd_times) begin
                rd_cnt <= rd_cnt + 1'b1;
            end
            else if(pixel_valid_req) begin
                rd_cnt <= 1'b0;
            end
            rd_cnt_q <= rd_cnt;
            rd_cnt_qq <= rd_cnt_q;
        end
    end

    // reg [1:0] rd_ltcy_cnt;
    // reg enb_q;
    // reg enb_qq;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            enb_q <= 1'b0;
            enb_qq <= 1'b0;
        end
        else begin
            enb_q <= enb;
            enb_qq <= enb_q;
        end
    end

    // reg pixel_ready;
    // reg rdback_ready;
    // always@(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         pixel_ready <= 'b0;
    //         rdback_ready <= 'b0;
    //     end
    //     else begin
    //         if(!enb_q && enb_qq ) begin
    //             case (cstate)
    //                 S_PREPARE: begin
    //                     pixel_ready <= 1'b1;
    //                 end
    //                 S_RDBACK: begin
    //                     rdback_ready <= 1'b1;
    //                 end
    //                 default: begin
    //                     pixel_ready <= 1'b0;
    //                     rdback_ready <= 1'b0;
    //                 end
    //             endcase
    //         end
    //     end
    // end


    // reg [9:0] out_index [0:15];
    // reg [9:0] addrb [0:3];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            // for(i = 1; i<16; i = i + 1) begin
            //     out_index[i] <= 10'd963;
            // end
            // out_index[0] <= 10'd0;
            for(i = 0; i<4; i = i + 1) begin
                addrb[i] <= 'b0;
            end
        end
        else begin
            case (nstate)
                S_IDLE: begin
                    for(i = 0; i<4; i = i + 1) begin
                        addrb[i] <= 'b0;
                    end
                end
                S_RSTMEM: begin
                    for(i = 0; i<4; i = i + 1) begin
                        addrb[i] <= 10'd963;
                    end
                end 
                // S_LOAD: begin
                //     for(i = 0; i<4; i = i + 1) begin
                //         addrb[i] <= addrb_cnt[i];
                //     end
                // end
                S_PREPARE: begin
                    if(rd_cnt & !rd_cnt_q || (cstate != S_PREPARE)) begin
                        if(rd_cnt == rd_times) begin
                            for(i = 0; i<4; i = i + 1) begin
                                if(out_cnt < 19'd518400) begin
                                    addrb[i] <= addrb_cnt[i];
                                end
                                else if(addrb_cnt[i] < 10'd16) begin
                                    addrb[i] <= 10'd963;
                                end
                                else begin
                                    addrb[i] <= addrb_cnt[i];
                                end
                            end
                        end
                        else begin
                            for(i = 0; i<4; i = i + 1) begin
                                addrb[i] <= addrb_shadow[i];
                            end
                        end
                    end
                end
                S_RDBACK: begin
                    addrb[0] <= addra;
                    addrb[1] <= addra;
                    addrb[2] <= addra;
                    addrb[3] <= addra;
                end
                default: begin
                    for(i = 0; i<4; i = i + 1) begin
                        addrb[i] <= addrb[i];
                    end
                end
            endcase
            
            // if(cstate == S_IDLE) begin
            //     out_index[0] <= 10'd0;
            // end
            // // generate output index
            // if(pixel_valid_reg) begin
            //     for(i = 0; i<16; i = i + 1) begin
            //         if(out_index[i] < 10'd959 + i % 4) begin
            //             out_index[i] <= out_index[i] + 10'd1;
            //         end
            //         else if(out_index[i] == 10'd959 + i % 4) begin
            //             if(nstate != S_TAIL && nstate != S_IDLE) begin
            //                 out_index[i] <= 10'd0 + i % 4;
            //             end
            //             else begin
            //                 out_index[i] <= 10'd963;
            //             end
            //         end
            //     end
            //     for(i = 1; i<16; i = i + 1) begin
            //         if(out_cnt == i - 1) begin
            //             out_index[i] <= i % 4;
            //         end
            //     end
            // end
        end
    end

    // reg [9:0] addrb_shadow [0:3];
    always@(*) begin
        for(i = 0; i < 4; i = i + 1) begin
            if(addrb_cnt[i] < 10'd3) begin
                addrb_shadow[i] = 10'd960 + addrb_cnt[i];
            end
            else begin
                addrb_shadow[i] = addrb_cnt[i];
            end
        end
    end

    // reg [9:0] addrb_alt [0:3]
    // always@(*) begin
    //     if(out_cnt > 19'd518399) begin

    //     end
    //     else begin
    //         for(i = 0; i<4; i = i + 1) begin
    //             addrb_alt[i] <= 'b0;
    //         end
    //     end
    // end

    // reg [9:0] addrb_cnt [0:3];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<4; i = i + 1) begin
                addrb_cnt[i] <= 'b0;
            end
        end
        else begin
            if(cstate == S_IDLE) begin
                for(i = 0; i<4; i = i + 1) begin
                    addrb_cnt[i] <= 'b0;
                end
            end
            else if(cstate == S_PREPARE && nstate == S_TX) begin
                for(i = 0; i<4; i = i + 1) begin
                    if(addrb_cnt[i] < 10'd959) begin
                        addrb_cnt[i] <= addrb_cnt[i] + 10'd1;
                    end
                    else if(addrb_cnt[i] == 10'd959) begin
                        if(nstate != S_IDLE) begin
                            addrb_cnt[i] <= 10'd0;
                        end
                        else begin
                            addrb_cnt[i] <= 10'd963;
                        end
                    end
                end
                for(i = 1; i<4; i = i + 1) begin
                    if(out_cnt == i * 4 - 1) begin
                        addrb_cnt[i] <= 0;
                    end
                end
            end
            else if(cstate == S_LOAD) begin
                addrb_cnt[0] <= 'b0;
                addrb_cnt[1] <= 10'd963;
                addrb_cnt[2] <= 10'd963;
                addrb_cnt[3] <= 10'd963;
            end
        end
    end


    // reg wr_ready;
    always@(*) begin
        if(cstate == S_LOAD ) begin
            wr_ready = buf_write_req;
        end
        else if(cstate == S_UPDATE) begin
            if(load_done) begin
                wr_ready = rdback_hold;
            end
            else begin
                wr_ready = buf_write_req & rdback_hold;
            end
        end
        else begin
            wr_ready = 1'b0;
        end
    end 

    // reg wr_times;
    always@(*) begin
        if(w_col_cnt == 10'd1 || w_col_cnt == 10'd957 || w_col_cnt == 10'd958) begin
            wr_times = 1'b1;
        end
        else begin
            wr_times = 1'b0;
        end
    end

    // reg wr_cnt;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            wr_cnt <= 'b0;
        end
        else begin
            if(wea_or) begin
                if(wr_cnt < wr_times) begin
                    wr_cnt <= wr_cnt + 1'b1;
                end
                else begin
                    wr_cnt <= 1'b0;
                end
            end
        end
    end 


    // reg [3:0] wea;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            wea <= 'b0;
        end
        else begin
            if(!wea_or && wr_ready) begin
                if(!load_done) begin
                    if(w_row_cnt == 10'd0) begin
                        wea <= 4'b0010;
                    end
                    else if(w_row_cnt == 10'd1) begin
                        wea <= 4'b0101;
                    end
                    else if(w_row_cnt == 10'd2) begin
                        wea <= 4'b1000;
                    end
                    else begin
                        wea <= 4'b1111;
                    end
                end 
                else begin
                    wea <= 4'b1111;
                end
                // case (w_row_cnt)
                //     10'd0: wea <= 4'b0010;
                //     10'd1: wea <= 4'b0101;
                //     10'd2: wea <= 4'b1000;
                //     default: wea <= 4'b1111;
                // endcase
                // if(w_row_cnt  == 10'd0) begin
                //     wea <= 4'b0010;
                // end
                // if(w_row_cnt == 10'd1) begin
                //     wea <= 4'b0101;
                // end
                // if(w_row_cnt == 10'd2) begin
                //     wea <= 4'b1000;
                // end
            end
            else begin
                wea <= 'b0;
            end
        end
    end 

    // reg [9:0] addra;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            addra <= 'b1;
        end
        else begin
            if(|wea) begin
                case (addra)
                    10'd1: addra <= 10'd0;
                    10'd0: addra <= 10'd2;
                    10'd958: addra <= 10'd962;
                    10'd962: addra <= 10'd959;
                    10'd959: addra <= 10'd961;
                    10'd961: addra <= 10'd960;
                    10'd960: addra <= 10'd1;
                    default: addra <= addra + 10'd1;
                endcase
            end
        end
    end

    // reg [23:0] dina [0:3];
    always@(*) begin
        // if(!aresetn) begin
        //     for(i = 0; i<4; i = i + 1) begin
        //         dina[i] <= 'b0;
        //     end
        // end
        // else begin
        //     if(|wea) begin
        //         case (nstate)
        //             S_LOAD: begin
        //                 if(w_row_cnt == 10'd0) begin
        //                     dina[1] <= rx_buf[31:0];
        //                 end 
        //                 else if(w_row_cnt == 10'd1) begin
        //                     dina[0] <= rx_buf[31:0];
        //                     dina[2] <= rx_buf[31:0];
        //                 end
        //                 else if(w_row_cnt == 10'd2) begin
        //                     dina[3] <= rx_buf[31:0];
        //                 end
        //             end
        //             S_PREPARE: begin
        //             end
        //             default: begin
        //             end
        //         endcase
        //     end
        // end
        case (cstate)
            S_LOAD: begin
                if(w_row_cnt == 10'd0) begin
                    dina[1] = rx_buf[31:0];
                end 
                else if(w_row_cnt == 10'd1) begin
                    dina[0] = rx_buf[31:0];
                    dina[2] = rx_buf[31:0];
                end
                else if(w_row_cnt == 10'd2) begin
                    dina[3] = rx_buf[31:0];
                end
            end
            S_UPDATE: begin
                if(!load_done) begin
                    dina[0] = rdback_data[0];
                    dina[1] = rdback_data[1];
                    dina[2] = rdback_data[2];
                    dina[3] = rx_buf[31:0];
                end
                else begin
                    if(padding_cnt < 11'd960) begin
                        dina[0] = rdback_data[0];
                        dina[1] = rdback_data[1];
                        dina[2] = rdback_data[2];
                        dina[3] = rdback_data[1];
                    end
                    else begin
                        dina[0] = rdback_data[1];
                        dina[1] = rdback_data[2];
                        dina[2] = rdback_data[1];
                        dina[3] = rdback_data[0];
                    end
                end
            end
            default: begin
                for(i = 0; i<4; i = i + 1) begin
                    dina[i] = 'b0;
                end
            end
        endcase
    end

    //  reg [23:0] rdback_data [0:3];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rdback_data[0] <= 'b0;
            rdback_data[1] <= 'b0;
            rdback_data[2] <= 'b0;
        end
        else begin
            if(cstate == S_IDLE) begin
                rdback_data[0] <= 'b0;
                rdback_data[1] <= 'b0;
                rdback_data[2] <= 'b0;
            end
            else if(cstate == S_RDBACK && rdback_ready) begin
                if(padding_cnt < 11'd960) begin
                    rdback_data[0] <= doutb[1];
                    rdback_data[1] <= doutb[2];
                    rdback_data[2] <= doutb[3];
                end
                else begin
                    rdback_data[0] <= doutb[0];
                    rdback_data[1] <= doutb[1];
                    rdback_data[2] <= doutb[2];
                end


                // rdback_data[0] <= doutb[1];
                // rdback_data[1] <= doutb[2];
                // rdback_data[2] <= doutb[3];
            end
        end
    end

    // reg [1:0] rstb;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rstb <= 'b0;
        end
        else begin
            if(cstate == S_IDLE && nstate == S_RSTMEM) begin
                rstb <= 1'b1;
            end
            else if(rst_cnt > 4'd5)begin
                rstb <= 'b0;
            end
        end
    end 

    // reg [3:0] rst_cnt;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rst_cnt <= 4'hF;
        end
        else begin
            if(rst_cnt < 4'd10) begin
                rst_cnt <= rst_cnt + 4'd1;
            end
            else if(rstb) begin
                rst_cnt <= 4'd0;
            end
        end
    end 

    // reg [3:0] enb;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            enb <= 'b0;
        end
        else begin
            case (nstate)
                S_RSTMEM: begin
                    enb <= 1'b1;
                end 
                S_PREPARE: begin
                    if(cstate != S_PREPARE) begin
                        enb <= 1'b1;
                    end
                    else if(rd_cnt_qq == rd_times && enb_q) begin
                        enb <= 1'b0;
                    end
                end
                S_RDBACK: begin
                    if(cstate != S_RDBACK) begin
                        enb <= 1'b1;
                    end
                    else if(enb_q) begin
                        enb <= 1'b0;
                    end
                end
                default: begin
                    enb <= 1'b0;
                end
            endcase
            // if(nstate == S_RSTMEM) begin
            //     enb <= 4'b1111;
            // end
            // else if(cstate == S_RDBACK && buf_write_req) begin
            //     enb <= 4'b0111;
            // end
            // else begin
            //     enb <= 'b0;
            // end
        end
    end

    // reg [9:0] addrb [0:3];
    // always@(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         for(i = 0; i<4; i = i + 1) begin
    //             addrb[i] <= 'b0;
    //         end
    //     end
    //     else begin
    //         if(cstate == S_RSTMEM) begin
    //             for(i = 0; i<4; i = i + 1) begin
    //                 addrb[i] <= 10'd963;
    //             end
    //         end
    //     end
    // end
    
    // reg [23:0] pixel_reg [0:15];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<16; i = i + 1) begin
                pixel_reg[i] <= 'b0;
            end
        end
        else begin
            if(cstate == S_IDLE || cstate == S_LAST) begin
                for(i = 0; i<16; i = i + 1) begin
                    pixel_reg[i] <= 'b0;
                end
            end
            else if(cstate == S_PREPARE && (pixel_valid_req || (rd_cnt && !rd_cnt_q))) begin
                if(rd_cnt_q == rd_times) begin
                    for(i = 0; i < 4; i = i + 1) begin
                        case (addrb_cnt[i])
                            10'd0:begin
                                if(out_cnt > 19'd15) begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                end
                                else begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                end
                            end
                            10'd1: begin
                                if(out_cnt > 19'd15) begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                    pixel_reg[i * 4 + 1] <= doutb[i];
                                end
                                else begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                    pixel_reg[i * 4 + 1] <= doutb[i];
                                end
                            end
                            10'd2: begin
                                if(out_cnt > 19'd15) begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                    pixel_reg[i * 4 + 1] <= doutb[i];
                                    pixel_reg[i * 4 + 2] <= doutb[i];
                                end
                                else begin
                                    pixel_reg[i * 4 + 0] <= doutb[i];
                                    pixel_reg[i * 4 + 1] <= doutb[i];
                                    pixel_reg[i * 4 + 2] <= doutb[i];
                                end
                            end 
                            default: begin
                                pixel_reg[i * 4 + 0] <= doutb[i];
                                pixel_reg[i * 4 + 1] <= doutb[i];
                                pixel_reg[i * 4 + 2] <= doutb[i];
                                pixel_reg[i * 4 + 3] <= doutb[i];
                            end
                        endcase
                    end
                end
                else begin
                    for(i = 0; i < 4; i = i + 1) begin
                        case (addrb_cnt[i])
                            10'd0:begin
                                pixel_reg[i * 4 + 1] <= doutb[i];
                                pixel_reg[i * 4 + 2] <= doutb[i];
                                pixel_reg[i * 4 + 3] <= doutb[i];
                            end
                            10'd1: begin
                                pixel_reg[i * 4 + 2] <= doutb[i];
                                pixel_reg[i * 4 + 3] <= doutb[i];
                            end
                            10'd2: begin
                                pixel_reg[i * 4 + 3] <= doutb[i];
                            end 
                            default: begin
                                pixel_reg[i * 4 + 0] <= doutb[i];
                                pixel_reg[i * 4 + 1] <= doutb[i];
                                pixel_reg[i * 4 + 2] <= doutb[i];
                                pixel_reg[i * 4 + 3] <= doutb[i];
                            end
                        endcase
                    end
                end
            end
        end
    end

    // reg pixel_valid_req_ex;
    // reg pixel_valid_reg;
    // reg pixel_valid_req;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            pixel_valid_req <= 1'b0;
            pixel_valid_reg <= 1'b0;
            pixel_valid_req_ex <= 1'b0;
            pixel_valid_req_q <= 1'b0;
        end
        else begin
            if(pixel_valid_req_ex & enable) begin
                pixel_valid_req_ex <= 1'b0;
            end
            else if((enb && enb_q && rd_cnt_qq == rd_times && cstate == S_PREPARE) || (cstate == S_LAST && !pixel_valid_req_ex && !pixel_valid_req_q && !pixel_valid_reg)) begin
                pixel_valid_req_ex <= 1'b1;
            end

            if(pixel_valid_req) begin
                pixel_valid_req <= 1'b0;
            end
            else if((enb && enb_q && rd_cnt_qq == rd_times && cstate == S_PREPARE) || (cstate == S_LAST && !pixel_valid_req_ex && !pixel_valid_req_q && !pixel_valid_reg)) begin
                pixel_valid_req <= 1'b1;
            end

            pixel_valid_reg <= pixel_valid_req_ex & enable;
            pixel_valid_req_q <= pixel_valid_req;
        end
    end

    // reg [10:0] padding_cnt;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            padding_cnt <= 'b0;
        end
        else begin
            if(cstate == S_IDLE) begin
                padding_cnt <= 'b0;
            end
            else if(load_done && handshake_mem_write && wr_cnt == wr_times) begin
                padding_cnt <= padding_cnt + 11'd1;
            end
        end
    end

    // reg wea_hold;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            wea_hold <= 'b0;
        end
        else begin
            if((addra == 10'd0 || addra == 10'd958 || addra == 10'd959) && |wea) begin
                wea_hold <= 1'b1;
            end
            else begin
                wea_hold <= 1'b0;
            end
        end
    end

    // reg rdback_hold;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rdback_hold <= 'b0;
        end
        else begin
            if(rdback_ready) begin
                rdback_hold <= 1'b1;
            end
            else if(|wea) begin
                rdback_hold <= 1'b0;
            end
        end
    end

    // reg start_q
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            start_q <= 2'b0;
        end
        else begin
            start_q <= {start_q[0], start};
        end
    end

    

genvar n;
generate
    for(n = 0; n<4; n = n + 1) begin: buf_line
        buf_mem inst_buf_line (
        .clka(aclk),            // input wire clka
        .wea(wea[n]),              // input wire [0 : 0] wea
        .addra(addra),          // input wire [9 : 0] addra
        .dina(dina[n]),            // input wire [23 : 0] dina

        .clkb(aclk),            // input wire clkb
        .rstb(rstb),            // input wire rstb
        .enb(enb),              // input wire enb
        .addrb(addrb[n]),          // input wire [9 : 0] addrb
        .doutb(doutb[n]),          // output wire [23 : 0] doutb
        .rsta_busy(rsta_busy[n]),  // output wire rsta_busy
        .rstb_busy(rstb_busy[n])  // output wire rstb_busy
        );
    end
endgenerate
    
endmodule
