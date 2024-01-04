`timescale 1ns / 1ps

module pc #(parameter WIDTH = 32)(
	input wire clk,rst,en,
	input wire clear,
	input wire [WIDTH-1:0] d,
	input wire [WIDTH-1:0] newPC,
	output reg [WIDTH-1:0] q,
	output reg ce
    );
	always @(posedge clk) begin
		if(!ce) begin
			q <= 32'hbfc00000;
		end 
		else if (clear) begin
			q <= newPC;
		end	
		else if(en) begin
			q <= d;
		end
	end
	always @(posedge clk) begin
		if (rst)
			ce <= 1'b0;
		else
			ce <= 1'b1;
	end
endmodule