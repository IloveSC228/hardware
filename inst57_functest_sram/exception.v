`timescale 1ns / 1ps

module exception(
	input wire rst,
	input wire [7:0] exceptM,
	input wire adelM, adesM,
	input wire [31:0] cp0_status,cp0_cause,
	output reg [31:0] excepttype
    );

	always @(*) begin
        if (rst) begin
			excepttype <= 32'b0;
		end
		else begin
			excepttype <= 32'b0;
			// 软件中断
			if (((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) && 
			(cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin
				excepttype <= 32'h00000001;
			end
			else if (exceptM[7] == 1'b1 || adelM)
				excepttype <= 32'h00000004;
			else if (adesM)
				excepttype <= 32'h00000005;
			else if (exceptM[6] == 1'b1)
				excepttype <= 32'h00000008;
			else if (exceptM[5] == 1'b1)
				excepttype <= 32'h00000009;
			else if (exceptM[4] == 1'b1)
				excepttype <= 32'h0000000e;
			else if (exceptM[3] == 1'b1)
				excepttype <= 32'h0000000a;
			else if (exceptM[2] == 1'b1)
				excepttype <= 32'h0000000c;
		end
    end
endmodule