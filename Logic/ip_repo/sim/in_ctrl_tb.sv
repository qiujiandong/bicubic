`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/09 09:15:27
// Design Name: 
// Module Name: in_ctrl_tb
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


module in_ctrl_tb;

    import SimSrcGen::*;
    logic aclk;
    initial GenClk(aclk, 1, 10);
    logic aresetn;
    initial GenArst(aclk, aresetn, 2, 3);

    localparam BUF_MEM = 1;

    // in_ctrl Inputs
    reg   start;
    // reg   enable;
    reg   [31:0]  s_axis_tdata;
    // reg   [3:0]  s_axis_tstrb;
    // reg   [3:0]  s_axis_tkeep;
    // reg   s_axis_tlast;
    reg   s_axis_tvalid;

    reg [3:0] cnt;

    // in_ctrl Outputs
    wire  [16 * 24 - 1 : 0]  pixel;
    wire  pixel_valid;
    wire  s_axis_tready;

    reg [12*8-1:0] data;
    reg data_ready;
    reg [1:0] tx_cnt;

    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            s_axis_tdata <= {8'd1, 24'd0};
            s_axis_tvalid <= 'b0;
            data_ready <= 'b1;
            data <= {24'd3, 24'd2, 24'd1, 24'd0};
            tx_cnt <= 2'd01;
        end
        else begin
            if(data_ready && s_axis_tvalid && s_axis_tready) begin
                case (tx_cnt)
                    2'b00:  begin
                        s_axis_tdata <= data[31:0];
                        tx_cnt <= tx_cnt + 2'b01;
                    end
                    2'b01:  begin
                        s_axis_tdata <= data[63:32];
                        tx_cnt <= tx_cnt + 2'b01;
                    end
                    2'b10:  begin
                        s_axis_tdata <= data[95:64];
                        tx_cnt <= 2'b00;
                        data_ready <= 1'b0;
                    end
                endcase
                s_axis_tvalid <= 1'b0;
            end
            if(!data_ready && data[95:72] != 24'd518399) begin
                data[95:72] <= data[95:72] + 24'd4;
                data[71:48] <= data[71:48] + 24'd4;
                data[47:24] <= data[47:24] + 24'd4;
                data[23:0] <= data[23:0] + 24'd4;
                data_ready <= 1'b1;
            end
            if(data[95:72] == 32'd518400) begin
                s_axis_tvalid <= 1'b0;
            end
            else if(s_axis_tvalid == 1'b0) begin
                s_axis_tvalid <= {$random} % 2;
            end
        end
    end

    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cnt <= 'b0;
            start <= 1'b0;
        end
        else begin
            if(cnt < 4'd10) begin
                cnt <= cnt + 4'd1;
            end
            if(cnt == 4'd5) begin
                start <= 1'b1;
            end
            else begin
                start <= 1'b0;
            end
        end
    end

generate
    if (BUF_MEM) begin: buf_men
        in_ctrl_mem  u_in_ctrl (
            .aclk                    ( aclk            ),
            .aresetn                 ( aresetn         ),
            .start                   ( start           ),
            .enable                  ( 1'b1          ),
            .s_axis_tdata            ( s_axis_tdata    ),
            .s_axis_tstrb            ( 4'hF    ),
            .s_axis_tkeep            ( 4'hF    ),
            .s_axis_tlast            ( 1'b0    ),
            .s_axis_tvalid           ( s_axis_tvalid   ),

            .pixel                   ( pixel           ),
            .pixel_valid             ( pixel_valid     ),
            .s_axis_tready           ( s_axis_tready   )
        );
    end
    else begin: buf_lut
        in_ctrl  u_in_ctrl (
            .aclk                    ( aclk            ),
            .aresetn                 ( aresetn         ),
            .start                   ( start           ),
            .enable                  ( 1'b1          ),
            .s_axis_tdata            ( s_axis_tdata    ),
            .s_axis_tstrb            ( 4'hF    ),
            .s_axis_tkeep            ( 4'hF    ),
            .s_axis_tlast            ( 1'b0    ),
            .s_axis_tvalid           ( s_axis_tvalid   ),

            .pixel                   ( pixel           ),
            .pixel_valid             ( pixel_valid     ),
            .s_axis_tready           ( s_axis_tready   )
        );
    end
endgenerate
    

endmodule
