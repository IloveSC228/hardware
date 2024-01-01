`timescale 1ns / 1ps

module pc #(parameter WIDTH = 8)(
	input wire clk,rst,en,
	input wire clear,
	input wire [WIDTH-1:0] d,
	input wire [WIDTH-1:0] newPC,
	output reg [WIDTH-1:0] q
    );
	always @(posedge clk,posedge rst) begin
		if(rst) begin
			q <= 32'hbfc00000;
		end 
		else if (clear) begin
			q <= newPC;
		end	
		else if(en) begin
			q <= d;
		end
	end
endmodule