`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 22:57:01
// Design Name: 
// Module Name: eqcmp
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
module eqcmp(
	input wire [31:0] a,b,
	input wire [31:0] instrD,
	output reg y,
	output wire Trap
    );
	wire [5:0] op;
	wire [4:0] rt;
	wire [31:0] signedExtendImm;
	assign signedExtendImm = {{16{instrD[15]}},instrD[15:0]};
	assign op = instrD[31:26];
	assign rt = instrD[20:16];

	wire aEb,aGEb,aGTb,aGTbU,aGEbU;
	assign aEb = (a==b) ? 1 :0;
	assign aGTb = ($signed(a)>$signed(b)) ? 1 : 0;
	assign aGEb = aEb | aGTb ;
	assign aGTbU = (a)>(b) ? 1 : 0;
	assign aGEbU = aEb | aGTbU ;

	wire aEimm,aGEimm,aGTimm,aGTimmU,aGEimmU;
	assign aEimm = (a==signedExtendImm) ? 1 :0;
	assign aGTimm = ($signed(a)>$signed(signedExtendImm)) ? 1 : 0;
	assign aGEimm = aEimm | aGTimm ;
	assign aGTimmU = (a)>(signedExtendImm) ? 1 : 0;
	assign aGEimmU = aEimm | aGTimmU ;

	always@(*) begin
		case(op)
			`BEQ,`BEQL:y <=  aEb  ;
			`BNE,`BNEL:y <=  !aEb ;
			`BGTZ,`BGTZL:y <= (a[31] == 0 && a != 32'b0) ? 1: 0;
			`BLEZ,`BLEZL:y <= (a[31] == 1 || a == 32'b0) ? 1: 0;
			`REGIMM_INST:case(rt)
							`BLTZ,`BLTZL:y <= (a[31] == 1) ? 1: 0;
							`BLTZAL,`BLTZALL:y <= (a[31] == 1) ? 1: 0;
							`BGEZ,`BGEZL:y <= (a[31] == 0) ? 1: 0;
							`BGEZAL,`BGEZALL:y <= (a[31] == 0) ? 1: 0;
							`TEQI:  y<= aEimm;
							`TGEI: y<= aGEimm ;
							`TLTI: y<= !aGEimm;
							`TNEI: y<= !aEimm;
							`TGEIU: y<= aGEimmU;
							`TLTIU: y<= !aGEimmU;
							default:y <= 0;
						 endcase
			`R_TYPE: case(instrD[5:0])
					`MOVN: y<= (b != 32'b0) ? 1 : 0;
					`MOVZ: y<= (b == 32'b0) ? 1 : 0;
					`TEQ:  y<= aEb;
					`TGE: y<= aGEb ;
					`TLT: y<= !aGEb;
					`TNE: y<= !aEb;
					`TGEU: y<= aGEbU;
					`TLTU: y<= !aGEbU;
					default:y <= 0;
			endcase
			default:y<=0;
		endcase
	end

	reg isTrap;
	always@(*) begin
		case(op)
			`REGIMM_INST:
			case(rt)
				`TEQI,`TGEI,`TLTI,`TNEI,`TGEIU,`TLTIU: isTrap<= 1'b1;
				default:isTrap <= 1'b0;
			endcase
			`R_TYPE: 
			case(instrD[5:0])
				`TEQ,`TGE,`TLT,`TNE,`TGEU,`TLTU: isTrap<= 1'b1;
				default:isTrap <= 1'b0;
			endcase
			default:isTrap<=0;
		endcase
	end

	assign Trap = isTrap & y;

endmodule
