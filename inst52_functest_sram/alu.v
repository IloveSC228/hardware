`timescale 1ns / 1ps
`include "defines2.vh"

module alu(
	input wire [31:0] a,b,
	input wire [4:0] alucontrol,
	input wire [4:0] sa, // 移位指令的sa
	output reg [31:0] y,
	input wire [31:0] hi_in, lo_in,
	output reg [31:0] hi_alu_out, lo_alu_out,
	output reg overflow
    );
	always @(*) begin
		case (alucontrol)
			// 逻辑运算
			`AND_CONTROL: y <= a & b;
			`OR_CONTROL: y <= a | b;
			`XOR_CONTROL: y <= a ^ b;
			`NOR_CONTROL: y <= ~(a | b);
			`LUI_CONTROL: y <= {b[15:0], 16'b0};
			// 移位运算
			`SLL_CONTROL: y <= b << sa;
			`SRL_CONTROL: y <= b >> sa;
			`SRA_CONTROL: y <= ({32{b[31]}} << (6'd32 - {1'b0,sa})) | (b >> sa);
			`SLLV_CONTROL: y <= b << a[4:0];
			`SRLV_CONTROL: y <= b >> a[4:0];
			`SRAV_CONTROL: y <= ({32{b[31]}} << (6'd32 - {1'b0,a[4:0]})) | (b >> a[4:0]);
			// 数据移动
			`MFHI_CONTROL: y <= hi_in[31:0];
			`MFLO_CONTROL: y <= lo_in[31:0];
			`MTHI_CONTROL: hi_alu_out <= a;
			`MTLO_CONTROL: lo_alu_out <= a;
			// 算术运算 (除法放在外部除法器了)
			`ADD_CONTROL, `ADDU_CONTROL: y <= a + b; // 访存指令直接复用ADD的加号
			`SUB_CONTROL, `SUBU_CONTROL: y <= a - b;
			`SLT_CONTROL: y <= ($signed(a) < $signed(b)) ? 1 : 0;
			`SLTU_CONTROL: y <= (a < b); 
			`MULT_CONTROL: {hi_alu_out, lo_alu_out} <= $signed(a) * $signed(b);
			`MULTU_CONTROL: {hi_alu_out, lo_alu_out} <= a * b;
			default : y <= 32'b0;
		endcase	
	end

	always @(*) begin
		case (alucontrol)
			`ADD_CONTROL: overflow <= a[31] & b[31] & ~y[31] | ~a[31] & ~b[31] & y[31];
			`SUB_CONTROL: overflow <= (((a[31] && !b[31]) && !y[31]) || ((!a[31] && b[31]) && y[31]));
			`ADDU_CONTROL: overflow <= 1'b0;
			`SUBU_CONTROL: overflow <= 1'b0;
			default : overflow <= 1'b0;
		endcase	
	end
endmodule
