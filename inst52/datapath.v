`timescale 1ns / 1ps
`include "defines2.vh"

module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,jalD,jrD,balD,jalrD,
	output wire equalD,stallD,
	output wire[5:0] opD,functD,
	output wire[31:0] instrD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire [4:0] alucontrolE,
	input wire [1:0] hilo_weE,
	output wire flushE,stallE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedata2M,
	input wire[31:0] readdataM,
	output wire flushM,
	output wire [3:0] memwriteM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire flushW
    );
	
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcplus8F,pcbranchD,pcnextJFD;
	//decode stage
	wire [31:0] pcplus4D,pcplus8D;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rtD,rdD;
	wire [4:0] saD; // 用于移位指令sll，srl，sra
	wire [31:0] pcD;
	wire [39:0] asciiD;
	wire flushD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE,aluout2E;
	wire [31:0] pcplus8E;
	wire overflow;
	wire [31:0] pcE;
	wire [31:0] hiE, loE;
	wire [31:0] hi_alu_outE,lo_alu_outE,hi_div_outE,lo_div_outE;
	wire ready_oE, start_iE; // 除法开始结束信号
	wire div_signalE;
	wire [31:0] hi_mux_outE,lo_mux_outE;
	wire [4:0] writeregjalrE; // jalr特殊写寄存器，需要提前声明，因为有特殊情况需记为31
	wire jalE,balE,jalrE;
	wire [5:0] opE;
	//mem stage
	wire [4:0] writeregM;
	wire [31:0] pcM;
	wire [5:0] opM;
	wire [31:0] writedataM;
	//writeback stage
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW,readdata2W;
	wire [31:0] pcW;
	wire [5:0] opW;
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,jumpD,jrD,balD,jalrD,
		//execute stage
		rsE,rtE,
		writereg2E,alucontrolE,
		regwriteE,
		memtoregE,
		ready_oE,
		forwardaE,forwardbE,
		flushE,stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		flushM,
		//write back stage
		writeregW,
		regwriteW
		);

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	/*-----------------------------取指---------------------------------*/
	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	adder pcadde(pcF,32'b1000,pcplus8F);
	// 计算下一条pc
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD); // 是否是branch指令
	mux2 #(32) pcmux(pcnextbrFD,{pcplus4D[31:28],instrD[25:0],2'b00},jumpD | jalD,pcnextJFD); // 是否是J和JAL
	mux2 #(32) pcJmux(pcnextJFD,srca2D,jrD | jalrD,pcnextFD); // 是否是JR或JARL
	/*------------------------取指到译码的寄存器-------------------------*/
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	flopenrc #(32) r4D(clk,rst,~stallD,flushD,pcplus8F,pcplus8D);
	/*-----------------------------译码---------------------------------*/
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	signext se(instrD[15:0],instrD[29:28],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);
	/*------------------------译码到运算的寄存器-------------------------*/
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(32) r8E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(32) r9E(clk,rst,~stallE,flushE,pcplus8D,pcplus8E);
	flopenrc #(3) r10E(clk,rst,~stallE,flushE,{jalD,balD,jalrD},{jalE,balE,jalrE});
	flopenrc #(6) r11E(clk,rst,~stallE,flushE,opD,opE);
	/*-----------------------------运算---------------------------------*/
	// 除法信号量
	assign div_signalE = ((alucontrolE == `DIV_CONTROL) || (alucontrolE == `DIVU_CONTROL)) ? 1'b1 : 1'b0;
	assign start_iE = (((alucontrolE == `DIV_CONTROL) | (alucontrolE == `DIVU_CONTROL)) & ~ready_oE) ? 1'b1 : 1'b0;
	// 选择ALU的左操作数(前推数据)
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E); 
	// 第一次选择ALU的右操作数(前推数据)
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	// 第二次选择ALU的右操作数(立即数)
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,alucontrolE,saE,aluoutE,hiE,loE,hi_alu_outE,lo_alu_outE,overflow);
	// 除法
	div div(clk,rst,alucontrolE,srca2E,srcb3E,start_iE,1'b0,{hi_div_outE,lo_div_outE},ready_oE);
	// 选择写入hilo寄存器的是alu结果还是除法器结果
	mux2 #(64) hiloin({hi_alu_outE,lo_alu_outE},{hi_div_outE,lo_div_outE},div_signalE,{hi_mux_outE,lo_mux_outE});
	// hilo寄存器
	hilo_reg hilo(clk,rst,hilo_weE,hi_mux_outE,lo_mux_outE,hiE,loE);
	// 选择写入的寄存器为rt还是rd
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	//JALR指令选择写寄存器，没有指定时默认为31
	assign writeregjalrE = (jalrE & writeregE == 0)? 5'b11111 : writeregE;
	// 选择是跳转JALR寄存器还是JAL或BAL的31寄存器
	mux2 #(5) wrmux2(writeregjalrE,5'b11111,jalE | balE, writereg2E);
	// 选择写入的值是alu的结果还是jaL或bal或jalr的值
	mux2 #(32) wrmux3(aluoutE,pcplus8E,jalE | jalrE | balE,aluout2E);
	/*------------------------运算到存储的寄存器-------------------------*/
	floprc #(32) r1M(clk,rst,flushM,srcb2E,writedataM);
	floprc #(32) r2M(clk,rst,flushM,aluout2E,aluoutM);
	floprc #(5) r3M(clk,rst,flushM,writereg2E,writeregM);
	floprc #(32) r4M(clk,rst,flushM,pcE,pcM);
	floprc #(6) r5M(clk,rst,flushM,opE,opM);
	/*-----------------------------存储---------------------------------*/
	// 获取s指令的写字节，以及设置l的memwrite为0000m,并修改写ram的值
	swdec swdec(opM,aluoutM,writedataM,memwriteM,writedata2M);
	/*------------------------存储到写回的寄存器-------------------------*/
	floprc #(32) r1W(clk,rst,flushW,aluoutM,aluoutW);
	floprc #(32) r2W(clk,rst,flushW,readdataM,readdataW);
	floprc #(5) r3W(clk,rst,flushW,writeregM,writeregW);
	floprc #(32) r4W(clk,rst,flushW,pcM,pcW);
	floprc #(6) r5W(clk,rst,flushW,opM,opW);
	/*-----------------------------写回---------------------------------*/
	lwdec lwdec(opW,readdataW,aluoutW,readdata2W);
	// 选择写回的值是来自dataram还是alu
	mux2 #(32) resmux(aluoutW,readdata2W,memtoregW,resultW);  
endmodule
