`timescale 1ns / 1ps
`include "defines2.vh"

module maindec(
	input wire stallD,
	input wire [31:0] instrD,
	// 控制信号量
	output wire memtoreg,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jal,jr,bal,jalr,
	output wire [3:0] aluop,
	output wire memen,
	output wire [1:0] hilo_we,
	output reg invalidD, cp0_we, cp0_re
    );
	wire [4:0] rs, rt, rd;
	wire [5:0] op, funct;
	assign rs = instrD[25:21];
	assign rt = instrD[20:16];
	assign rd = instrD[15:11];
	assign op = instrD[31:26];
	assign funct = instrD[5:0];
	reg [16:0] controls;
	assign {regwrite,regdst,alusrc,branch,memtoreg,jump,jal,jr,bal,jalr,aluop,memen,hilo_we} = controls;
	/*
	regwrite 是否需要写入寄存器 1是 0否
    regdst 写入寄存器rd还是rt 1rd 0rt,立即数置0
    alusrc alu的第二个操作数是否来自立即数 1是 0否
    branch 是否是分支指令 1是 0否
    memtoreg WB阶段写回寄存器堆的是否来自内存 1是 0否
	jump j跳转指令 1是 0否
    jal jal跳转指令 1是 0否
    jr jr跳转指令 1是 0否
    bal bal跳转指令（包括bltzal和bgezal） 1是 0否
	jalr jalr跳转指令 1是 0否
	memen data ram使能信号 1是 0否 
    hilo_we 是否需要写入hilo寄存器 1是 0否, 高位写高位，低位写低位
	*/
	always @(*) begin
		invalidD = 0;
		cp0_we = 0;
		cp0_re = 0;
		case (op)
			// 逻辑运算
			`ANDI: controls <= {10'b1010000000,`ANDI_OP,3'b000};
			`XORI: controls <= {10'b1010000000,`XORI_OP,3'b000};
			`LUI: controls <= {10'b1010000000,`LUI_OP,3'b000};
			`ORI: controls <= {10'b1010000000,`ORI_OP,3'b000};
			// 算术运算
			`ADDI: controls <= {10'b1010000000,`ADDI_OP,3'b000};
			`ADDIU: controls <= {10'b1010000000,`ADDIU_OP,3'b000};
			`SLTI: controls <= {10'b1010000000,`SLTI_OP,3'b000};
			`SLTIU: controls <= {10'b1010000000,`SLTIU_OP,3'b000};
			// 跳转
			`J: controls <= {10'b0000010000,`USELESS_OP,3'b000};
			`JAL: controls <= {10'b1000001000,`USELESS_OP,3'b000};
			// 分支
			`BEQ: controls <= {10'b0001000000,`USELESS_OP,3'b000};
			`BGTZ: controls <= {10'b0001000000,`USELESS_OP,3'b000};
			`BLEZ: controls <= {10'b0001000000,`USELESS_OP,3'b000};
			`BNE: controls <= {10'b0001000000,`USELESS_OP,3'b000};
			`REGIMM_INST: case(rt)
				`BLTZ: controls <= {10'b0001000000,`USELESS_OP,3'b000};
				`BLTZAL: controls <= {10'b1001000010,`USELESS_OP,3'b000};
				`BGEZ: controls <= {10'b0001000000,`USELESS_OP,3'b000};
				`BGEZAL: controls <= {10'b1001000010,`USELESS_OP,3'b000};
				default: {controls, invalidD} <= {17'b0000000000000, 1'b1};
			endcase
			// 访存
			`LB: controls <= {10'b1010100000,`MEM_OP,3'b100};
			`LBU: controls <= {10'b1010100000,`MEM_OP,3'b100};
			`LH: controls <= {10'b1010100000,`MEM_OP,3'b100};
			`LHU: controls <= {10'b1010100000,`MEM_OP,3'b100};
			`LW: controls <= {10'b1010100000,`MEM_OP,3'b100};
			`SB: controls <= {10'b0010000000,`MEM_OP,3'b100};
			`SH: controls <= {10'b0010000000,`MEM_OP,3'b100};
			`SW: controls <= {10'b0010000000,`MEM_OP,3'b100};
			// 特权指令
			`SPECIAL3_INST: case(rs)
				`MTC0: begin
					cp0_we <= 1;
					controls <= {10'b0000000000,`MTC0_OP,3'b000};
				end
				`MFC0: begin
					cp0_re <= 1;
					controls <= {10'b1000000000,`MFC0_OP,3'b000};
				end
				`ERET: controls <= {10'b1000000000,`USELESS_OP,3'b000};
				default: {controls, invalidD} <= {17'b0000000000000, 1'b1};
			endcase
			// R-Type
			`R_TYPE: case(funct)
				// 逻辑运算
				`AND,`OR,`XOR,`NOR: controls <= {10'b1100000000,`R_TYPE_OP,3'b000};
				// 移位运算
				`SLL,`SRL,`SRA,`SLLV,`SRLV,`SRAV: controls <= {10'b1100000000,`R_TYPE_OP,3'b000};
				// 数据移动
				`MTHI: controls <= {10'b0000000000,`R_TYPE_OP,3'b010};
				`MTLO: controls <= {10'b0000000000,`R_TYPE_OP,3'b001};
				`MFHI: controls <= {10'b1100000000,`R_TYPE_OP,3'b000};
				`MFLO: controls <= {10'b1100000000,`R_TYPE_OP,3'b000};
				// 算术运算
				`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU: controls <= {10'b1100000000,`R_TYPE_OP,3'b000};
				`MULT,`MULTU,`DIV,`DIVU: controls <= {10'b0000000000,`R_TYPE_OP,3'b011}; // 这里感觉regdst置0或1都可以，因为反正都不写入寄存器，无所谓写入寄存器是哪一个
				// 跳转
				`JR: controls <= {10'b0000000100,`USELESS_OP,3'b000};
				`JALR: controls <= {10'b1100000001,`USELESS_OP,3'b000};
				// 内陷
				`SYSCALL: controls <= {10'b0000000000,`USELESS_OP,3'b000};
				`BREAK: controls <= {10'b0000000000,`USELESS_OP,3'b000};
				default: {controls, invalidD} <= {17'b0000000000000, 1'b1};
			endcase
			default: {controls, invalidD} <= {17'b0000000000000, 1'b1};//illegal op
		endcase
	end
endmodule
