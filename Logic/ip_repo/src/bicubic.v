`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/06 10:39:52
// Design Name: 
// Module Name: bicubic
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


module bicubic #(
    parameter IRQ_CYCLES = 3,
    parameter FRACTION_BITS = 16,
    localparam AXIL_DW = 32,
    localparam AXIL_AW = 4
)(

    input aclk,
    input aresetn,

    (* mark_debug = "true" *) output finish_irq,
    // input start,
    // input wire [31:0] dst_addr,

// axi master interface
    // input  m_axi_init_axi_txn,
    // output m_axi_txn_done,
    // output m_axi_error,
    // input m_axi_aclk,
    // input m_axi_aresetn,
    // output [C_m_axi_ID_WIDTH-1 : 0] m_axi_awid,
    // output [C_m_axi_AWUSER_WIDTH-1 : 0] m_axi_awuser,
    // output [C_m_axi_WUSER_WIDTH-1 : 0] m_axi_wuser,
    // input [C_m_axi_ID_WIDTH-1 : 0] m_axi_bid,
    // input [C_m_axi_BUSER_WIDTH-1 : 0] m_axi_buser,
    // output [C_m_axi_ID_WIDTH-1 : 0] m_axi_arid,
    // output [C_m_axi_ARUSER_WIDTH-1 : 0] m_axi_aruser,
    // input [C_m_axi_ID_WIDTH-1 : 0] m_axi_rid,
    // input [C_m_axi_RUSER_WIDTH-1 : 0] m_axi_ruser,

    output [2 : 0] m_axi_awsize,
    output [1 : 0] m_axi_awburst,
    output m_axi_awlock,
    output [3 : 0] m_axi_awcache,
    output [2 : 0] m_axi_awprot,
    output [3 : 0] m_axi_awqos,
    
    output [2 : 0] m_axi_arsize,
    output [1 : 0] m_axi_arburst,
    output m_axi_arlock,
    output [3 : 0] m_axi_arcache,
    output [2 : 0] m_axi_arprot,
    output [3 : 0] m_axi_arqos,
    output m_axi_bready,
    input [1 : 0] m_axi_rresp,
    input [1 : 0] m_axi_bresp,
    input m_axi_bvalid,
    // aw
    (* mark_debug = "true" *) output [31 : 0] m_axi_awaddr,
    (* mark_debug = "true" *) output [7 : 0] m_axi_awlen,
    (* mark_debug = "true" *) output m_axi_awvalid,
    (* mark_debug = "true" *) input m_axi_awready,
    // w
    (* mark_debug = "true" *) output [31 : 0] m_axi_wdata,
    output [3 : 0] m_axi_wstrb,
    (* mark_debug = "true" *) output m_axi_wlast,
    (* mark_debug = "true" *) output m_axi_wvalid,
    (* mark_debug = "true" *) input m_axi_wready,
    // ar
    // output [31 : 0] m_axi_araddr,
    // output [7 : 0] m_axi_arlen,
    // output m_axi_arvalid,
    // input m_axi_arready,
    // // r
    // input [31 : 0] m_axi_rdata,
    // input m_axi_rlast,
    // input m_axi_rvalid,
    // output m_axi_rready,
// end of axi master interface
   
// s_axis interface
    // (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TID" *)
    // Uncomment the following to set interface specific parameter on the bus interface.
    //  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN <value>,PHASE <value>,FREQ_HZ <value>,LAYERED_METADATA <value>,HAS_TLAST <value>,HAS_TKEEP <value>,HAS_TSTRB <value>,HAS_TREADY <value>,TUSER_WIDTH <value>,TID_WIDTH <value>,TDEST_WIDTH <value>,TDATA_NUM_BYTES <value>" *)
    // input [<left_bound>:0] <s_tid>, // Transfer ID tag (optional)
    // (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TDEST" *)
    // input [<left_bound>:0] <s_tdest>, // Transfer Destination (optional)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TDATA" *)
    (* mark_debug = "true" *) input [31:0] s_axis_tdata, // Transfer Data (optional)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TSTRB" *)
    input [3:0] s_axis_tstrb, // Transfer Data Byte Strobes (optional)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TKEEP" *)
    input [3:0] s_axis_tkeep, // Transfer Null Byte Indicators (optional)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TLAST" *)
    input s_axis_tlast, // Packet Boundary Indicator (optional)
    // (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TUSER" *)
    // input [<left_bound>:0] <s_tuser>, // Transfer user sideband (optional)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TVALID" *)
    (* mark_debug = "true" *) input s_axis_tvalid, // Transfer valid (required)
//    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 <interface_name> TREADY" *)
    (* mark_debug = "true" *) output s_axis_tready, // Transfer ready (optional)
//  end of s_axis interface

// AXI4-Lite interface
    input [AXIL_AW-1:0] s_axil_awaddr,
    input [2:0] s_axil_awprot,
    input s_axil_awvalid,
    output s_axil_awready,

    input [AXIL_DW-1:0] s_axil_wdata,
    input [3:0] s_axil_wstrb,
    input s_axil_wvalid,
    output s_axil_wready,

    output [1:0] s_axil_bresp,
    output s_axil_bvalid,
    input s_axil_bready,

    input [AXIL_AW-1:0] s_axil_araddr,
    input [2:0] s_axil_arprot,
    input s_axil_arvalid,
    output s_axil_arready,

    output [AXIL_DW-1:0] s_axil_rdata,
    output [1:0] s_axil_rresp,
    output s_axil_rvalid,
    input s_axil_rready
// end of AXI4-Lite interface

    );

// module interconnections
    (* mark_debug = "true" *) wire  pixel_valid;
    wire  [16 * 24 - 1 : 0]  pixel;
    (* mark_debug = "true" *) wire result_valid;
    wire  [16 * 24 - 1 : 0]  result;
    (* mark_debug = "true" *) wire busy;
// end of module interconnections

// axil signals define 
    integer i;

    reg axil_awready;
    reg axil_wready;
    reg [1:0] axil_bresp;
    reg axil_bvalid;

    reg axil_arready;
    reg axil_rvalid;
    reg [1:0] axil_rresp;
    reg [31:0] axil_rdata;
    reg axil_rlast;

    reg allow_aw;

    wire handshake_aw;
    wire handshake_w;
    wire handshake_b;
    wire handshake_ar;
    wire handshake_r;

    wire write_en;

    (* mark_debug = "true" *) reg [AXIL_DW-1:0] START_REG;
    (* mark_debug = "true" *) reg [AXIL_DW-1:0] DSTADDR_REG;

    wire start;
    wire [31:0] dst_addr;

    assign start = START_REG[0];
    assign dst_addr = DSTADDR_REG;
// end of axil signals define 

// axi master
    assign m_axi_awsize = 3'b010; // awsize = 4 bytes
    assign m_axi_awburst = 2'b01; // INCR
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0010; // Normal Non-cacheable Non-bufferable
    assign m_axi_awprot = 3'b000;
    assign m_axi_awqos = 4'b0;
    // assign m_axi_wstrb = 8'hFF;
    assign m_axi_arsize = 3'b010;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0010; // Normal Non-cacheable
    assign m_axi_arprot = 3'b000;
    assign m_axi_arqos = 4'b0;
    assign m_axi_bready = 1'b1;
// end of axi master

// axi-lite signals
    assign s_axil_awready = axil_awready;
    assign s_axil_wready = axil_wready;
    assign s_axil_bresp = axil_bresp;
    assign s_axil_bvalid = axil_bvalid;

    assign s_axil_arready = axil_arready;
    assign s_axil_rresp = axil_rresp;
    assign s_axil_rvalid = axil_rvalid;
    assign s_axil_rdata = axil_rdata;
    assign s_axil_rlast = axil_rlast; 

    assign handshake_aw = s_axil_awvalid & s_axil_awready;
    assign handshake_w = s_axil_wvalid & s_axil_wready;
    assign handshake_b = s_axil_bvalid & s_axil_bready;
    assign handshake_ar = s_axil_arvalid & s_axil_arready;
    assign handshake_r = s_axil_rvalid & s_axil_rready;
    // allow_aw
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            allow_aw <= 1'b1;
        end
        else begin
            if(s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                allow_aw <= 1'b0;
            end
            else if(handshake_b) begin
                allow_aw <= 1'b1;
            end
        end
    end

    // awready
    always @(posedge aclk or negedge aresetn) begin 
        if (!aresetn) begin 
            axil_awready <= 1'b0;
        end 
        else begin
            if(!axil_awready && s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                axil_awready <= 1'b1;
            end
            else begin // make awready stay only one cycle
                axil_awready <= 1'b0;
            end
        end
    end

    // wready
    always @(posedge aclk or negedge aresetn) begin 
        if(!aresetn) begin 
            axil_wready <= 1'b0;
        end
        else begin 
            if(!axil_wready && s_axil_awvalid && s_axil_wvalid && allow_aw) begin 
                axil_wready <= 1'b1;
            end
            else begin 
                axil_wready <= 1'b0;
            end
        end
    end

    // write regs
    assign write_en = handshake_aw & handshake_w;

    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            START_REG <= 'b0;
            DSTADDR_REG <= 'b0;
        end
        else begin
            if(write_en) begin 
                case (s_axil_awaddr[AXIL_AW-1:2])
                    2'b00:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) START_REG[(i*8)+:8] <= s_axil_wdata[(i*8)+:8];
                    2'b01:
                        for(i = 0; i < 4; i = i + 1)
                            if(s_axil_wstrb[i]) DSTADDR_REG[(i*8)+:8] <= s_axil_wdata[(i*8)+:8];
                    default: begin
                        START_REG <= START_REG;
                        DSTADDR_REG <= DSTADDR_REG;
                    end 
                endcase
            end
            else if(finish_irq) begin
                START_REG <= 'b0;
            end
        end
    end
    // s_axil_bresp
    // s_axil_bvalid
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            axil_bresp <= 2'b0;
            axil_bvalid <= 1'b0;
        end
        else begin
            if(!axil_bvalid && write_en) begin
                axil_bvalid <= 1'b1;
            end
            else if(handshake_b) begin
                axil_bvalid <= 1'b0;
            end
        end
    end

    // s_axil_arready
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            axil_arready <= 1'b0;
        end
        else begin 
            if(!axil_arready && s_axil_arvalid) begin 
                axil_arready <= 1'b1;
            end
            else begin
                axil_arready <= 1'b0;
            end
        end
    end

    // rvalid rresp rdata
    always @(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin 
            axil_rvalid <= 1'b0;
            axil_rresp <= 2'b0;
            axil_rdata <= 'b0;
        end
        else begin 
            if(!axil_rvalid && handshake_ar) begin
                axil_rvalid <= 1'b1;
                case (s_axil_araddr[AXIL_AW-1:2])
                    2'b00: axil_rdata <= START_REG; 
                    2'b01: axil_rdata <= DSTADDR_REG;
                    default: axil_rdata <= 'b0;
                endcase
            end
            else if(handshake_r) begin
                axil_rvalid <= 1'b0;
                axil_rdata <= 'b0;
            end
        end
    end
    
// end of axi-lite signals

// module instance
    in_ctrl_mem  u_in_ctrl (
        .aclk ( aclk ),
        .aresetn ( aresetn ),
        .start ( start ),
        .s_axis_tdata ( s_axis_tdata ),
        .s_axis_tstrb ( s_axis_tstrb ),
        .s_axis_tkeep ( s_axis_tkeep ),
        .s_axis_tlast ( s_axis_tlast ),
        .s_axis_tvalid ( s_axis_tvalid ),
        .enable (~busy),

        .pixel ( pixel ),
        .pixel_valid ( pixel_valid ),
        .s_axis_tready ( s_axis_tready )
    );

    systolic_array #(
        .FRACTION_BITS ( FRACTION_BITS ))
    u_systolic_array (
        .aclk ( aclk ),
        .aresetn ( aresetn ),
        .pixel ( pixel ),
        .pixel_valid ( pixel_valid ),

        .result ( result ),
        .result_valid(result_valid)
    );

    out_ctrl #(
        .IRQ_CYCLES(IRQ_CYCLES))
    u_out_ctrl(
        .aclk ( aclk ),
        .aresetn ( aresetn ),
        .start ( start ),
        .dst_addr ( dst_addr ),
        .result ( result ),
        .result_valid ( result_valid ),
        .m_axi_awready ( m_axi_awready ),
        .m_axi_wready ( m_axi_wready ),

        .busy(busy),
        .finish_irq(finish_irq),
        .m_axi_awaddr ( m_axi_awaddr ),
        .m_axi_awvalid ( m_axi_awvalid ),
        .m_axi_awlen ( m_axi_awlen ),
        .m_axi_wdata ( m_axi_wdata ),
        .m_axi_wstrb ( m_axi_wstrb ),
        .m_axi_wlast ( m_axi_wlast ),
        .m_axi_wvalid ( m_axi_wvalid )
    );

// end of module instance

endmodule
