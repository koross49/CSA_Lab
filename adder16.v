`timescale 1ns / 1ps

module adder16(
    input[15:0] a,
    input[15:0] b,
    input cin,
    output gout,
    output pout,
    output[15:0] s,
    output[15:0] cout
    );
    wire[3:0] p;
    wire[3:0] g;
    wire[3:0] c;
    adder4 a0(.a(a[3:0]), .b(b[3:0]), .cin(cin), .gout(g[0]), .pout(p[0]), .s(s[3:0]), .cout(cout[3:0]));
    adder4 a1(.a(a[7:4]), .b(b[7:4]), .cin(c[0]), .gout(g[1]), .pout(p[1]), .s(s[7:4]), .cout(cout[7:4]));
    adder4 a2(.a(a[11:8]), .b(b[11:8]), .cin(c[1]), .gout(g[2]), .pout(p[2]), .s(s[11:8]), .cout(cout[11:8]));
    adder4 a3(.a(a[15:12]), .b(b[15:12]), .cin(c[2]), .gout(g[3]), .pout(p[3]), .s(s[15:12]), .cout(cout[15:12]));
    cla u_cla(.p(p), .g(g), .cin(cin), .cout(c), .gout(gout), .pout(pout));
endmodule