`timescale 1ns / 1ps

module signext(
	input wire [15:0] a,
	input wire [1:0] type, // 需要判断是0扩展还是有符号扩展
	output wire [31:0] y
    );
	// I-type中opcode的三四位为11的是0扩展，如逻辑立即数运算，其余的算数，跳转，访存指令为有符号扩展
	assign y = (type == 2'b11) ? {{16{1'b0}}, a} : {{16{a[15]}},a};
endmodule
