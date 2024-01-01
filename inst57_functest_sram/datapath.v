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
	input wire invalidD,
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
	output wire[31:0] aluout2M,writedata2M,
	input wire[31:0] readdataM,
	output wire flushM,
	output wire [3:0] memwriteM,
	input wire cp0_weM,cp0_reM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire flushW,
	// debug 
	output wire [31:0] pcW,
    output wire [4:0] writeregW,
    output wire [31:0] resultW
    );
	
	//fetch stage
	wire stallF,flushF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcplus8F,pcbranchD,pcnextJFD;
	wire [7:0] exceptF;
	wire is_in_delayslotF;
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
	wire [7:0] exceptD;
	wire syscallD, breakD, eretD,is_in_delayslotD;
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
	wire [7:0] exceptE;
	wire is_in_delayslotE;
	//mem stage
	wire [4:0] writeregM;
	wire [31:0] pcM;
	wire [5:0] opM;
	wire [31:0] writedataM;
	wire [7:0] exceptM;
	wire [31:0] readdata2M;
	wire [31:0]bad_addr;
	wire adelM, adesM;
	wire [1:0] size;
	wire [31:0] cp0_status,cp0_cause,excepttype;
	wire [4:0] rdM;
	wire [31:0] srcbM;
	wire [31:0] count_o, cp0_datao, compare_o, epc_o,config_o,prid_o,badvaddr;
	wire timer_int_o,is_in_delayslotM;
	wire [31:0] newPCM;
	wire [31:0] aluoutM;
	//writeback stage
	wire [31:0] aluoutW,readdataW;
	wire [5:0] opW;
	//hazard detection
	hazard h(
		//fetch stage
		stallF,flushF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
		jumpD,jrD,balD,jalrD,
		flushD,
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
		excepttype,epc_o,
		newPCM,
		//write back stage
		writeregW,
		regwriteW,
		flushW
		);

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	/*-----------------------------取指---------------------------------*/
	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,flushF,pcnextFD,newPCM,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	adder pcadde(pcF,32'b1000,pcplus8F);
	// 取指地址错例外
	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b10000000;
	// 计算下一条pc
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD); // 是否是branch指令
	mux2 #(32) pcmux(pcnextbrFD,{pcplus4D[31:28],instrD[25:0],2'b00},jumpD | jalD,pcnextJFD); // 是否是J和JAL
	mux2 #(32) pcJmux(pcnextJFD,srca2D,jrD | jalrD,pcnextFD); // 是否是JR或JARL
	// 判断是否是延迟槽
	assign is_in_delayslotF = branchD | jumpD | jrD | jalD | jalrD;
	/*------------------------取指到译码的寄存器-------------------------*/
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	flopenrc #(32) r4D(clk,rst,~stallD,flushD,pcplus8F,pcplus8D);
	flopenrc #(8) r5D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(1) r6D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
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
	mux2 #(32) forwardamux(srcaD,aluout2M,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluout2M,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);
	// 指令中断以及保留指令处理
	assign syscallD = (opD == 6'b000000 && functD == 6'b001100);
	assign breakD = (opD == 6'b000000 && functD == 6'b001101);
	assign eretD = (instrD == 32'b010000_1_0000000000000000000_011000);
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
	flopenrc #(8) r12E(clk,rst,~stallE,flushE,{exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]},exceptE);
	flopenrc #(1) r13E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
	/*-----------------------------运算---------------------------------*/
	// 除法信号量
	assign div_signalE = ((alucontrolE == `DIV_CONTROL) || (alucontrolE == `DIVU_CONTROL)) ? 1'b1 : 1'b0;
	assign start_iE = (((alucontrolE == `DIV_CONTROL) | (alucontrolE == `DIVU_CONTROL)) & ~ready_oE) ? 1'b1 : 1'b0;
	// 选择ALU的左操作数(前推数据)
	mux3 #(32) forwardaemux(srcaE,resultW,aluout2M,forwardaE,srca2E); 
	// 第一次选择ALU的右操作数(前推数据)
	mux3 #(32) forwardbemux(srcbE,resultW,aluout2M,forwardbE,srcb2E);
	// 第二次选择ALU的右操作数(立即数)
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,alucontrolE,saE,aluoutE,hiE,loE,hi_alu_outE,lo_alu_outE,overflow);
	// 除法
	div div(clk,rst,alucontrolE,srca2E,srcb3E,start_iE,1'b0,{hi_div_outE,lo_div_outE},ready_oE);
	// 选择写入hilo寄存器的是alu结果还是除法器结果
	mux2 #(64) hiloin({hi_alu_outE,lo_alu_outE},{hi_div_outE,lo_div_outE},div_signalE,{hi_mux_outE,lo_mux_outE});
	// hilo寄存器
	hilo_reg hilo(clk,rst,flushE,hilo_weE,hi_mux_outE,lo_mux_outE,hiE,loE);
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
	floprc #(8) r6M(clk,rst,flushM,{exceptE[7:3], overflow, exceptE[1:0]},exceptM);
	floprc #(5) r7M(clk,rst,flushM,rdE,rdM);
	floprc #(32) r8M(clk,rst,flushM,srcb3E,srcbM);
	floprc #(1) r9M(clk,rst,flushM,is_in_delayslotE,is_in_delayslotM);
	/*-----------------------------存储---------------------------------*/
	// 写入寄存器的是否是来自cp0
	mux2 #(32) resmux2(aluoutM,cp0_datao,cp0_reM,aluout2M);
	// 操作lsw的相关指令，同时将dataram的读写地址错误异常输出出来
	memsel ml(pcM,opM,aluout2M,writedataM,memwriteM,writedata2M,readdataM,readdata2M,bad_addr,adelM,adesM,size);
	exception exce(rst,exceptM,adelM,adesM,cp0_status,cp0_cause,excepttype);
	cp0_reg cp0reg(clk,rst,cp0_weM,rdM,rdM,srcbM,6'b000000,excepttype,pcM,is_in_delayslotM,bad_addr,count_o,cp0_datao,compare_o,cp0_status,cp0_cause,epc_o,config_o,prid_o,badvaddr,timer_int_o);
	
	/*------------------------存储到写回的寄存器-------------------------*/
	floprc #(32) r1W(clk,rst,flushW,aluout2M,aluoutW);
	floprc #(32) r2W(clk,rst,flushW,readdata2M,readdataW);
	floprc #(5) r3W(clk,rst,flushW,writeregM,writeregW);
	floprc #(32) r4W(clk,rst,flushW,pcM,pcW);
	floprc #(6) r5W(clk,rst,flushW,opM,opW);
	/*-----------------------------写回---------------------------------*/
	// 选择写回的值是来自dataram还是alu
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);  
	
endmodule
