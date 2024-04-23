`timescale 1ns / 1ps
`include "common.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/07 08:51:49
// Design Name: 
// Module Name: mul_tb
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


module mul_tb;

    import SimSrcGen::*;
    logic aclk;
    initial GenClk(aclk, 1, 6.4);
    logic aresetn;
    initial GenArst(aclk, aresetn, 2, 3);

    reg   [17:0]  A;
    reg   [7:0]  B;

    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            A <= 'b0;
            B <= 'b0;
        end
        else begin
            A <= A + 'b1;
            B <= B + 'b1;
        end
    end

    // mul_test Outputs
    wire  [25:0]  C;

    mult_gen_00  u_mul_test (

        .A                       ( B         ),
        .P                       ( C         )
    );
endmodule
