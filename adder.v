`timescale 1ns / 1ps

module adder(
    input a, // 加数1
    input b,// 加数2
    input cin,// 进位
    output g, // 生成进位信号
    output p, // 传递进位信号
    output s, // 和
    output cout // 进位
    );
    assign s = a ^ b ^ cin; // 异或运算得到和
    assign cout = (a & b) | (a & cin) | (b & cin); // 与运算得到进位
    assign g = a & b; // 与运算得到生成进位信号
    assign p = a | b; // 或运算得到传递进位信号
endmodule