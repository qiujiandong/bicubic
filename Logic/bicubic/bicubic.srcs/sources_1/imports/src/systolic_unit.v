`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/06 20:25:14
// Design Name: 
// Module Name: systolic_unit
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


module systolic_unit#(
    parameter [7:0] MULT_TYPE = 5'd00,
    parameter FRACTION_BITS = 16 // F
    )(
        input aclk,
        input aresetn,

        // Q10.F range: -512 ~ 512 - 2^-F
        input signed [FRACTION_BITS + 10 - 1:0] pre_sum, 
        output signed [FRACTION_BITS + 10 - 1:0] sum,

        input [7:0] channel,
        input channel_valid
    );

// mult type define
    localparam MULT_TYPE_ZERO = 5'd00;
    localparam MULT_TYPE_00 = 5'd01;
    localparam MULT_TYPE_01 = 5'd02;
    localparam MULT_TYPE_02 = 5'd03;
    localparam MULT_TYPE_03 = 5'd04;
    localparam MULT_TYPE_05 = 5'd05;
    localparam MULT_TYPE_06 = 5'd06;
    localparam MULT_TYPE_07 = 5'd07;
    localparam MULT_TYPE_11 = 5'd08;
    localparam MULT_TYPE_12 = 5'd09;
    localparam MULT_TYPE_13 = 5'd10;
    localparam MULT_TYPE_15 = 5'd11;
    localparam MULT_TYPE_16 = 5'd12;
    localparam MULT_TYPE_17 = 5'd13;
    localparam MULT_TYPE_22 = 5'd14;
    localparam MULT_TYPE_23 = 5'd15;
    localparam MULT_TYPE_25 = 5'd16;
    localparam MULT_TYPE_26 = 5'd17;
    localparam MULT_TYPE_27 = 5'd18;
    localparam MULT_TYPE_33 = 5'd19;
    localparam MULT_TYPE_35 = 5'd20;
    localparam MULT_TYPE_36 = 5'd21;
    localparam MULT_TYPE_37 = 5'd22;
    localparam MULT_TYPE_55 = 5'd23;
    localparam MULT_TYPE_56 = 5'd24;
    localparam MULT_TYPE_57 = 5'd25;
    localparam MULT_TYPE_66 = 5'd26;
    localparam MULT_TYPE_67 = 5'd27;
    localparam MULT_TYPE_77 = 5'd28;
// end of mult define

    // NOTE the data width of P is configed in IP, when modify FRACTION_BITS, should also consider if the data width of P is proper
    wire [25:0] P;
    reg [FRACTION_BITS + 10 - 1: 0] sum_reg;
    assign sum = sum_reg;

    always@(posedge aclk or negedge aresetn) begin
        if(!aresetn) begin
            sum_reg <= 'b0;
        end
        else if(channel_valid) begin
            sum_reg <= pre_sum + P;
        end
    end

// mult inst
    generate 
        if(MULT_TYPE == MULT_TYPE_ZERO) begin: mult_zero
            mult_gen_zero mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_00) begin: mult_00
            mult_gen_00 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_01) begin: mult_01
            mult_gen_01 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_02) begin: mult_02
            mult_gen_02 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_03) begin: mult_03
            mult_gen_03 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_05) begin: mult_05
            mult_gen_05 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_06) begin: mult_06
            mult_gen_06 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_07) begin: mult_07
            mult_gen_07 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_11) begin: mult_11
            mult_gen_11 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_12) begin: mult_12
            mult_gen_12 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_13) begin: mult_13
            mult_gen_13 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_15) begin: mult_15
            mult_gen_15 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_16) begin: mult_16
            mult_gen_16 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_17) begin: mult_17
            mult_gen_17 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_22) begin: mult_22
            mult_gen_22 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_23) begin: mult_23
            mult_gen_23 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_25) begin: mult_25
            mult_gen_25 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_26) begin: mult_26
            mult_gen_26 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_27) begin: mult_27
            mult_gen_27 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_33) begin: mult_33
            mult_gen_33 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_35) begin: mult_35
            mult_gen_35 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_36) begin: mult_36
            mult_gen_36 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_37) begin: mult_37
            mult_gen_37 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_55) begin: mult_55
            mult_gen_55 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_56) begin: mult_56
            mult_gen_56 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_57) begin: mult_57
            mult_gen_57 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_66) begin: mult_66
            mult_gen_66 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_67) begin: mult_67
            mult_gen_67 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else if(MULT_TYPE == MULT_TYPE_77) begin: mult_77
            mult_gen_77 mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
        else begin
            mult_gen_zero mult_inst (
                .A(channel),  // input wire [7 : 0] A
                .P(P)  // output wire [25 : 0] P
            );
        end
    endgenerate
endmodule
