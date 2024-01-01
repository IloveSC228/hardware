`timescale 1ns / 1ps

module lwdec (
    input wire [5:0] opW,
    input wire [31:0] readdataW,aluoutW,
    output reg [31:0] readdata2W
);
    always @(*) begin
        case (opW)
            `LW: readdata2W = readdataW;
            `LB: case (aluoutW[1:0])
                2'b00: readdata2W = {{24{readdataW[7]}},readdataW[7:0]};
                2'b01: readdata2W = {{24{readdataW[15]}},readdataW[15:8]};
                2'b10: readdata2W = {{24{readdataW[23]}},readdataW[23:16]};
                2'b11: readdata2W = {{24{readdataW[31]}},readdataW[31:24]};
                default: readdata2W = readdataW;
            endcase
            `LBU: case (aluoutW[1:0])
                2'b00: readdata2W = {{24{1'b0}},readdataW[7:0]};
                2'b01: readdata2W = {{24{1'b0}},readdataW[15:8]};
                2'b10: readdata2W = {{24{1'b0}},readdataW[23:16]};
                2'b11: readdata2W = {{24{1'b0}},readdataW[31:24]};
                default: readdata2W = readdataW;
            endcase
            `LH: case (aluoutW[1:0])
                2'b00: readdata2W = {{16{readdataW[15]}},readdataW[15:0]};
                2'b10: readdata2W = {{16{readdataW[31]}},readdataW[31:16]};
                default: readdata2W = readdataW;
            endcase
            `LHU: case (aluoutW[1:0])
                2'b00: readdata2W = {{16{1'b0}},readdataW[15:0]};
                2'b10: readdata2W = {{16{1'b0}},readdataW[31:16]};
                default: readdata2W = readdataW;
            endcase
            default: readdata2W = readdataW;
        endcase        
    end
endmodule