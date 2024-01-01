`timescale 1ns / 1ps

module mips(
	input wire clk,rst,
	output wire[31:0] pcF, // 拿出去给instram读指令
	input wire[31:0] instrF, // 从instram读取到的指令
	output wire [3:0] memwriteM, // dataram的写信号
	output wire memenM, // dataram的使能信号
	output wire [31:0] aluoutM,writedataM, // alu的运算结果，dataram的操作地址 / dataram的写数据
	input wire [31:0] readdataM,  // dataram读数据
	// debug 
	output wire [31:0] pcW,
	output wire regwriteW,
    output wire [4:0] writeregW,
    output wire [31:0] resultW
    );
	// 取指 f

    // 译码 d
	wire pcsrcD,equalD; 
    wire [5:0] opD,functD;
	wire [31:0] instrD;
	wire stallD,branchD,jumpD,jalD,jrD,balD,jalrD,invalidD;
    // 运算 e
	wire regdstE,alusrcE,memtoregE,regwriteE,flushE,stallE;	
	wire [4:0] alucontrolE;
	wire [1:0] hilo_weE;
    // 写存 m
    wire memtoregM,regwriteM;
	wire flushM;
	wire cp0_weM,cp0_reM;
    // 写回 w
	wire memtoregW;
	wire flushW;

	controller c(
	clk,rst,
	//decode stage
	functD,
	instrD,
	pcsrcD,branchD,equalD,jumpD,jalD,jrD,balD,jalrD,
	stallD,invalidD,
	//execute stage
	flushE,stallE,
	memtoregE,alusrcE,
	regdstE,regwriteE,	
	alucontrolE,
	hilo_weE,
	//mem stage
	memtoregM,regwriteM,memenM,
	flushM,cp0_weM,cp0_reM,
	//write back stage
	memtoregW,regwriteW,
	flushW
    );

	datapath dp(
	clk,rst,
	//fetch stage
	pcF,
	instrF,
	//decode stage
	pcsrcD,branchD,
	jumpD,jalD,jrD,balD,jalrD,
	equalD,stallD,
	opD,functD,
	instrD,
	invalidD,
	//execute stage
	memtoregE,
	alusrcE,regdstE,
	regwriteE,
	alucontrolE,
	hilo_weE,
	flushE,stallE,
	//mem stage
	memtoregM,
	regwriteM,
	aluoutM,writedataM,
	readdataM,
	flushM,
	memwriteM,
	cp0_weM,cp0_reM,
	//writeback stage
	memtoregW,
	regwriteW,
	flushW,
	// debug
	pcW,
	writeregW,
	resultW
	);
	
endmodule
