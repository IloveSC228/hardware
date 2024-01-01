`timescale 1ns / 1ps

module hazard(
	//fetch stage
	output wire stallF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	input wire jumpD,jrD,balD,jalrD,
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
	output wire flushM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW
    );

	wire lwstallD,branchstallD,stall;

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

	//stalls
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = (branchD & regwriteE & (writereg2E == rsD | writereg2E == rtD)) | (branchD & memtoregM & (writeregM == rsD | writeregM == rtD));
	assign jalstallD = (jrD | jalrD) & ((regwriteE & writereg2E == rsD) | (memtoregM & writeregM == rsD)); // 增加jr和jalr的暂停
	assign stall_divE = ((alucontrolE == `DIV_CONTROL | alucontrolE == `DIVU_CONTROL)) & ~ready_oE;
	assign stallF = stallD;
	assign stallD = lwstallD | stall_divE | branchstallD | jalstallD;
	assign stallE = stall_divE;
	// flushs
	assign branchFlushD = branchD & !balD;
	assign flushE = lwstallD | jumpD | jrD | branchFlushD;
endmodule
