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
	output wire invalidD,
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire [4:0] alucontrolE,
	output wire [1:0] hilo_weE,
	//mem stage
	output wire memtoregM,
	output wire regwriteM,memenM,
	input wire flushM,stallM,
	output wire cp0_weM,cp0_reM,
	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW,stallW
    );
	
	//decode stage
	wire [3:0] aluopD;
	wire memtoregD,alusrcD,regdstD,regwriteD;
	wire [4:0] alucontrolD;
	wire [1:0] hilo_weD;
	wire cp0_weD,cp0_reD,memenD;
	//execute stage
	wire [3:0] memwriteE;
	wire memenE,cp0_weE,cp0_reE;
	maindec md(
		stallD,
		instrD,
		memtoregD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,balD,jalrD,
		aluopD,memenD,hilo_weD,invalidD,cp0_weD,cp0_reD
		);
	aludec ad(stallD,functD,aluopD,alucontrolD);
	assign pcsrcD = branchD & equalD;
	//pipeline registers
	flopenrc #(14) regE(
		clk,rst,~stallE,flushE,
		{memtoregD,alusrcD,regdstD,regwriteD,alucontrolD,memenD,hilo_weD,cp0_weD,cp0_reD},
		{memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,memenE,hilo_weE,cp0_weE,cp0_reE}
		);
	flopenrc #(5) regM(
		clk,rst,~stallM,flushM,
		{memtoregE,regwriteE,memenE,cp0_weE,cp0_reE},
		{memtoregM,regwriteM,memenM,cp0_weM,cp0_reM}
		);
	flopenrc #(2) regW(
		clk,rst,~stallW,flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule
