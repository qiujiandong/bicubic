`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/10 16:20:40
// Design Name: 
// Module Name: bicubic_tb
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


module bicubic_tb;

import SimSrcGen::*;
logic aclk;
initial GenClk(aclk, 1, 10);
logic aresetn;
initial GenArst(aclk, aresetn, 2, 3);

// bicubic Parameters
parameter IRQ_CYCLES     = 3 ;
parameter FRACTION_BITS  = 16;
parameter AXIL_DW        = 32;
parameter AXIL_AW        = 4 ;

// bicubic Inputs
// reg   aclk;
// reg   aresetn;
// reg   start;
// wire   [31:0]  dst_addr;
// assign dst_addr = 32'hE0000000;

reg   m_axi_awready;
reg   m_axi_wready;

wire   [3:0]  s_axis_tstrb;
wire   [3:0]  s_axis_tkeep;
wire   s_axis_tlast;
assign s_axis_tstrb = 8'hFF;
assign s_axis_tkeep = 8'hFF;
assign s_axis_tlast = 1'b0;

reg   [31:0]  s_axis_tdata;
reg   s_axis_tvalid;

// bicubic Outputs
wire  finish_irq;
wire  [31 : 0]  m_axi_awaddr;
wire  [7 : 0]  m_axi_awlen;
wire  m_axi_awvalid;
wire  [31 : 0]  m_axi_wdata;
wire  [3 : 0]  m_axi_wstrb;
wire  m_axi_wlast;
wire  m_axi_wvalid;
wire  s_axis_tready;

reg [12*8-1:0] data;
reg data_ready;
reg [1:0] tx_cnt;
reg [31:0] cnt;

// reg   m_axi_awready;
// reg   m_axi_wready;
always_ff@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        m_axi_awready <= 1'b0;
        m_axi_wready <= 1'b0;
    end
    else begin
        m_axi_awready <= {$random} % 2;
        m_axi_wready <= {$random} % 2;
    end
end

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
        end

        if(!data_ready && data[95:72] != 24'd518399) begin
            data[95:72] <= data[95:72] + 24'd4;
            data[71:48] <= data[71:48] + 24'd4;
            data[47:24] <= data[47:24] + 24'd4;
            data[23:0] <= data[23:0] + 24'd4;
            data_ready <= 1'b1;
        end
        
        if(data[95:72] == 32'd518399) begin
            s_axis_tvalid <= 1'b0;
        end
        else if(s_axis_tvalid == 1'b0) begin
            s_axis_tvalid <= {$random} % 2;
        end
    end
end

always_ff @( posedge aclk or negedge aresetn ) begin
    if(!aresetn) begin
        cnt <= 'b0;
    end
    else begin
        cnt <= cnt + 'b1;
    end
end

// always_ff@(posedge aclk or negedge aresetn) begin
//     if(!aresetn) begin
//         cnt <= 'b0;
//         start <= 1'b0;
//     end
//     else begin
//         if(cnt < 4'd10) begin
//             cnt <= cnt + 4'd1;
//         end
//         if(cnt == 4'd5) begin
//             start <= #2 1'b1;
//         end
//         // else if(cnt > 4'd6) begin
//         else begin
//             start <= #2 1'b0;
//         end
//     end
// end

// axil

    // signals output from ip
    wire  s_axil_awready;
    wire  s_axil_wready;
    wire  [1:0]  s_axil_bresp;
    wire  s_axil_bvalid;
    wire  s_axil_arready;
    wire  [AXIL_DW-1:0]  s_axil_rdata;
    wire  [1:0]  s_axil_rresp;
    wire  s_axil_rvalid;

    // assignment
    logic [2:0]  s_axil_awprot;
    logic [3:0]  s_axil_wstrb;
    logic s_axil_bready;
    logic [AXIL_AW-1:0]  s_axil_araddr;
    logic [2:0]  s_axil_arprot;
    logic s_axil_arvalid;
    logic s_axil_rready;

    assign s_axil_awprot = 'b0;
    assign s_axil_wstrb = 8'hFF;
    assign s_axil_bready = 1'b1;
    assign s_axil_araddr = 'b0;
    assign s_axil_arprot = 'b0;
    assign s_axil_arvalid = 'b0;
    assign s_axil_rready = 1'b1;

    // logic
    logic handshake_aw;
    logic handshake_w;

    logic [AXIL_AW-1:0]  s_axil_awaddr;
    logic s_axil_awvalid;
    logic [AXIL_DW-1:0]  s_axil_wdata;
    logic s_axil_wvalid;

    assign handshake_aw = s_axil_awvalid && s_axil_awready;
    assign handshake_w = s_axil_wvalid && s_axil_wready;

    // logic
    always_ff @( posedge aclk or negedge aresetn ) begin
        if(!aresetn) begin
            s_axil_awvalid <= 1'b0;
            s_axil_wvalid <= 1'b0;
            s_axil_wdata <= 'b0;
            s_axil_awaddr = 'b0;
        end
        else begin
            if(cnt == 20) begin // : addr_reset
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'd1;
                s_axil_awaddr <= 4'h0;
            end
            if(cnt == 10) begin // : setup address
                s_axil_awvalid <= 1'b1;
                s_axil_wvalid <= 1'b1;
                s_axil_wdata <= 32'hE0000000;
                s_axil_awaddr <= 4'h4;
            end

            if(handshake_w) begin
                s_axil_wvalid <= 1'b0;
            end
            if(handshake_aw) begin
                s_axil_awvalid <= 1'b0;
            end
        end
    end

// end of axil

// bicubic u_bicubic (
//     .aclk                    ( aclk                  ),
//     .aresetn                 ( aresetn               ),
//     .start                   ( start                 ),
//     .dst_addr                ( dst_addr              ),
//     .m_axi_awready           ( m_axi_awready         ),
//     .m_axi_wready            ( m_axi_wready          ),
//     .s_axis_tdata            ( s_axis_tdata          ),
//     .s_axis_tstrb            ( s_axis_tstrb          ),
//     .s_axis_tkeep            ( s_axis_tkeep          ),
//     .s_axis_tlast            ( s_axis_tlast          ),
//     .s_axis_tvalid           ( s_axis_tvalid         ),


//     .finish_irq              ( finish_irq            ),
//     .m_axi_awaddr            ( m_axi_awaddr          ),
//     .m_axi_awlen             ( m_axi_awlen           ),
//     .m_axi_awvalid           ( m_axi_awvalid         ),
//     .m_axi_wdata             ( m_axi_wdata           ),
//     .m_axi_wstrb             ( m_axi_wstrb           ),
//     .m_axi_wlast             ( m_axi_wlast           ),
//     .m_axi_wvalid            ( m_axi_wvalid          ),
//     .s_axis_tready           ( s_axis_tready         )
// );

bicubic u_bicubic (
    .aclk                    ( aclk                  ),
    .aresetn                 ( aresetn               ),
    .m_axi_rresp             ( m_axi_rresp           ),
    .m_axi_bresp             ( m_axi_bresp           ),
    .m_axi_bvalid            ( m_axi_bvalid          ),
    .m_axi_awready           ( m_axi_awready         ),
    .m_axi_wready            ( m_axi_wready          ),
    .s_axis_tdata            ( s_axis_tdata          ),
    .s_axis_tstrb            ( s_axis_tstrb          ),
    .s_axis_tkeep            ( s_axis_tkeep          ),
    .s_axis_tlast            ( s_axis_tlast          ),
    .s_axis_tvalid           ( s_axis_tvalid         ),
    .s_axil_awaddr           ( s_axil_awaddr         ),
    .s_axil_awprot           ( s_axil_awprot         ),
    .s_axil_awvalid          ( s_axil_awvalid        ),
    .s_axil_wdata            ( s_axil_wdata          ),
    .s_axil_wstrb            ( s_axil_wstrb          ),
    .s_axil_wvalid           ( s_axil_wvalid         ),
    .s_axil_bready           ( s_axil_bready         ),
    .s_axil_araddr           ( s_axil_araddr         ),
    .s_axil_arprot           ( s_axil_arprot         ),
    .s_axil_arvalid          ( s_axil_arvalid        ),
    .s_axil_rready           ( s_axil_rready         ),

    .finish_irq              ( finish_irq            ),
    .m_axi_awsize            ( m_axi_awsize          ),
    .m_axi_awburst           ( m_axi_awburst         ),
    .m_axi_awlock            ( m_axi_awlock          ),
    .m_axi_awcache           ( m_axi_awcache         ),
    .m_axi_awprot            ( m_axi_awprot          ),
    .m_axi_awqos             ( m_axi_awqos           ),
    .m_axi_arsize            ( m_axi_arsize          ),
    .m_axi_arburst           ( m_axi_arburst         ),
    .m_axi_arlock            ( m_axi_arlock          ),
    .m_axi_arcache           ( m_axi_arcache         ),
    .m_axi_arprot            ( m_axi_arprot          ),
    .m_axi_arqos             ( m_axi_arqos           ),
    .m_axi_bready            ( m_axi_bready          ),
    .m_axi_awaddr            ( m_axi_awaddr          ),
    .m_axi_awlen             ( m_axi_awlen           ),
    .m_axi_awvalid           ( m_axi_awvalid         ),
    .m_axi_wdata             ( m_axi_wdata           ),
    .m_axi_wstrb             ( m_axi_wstrb           ),
    .m_axi_wlast             ( m_axi_wlast           ),
    .m_axi_wvalid            ( m_axi_wvalid          ),
    .s_axis_tready           ( s_axis_tready         ),
    .s_axil_awready          ( s_axil_awready        ),
    .s_axil_wready           ( s_axil_wready         ),
    .s_axil_bresp            ( s_axil_bresp          ),
    .s_axil_bvalid           ( s_axil_bvalid         ),
    .s_axil_arready          ( s_axil_arready        ),
    .s_axil_rdata            ( s_axil_rdata          ),
    .s_axil_rresp            ( s_axil_rresp          ),
    .s_axil_rvalid           ( s_axil_rvalid         )
);
endmodule
