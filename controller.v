`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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

module controller(
	input wire clk,rst,

	//decode stage
	input wire[31:0] instrD,
	input wire equalD,stallD,
	output wire pcsrcD,branchD,branch_likely,jumpD,
	output wire jalD,jrD,balD,jalrD,
	output wire[7:0] alucontrolD,
	output wire [1:0] hilo_weD,
	output wire invalidD,

	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,

	//mem stage
	output wire memtoregM,memwriteM,memenM,regwriteM,cp0weM,
	input wire stallM,flushM,	
	output wire[2:0] tlb_typeM,
	input wire[5:0] opM,

	//write back stage
	output wire memtoregW,regwriteW,
	input wire flushW,
	output wire LLbit_weW,
	input wire LLbit_o
    );
	
	//decode stage
	wire[3:0] aluopD;
	wire [5:0] funcD;
	wire [4:0] rsD;
	wire [2:0] tlb_typeD;
	wire memtoregD,memwriteD,memenD,alusrcD,regdstD,regwriteD,cp0weD;
	wire LLbit_weD,LLbit_weE,LLbit_weM;
	wire regwrite2D;
	wire isMoveInstr;
	wire memwriteMll;
	assign funcD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign regwrite2D = ~regwriteD ? 0:
						~isMoveInstr ? 1 :
						equalD ;

	//execute stage
	wire memwriteE,memenE,cp0weE;
	wire[2:0] tlb_typeE;

	maindec md(
		stallD,
		instrD,
		memtoregD,memwriteD,memenD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		LLbit_weD,
		aluopD,
		jalD,
		jrD,
		balD,
		jalrD,
		hilo_weD,
		cp0weD,
		invalidD,
		tlb_typeD,
		isMoveInstr
		);
	aludec ad(stallD,funcD,aluopD,rsD,alucontrolD);

	//judge branch instrs whther should execute
	assign pcsrcD = branchD & equalD;
	assign branch_likely =  equalD ? 0 :
							(instrD[31:26]==`BEQL)  ? 1 :
							(instrD[31:26]==`BNEL)  ? 1 :
							(instrD[31:26]==`BLEZL) ? 1 :
							(instrD[31:26]==`BGTZL) ? 1 : 
							(instrD[31:26]==`REGIMM_INST && instrD[20:16]==`BLTZL)  ? 1 :
							(instrD[31:26]==`REGIMM_INST && instrD[20:16]==`BGEZL)  ? 1 :
							(instrD[31:26]==`REGIMM_INST && instrD[20:16]==`BLTZALL) ? 1 :
							(instrD[31:26]==`REGIMM_INST && instrD[20:16]==`BGEZALL) ? 1 : 0;

	//pipeline registers 
	//
	//use the pipeline spread the signal
	//
	//stall and flush in Fetch and Decode stages only used in datapath to stall and flush  
	flopenrc #(12) regE(
		clk,
		rst,~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwrite2D,cp0weD,memenD,tlb_typeD,LLbit_weD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,cp0weE,memenE,tlb_typeE,LLbit_weE}
		);
	flopenrc #(9) regM(
		clk,rst,~stallM,flushM,
		{memtoregE,memwriteE,regwriteE,cp0weE,memenE,tlb_typeE,LLbit_weE},
		{memtoregM,memwriteMll,regwriteM,cp0weM,memenM,tlb_typeM,LLbit_weM}
		);
	assign memwriteM = (opM == `SC) ? ((LLbit_o) ? 1:0) : memwriteMll;


	flopenrc #(3) regW(
		clk,rst,1'b1,flushW,
		{memtoregM,regwriteM,LLbit_weM},
		{memtoregW,regwriteW,LLbit_weW}
		);
endmodule
