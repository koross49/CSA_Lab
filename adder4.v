`timescale 1ns / 1ps

module adder4(
    input[3:0] a,
    input[3:0] b,
    input cin,
    output gout,
    output pout,
    output[3:0] s,
    output[3:0] cout
    );
    wire[3:0] p;
    wire[3:0] g;
    wire[3:0] c;
    assign cout[3] = c[3];
    adder a0(.a(a[0]), .b(b[0]), .cin(cin), .g(g[0]), .p(p[0]), .s(s[0]), .cout(cout[0]));
    adder a1(.a(a[1]), .b(b[1]), .cin(c[0]), .g(g[1]), .p(p[1]), .s(s[1]), .cout(cout[1]));
    adder a2(.a(a[2]), .b(b[2]), .cin(c[1]), .g(g[2]), .p(p[2]), .s(s[2]), .cout(cout[2]));
    adder a3(.a(a[3]), .b(b[3]), .cin(c[2]), .g(g[3]), .p(p[3]), .s(s[3]), .cout());
    cla u_cla(.p(p), .g(g), .cin(cin), .cout(c), .gout(gout), .pout(pout));
endmodule