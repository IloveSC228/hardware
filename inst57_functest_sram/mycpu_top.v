module mycpu_top(
    input clk,
    input resetn,  //low active
    input wire [5:0] ext_int,
    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug信号
	output wire [31:0] debug_wb_pc,
	output wire [3:0] debug_wb_rf_wen,
	output wire [4:0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata
);
	wire [31:0] pcF, instrF, instpaddr;
    wire memenM;
	wire [3:0] memwriteM;
	wire [31:0] aluoutM, writedataM, readdataM, datapaddr;
    wire [31:0] pcW;
    wire regwriteW;
    wire [4:0] writeregW;
    wire [31:0] resultW;
    wire nodcache;
    mips mips(
        .clk(~clk),
        .rst(~resetn),
        //instr
        // .inst_en(inst_en),
        .pcF(pcF),                    //pcF
        .instrF(instrF),              //instrF
        .memwriteM(memwriteM),
        .memenM(memenM),
        .aluoutM(aluoutM),
        .writedataM(writedataM),
        .readdataM(readdataM),
        .pcW(pcW),
        .regwriteW(regwriteW),
        .writeregW(writeregW),
        .resultW(resultW)
    );
    mmu m(
    .inst_vaddr(pcF),
    .inst_paddr(instpaddr),
    .data_vaddr(aluoutM),
    .data_paddr(datapaddr),
    .no_dcache(nodcache)    //是否经过d cache
    );
    assign inst_sram_en = 1'b1;     //如果有inst_en，就用inst_en
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = instpaddr;
    assign inst_sram_wdata = 32'b0;
    assign instrF = inst_sram_rdata;

    assign data_sram_en = memenM;     //如果有data_en，就用data_en
    assign data_sram_wen = memwriteM;
    assign data_sram_addr = datapaddr;
    assign data_sram_wdata = writedataM;
    assign readdataM = data_sram_rdata;

    assign	debug_wb_pc			= pcW;
	assign	debug_wb_rf_wen		= {4{regwriteW}};
	assign	debug_wb_rf_wnum	= writeregW;
	assign	debug_wb_rf_wdata	= resultW;

    //ascii
    instdec instdec(
        .instr(instrF)
    );

endmodule