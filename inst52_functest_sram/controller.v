`timescale 1ns / 1ps

module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] functD,
	input wire[31:0] instrD,
	output wire pcsrcD,branchD,
	input wire equalD,
	output wire jumpD,jalD,jrD,balD,jalrD,
	input wire stallD,
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire [4:0] alucontrolE,
	output wire [1:0] hilo_weE,
	//mem stage
	output wire memtoregM,
	output wire regwriteM,memenM,
	input wire flushM,
	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW
    );
	
	//decode stage
	wire [3:0] aluopD;
	wire memtoregD,alusrcD,regdstD,regwriteD;
	wire [4:0] alucontrolD;
	wire [1:0] hilo_weD;
	//execute stage
	wire [3:0] memwriteE;
	wire memenE;
	maindec md(
		stallD,
		instrD,
		memtoregD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,balD,jalrD,
		aluopD,memenD,hilo_weD
		);
	aludec ad(stallD,functD,aluopD,alucontrolD);
	assign pcsrcD = branchD & equalD;
	//pipeline registers
	flopenrc #(12) regE(
		clk,rst,~stallE,flushE,
		{memtoregD,alusrcD,regdstD,regwriteD,alucontrolD,memenD,hilo_weD},
		{memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,memenE,hilo_weE}
		);
	floprc #(8) regM(
		clk,rst,flushM,
		{memtoregE,regwriteE,memenE},
		{memtoregM,regwriteM,memenM}
		);
	floprc #(8) regW(
		clk,rst,flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule
