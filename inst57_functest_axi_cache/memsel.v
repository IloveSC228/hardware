`timescale 1ns / 1ps

module memsel (
    input wire [31:0] pcM,
    input wire [5:0] opM,
    input wire [31:0] addr, // 读写地址，末两位决定写哪个字节或是高低位
    input wire [31:0] writedataM, // 从执行阶段传递过来的写ram值，在这里进行修改
    output reg [3:0] memwriteM,
    output reg [31:0] writedata2M, // 经过字节半字处理的写入ram的值
    input wire [31:0] readdataM,
    output reg [31:0] readdata2M,
    output reg [31:0] bad_addr, // 返回错误地址
    output reg adelM, adesM, // 分别是lw和sw的错误
    output reg [1:0] size
);
    always @(*) begin
        bad_addr = pcM;
        adesM = 1'b0;
        adelM = 1'b0;
        case (opM)
            `SW: begin
                if (addr[1:0] != 2'b00) begin
                    adesM = 1'b1;
                    bad_addr = addr;
                    memwriteM = 4'b0000;
                end
                else begin
                    memwriteM = 4'b1111;
                    writedata2M = writedataM;
                end
                
            end
            `SH: begin 
                if (addr[1:0] != 2'b00 && addr[1:0] != 2'b10) begin
                    adesM = 1'b1;
                    bad_addr = addr;
                    memwriteM = 4'b0000;
                end 
                else begin
                    writedata2M = {2{writedataM[15:0]}};
                    case (addr[1:0])
                    2'b00: memwriteM = 4'b0011;
                    2'b10: memwriteM = 4'b1100;
                    default: begin
                        memwriteM = 4'b0000;
                        writedata2M = writedataM;
                    end 
                    endcase
                end
            end
            `SB: begin
                writedata2M = {4{writedataM[7:0]}};
                case (addr[1:0])
                2'b00: memwriteM = 4'b0001;
                2'b01: memwriteM = 4'b0010;
                2'b10: memwriteM = 4'b0100;
                2'b11: memwriteM = 4'b1000;
                default: begin
                    memwriteM = 4'b0000;
                    writedata2M = writedataM;
                end 
                endcase
            end
            `LW: begin
                memwriteM = 4'b0000;
                size = 2'b10;
                if (addr[1:0] != 2'b00) begin
                    adelM = 1'b1;
                    bad_addr = addr;
                    readdata2M = 32'b0;
                end
                else begin
                    readdata2M = readdataM;
                end
            end
            `LB: begin
                memwriteM = 4'b0000;
                case (addr[1:0])
                2'b00: readdata2M = {{24{readdataM[7]}},readdataM[7:0]};
                2'b01: readdata2M = {{24{readdataM[15]}},readdataM[15:8]};
                2'b10: readdata2M = {{24{readdataM[23]}},readdataM[23:16]};
                2'b11: readdata2M = {{24{readdataM[31]}},readdataM[31:24]};
                default: readdata2M = readdataM;
                endcase
            end
            `LBU: begin
                memwriteM = 4'b0000;
                case (addr[1:0])
                2'b00: readdata2M = {{24{1'b0}},readdataM[7:0]};
                2'b01: readdata2M = {{24{1'b0}},readdataM[15:8]};
                2'b10: readdata2M = {{24{1'b0}},readdataM[23:16]};
                2'b11: readdata2M = {{24{1'b0}},readdataM[31:24]};
                default: readdata2M = readdataM;
                endcase
            end
            `LH: begin
                memwriteM = 4'b0000;
                if (addr[1:0] != 2'b00 && addr[1:0] != 2'b10) begin
                    adelM = 1'b1;
                    bad_addr = addr;
                end
                else begin
                    case (addr[1:0])
                    2'b00: readdata2M = {{16{readdataM[15]}},readdataM[15:0]};
                    2'b10: readdata2M = {{16{readdataM[31]}},readdataM[31:16]};
                    default: readdata2M = readdataM;
                    endcase
                end
            end
            `LHU: begin
                memwriteM = 4'b0000;
                if (addr[1:0] != 2'b00 && addr[1:0] != 2'b10) begin
                    adelM = 1'b1;
                    bad_addr = addr;
                end
                else begin
                    case (addr[1:0])
                    2'b00: readdata2M = {{16{1'b0}},readdataM[15:0]};
                    2'b10: readdata2M = {{16{1'b0}},readdataM[31:16]};
                    default: readdata2M = readdataM;
                    endcase
                end
            end
            default: begin
                memwriteM = 4'b0000;
                writedata2M = writedataM;
                readdata2M = readdataM;
            end 
        endcase
    end
endmodule