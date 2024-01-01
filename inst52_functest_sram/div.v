`include "defines2.vh"

module div(
	input wire clk,
	input wire rst,
	input wire [4:0] alucontrolE,
	input wire [31:0] opdata1_i,
	input wire [31:0] opdata2_i,
	input wire start_i,
	input wire annul_i, // 中断除法信号
	output reg [63:0] result_o,
	output reg ready_o
);

	wire [32:0] div_temp;
	reg [5:0] cnt;
	reg [64:0] dividend;
	reg [1:0] state;
	reg [31:0] divisor;	 
	reg [31:0] temp_op1, temp_op2;
	reg [31:0] temp1_op1, temp1_op2; // 存储最初的运算数，因为结果算出时opdata_i会被修改
	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end else begin
		  case (state)
		  	// 除法模块空闲，可以执行除法
		  	`DivFree: begin //DivFree
		  		if(start_i == `DivStart && annul_i == 1'b0) begin
		  			if(opdata2_i == `ZeroWord) begin
		  				state <= `DivByZero;
		  			end 
					else begin
		  				state <= `DivOn; //状态切换为除法运算进行中
		  				cnt <= 6'b000000; //开始计数
						//被除数为负
		  				if(alucontrolE == `DIV_CONTROL && opdata1_i[31] == 1'b1) begin 
		  					temp_op1 = ~opdata1_i + 1;
		  				end else begin
		  					temp_op1 = opdata1_i;
		  				end
						//除数为负
		  				if(alucontrolE == `DIV_CONTROL && opdata2_i[31] == 1'b1) begin
		  					temp_op2 = ~opdata2_i + 1;
		  				end else begin
		  					temp_op2 = opdata2_i;
		  				end
		  				dividend <= {`ZeroWord,`ZeroWord};
              	dividend[32:1] <= temp_op1;
              	divisor <= temp_op2;
			  	temp1_op1 <= opdata1_i;
				temp1_op2 <= opdata2_i; // 在执行开始前将运算数存起来
             end
          end else begin
				ready_o <= `DivResultNotReady;
				result_o <= {`ZeroWord,`ZeroWord};
				end          	
		  	end
		  	`DivByZero: begin //DivByZero
         	dividend <= {`ZeroWord,`ZeroWord};
          state <= `DivEnd;		 		
		  	end
		  	`DivOn:	begin //DivOn
		  		if(annul_i == 1'b0) begin
		  			if(cnt != 6'b100000) begin
               			if(div_temp[32] == 1'b1) begin
                  			dividend <= {dividend[63:0] , 1'b0};
               			end 
						else begin
                  			dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
               			end
               				cnt <= cnt + 1;
             			end 
					else begin
               			if((alucontrolE == `DIV_CONTROL) && ((temp1_op1[31] ^ temp1_op2[31]) == 1'b1)) begin
                  			dividend[31:0] <= (~dividend[31:0] + 1);
               			end
               			if((alucontrolE == `DIV_CONTROL) && ((temp1_op1[31] ^ dividend[64]) == 1'b1)) begin              
                  			dividend[64:33] <= (~dividend[64:33] + 1);
               			end
               			state <= `DivEnd;
               			cnt <= 6'b000000;            	
             		end
		  		end 
				else begin
		  			state <= `DivFree;
		  		end	
		  	end
		  	`DivEnd: begin //DivEnd
        		result_o <= {dividend[64:33], dividend[31:0]};  
          		ready_o <= `DivResultReady;
          		if(start_i == `DivStop) begin
          			state <= `DivFree;
					ready_o <= `DivResultNotReady;
					result_o <= {`ZeroWord,`ZeroWord};       	
          		end		  	
		  	end
		  endcase
		end
	end

endmodule