`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/08/06 20:25:14
// Design Name:
// Module Name: systolic_line
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


module systolic_line#(
    parameter [79:0] MULT_TYPE = 0,
    parameter FRACTION_BITS = 16
)(  input aclk,
    input aresetn,
    input [16 * 24 - 1:0] pixel,
    input pixel_valid,
    output [23:0] result);
    
    reg [7:0] result_blue;
    reg [7:0] result_green;
    reg [7:0] result_red;
    
    assign result = {result_red, result_green, result_blue};
    
    wire signed [(FRACTION_BITS + 10) - 1:0] sum_blue;
    wire signed [(FRACTION_BITS + 10) - 1:0] sum_green;
    wire signed [(FRACTION_BITS + 10) - 1:0] sum_red;
    
    wire [16 * (FRACTION_BITS + 10) - 1:0] inter_blue;
    wire [16 * (FRACTION_BITS + 10) - 1:0] inter_green;
    wire [16 * (FRACTION_BITS + 10) - 1:0] inter_red;
    
    assign inter_blue[FRACTION_BITS + 10 - 1:0]  = 'b0; // the left input for every line is 0
    assign inter_green[FRACTION_BITS + 10 - 1:0] = 'b0;
    assign inter_red[FRACTION_BITS + 10 - 1:0]   = 'b0;
    
    always@(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            result_blue  <= 'b0;
            result_green <= 'b0;
            result_red   <= 'b0;
        end
        else begin
            // // blue channel overflow
            // if (sum_blue[FRACTION_BITS + 8]) begin
            //     result_blue <= 8'hFF;
            // end
            // // blue channel underflow
            // else if (sum_blue[(FRACTION_BITS + 10) - 1]) begin
            //     result_blue <= 8'd0;
            // end
            // // normal condition
            // else begin
            //     result_blue <= sum_blue >> FRACTION_BITS;
            // end
            // blue channel underflow
            if (sum_blue[(FRACTION_BITS + 10) - 1]) begin
                result_blue <= 8'd0;
            end
            // blue channel overflow
            else if (sum_blue[FRACTION_BITS + 8]) begin
                result_blue <= 8'hFF;
            end
            // normal condition
            else begin
                result_blue <= (sum_blue + (1 << (FRACTION_BITS  - 1))) >> FRACTION_BITS;
            end
    
            // green channel underflow
            if (sum_green[(FRACTION_BITS + 10) - 1]) begin
                result_green <= 8'd0;
            end
            // green channel overflow
            else if (sum_green[FRACTION_BITS + 8]) begin
                result_green <= 8'hFF;
            end
            // normal condition
            else begin
                result_green <= (sum_green + (1 << (FRACTION_BITS  - 1))) >> FRACTION_BITS;
            end
            
            // red channel underflow
            if (sum_red[(FRACTION_BITS + 10) - 1]) begin
                result_red <= 8'd0;
            end
            // red channel overflow
            else if (sum_red[FRACTION_BITS + 8]) begin
                result_red <= 8'hFF;
            end
            // normal condition
            else begin
                result_red <= (sum_red + (1 << (FRACTION_BITS  - 1))) >> FRACTION_BITS;
            end
        end
    end
    
    genvar i;
    
    // blue channel
    generate
    for(i = 0; i<15; i = i + 1) begin: cha_blue
        systolic_unit #(
            .MULT_TYPE (MULT_TYPE[(16-i)*5-1: (15-i)*5]),
            .FRACTION_BITS (FRACTION_BITS))
        inst_blue (
            .aclk (aclk),
            .aresetn (aresetn),
            .pre_sum (inter_blue[(i+1) * (FRACTION_BITS + 10) - 1 : i * (FRACTION_BITS + 10)]),
            .channel (pixel[(i+1) * 24 - 1 - 16: i*24]),
            .channel_valid (pixel_valid),
            
            .sum (inter_blue[(i+2) * (FRACTION_BITS + 10) - 1 : (i+1) * (FRACTION_BITS + 10)])
        );
    end
    endgenerate
    
    systolic_unit #(
        .MULT_TYPE (MULT_TYPE[4:0]),
        .FRACTION_BITS (FRACTION_BITS))
    inst_blue (
        .aclk (aclk),
        .aresetn (aresetn),
        .pre_sum (inter_blue[16 * (FRACTION_BITS + 10) - 1 : 15 * (FRACTION_BITS + 10)]),
        .channel (pixel[16 * 24 - 1 - 16: 15 * 24]),
        .channel_valid (pixel_valid),
        
        .sum (sum_blue)
    );
    // end of blue channel
    
    // green channel
    generate
    for(i = 0; i<15; i = i + 1) begin: cha_green
        systolic_unit #(
            .MULT_TYPE (MULT_TYPE[(16-i)*5-1: (15-i)*5]),
            .FRACTION_BITS (FRACTION_BITS))
        inst_green (
            .aclk (aclk),
            .aresetn (aresetn),
            .pre_sum (inter_green[(i+1) * (FRACTION_BITS + 10) - 1 : i * (FRACTION_BITS + 10)]),
            .channel (pixel[(i+1) * 24 - 1 - 8: i*24 + 8]),
            .channel_valid (pixel_valid),
            
            .sum (inter_green[(i+2) * (FRACTION_BITS + 10) - 1 : (i+1) * (FRACTION_BITS + 10)])
        );
    end
    endgenerate
    
    systolic_unit #(
        .MULT_TYPE (MULT_TYPE[4:0]),
        .FRACTION_BITS (FRACTION_BITS))
    inst_green (
        .aclk (aclk),
        .aresetn (aresetn),
        .pre_sum (inter_green[16 * (FRACTION_BITS + 10) - 1 : 15 * (FRACTION_BITS + 10)]),
        .channel (pixel[16 * 24 - 1 - 8: 15 * 24 + 8]),
        .channel_valid (pixel_valid),
        
        .sum (sum_green)
    );
    // end of green channel
    
    // red channel
    generate
    for(i = 0; i<15; i = i + 1) begin: cha_red
        systolic_unit #(
            .MULT_TYPE (MULT_TYPE[(16-i)*5-1: (15-i)*5]),
            .FRACTION_BITS (FRACTION_BITS))
        inst_red (
            .aclk (aclk),
            .aresetn (aresetn),
            .pre_sum (inter_red[(i+1) * (FRACTION_BITS + 10) - 1 : i * (FRACTION_BITS + 10)]),
            .channel (pixel[(i+1) * 24 - 1: i*24 + 16]),
            .channel_valid (pixel_valid),
            
            .sum (inter_red[(i+2) * (FRACTION_BITS + 10) - 1 : (i+1) * (FRACTION_BITS + 10)])
            );
    end
    endgenerate
    
    systolic_unit #(
        .MULT_TYPE (MULT_TYPE[4:0]),
        .FRACTION_BITS (FRACTION_BITS))
    inst_red (
        .aclk (aclk),
        .aresetn (aresetn),
        .pre_sum (inter_red[16 * (FRACTION_BITS + 10) - 1 : 15 * (FRACTION_BITS + 10)]),
        .channel (pixel[16 * 24 - 1: 15 * 24 + 16]),
        .channel_valid (pixel_valid),
        
        .sum (sum_red)
    );
    // end of red channel
    
endmodule
