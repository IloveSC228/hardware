`timescale 1ns / 1ps
`include "defines2.vh"

module eqcmp(
	input wire [31:0] a,b,
	input wire [5:0] opcodeD,
	input wire [4:0] rtD,
	output reg y	
    );

	always@(*) begin
		case(opcodeD)
			`BEQ: y = (a == b) ? 1 : 0;
			`BNE: y = (a == b) ? 0 : 1;
			`BGTZ: y = ((a[31] == 0) && a != 32'b0) ? 1 : 0;
			`BLEZ: y = ((a[31] == 1) || a == 32'b0) ? 1 : 0;
			`REGIMM_INST: case (rtD)
				`BGEZ, `BGEZAL: y = (a[31] == 1) ? 0 : 1; 
				`BLTZ, `BLTZAL: y = (a[31] == 1) ? 1 : 0; // 负数小于0
				default: y = 0;
			endcase
			default: y = 0;
		endcase
	end
endmodule
