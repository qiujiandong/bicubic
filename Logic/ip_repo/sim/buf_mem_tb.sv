`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/12 15:28:10
// Design Name: 
// Module Name: buf_mem_tb
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


module buf_mem_tb;

    import SimSrcGen::*;
    logic aclk;
    initial GenClk(aclk, 1, 10);
    logic aresetn;
    initial GenArst(aclk, aresetn, 2, 3);

    reg wea;
    wire [9:0] addra;
    wire [23:0] dina;
    reg rstb;
    reg enb;
    wire [9:0] addrb;
    wire [23:0] doutb;
    wire rsta_busy;
    wire rstb_busy;

    reg [9:0] cnt;

    // assign rstb = 1'b0;
    assign addra = 'b1;
    assign dina = 24'h123456;
//    assign enb = 1'b1;
    assign addrb = 'b1;

    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            cnt <= 'b0;
            wea <= 1'b0;
            rstb <= 1'b0;
            enb <= 1'b0;
        end
        else begin
            if(cnt < 10'd100) begin
                cnt <= cnt + 10'd1;
            end

            if(cnt == 10'd20) begin
                wea <= 1'b1;
            end
            else begin
                wea <= 1'b0;
            end

            if(cnt == 10'd30) begin
                enb <= #1 1'b1;
            end
            else begin
                enb <= #1 1'b0;
            end

            if(cnt < 4'd10) begin
                rstb <= 1'b1;
            end
            else begin
                rstb <= 1'b0;
            end
        end
    end


buf_mem inst_buf_mem (
  .clka(aclk),            // input wire clka
  .wea(wea),              // input wire [0 : 0] wea
  .addra(addra),          // input wire [9 : 0] addra
  .dina(dina),            // input wire [23 : 0] dina

  .clkb(aclk),            // input wire clkb
  .rstb(rstb),            // input wire rstb
  .enb(enb),              // input wire enb
  .addrb(addrb),          // input wire [9 : 0] addrb
  .doutb(doutb),          // output wire [23 : 0] doutb
  .rsta_busy(rsta_busy),  // output wire rsta_busy
  .rstb_busy(rstb_busy)  // output wire rstb_busy
);
endmodule
