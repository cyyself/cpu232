`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.h"

module hazard(
	//fetch stage
	output wire stallF,
	output wire flushF,
	//decode stage
	output flushD,
	input wire[5:0] opD,
	input wire[4:0] rsD,rtD,
	input wire jrD,
	input wire jalrD,
	input wire branchD,
	output wire[1:0] forwardaD,forwardbD,
	output wire stallD,
	input wire invalidD,
	input wire branch_likely,
	//execute stage
	input wire[4:0] alucontrolE,
	input wire[4:0] rsE,rtE,
	input wire[4:0] rdE,
	input wire[4:0] writereg2E,
	input wire regwriteE,
	input wire memtoregE,
	input wire [1:0] hilo_weE,
	output wire[1:0] forwardaE,forwardbE,
	output wire[1:0] forwardhiloE,
	output wire forwardcp0E,
	output wire flushE,
	output wire stallE,
	output wire div_start,
	input wire div_ready,//start and ready should exchange
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	input wire [1:0] hilo_weM,
	output wire stallM,flushM,
	input wire [5:0] opM,
	input wire cp0weM,
	input wire [4:0] rdM,
	input wire [31:0] excepttypeM,
	input wire [31:0] cp0_epcM,
	output reg [31:0] newpcM,
	input wire [31:0] ebaseM,
	input wire BEV,
	//need to add flushM

	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input wire [1:0] hilo_weW,
	output wire flushW,
	input wire stallreq_from_if,stallreq_from_mem,
	input wire LLbit_o
    );

	wire lwstallD,flush_except;

	assign div_start = (alucontrolE == `DIV_CONTROL && div_ready == 1'b0)?1'b1:
				   (alucontrolE == `DIV_CONTROL && div_ready == 1'b1)?1'b0:
				   (alucontrolE == `DIVU_CONTROL && div_ready == 1'b0)?1'b1:
				   (alucontrolE == `DIVU_CONTROL && div_ready == 1'b1)?1'b0:
			       1'b0;

	assign #1 lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	
	assign stallF = lwstallD | div_start | stallreq_from_if | stallreq_from_mem;
	assign stallD = lwstallD | div_start | stallreq_from_if | stallreq_from_mem;
	assign stallE = div_start | stallreq_from_mem;		       
	assign stallM = stallreq_from_mem;
		//stalling D stalls all previous stages

	assign flush_except = (excepttypeM != 32'b0);

	assign flushF = flush_except;
	assign flushD = flush_except | branch_likely ;
	assign flushE = lwstallD | flush_except;
	assign flushM = flush_except;
	assign flushW = flush_except | stallreq_from_mem;
	//stalling D flushes next stage
	//forwarding sources to D stage (branch equality)

	assign forwardaD =	(rsD==0)? 2'b00:
						(rsD == writereg2E & regwriteE)?2'b01:
						(rsD == writeregM & regwriteM)?2'b10:
						(rsD == writeregW & regwriteW)?2'b11:2'b00;
	assign forwardbD =	(rtD==0)?2'b00:
						(rtD == writereg2E & regwriteE)?2'b01:
						(rtD == writeregM & regwriteM)?2'b10:
						(rtD == writeregW & regwriteW)?2'b11:2'b00;

	assign forwardaE =	(rsE==0)?2'b00:
						(rsE == writeregM & regwriteM)?2'b10:
						(rsE == writeregW & regwriteW)?2'b01:2'b00;
	assign forwardbE =	(rtE==0)?2'b00:
						(rtE == writeregM & regwriteM)?2'b10:
						(rtE == writeregW & regwriteW)?2'b01:2'b00;

	assign forwardhiloE =	(hilo_weE==2'b00 & (hilo_weM==2'b10 | hilo_weM==2'b01 | hilo_weM==2'b11))?2'b01:
							(hilo_weE==2'b00 & (hilo_weW==2'b10 | hilo_weW==2'b01 | hilo_weW==2'b11))?2'b10:
							2'b00;

	assign forwardcp0E = ((rdE!=0)&(rdE == rdM)&(cp0weM))?1'b1:1'b0;

	//CP0 ->bfc00380
  	always @(*) begin
		if(excepttypeM != 32'b0) begin
			/* code */
			if(BEV)begin
			  	case (excepttypeM)
					32'h00000010,32'h00000012: begin
						newpcM <= 32'hBFC00200;
					end
					32'h0000000e :begin
						newpcM <= cp0_epcM;
					end
					default: newpcM <= 32'hBFC00380;
			  	endcase
			end
			else begin
				case (excepttypeM)
					32'h00000010,32'h00000012: begin
						newpcM <= {ebaseM[31:12],12'h000};
					end
					32'h0000000e :begin
						newpcM <= cp0_epcM;
					end
					default: newpcM <= {ebaseM[31:12],12'h000} + 32'h00000180;
				endcase
			end
		end
  	end

endmodule
