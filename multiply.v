`timescale 1ns / 1ps

`define MUL_IDLE 1'b0
`define MUL_ON 1'b1
`define ZeroWord 32'b0

module multiply(              // 乘法器
    input         clk,        // 时钟
    input         mult_begin, // 乘法开始信号
    input  [31:0] mult_op1,   // 乘法源操作数1
    input  [31:0] mult_op2,   // 乘法源操作数2
    output [63:0] product,    // 乘积
    output reg    mult_end    // 乘法结束信号
);

    reg state;
    reg s_next;
    reg[63:0] adder1;
    reg[63:0] adder2;
    
    
    always @ (*) begin
        case (state)
        `MUL_IDLE: begin
            if (mult_begin) s_next = `MUL_ON;
            else s_next = `MUL_IDLE;
        end
        `MUL_ON: s_next = `MUL_IDLE;
        default: s_next = `MUL_IDLE;
        endcase
    end
    
    always @ (posedge clk) state <= s_next;
    
    wire[32:0] x_ext; // 根据乘法属性对x进行符号扩展或零扩展
    wire[33:0] y_ext; // 根据乘法属性对y进行符号扩展或零扩展
    wire[63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp16; // 改进的Booth算法生成的部分积
    wire[63:0] pp17;
    wire[33:0] c;
    // 第一级压缩结果
    wire[63:0] s_l1_1, s_l1_2, s_l1_3, s_l1_4, s_l1_5, s_l1_6;
    wire[63:0] c_l1_1, c_l1_2, c_l1_3, c_l1_4, c_l1_5, c_l1_6;
    // 第二级压缩结果
    wire[63:0] s_l2_1, s_l2_2, s_l2_3, s_l2_4;
    wire[63:0] c_l2_1, c_l2_2, c_l2_3, c_l2_4;
    // 第三级压缩结果
    wire[63:0] s_l3_1, s_l3_2;
    wire[63:0] c_l3_1, c_l3_2;
    // 第四级压缩结果
    wire[63:0] s_l4_1, s_l4_2;
    wire[63:0] c_l4_1, c_l4_2;
    // 第五级压缩结果
    wire[63:0] s_l5_1;
    wire[63:0] c_l5_1;
    // 第六级压缩结果
    wire[63:0] s_l6_1;
    wire[63:0] c_l6_1;
    
    // 有符号扩展
    assign x_ext = {mult_op1[31], mult_op1};
    assign y_ext = {{2{mult_op2[31]}}, mult_op2};
    
    // 生成部分积
    booth2 u_b0(.x(x_ext), .y({y_ext[1:0], 1'b0}), .z(pp0), .c(c[1:0]));
    booth2 u_b1(.x(x_ext), .y(y_ext[3:1]), .z(pp1), .c(c[3:2]));
    booth2 u_b2(.x(x_ext), .y(y_ext[5:3]), .z(pp2), .c(c[5:4]));
    booth2 u_b3(.x(x_ext), .y(y_ext[7:5]), .z(pp3), .c(c[7:6]));
    booth2 u_b4(.x(x_ext), .y(y_ext[9:7]), .z(pp4), .c(c[9:8]));
    booth2 u_b5(.x(x_ext), .y(y_ext[11:9]), .z(pp5), .c(c[11:10]));
    booth2 u_b6(.x(x_ext), .y(y_ext[13:11]), .z(pp6), .c(c[13:12]));
    booth2 u_b7(.x(x_ext), .y(y_ext[15:13]), .z(pp7), .c(c[15:14]));
    booth2 u_b8(.x(x_ext), .y(y_ext[17:15]), .z(pp8), .c(c[17:16]));
    booth2 u_b9(.x(x_ext), .y(y_ext[19:17]), .z(pp9), .c(c[19:18]));
    booth2 u_b10(.x(x_ext), .y(y_ext[21:19]), .z(pp10), .c(c[21:20]));
    booth2 u_b11(.x(x_ext), .y(y_ext[23:21]), .z(pp11), .c(c[23:22]));
    booth2 u_b12(.x(x_ext), .y(y_ext[25:23]), .z(pp12), .c(c[25:24]));
    booth2 u_b13(.x(x_ext), .y(y_ext[27:25]), .z(pp13), .c(c[27:26]));
    booth2 u_b14(.x(x_ext), .y(y_ext[29:27]), .z(pp14), .c(c[29:28]));
    booth2 u_b15(.x(x_ext), .y(y_ext[31:29]), .z(pp15), .c(c[31:30]));
    booth2 u_b16(.x(x_ext), .y(y_ext[33:31]), .z(pp16), .c(c[33:32]));
    assign pp17 = {30'b0, c};
    
    // 压缩部分积
    csa u_csa_l1_1(
        .x(pp0),
        .y({pp1[61:0], 2'b0}),
        .z({pp2[59:0], 4'b0}),
        .s(s_l1_1),
        .c(c_l1_1)
        );
    csa u_csa_l1_2(
        .x({pp3[57:0], 6'b0}),
        .y({pp4[55:0], 8'b0}),
        .z({pp5[53:0], 10'b0}),
        .s(s_l1_2),
        .c(c_l1_2)
        );
    csa u_csa_l1_3(
        .x({pp6[51:0], 12'b0}),
        .y({pp7[49:0], 14'b0}),
        .z({pp8[47:0], 16'b0}),
        .s(s_l1_3),
        .c(c_l1_3)
        );
    csa u_csa_l1_4(
        .x({pp9[45:0], 18'b0}),
        .y({pp10[43:0], 20'b0}),
        .z({pp11[41:0], 22'b0}),
        .s(s_l1_4),
        .c(c_l1_4)
        );
    csa u_csa_l1_5(
        .x({pp12[39:0], 24'b0}),
        .y({pp13[37:0], 26'b0}),
        .z({pp14[35:0], 28'b0}),
        .s(s_l1_5),
        .c(c_l1_5)
        );
    csa u_csa_l1_6(
        .x({pp15[33:0], 30'b0}),
        .y({pp16[31:0], 32'b0}),
        .z(pp17),
        .s(s_l1_6),
        .c(c_l1_6)
        );
    csa u_csa_l2_1(
        .x(s_l1_1),
        .y(s_l1_2),
        .z(s_l1_3),
        .s(s_l2_1),
        .c(c_l2_1)
        );
    csa u_csa_l2_2(
        .x(s_l1_4),
        .y(s_l1_5),
        .z(s_l1_6),
        .s(s_l2_2),
        .c(c_l2_2)
        );
    csa u_csa_l2_3(
        .x({c_l1_1[62:0], 1'b0}),
        .y({c_l1_2[62:0], 1'b0}),
        .z({c_l1_3[62:0], 1'b0}),
        .s(s_l2_3),
        .c(c_l2_3)
        );
    csa u_csa_l2_4(
        .x({c_l1_4[62:0], 1'b0}),
        .y({c_l1_5[62:0], 1'b0}),
        .z({c_l1_6[62:0], 1'b0}),
        .s(s_l2_4),
        .c(c_l2_4)
        );
    csa u_csa_l3_1(
        .x(s_l2_1),
        .y(s_l2_2),
        .z(s_l2_3),
        .s(s_l3_1),
        .c(c_l3_1)
        );
    csa u_csa_l3_2(
        .x(s_l2_4),
        .y({c_l2_1[62:0], 1'b0}),
        .z({c_l2_2[62:0], 1'b0}),
        .s(s_l3_2),
        .c(c_l3_2)
        );
    csa u_csa_l4_1(
        .x(s_l3_1),
        .y(s_l3_2),
        .z({c_l3_1[62:0], 1'b0}),
        .s(s_l4_1),
        .c(c_l4_1)
        );
    csa u_csa_l4_2(
        .x({c_l3_2[62:0], 1'b0}),
        .y({c_l2_3[62:0], 1'b0}),
        .z({c_l2_4[62:0], 1'b0}),
        .s(s_l4_2),
        .c(c_l4_2)
        );
    csa u_csa_l5_1(
        .x(s_l4_1),
        .y(s_l4_2),
        .z({c_l4_1[62:0], 1'b0}),
        .s(s_l5_1),
        .c(c_l5_1)
        );
    csa u_csa_l6_1(
        .x(s_l5_1),
        .y({c_l5_1[62:0], 1'b0}),
        .z({c_l4_2[62:0], 1'b0}),
        .s(s_l6_1),
        .c(c_l6_1)
        );
    
    // 加法
    adder64 u_fa64(.a(adder1), .b(adder2), .cin(1'b0), .sub(1'b0), .s(product), .cout());
    
    always @ (posedge clk) begin
        case (s_next)
        `MUL_IDLE: begin
            adder1 <= {`ZeroWord, `ZeroWord};
            adder2 <= {`ZeroWord, `ZeroWord};
            mult_end <= 1'b0;
        end
        `MUL_ON: begin
            adder1 <= s_l6_1;
            adder2 <= {c_l6_1[62:0], 1'b0};
            mult_end <= 1'b1;
        end
        default: begin
            adder1 <= {`ZeroWord, `ZeroWord};
            adder2 <= {`ZeroWord, `ZeroWord};
            mult_end <= 1'b0;
        end
        endcase
    end
endmodule
