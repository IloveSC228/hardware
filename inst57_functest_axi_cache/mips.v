`timescale 1ns / 1ps

module mips(
	input wire clk, rst,
    input wire [5:0] ext_int,
    // inst_ram
    output wire inst_req,
    output wire inst_wr, // 写请求置1
    output wire [1:0] inst_size, // 请求传输字节数
    output wire [31:0] inst_addr, // 请求地址
    output wire [31:0] inst_wdata, // 请求写数据
    input wire inst_addr_ok, // 请求地址传输ok
    input wire inst_data_ok, // 请求数据传输ok
    input wire [31:0] inst_rdata, // 读请求返回数据
    // data_ram
    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata,
    // debug
    output wire [31:0] debug_wb_pc,      
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum, 
    output wire [31:0] debug_wb_rf_wdata
    );
	
	// 取指 f
	wire [31:0] pcF; // 拿出去给instram读指令
	wire [31:0] instrF; // 从instram读取到的指令
	wire inst_en; // instram的使能信号
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
	wire flushM,stallM;
	wire cp0_weM,cp0_reM;
	wire [3:0] memwriteM; // dataram的写信号
	wire memenM; // dataram的使能信号
	wire [31:0] aluoutM,writedataM; // alu的运算结果，dataram的操作地址 / dataram的写数据
    wire [31:0] readdataM;  // dataram读数据
    // 写回 w
	wire memtoregW;
	wire flushW,stallW;
	wire [31:0] pcW;
	wire regwriteW;
    wire [4:0] writeregW;
    wire [31:0] resultW;
	/*--------------------------------sram-----------------------------*/
	// inst_ram
	wire inst_sram_en;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_rdata;
    wire i_stall; // isram正在读写,需要暂停流水线
    wire longest_stall; // 和流水线暂停取或,防止多次停止
	// data_ram
	wire data_sram_en;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_rdata;
    wire [3:0] data_sram_wen;
    wire [31:0] data_sram_wdata;
    wire d_stall;
	// 赋值
	assign inst_sram_en = inst_en;
	assign inst_sram_addr = pcF;
	assign instrF = inst_sram_rdata;
	assign data_sram_en = memenM;
	assign data_sram_addr = aluoutM;
	assign readdataM = data_sram_rdata;
	assign data_sram_wen = memwriteM;
	assign data_sram_wdata = writedataM;
	// debug
    assign	debug_wb_pc			= pcW;
	assign	debug_wb_rf_wen		= {4{regwriteW & ~longest_stall}};
	assign	debug_wb_rf_wnum	= writeregW;
	assign	debug_wb_rf_wdata	= resultW;

	controller c(
	clk,rst,
	//decode stage
	functD,instrD,pcsrcD,branchD,equalD,jumpD,jalD,jrD,balD,jalrD,stallD,invalidD,
	//execute stage
	flushE,stallE,memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_weE,
	//mem stage
	memtoregM,regwriteM,memenM,flushM,stallM,cp0_weM,cp0_reM,
	//write back stage
	memtoregW,regwriteW,flushW,stallW
    );

	datapath dp(
	clk,rst,
	//fetch stage
	pcF,instrF,inst_en,
	//decode stage
	pcsrcD,branchD,jumpD,jalD,jrD,balD,jalrD,equalD,stallD,opD,functD,
	instrD,invalidD,
	//execute stage
	memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_weE,flushE,stallE,
	//mem stage
	memtoregM,regwriteM,aluoutM,writedataM,readdataM,flushM,stallM,memwriteM,cp0_weM,cp0_reM,ext_int,
	//writeback stage
	memtoregW,regwriteW,flushW,stallW,
	// debug
	pcW,writeregW,resultW,
	// stall
	i_stall,d_stall,longest_stall
	);
	
	i_sram2sraml i_sram2sraml(
	clk, rst,
    //sram
    inst_sram_en,inst_sram_addr,inst_sram_rdata,
    i_stall, // isram正在读写,需要暂停流水线
    longest_stall, // 和流水线暂停取或,防止多次停止
    //sram like
    inst_req,inst_wr,inst_size,inst_addr,inst_wdata,
	inst_addr_ok,inst_data_ok,inst_rdata
	);

	d_sram2sraml d_sram2sraml(
	clk, rst,
    //sram
    data_sram_en,data_sram_addr,data_sram_rdata,data_sram_wen,data_sram_wdata,
    d_stall,longest_stall,
    //sram like
    data_req,data_wr,data_size,data_addr,data_wdata,data_rdata,
	data_addr_ok,data_data_ok
	);
endmodule
