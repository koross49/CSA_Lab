module adder32(
    input[31:0] operand1,
    input[31:0] operand2,
    input cin,
    output[31:0] result,
    output cout
    );
    wire[31:0] cout_tmp;
    assign cout = cout_tmp[31];
    adder16 a0(.a(operand1[15:0]), .b(operand2[15:0]), .cin(cin), .s(result[15:0]), .cout(cout_tmp[15:0]));
    adder16 a1(.a(operand1[31:16]), .b(operand2[31:16]), .cin(cout_tmp[15]), .s(result[31:16]), .cout(cout_tmp[31:16]));
endmodule

