`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/08 16:57:33
// Design Name: 
// Module Name: exception
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



module exception(
	input wire rst,
	input wire[7:0] except,
	input wire[4:0] tlb_except2M,
	input wire Trap,CpU,
	input wire adel,ades,
	input wire[31:0] cp0_status,cp0_cause,
	output reg[31:0] excepttype
    );

	always @(*) begin
		if(rst) begin
			/* code */
			excepttype <= 32'b0;
		end else begin 
			if(((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) &&
				 	(cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin
				/* code */
				excepttype <= 32'h00000001;
			end else if(except[7] == 1'b1 || adel) begin
				/* 取址 */
				excepttype <= 32'h00000004;
			end else if(ades) begin
				/* 取址 */
				excepttype <= 32'h00000005;
			end else if(tlb_except2M[4] == 1'b1) begin
				/* inst_tlb_refill_fault */
				excepttype <= 32'h00000010;
			end else if(tlb_except2M[3] == 1'b1) begin
				/* inst_tlb_invalid_fault */
				excepttype <= 32'h00000011;	
			//
			end else if(except[6] == 1'b1) begin
				/* 系统调用指令_sys */
				excepttype <= 32'h00000008;
			end else if(except[5] == 1'b1) begin
				/* 终止指令_break */
				excepttype <= 32'h00000009;
			end else if(except[4] == 1'b1) begin
				/* 特权指令_eret */
				excepttype <= 32'h0000000e;
			end else if(Trap) begin
				/* 内陷指令_trap */
				excepttype <= 32'h0000000d;
			end else if(except[3] == 1'b1) begin
				/* 无效指令_invalid */
				excepttype <= 32'h0000000a;
			end else if(CpU) begin
				/* 协处理器无效CpU */
				excepttype <= 32'h0000000b;
			end else if(except[2] == 1'b1) begin
				/* ov */
				excepttype <= 32'h0000000c;
			end else if(tlb_except2M[2] == 1'b1) begin
				/* inst_tlb_invalid_fault */
				excepttype <= 32'h00000012;
			end else if(tlb_except2M[1] == 1'b1) begin
				/* inst_tlb_invalid_fault */
				excepttype <= 32'h00000013;
			end else if(tlb_except2M[0] == 1'b1) begin
				/* inst_tlb_invalid_fault */
				excepttype <= 32'h00000014;
			end
			else begin
				excepttype <= 32'b0;
			end
		end
	end
	
endmodule

