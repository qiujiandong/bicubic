`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/06 10:39:52
// Design Name: 
// Module Name: output_ctrl
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


module out_ctrl#(
    // 0-15 for 1-16 cycles
    parameter [3:0] IRQ_CYCLES = 3
)(

    input aclk,
    input aresetn,

    input start,
    input [31:0] dst_addr,

    input [16 * 24 - 1:0] result, // 24 bits * 16 = 384 bits
    input result_valid,

    output busy,
    output finish_irq,

//  m_axi interface
    output [31 : 0] m_axi_awaddr,
    output m_axi_awvalid,
    input m_axi_awready,
    output [7:0] m_axi_awlen,

    output [31 : 0] m_axi_wdata,
    output [3 : 0] m_axi_wstrb,
    output m_axi_wlast,
    output m_axi_wvalid,
    input m_axi_wready
// end m_axi interface
    );

    localparam [2:0] S_IDLE = 3'b000;
    localparam [2:0] S_PASS = 3'b001;
    localparam [2:0] S_STORE = 3'b010;
    localparam [2:0] S_TX_0 = 3'b011;
    localparam [2:0] S_TX_1 = 3'b111;
    localparam [2:0] S_TX_2 = 3'b110;
    localparam [2:0] S_TX_3 = 3'b100;

/* signal definition */
    (* mark_debug = "true" *) (* keep = "true" *) reg [2:0] cstate;
    (* mark_debug = "true" *) (* keep = "true" *) reg [2:0] nstate;

    /* data[0:3] for result pixel[0:3]
     * data[4:7] for result pixel[4:7]
     * data[8:11] for result pixel[8:11]
     * data[12:15] for result pixel[12:15]
     */
    reg [4 * 24 - 1:0] data [0:15];
    (* mark_debug = "true" *) reg [3:0] pass_data_cnt;
    (* mark_debug = "true" *) reg [15:0] rx_strb;
    (* mark_debug = "true" *) reg [18:0] rx_cnt;
    (* mark_debug = "true" *) reg [3:0] rx_index [0:15];
    
    // reg [2:0] part_tx_cnt;
    // wire [2:0] tx_times;
    (* mark_debug = "true" *) reg [3:0] tx_strb;
    (* mark_debug = "true" *) wire [3:0] tx_index [0:3];
    // every tx package incr tx_cnt
    // reg [20:0] tx_cnt;
    (* mark_debug = "true" *) reg [9:0] tx_col_cnt [0:3];
    (* mark_debug = "true" *) reg [9:0] tx_row_cnt [0:3];

    (* mark_debug = "true" *) reg tx_checked;
    
    reg [31:0] axi_awaddr;
    reg axi_awvalid;
    // reg [7:0] axi_awlen;

    reg [31:0] axi_wdata;
    // reg [15:0] axi_wstrb;
    reg axi_wlast;
    reg axi_wvalid;

    wire handshake_w;
    wire handshake_aw;

    reg finish_irq_reg;
    reg [3:0] irq_cnt;

    reg [31:0] addr_line_reg [0:3];

    // reg busy_reg;
    (* mark_debug = "true" *) wire start_en;
    reg [1:0] start_q;

    (* mark_debug = "true" *) reg [1:0] axi_wcnt;
    reg aw_tx_finished;

    integer i;
/* end of signal definition */

/* assignment */
    assign busy = ((cstate != S_PASS && cstate != S_STORE) || nstate == S_TX_0)? 1'b1:1'b0;
    // assign busy = 1'b1;
    // assign busy = busy_reg;
    assign handshake_aw = m_axi_awvalid && m_axi_awready;
    assign handshake_w = m_axi_wvalid && m_axi_wready;

    assign m_axi_awaddr = axi_awaddr;
    assign m_axi_awvalid = axi_awvalid;
    assign m_axi_awlen = 8'd2;
    assign m_axi_wdata = axi_wdata;
    assign m_axi_wstrb = 4'b1111;
    assign m_axi_wlast = axi_wlast;
    assign m_axi_wvalid = axi_wvalid;

    assign tx_times = {2'b00, tx_strb[0]} + {2'b00, tx_strb[1]} + {2'b00, tx_strb[2]} + {2'b00, tx_strb[3]};
    assign finish_irq = finish_irq_reg;

    assign tx_index[0] = tx_col_cnt[0] % 4;
    assign tx_index[1] = tx_col_cnt[1] % 4 + 4'd4;
    assign tx_index[2] = tx_col_cnt[2] % 4 + 4'd8;
    assign tx_index[3] = tx_col_cnt[3] % 4 + 4'd12;

    assign start_en = (start_q == 2'b01)? 1'b1: 1'b0;
/* end of assignment */

/* state machine */
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cstate <= S_IDLE;
        end
        else begin
            cstate <= nstate;
        end
    end

    always@(*) begin
        nstate = cstate;
        case (cstate)
            S_IDLE: 
                if(start_en) begin
                    nstate = S_PASS;
                end
            S_PASS:
                if(pass_data_cnt == 4'd15) begin
                    nstate = S_STORE;
                end
            S_STORE:
                if(rx_cnt > 19'd2 && result_valid) begin
                    nstate = S_TX_0;
                end
            S_TX_0:
                if(tx_checked) begin
                    nstate = S_TX_1;
                end
            S_TX_1:
                if(tx_checked) begin
                    nstate = S_TX_2;
                end
            S_TX_2:
                if(tx_checked) begin
                    nstate = S_TX_3;
                end
            S_TX_3:
                if(tx_checked) begin
                    if(tx_col_cnt[3] == 10'd0 && tx_row_cnt[3] == 10'd540) begin // 1843200 = 3840 * 1920 / 4
                        nstate = S_IDLE;
                    end
                    else begin
                        nstate = S_STORE;
                    end
                end
            default: nstate = S_IDLE;
        endcase
    end
/* end of state machine */

    // pass_data_cnt
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            pass_data_cnt <= 4'd0;
        end
        else begin
            if(cstate == S_IDLE) begin
                pass_data_cnt <= 'b0;
            end
            else if(cstate == S_PASS && result_valid) begin
                pass_data_cnt <= pass_data_cnt + 4'b1;
            end
        end
    end

    // rx_strb
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rx_strb <= 16'b0;
        end
        else begin
            if(cstate == S_STORE && result_valid) begin
                if(rx_cnt < 19'd15) begin
                    rx_strb <= (rx_strb << 1) + 16'b1;
                end
                else if(rx_cnt > 19'd518398) begin
                    rx_strb <= rx_strb << 1;
                end
            end 
            else if(cstate == S_IDLE) begin
                rx_strb <= 16'b1;
            end
        end
    end

    // rx_cnt
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            rx_cnt <= 4'd0;
        end
        else begin
            if(cstate == S_STORE && result_valid) begin
                if(rx_cnt < 19'd518414) begin
                    rx_cnt <= rx_cnt + 19'd1;
                end
                else begin
                    rx_cnt <= 'b0;
                end
            end
        end
    end

    // reg [3:0] rx_index [0:15];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<16; i = i + 1) begin
                rx_index[i] <= 'b0;
            end
        end
        else begin
            if(cstate == S_STORE && result_valid) begin
                for(i = 0; i<16; i = i + 1) begin
                    if(rx_strb[i]) begin
                        if(rx_index[i] == i / 4 * 4 + 4'd3) begin
                            rx_index[i] <= i / 4 * 4;
                        end
                        else begin
                            rx_index[i] <= rx_index[i] + 4'd1;
                        end
                    end
                end
            end
            else if(cstate == S_IDLE) begin
                for(i = 0; i<4; i = i + 1) begin
                    rx_index[i] <= 4'd0;
                end
                for(i = 4; i<8; i = i + 1) begin
                    rx_index[i] <= 4'd4;
                end
                for(i = 8; i<12; i = i + 1) begin
                    rx_index[i] <= 4'd8;
                end
                for(i = 12; i<16; i = i + 1) begin
                    rx_index[i] <= 4'd12;
                end
            end
        end
    end

    // reg [4 * 24 - 1:0] data [0:15];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<16; i = i + 1) begin
                data[i] <= 'b0;
            end
        end
        else begin
            if(cstate == S_STORE && result_valid) begin
                for(i = 0; i<16; i = i + 1) begin
                    if(rx_strb[i]) begin
                        data[rx_index[i]][i%4 * 24 +: 24] <= result[i*24 +: 24];
                    end
                end
            end
        end
    end

    // reg [31:0] addr_line_reg [0:3];
    // reg [9:0] tx_col_cnt [0:3];
    // reg [9:0] tx_row_cnt [0:3];
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(i = 0; i<4; i = i + 1) begin
                tx_col_cnt[i] <= 'b0;
                tx_row_cnt[i] <= 'b0;
                addr_line_reg[i] <= 'b0;
            end
        end
        else begin
            if(start_en) begin
                addr_line_reg[0] <= dst_addr;
                addr_line_reg[1] <= dst_addr + 32'd11520; // 3840 * 3
                addr_line_reg[2] <= dst_addr + 32'd23040; // 3840 * 3 * 2
                addr_line_reg[3] <= dst_addr + 32'd34560; // 3840 * 3 * 3
            end
            else begin
                case (nstate)
                    S_IDLE: begin
                        for(i = 0; i<4; i = i + 1) begin
                            tx_col_cnt[i] <= 'b0;
                            tx_row_cnt[i] <= 'b0;
                            addr_line_reg[i] <= 'b0;
                        end
                    end
                    S_TX_0: begin
                        if(handshake_w && axi_wcnt == 2'b10) begin
                            if(tx_col_cnt[0] < 10'd959) begin
                                tx_col_cnt[0] <= tx_col_cnt[0] + 10'd1;
                                addr_line_reg[0] <= addr_line_reg[0] + 32'd12;
                            end
                            else begin
                                tx_col_cnt[0] <= 'b0;
                                tx_row_cnt[0] <= tx_row_cnt[0] + 10'd1;
                                addr_line_reg[0] <= addr_line_reg[0] + 32'd12 + 32'd34560;
                            end
                        end
                    end
                    S_TX_1: begin
                        if(handshake_w && axi_wcnt == 2'b10) begin
                            if(tx_col_cnt[1] < 10'd959) begin
                                tx_col_cnt[1] <= tx_col_cnt[1] + 10'd1;
                                addr_line_reg[1] <= addr_line_reg[1] + 32'd12;
                            end
                            else begin
                                tx_col_cnt[1] <= 'b0;
                                tx_row_cnt[1] <= tx_row_cnt[1] + 10'd1;
                                addr_line_reg[1] <= addr_line_reg[1] + 32'd12 + 32'd34560;
                            end
                        end
                    end
                    S_TX_2: begin
                        if(handshake_w && axi_wcnt == 2'b10) begin
                            if(tx_col_cnt[2] < 10'd959) begin
                                tx_col_cnt[2] <= tx_col_cnt[2] + 10'd1;
                                addr_line_reg[2] <= addr_line_reg[2] + 32'd12;
                            end
                            else begin
                                tx_col_cnt[2] <= 'b0;
                                tx_row_cnt[2] <= tx_row_cnt[2] + 10'd1;
                                addr_line_reg[2] <= addr_line_reg[2] + 32'd12 + 32'd34560;
                            end
                        end
                    end
                    S_TX_3: begin
                        if(handshake_w && axi_wcnt == 2'b10) begin
                            if(tx_col_cnt[3] < 10'd959) begin
                                tx_col_cnt[3] <= tx_col_cnt[3] + 10'd1;
                                addr_line_reg[3] <= addr_line_reg[3] + 32'd12;
                            end
                            else begin
                                tx_col_cnt[3] <= 'b0;
                                tx_row_cnt[3] <= tx_row_cnt[3] + 10'd1;
                                addr_line_reg[3] <= addr_line_reg[3] + 32'd12 + 32'd34560;
                            end
                        end
                    end
                    default: begin
                        for(i = 0; i<4; i = i + 1) begin
                            tx_col_cnt[i] <= tx_col_cnt[i];
                            tx_row_cnt[i] <= tx_row_cnt[i];
                            addr_line_reg[i] <= addr_line_reg[i];
                        end
                    end
                endcase
            end
        end
    end

    // tx_strb
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            tx_strb <= 4'b0000;
        end
        else begin
            if(nstate == S_IDLE || nstate == S_STORE) begin
                if(tx_col_cnt[0] == 10'd0 && tx_row_cnt[0] == 10'd540) begin
                    tx_strb[0] <= 1'b0;
                end

                if(tx_col_cnt[0] == 10'd4) begin
                    tx_strb[1] <= 1'b1;
                end
                else if(tx_col_cnt[1] == 10'd0 && tx_row_cnt[1] == 10'd540) begin
                    tx_strb[1] <= 1'b0;
                end

                if(tx_col_cnt[1] == 10'd4) begin
                    tx_strb[2] <= 1'b1;
                end
                else if(tx_col_cnt[2] == 10'd0 && tx_row_cnt[2] == 10'd540) begin
                    tx_strb[2] <= 1'b0;
                end

                if(tx_col_cnt[2] == 10'd4) begin
                    tx_strb[3] <= 1'b1;
                end
                else if(tx_col_cnt[3] == 10'd0 && tx_row_cnt[3] == 10'd540) begin
                    tx_strb[3] <= 1'b0;
                end
                
            end
            else if(cstate == S_IDLE) begin
                tx_strb <= 4'b0001;
            end
        end
    end

    // part_tx_cnt
    // always@(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         part_tx_cnt <= 'b0;
    //     end
    //     else begin
    //         if(handshake_w) begin
    //             if(part_tx_cnt < tx_times - 3'b1) begin
    //                 part_tx_cnt <= part_tx_cnt + 3'b1;
    //             end
    //             else begin
    //                 part_tx_cnt <= 'b0;
    //             end
    //         end
    //     end
    // end

    // finish_irq_reg
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            irq_cnt <= 4'b0;
            finish_irq_reg <= 1'b0;
        end
        else begin
            if(irq_cnt == IRQ_CYCLES) begin
                irq_cnt <= 'b0;
            end
            else if(cstate == S_TX_3 && nstate == S_IDLE)begin
                irq_cnt <= 4'b1;
            end
            else if(|irq_cnt) begin
                irq_cnt <= irq_cnt + 4'b1;
            end

            if(cstate == S_TX_3 && nstate == S_IDLE) begin
                finish_irq_reg <= 1'b1;
            end
            else if(irq_cnt == IRQ_CYCLES) begin
                finish_irq_reg <= 1'b0;
            end
        end
    end

    // reg [31:0] addr_line_reg [0:3];
    // always@(posedge aclk or negedge aresetn) begin
    //     if(!aresetn) begin
    //         addr_line_reg[0] <= 'b0;
    //         addr_line_reg[1] <= 'b0;
    //         addr_line_reg[2] <= 'b0;
    //         addr_line_reg[3] <= 'b0;
    //     end
    //     else begin
    //         if(start) begin
    //             addr_line_reg[0] <= dst_addr;
    //             addr_line_reg[1] <= dst_addr + 32'd11520; // 3840 * 3
    //             addr_line_reg[2] <= dst_addr + 32'd23040; // 3840 * 3 * 2
    //             addr_line_reg[3] <= dst_addr + 32'd34560; // 3840 * 3 * 3
    //         end
    //         else begin
    //             case (cstate)
    //                 S_TX_0: begin
    //                     if(handshake_aw) begin
    //                         if(tx_col_cnt[0] < 10'd959) begin
    //                         end
    //                     end
    //                 end 
    //                 default: 
    //             endcase
    //         end
    //     end
    // end

    // reg tx_checked;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            tx_checked <= 1'b0;
        end
        else begin
            case (cstate)
                S_TX_0: begin
                    if(!tx_strb[0] && !tx_checked) begin
                        tx_checked <= 1'b1;
                    end
                    else if(handshake_w && axi_wcnt == 2'b10)begin
                        tx_checked <= 1'b1;
                    end
                    else if(nstate != cstate) begin
                        tx_checked <= 1'b0;
                    end
                end
                S_TX_1: begin
                    if(!tx_strb[1] && !tx_checked) begin
                        tx_checked <= 1'b1;
                    end
                    else if(handshake_w && axi_wcnt == 2'b10)begin
                        tx_checked <= 1'b1;
                    end
                    else if(nstate != cstate) begin
                        tx_checked <= 1'b0;
                    end
                end
                S_TX_2: begin
                    if(!tx_strb[2] && !tx_checked) begin
                        tx_checked <= 1'b1;
                    end
                    else if(handshake_w && axi_wcnt == 2'b10)begin
                        tx_checked <= 1'b1;
                    end
                    else if(nstate != cstate) begin
                        tx_checked <= 1'b0;
                    end
                end
                S_TX_3: begin
                    if(!tx_strb[3] && !tx_checked) begin
                        tx_checked <= 1'b1;
                    end
                    else if(handshake_w && axi_wcnt == 2'b10)begin
                        tx_checked <= 1'b1;
                    end
                    else if(nstate != cstate) begin
                        tx_checked <= 1'b0;
                    end
                end
                default: tx_checked <= 1'b0;
            endcase
        end
    end

    // reg [31:0] axi_awaddr;
    // reg axi_awvalid;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_awaddr <= 'b0;
            axi_awvalid <= 1'b0;
            aw_tx_finished <= 1'b0;
        end
        else begin
            if(!axi_awvalid && !axi_wvalid && !aw_tx_finished) begin
                case (nstate)
                    S_TX_0: if(tx_strb[0]) begin
                        axi_awaddr <= addr_line_reg[0];
                        axi_awvalid <= 1'b1;
                    end
                    S_TX_1: if(tx_strb[1]) begin
                        axi_awaddr <= addr_line_reg[1];
                        axi_awvalid <= 1'b1;
                    end
                    S_TX_2: if(tx_strb[2]) begin
                        axi_awaddr <= addr_line_reg[2];
                        axi_awvalid <= 1'b1;
                    end
                    S_TX_3: if(tx_strb[3]) begin
                        axi_awaddr <= addr_line_reg[3];
                        axi_awvalid <= 1'b1;
                    end
                    default: begin
                        axi_awaddr <= 'b0;
                        axi_awvalid <= 1'b0;
                    end
                endcase
            end
            else if(handshake_aw) begin
                axi_awvalid <= 1'b0;
            end

            if(handshake_aw) begin
                aw_tx_finished <= 1'b1;
            end
            else if(handshake_w && axi_wcnt == 2'b10) begin
                aw_tx_finished <= 1'b0;
            end
        end
    end

    // reg [127:0] axi_wdata;
    // reg axi_wvalid;
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_wdata <= 'd0;
            axi_wvalid <= 1'b0;
        end
        else begin
            case (cstate)
                S_TX_0: begin
                    if(!axi_wvalid && aw_tx_finished && tx_strb[0] && nstate != S_TX_1) begin
                        // axi_wdata <= {32'b0, data[tx_index[0]]};
                        case (axi_wcnt)
                            2'b00: axi_wdata <= data[tx_index[0]][31:0];
                            2'b01: axi_wdata <= data[tx_index[0]][63:32];
                            2'b10: axi_wdata <= data[tx_index[0]][95:64];
                            default: axi_wdata <= 'b0;
                        endcase
                        axi_wvalid <= 1'b1;
                    end
                    else if(handshake_w) begin
                        axi_wvalid <= 1'b0;
                    end
                end 
                S_TX_1: begin
                    if(!axi_wvalid && aw_tx_finished &&  tx_strb[1] && nstate != S_TX_2) begin
                        // axi_wdata <= {32'b0, data[tx_index[1]]};
                        case (axi_wcnt)
                            2'b00: axi_wdata <= data[tx_index[1]][31:0];
                            2'b01: axi_wdata <= data[tx_index[1]][63:32];
                            2'b10: axi_wdata <= data[tx_index[1]][95:64];
                            default: axi_wdata <= 'b0;
                        endcase
                        axi_wvalid <= 1'b1;
                    end
                    else if(handshake_w) begin
                        axi_wvalid <= 1'b0;
                    end
                end 
                S_TX_2: begin
                    if(!axi_wvalid && aw_tx_finished &&  tx_strb[2] && nstate != S_TX_3) begin
                        // axi_wdata <= {32'b0, data[tx_index[2]]};
                        case (axi_wcnt)
                            2'b00: axi_wdata <= data[tx_index[2]][31:0];
                            2'b01: axi_wdata <= data[tx_index[2]][63:32];
                            2'b10: axi_wdata <= data[tx_index[2]][95:64];
                            default: axi_wdata <= 'b0;
                        endcase
                        axi_wvalid <= 1'b1;
                    end
                    else if(handshake_w) begin
                        axi_wvalid <= 1'b0;
                    end
                end 
                S_TX_3: begin
                    if(!axi_wvalid && aw_tx_finished &&  tx_strb[3] && (nstate == cstate)) begin
                        // axi_wdata <= {32'b0, data[tx_index[3]]};
                        case (axi_wcnt)
                            2'b00: axi_wdata <= data[tx_index[3]][31:0];
                            2'b01: axi_wdata <= data[tx_index[3]][63:32];
                            2'b10: axi_wdata <= data[tx_index[3]][95:64];
                            default: axi_wdata <= 'b0;
                        endcase
                        axi_wvalid <= 1'b1;
                    end
                    else if(handshake_w) begin
                        axi_wvalid <= 1'b0;
                    end
                end 
                default: begin
                    axi_wdata <= 'b0;
                    axi_wvalid <= 1'b0;
                end
            endcase
        end
    end

    // reg axi_wlast
    always@(*) begin
        if(axi_wcnt == 2'b10 && axi_wvalid) begin
            axi_wlast = 1'b1;
        end
        else begin
            axi_wlast = 1'b0;
        end
    end

    // reg [1:0] axi_wcnt
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axi_wcnt <= 2'b0;
        end
        else begin
//            if(nstate == S_TX_0 && cstate == S_STORE) begin
//                axi_wcnt <= 2'b0;
//            end
            if((cstate == S_TX_0 || cstate == S_TX_1 || cstate == S_TX_2 || cstate == S_TX_3) && handshake_w) begin
                if(axi_wcnt < 2'b10) begin
                    axi_wcnt <= axi_wcnt + 2'b1;
                end
                else begin
                    axi_wcnt <= 2'b0;
                end
            end
        end
    end

    // reg busy_reg
    // always@(*) begin
        // assign busy = ((cstate != S_PASS && cstate != S_STORE) || nstate == S_TX_0)? 1'b1:1'b0;
        // if((cstate != S_PASS && cstate != S_STORE) || nstate == S_TX_0) begin
        //     busy_reg = 1'b1;
        // end
        // else begin
        //     busy_reg = 1'b0;
        // end
    //     if(cstate == S_PASS || cstate == S_STORE) begin
    //         if(nstate == S_TX_0) begin
    //             busy_reg = 1'b1;
    //         end
    //         else begin
    //             busy_reg = 1'b0;
    //         end
    //     end
    //     else begin
    //         busy_reg = 1'b1;
    //     end
    // end

    // reg start_q
    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            start_q <= 2'b0;
        end
        else begin
            start_q <= {start_q[0], start};
        end
    end

endmodule
