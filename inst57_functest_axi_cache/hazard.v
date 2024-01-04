`timescale 1ns / 1ps

module hazard(
	//fetch stage
	output wire stallF,flushF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	input wire jumpD,jrD,balD,jalrD,
	output wire flushD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writereg2E,alucontrolE,
	input wire regwriteE,
	input wire memtoregE,
	input wire ready_oE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushE,stallE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire flushM,stallM,
	input wire [31:0] excepttype, epc_o,
	output reg [31:0] newPC,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire flushW,stallW,
	// sram
	input wire i_stall, d_stall,
	output wire longest_stall
    );

	wire lwstallD,branchstallD,jrstallD,stall_divE,flush_except;

	//forwarding sources to D stage (branch equality,jal,jalr,bal)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	//forwarding sources to E stage (ALU)
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = (branchD & regwriteE & (writereg2E == rsD | writereg2E == rtD)) | (branchD & memtoregM & (writeregM == rsD | writeregM == rtD));
	assign jrstallD = (jrD | jalrD) & ((regwriteE & writereg2E == rsD) | (memtoregM & writeregM == rsD)); // 增加jr和jalr的暂停
	assign stall_divE = ((alucontrolE == `DIV_CONTROL | alucontrolE == `DIVU_CONTROL)) & ~ready_oE;
	assign flush_except = (excepttype != 32'h00000000);
	//stalls
	assign longest_stall = i_stall | d_stall | stall_divE;
	assign stallF = stallD;
	assign stallD = longest_stall | lwstallD | branchstallD | jrstallD;
	assign stallE = longest_stall;
	assign stallM = longest_stall;
	assign stallW = longest_stall;
	// flushs
	assign flushF = flush_except;
	assign flushD = flush_except;
	assign flushE = (lwstallD & ~longest_stall) | (branchstallD & ~longest_stall) | flush_except;
	assign flushM = flush_except;
	assign flushW = flush_except & ~longest_stall;

	// cp0->bfc00380
	always @(*) begin
		if (excepttype != 32'h00000000) begin
			case (excepttype)
				32'h00000001: newPC = 32'hbfc00380;
				32'h00000004: newPC = 32'hbfc00380;
				32'h00000005: newPC = 32'hbfc00380;
				32'h00000008: newPC = 32'hbfc00380;
				32'h00000009: newPC = 32'hbfc00380;
				32'h0000000a: newPC = 32'hbfc00380;
				32'h0000000c: newPC = 32'hbfc00380;
				32'h0000000e: newPC = epc_o;
				default: ;
			endcase
		end
	end
endmodule
