module mycpu_top(
    input [5:0] ext_int,   //high active

    input wire aclk, // AXI时钟
    input wire aresetn,   // AXI复位，低电平有效
    // 读地址请求通道,ar开头
    output wire [3:0] arid, 
    output wire [31:0] araddr, // 读请求地址
    output wire [7:0] arlen,
    output wire [2:0] arsize, // 请求传输大小-字节数
    output wire [1:0] arburst,
    output wire [1:0] arlock,
    output wire [3:0] arcache,
    output wire [2:0] arprot,
    output wire arvalid, // 读请求地址握手信号,读请求地址有效
    input wire arready, // 读请求地址握手信号,slave端准备接受地址传输
    // 读请求数据通道,以r开头            
    input wire [3:0] rid,
    input wire [31:0] rdata, // 读请求读回数据
    input wire [1:0] rresp,
    input wire rlast,
    input wire rvalid, // 读请求数据握手信号,读请求数据有效
    output wire rready, // 读请求数据握手信号,master端准备接受数据传输
    // 写请求地址通道,aw开头        
    output wire [3:0] awid,
    output wire [31:0] awaddr, // 写请求地址
    output wire [7:0] awlen,
    output wire [2:0] awsize, // 请求传输大小-字节数
    output wire [1:0] awburst,
    output wire [1:0] awlock,
    output wire [3:0] awcache,
    output wire [2:0] awprot,
    output wire awvalid, // 写请求地址握手信号,写请求地址有效
    input wire awready, // 写请求地址握手信号,slave端准备接受地址传输
    // 写请求数据通道,以w开头
    output wire [3:0] wid,
    output wire [31:0] wdata, // 写请求写数据
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid, // 写请求数据握手信号,写请求数据有效
    input wire wready, // 写请求数据握手信号,slave端准备接受数据传输
    // 写请求响应通道,以b开头
    input wire [3:0] bid,
    input wire [1:0] bresp,
    input wire bvalid, // 写请求响应握手信号,写请求响应有效
    output wire bready, // 写请求响应握手信号,master端准备接受写响应
    //debug interface
    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire clk, rst;
    assign clk = aclk;
    assign rst = ~aresetn;
    // inst_ram
    wire cpu_inst_req;
    wire cpu_inst_wr;
    wire [1:0] cpu_inst_size;
    wire [31:0] cpu_inst_addr;
    wire [31:0] cpu_inst_wdata;
    wire cpu_inst_addr_ok;
    wire cpu_inst_data_ok;
    wire [31:0] cpu_inst_rdata;
    // data_ram
    wire cpu_data_req;
    wire cpu_data_wr;
    wire [1:0] cpu_data_size;
    wire [31:0] cpu_data_addr;
    wire [31:0] cpu_data_wdata;
    wire cpu_data_addr_ok;
    wire cpu_data_data_ok;
    wire [31:0] cpu_data_rdata;
    // mmu
    wire [31:0] cpu_inst_paddr;
    wire [31:0] cpu_data_paddr;
    wire no_dcache;
    // 实例化
    mips mips(
        .clk(clk),
        .rst(rst),
        .ext_int(ext_int),
        // inst_ram
        .inst_req(cpu_inst_req),
        .inst_wr(cpu_inst_wr),
        .inst_size(cpu_inst_size),
        .inst_addr(cpu_inst_addr),
        .inst_wdata(cpu_inst_wdata),
        .inst_addr_ok(cpu_inst_addr_ok),
        .inst_data_ok(cpu_inst_data_ok),
        .inst_rdata(cpu_inst_rdata),
        // data_ram
        .data_req(cpu_data_req),
        .data_wr(cpu_data_wr),
        .data_size(cpu_data_size),
        .data_addr(cpu_data_addr),
        .data_wdata(cpu_data_wdata),
        .data_addr_ok(cpu_data_addr_ok),
        .data_data_ok(cpu_data_data_ok),
        .data_rdata(cpu_data_rdata),
        // debug
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );
    mmu m(
    .inst_vaddr(cpu_inst_addr),
    .inst_paddr(cpu_inst_paddr),
    .data_vaddr(cpu_data_addr),
    .data_paddr(cpu_data_paddr),
    .no_dcache(no_dcache)    //是否经过d cache
    );
    cpu_axi_interface cpu_axi_interface(
        .clk(clk),
        .resetn(~rst), 
        //inst sram-like 
        .inst_req(cpu_inst_req),
        .inst_wr(cpu_inst_wr),
        .inst_size(cpu_inst_size),
        .inst_addr(cpu_inst_paddr),
        .inst_wdata(cpu_inst_wdata),
        .inst_rdata(cpu_inst_rdata),
        .inst_addr_ok(cpu_inst_addr_ok),
        .inst_data_ok(cpu_inst_data_ok), 
        //data sram-like 
        .data_req(cpu_data_req),
        .data_wr(cpu_data_wr),
        .data_size(cpu_data_size),
        .data_addr(cpu_data_paddr),
        .data_wdata(cpu_data_wdata),
        .data_rdata(cpu_data_rdata),
        .data_addr_ok(cpu_data_addr_ok),
        .data_data_ok(cpu_data_data_ok),
        //axi
        //ar
        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arlock(arlock),
        .arcache(arcache),
        .arprot(arprot),
        .arvalid(arvalid),
        .arready(arready),
        //r           
        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready),
        //aw          
        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awlock(awlock),
        .awcache(awcache),
        .awprot(awprot),
        .awvalid(awvalid),
        .awready(awready),
        //w          
        .wid(wid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),
        //b           
        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)       
    );
endmodule