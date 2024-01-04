`timescale 1ns / 1ps

module hilo_reg(
	input wire clk,rst,flushE,
	input wire [1:0] we,
	input wire [31:0] hi_i,lo_i,
	output wire [31:0] hi_o,lo_o
    );
	
	reg [31:0] hi, lo;
	always @(posedge clk) begin
		if(rst) begin
			hi <= 0;
			lo <= 0;
		end else if (~flushE) begin
			if (we > 2'b00) begin
				hi <= (we[1]) ? hi_i : hi;
				lo <= (we[0]) ? lo_i : lo;
			end
		end
	end

	assign hi_o = hi;
	assign lo_o = lo;
endmodule
