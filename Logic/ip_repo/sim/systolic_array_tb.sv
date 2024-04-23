`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/08 08:20:56
// Design Name: 
// Module Name: systolic_array_tb
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


module systolic_array_tb;

    import SimSrcGen::*;
    logic aclk;
    initial GenClk(aclk, 1, 6.4);
    logic aresetn;
    initial GenArst(aclk, aresetn, 2, 3);

    // systolic_array Inputs
    reg   [16 * 24 - 1 : 0]  pixel;
    reg   pixel_valid;

    // systolic_array Outputs
    wire  [16 * 24 - 1 : 0]  result;

    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            pixel_valid <= 1'b0;
        end
        else begin
            pixel_valid <= 1'b1;
        end
    end

    // integer i;
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            pixel <= 'b0;
        end
        else begin
            pixel[23:0] <= 24'h010101;
            for(int i = 0; i<15; i = i + 1) begin
                if(pixel[i*24 +:24]) begin
                    pixel[(i+1)*24 +:24] <= 24'h010101;
                end
            end
        end
    end

    systolic_array #(
        .FRACTION_BITS ( 16 ))
    u_systolic_array (
        .aclk                    ( aclk          ),
        .aresetn                 ( aresetn       ),
        .pixel                   ( pixel         ),
        .pixel_valid             ( pixel_valid   ),

        .result                  ( result        )
    );

endmodule
