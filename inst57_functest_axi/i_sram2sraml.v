module i_sram2sraml (
    input wire clk, rst,
    //sram
    input wire inst_sram_en,
    input wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_rdata,
    output wire i_stall, // isram正在读写,需要暂停流水线
    input wire longest_stall, // 和流水线暂停取或,防止多次停止
    //sram like
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata
);
    reg addr_rcv; //地址握手成功
    reg do_finish; //读事务结束,也代表数据握手成功

    always @(posedge clk) begin
        if (rst)
            addr_rcv <= 1'b0;
        //保证先inst_req再addr_rcv；如果addr_ok同时data_ok，则优先data_ok
        else if (inst_req & inst_addr_ok & ~inst_data_ok) 
            addr_rcv <= 1'b1;
        else if (inst_data_ok)
            addr_rcv <= 1'b0;
        else 
            addr_rcv <= addr_rcv;
    end

    always @(posedge clk) begin
        if (rst)
            do_finish <= 1'b0;
        else if (inst_data_ok)
            do_finish <= 1'b1;
        else if (~longest_stall)
            do_finish <= 1'b0;
        else 
            do_finish <= do_finish;
    end

    //save rdata
    reg [31:0] inst_rdata_save;
    always @(posedge clk) begin
        if (rst)
            inst_rdata_save <= 32'b0;
        else if (inst_data_ok)
            inst_rdata_save <= inst_rdata;
        else
            inst_rdata_save <= inst_rdata_save;
    end

    //sram like
    // 指令读请求应一直置1，当握手成功和传回数据时不置1
    assign inst_req = inst_sram_en & ~addr_rcv & ~do_finish; 
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    //sram
    assign inst_sram_rdata = inst_rdata_save; // 将sraml收到的instdata返回流水线
    assign i_stall = inst_sram_en & ~do_finish;
endmodule