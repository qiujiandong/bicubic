`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/08/06 10:39:52
// Design Name:
// Module Name: systolic_array
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


module systolic_array#(
    parameter FRACTION_BITS = 16
    )(
        input aclk,
        input aresetn,

        input [16 * 24 - 1 : 0] pixel,
        input pixel_valid,             // when pixel channel has been read and not shifted, user try to read the pixel, then not valid

        output [16 * 24 - 1 : 0] result, // 24 * 16 bits
        output result_valid
    );
    
// determine mult type
    localparam T_ZERO = 5'd00;
    localparam T_00 = 5'd01;
    localparam T_01 = 5'd02;
    localparam T_02 = 5'd03;
    localparam T_03 = 5'd04;
    localparam T_05 = 5'd05;
    localparam T_06 = 5'd06;
    localparam T_07 = 5'd07;
    localparam T_11 = 5'd08;
    localparam T_12 = 5'd09;
    localparam T_13 = 5'd10;
    localparam T_15 = 5'd11;
    localparam T_16 = 5'd12;
    localparam T_17 = 5'd13;
    localparam T_22 = 5'd14;
    localparam T_23 = 5'd15;
    localparam T_25 = 5'd16;
    localparam T_26 = 5'd17;
    localparam T_27 = 5'd18;
    localparam T_33 = 5'd19;
    localparam T_35 = 5'd20;
    localparam T_36 = 5'd21;
    localparam T_37 = 5'd22;
    localparam T_55 = 5'd23;
    localparam T_56 = 5'd24;
    localparam T_57 = 5'd25;
    localparam T_66 = 5'd26;
    localparam T_67 = 5'd27;
    localparam T_77 = 5'd28;
    localparam [16 * 80 - 1 : 0] MULT_TYPE = {
      //0       1       2       3       4       5       6       7       8       9       10      11      12      13      14      15  
        T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_00,   T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO,
        T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_05,   T_01,   T_03,   T_07,   T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO,
        T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_06,   T_02,   T_02,   T_06,   T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO,
        T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_07,   T_03,   T_01,   T_05,   T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO, T_ZERO,
        T_ZERO, T_05,   T_ZERO, T_ZERO, T_ZERO, T_01,   T_ZERO, T_ZERO, T_ZERO, T_03,   T_ZERO, T_ZERO, T_ZERO, T_07,   T_ZERO, T_ZERO,
        T_55,   T_15,   T_35,   T_57,   T_15,   T_11,   T_13,   T_17,   T_35,   T_13,   T_33,   T_37,   T_57,   T_17,   T_37,   T_77,
        T_56,   T_25,   T_25,   T_56,   T_16,   T_12,   T_12,   T_16,   T_36,   T_23,   T_23,   T_36,   T_67,   T_27,   T_27,   T_67,
        T_57,   T_35,   T_15,   T_55,   T_17,   T_13,   T_11,   T_15,   T_37,   T_33,   T_13,   T_35,   T_77,   T_37,   T_17,   T_57,
        T_ZERO, T_06,   T_ZERO, T_ZERO, T_ZERO, T_02,   T_ZERO, T_ZERO, T_ZERO, T_02,   T_ZERO, T_ZERO, T_ZERO, T_06,   T_ZERO, T_ZERO,
        T_56,   T_16,   T_36,   T_67,   T_25,   T_12,   T_23,   T_27,   T_25,   T_12,   T_23,   T_27,   T_56,   T_16,   T_36,   T_67,
        T_66,   T_26,   T_26,   T_66,   T_26,   T_22,   T_22,   T_26,   T_26,   T_22,   T_22,   T_26,   T_66,   T_26,   T_26,   T_66,
        T_67,   T_36,   T_16,   T_56,   T_27,   T_23,   T_12,   T_25,   T_27,   T_23,   T_12,   T_25,   T_67,   T_36,   T_16,   T_56,
        T_ZERO, T_07,   T_ZERO, T_ZERO, T_ZERO, T_03,   T_ZERO, T_ZERO, T_ZERO, T_01,   T_ZERO, T_ZERO, T_ZERO, T_05,   T_ZERO, T_ZERO,
        T_57,   T_17,   T_37,   T_77,   T_35,   T_13,   T_33,   T_37,   T_15,   T_11,   T_13,   T_17,   T_55,   T_15,   T_35,   T_57,
        T_67,   T_27,   T_27,   T_67,   T_36,   T_23,   T_23,   T_36,   T_16,   T_12,   T_12,   T_16,   T_56,   T_25,   T_25,   T_56,
        T_77,   T_37,   T_17,   T_57,   T_37,   T_33,   T_13,   T_35,   T_17,   T_13,   T_11,   T_15,   T_57,   T_35,   T_15,   T_55
        };
// end of determine mult type

    integer n;
    // systolic_line Inputs
    reg [16 * 24 - 1 : 0] line_in [0:14];
    // reg [15 - 1:0] line_valid;
    reg result_valid_reg;
    reg pixel_valid_q;
    assign result_valid = result_valid_reg;

    wire [23:0] line_result [0:15];
    assign result = {
        line_result[15], 
        line_result[14], 
        line_result[13], 
        line_result[12], 
        line_result[11], 
        line_result[10], 
        line_result[9], 
        line_result[8], 
        line_result[7], 
        line_result[6], 
        line_result[5], 
        line_result[4], 
        line_result[3], 
        line_result[2], 
        line_result[1], 
        line_result[0]};

    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            for(n = 0; n < 15; n = n + 1) begin
                line_in[n] <= 'b0;
            end
            result_valid_reg <= 1'b0; 
            // line_valid <= 'b0;
        end
        else begin
            // line_in[0] <= pixel;
            // line_valid[0] <= pixel_valid;
            // for(n = 1; n<15; n = n + 1) begin
            //     line_in[n] <= line_in[n - 1];
            //     line_valid[n] <= line_valid[n - 1];
            // end
            if(pixel_valid) begin
                line_in[0] <= pixel;
                for(n = 1; n<15; n = n + 1) begin
                    line_in[n] <= line_in[n - 1];
                end
            end
            pixel_valid_q <= pixel_valid;
            result_valid_reg <= pixel_valid_q;
        end
    end

    systolic_line #(
        .MULT_TYPE ( MULT_TYPE[16 * 80 - 1 : 15 * 80]),
        .FRACTION_BITS ( FRACTION_BITS ))
    inst_line_first (
        .aclk ( aclk ),
        .aresetn ( aresetn ),
        .pixel ( pixel ),
        .pixel_valid ( pixel_valid ),

        .result ( line_result[0] )
    );
    
    genvar i;
    generate
    for(i = 1; i < 16; i = i + 1) begin : inst_line
        systolic_line #(
            .MULT_TYPE ( MULT_TYPE[(16-i) * 80 - 1 : (15-i) * 80]),
            .FRACTION_BITS ( FRACTION_BITS ))
        inst_line (
            .aclk ( aclk ),
            .aresetn ( aresetn ),
            .pixel ( line_in[i - 1] ),
            .pixel_valid ( pixel_valid ),

            .result ( line_result[i] )
        );
    end
    endgenerate

endmodule
