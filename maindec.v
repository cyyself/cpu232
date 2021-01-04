`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
module maindec(
	input wire stallD,
	input wire[31:0] instr,
	output wire memtoreg,memwrite,memen,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire LLbit_we,
	output wire[3:0] aluop,
	output wire jal,jr,bal,jalr,
	output wire [1:0] hilo_we,//first for highreg second for lowreg
	output wire cp0we,//cp0writeEnable
	output reg invalid,// invalid instr
	output reg[2:0] tlb_typeD,
	output wire isMoveInstr
    );
	wire [4:0]rt,rs,rd;
	wire [5:0]op,func;
	reg[19:0] controls;
	// wire memen;//useless
	assign op=instr[31:26];
	assign rs=instr[25:21];
	assign rt=instr[20:16];
	assign rd=instr[15:11];
	assign func=instr[5:0];
	assign cp0we=((op==`SPECIAL3_INST)&(rs==`MTC0) )?1:0;

	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,jal,jr,bal,jalr,LLbit_we,aluop,memen,hilo_we,isMoveInstr} = controls;
	always @(*) begin
		invalid = 0;
		controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,4'b0000, 3'b000,1'b0};
		tlb_typeD <= 3'b000;
		if (~stallD) begin
			case (op)
			`R_TYPE:case (func)

				//JR and JALR instrs
				`JR:  controls<=    {12'b0_0_0_0_0_0_0_0_1_0_0_0,`USELESS_OP,3'b000,1'b0};
				`JALR:controls<=    {12'b1_1_0_0_0_0_0_0_0_0_1_0,`USELESS_OP,3'b000,1'b0};

				// data_move instrs
				`MFHI:controls <=   {12'b1_1_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000,1'b0};
				`MFLO:controls <=   {12'b1_1_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000,1'b0};
				`MTHI:controls <=   {12'b0_0_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b010,1'b0};
				`MTLO:controls <=   {12'b0_0_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b001,1'b0};	
				//GPR move instrs
				`MOVZ:controls <= 	{12'b1_1_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000,1'b0};
				`MOVN:controls <= 	{12'b1_1_0_0_0_0_0_0_0_0_0_0,`R_TYPE_OP, 3'b000,1'b0};

				// mul and div instrs
				`MULTU:controls <=  {12'b0_0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011,1'b0};
				`MULT:controls <=   {12'b0_0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011,1'b0};
				`DIVU:controls <=   {12'b0_0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011,1'b0};
				`DIV:controls <=    {12'b0_0_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b011,1'b0};

				// R_TYPE Logic operation instrs
				`AND,`OR,`XOR,`NOR,`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU,`SLL,
				`SRL,`SRA,`SLLV,`SRLV,`SRAV:
					 	controls <= {12'b1_1_0_0_0_0_0_0_0_0_0_0, `R_TYPE_OP, 3'b000,1'b0};

				// Privileged instrs
				`BREAK,`SYSCALL:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP, 3'b000,1'b0};
				`SYNC:controls <= {12'b0_0_0_0_0_0_0_0_0_0_00,`USELESS_OP, 3'b000,1'b0};

				`TEQ,`TGE,`TLT,`TNE,`TGEU,`TLTU: controls <= {12'b0_0_0_0_0_0_0_0_0_0_00,`USELESS_OP, 3'b000,1'b0};

				default:invalid = 1;//illegal instr
				endcase

			`J:controls <=  {12'b0_0_0_0_0_0_1_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`JAL:controls<= {12'b1_0_0_0_0_0_0_1_0_0_0_0,`USELESS_OP,3'b000,1'b0};

			// branch instr
			`BEQ:controls<= {12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BNE:controls<= {12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BGTZ:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BLEZ:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};		
			`BEQL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BNEL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BLEZL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BGTZL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BLTZL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BGEZL:controls<={12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`BLTZALL:controls<={12'b1_0_0_1_0_0_0_0_0_1_0_0,`USELESS_OP,3'b000,1'b0};
			`BGEZALL:controls<={12'b1_0_0_1_0_0_0_0_0_1_0_0,`USELESS_OP,3'b000,1'b0};		
			`REGIMM_INST:case(rt)
				`BLTZ:controls<=  {12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
				`BLTZAL:controls<={12'b1_0_0_1_0_0_0_0_0_1_0_0,`USELESS_OP,3'b000,1'b0};
				`BGEZ:controls <=  {12'b0_0_0_1_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
				`BGEZAL:controls<={12'b1_0_0_1_0_0_0_0_0_1_0_0,`USELESS_OP,3'b000,1'b0};

				`TEQI,`TGEI,`TLTI,`TNEI,`TGEIU,`TLTIU: controls <= {12'b0_0_0_0_0_0_0_0_0_0_00,`USELESS_OP, 3'b000,1'b0};
				default:invalid = 1;//illegal op
				endcase

			//logic instr			
			`ANDI: controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0,`ANDI_OP,   3'b000,1'b0};
			`XORI: controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0,`XORI_OP,   3'b000,1'b0};
			`LUI:  controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0, `LUI_OP,   3'b000,1'b0};
			`ORI:  controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0, `ORI_OP,   3'b000,1'b0};
			`ADDI: controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0,`ADDI_OP,   3'b000,1'b0};
			`ADDIU:controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0, `ADDIU_OP, 3'b000,1'b0};
			`SLTI: controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0, `SLTI_OP,  3'b000,1'b0};
			`SLTIU:controls <= {12'b1_0_1_0_0_0_0_0_0_0_0_0, `SLTIU_OP, 3'b000,1'b0};

			// memory instr
			`LW: controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`SW: controls <= {12'b0_0_1_0_1_0_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`LB:controls <=  {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`LBU:controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`LH:controls <=  {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`LHU:controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`SH:controls <=  {12'b0_0_1_0_1_0_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`SB:controls <=  {12'b0_0_1_0_1_0_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};

			`LWL:controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`LWR:controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`SWL:controls <= {12'b0_0_1_0_1_0_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			`SWR:controls <= {12'b0_0_1_0_1_0_0_0_0_0_0_0,`MEM_OP,3'b100,1'b0};
			
			`CACHE:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			//mfc0 and mtc0
			`COP0:case(rs)
				`MTC0:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`MTC0_OP,    3'b000,1'b0};
				`MFC0:controls <= {12'b1_0_0_0_0_0_0_0_0_0_0_0,`MFC0_OP,    3'b000,1'b0};

				`TLB_ERET_INST:case(func)
					`ERET:controls <= {12'b1_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP, 3'b000,1'b0};
					`TLBP:begin
					  	controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,    3'b000,1'b0};
						tlb_typeD <= 3'b001;
					end
					`TLBR:begin
					  	controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,    3'b000,1'b0};
						tlb_typeD <= 3'b010;
					end
					`TLBWI:begin
					  	controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,    3'b000,1'b0};
						tlb_typeD <= 3'b011;
					end
					`TLBWR:begin
					  	controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,    3'b000,1'b0};
						tlb_typeD <= 3'b100;
					end
					`WAIT:begin
					  	controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,    3'b000,1'b0};
					end
					default: invalid=1;
					endcase
				default: invalid=1;//illegal instrs
				endcase
			`COP1:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`PREF:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`SWC1:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};
			`LWC1:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0,`USELESS_OP,3'b000,1'b0};

			//LL and SC
			`LL: controls <= {12'b1_0_1_0_0_1_0_0_0_0_0_1,`MEM_OP,3'b100,1'b0};
			`SC: controls <= {12'b1_0_1_0_1_0_0_0_0_0_0_1,`MEM_OP,3'b100,1'b0};

			//CLO and CLZ
			`SPECIAL2_INST_OP:case(func)
					`CLO: controls <= {12'b1_1_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b000,1'b0};
					`CLZ: controls <= {12'b1_1_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b000,1'b0};
					`MADD 	:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b011,1'b0}; 	
					`MADDU	:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b011,1'b0};	 
					`MUL 	:controls <= {12'b1_1_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b000,1'b0};	
					`MSUB 	:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b011,1'b0};	
					`MSUBU	:controls <= {12'b0_0_0_0_0_0_0_0_0_0_0_0, `SPECIAL2_OP, 3'b011,1'b0};	


					default:invalid = 1;
				endcase

			default: invalid=1;
			endcase
		end
		
	end
endmodule