`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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
module alu(
	input wire[31:0] a,b,
	input wire[4:0] sa,
	input wire[7:0] alucontrol,
	input wire [31:0] hi_in,lo_in,
	input wire [31:0] cp0data,
	output reg[31:0] y,
	output reg overflow,
	output  reg[31:0] hi_alu_out,lo_alu_out
	//need to add pcplus8E and cp0
    );
	
	reg [31:0] nop;

	always @(*) begin
		case (alucontrol)
			// logic and algor inst
			`AND_CONTROL:  y <= a & b;
			`OR_CONTROL:   y <= a | b;
			`XOR_CONTROL:  y <= a ^ b;
			`NOR_CONTROL:  y <= ~(a | b);

			`ADD_CONTROL, `ADDU_CONTROL: y <= a + b;
			`SUB_CONTROL, `SUBU_CONTROL: y <= a - b;
			`SLT_CONTROL:  y <= ($signed(a)<$signed(b))? 1 : 0;
			`SLTU_CONTROL: y <= (a<b);
			`LUI_CONTROL:  y <= {b[15:0], 16'b0};
			`MULT_CONTROL: {hi_alu_out,lo_alu_out} <= $signed(a)*$signed(b);
			`MULTU_CONTROL:{hi_alu_out,lo_alu_out} <= a * b;
			//shift inst
			`SLL_CONTROL:  y <= b << sa;
			`SRL_CONTROL:  y <= b >> sa;
			`SRA_CONTROL:  y <= ({32{b[31]}} << (6'd32-{1'b0,sa})) | b >> sa;
			`SLLV_CONTROL: y <= b << a[4:0];
			`SRLV_CONTROL: y <= b >> a[4:0];
			`SRAV_CONTROL: y <= ({32{b[31]}} << (6'd32-{1'b0,a[4:0]})) | b >> a[4:0];
			//data_move inst
			`MFHI_CONTROL:y <= hi_in[31:0];
			`MFLO_CONTROL:y <= lo_in[31:0];
			`MTHI_CONTROL:hi_alu_out <= a;
			`MTLO_CONTROL:lo_alu_out <= a;
			`MFC0_CONTROL: y <= cp0data;
			`MTC0_CONTROL: y <= b;
			`MOVE_CONTROL: y <= a;
			`CLZ_CONTROL: begin
				case(a)
					32'b00000000000000000000000000000000: y <= 32'd32;
		            32'b00000000000000000000000000000001: y <= 32'd31;
		            32'b0000000000000000000000000000001?: y <= 32'd30;
		            32'b000000000000000000000000000001??: y <= 32'd29;
		            32'b00000000000000000000000000001???: y <= 32'd28;
		            32'b0000000000000000000000000001????: y <= 32'd27;
		            32'b000000000000000000000000001?????: y <= 32'd26;
		            32'b00000000000000000000000001??????: y <= 32'd25;
		            32'b0000000000000000000000001???????: y <= 32'd24;
		            32'b000000000000000000000001????????: y <= 32'd23;
		            32'b00000000000000000000001?????????: y <= 32'd22;
		            32'b0000000000000000000001??????????: y <= 32'd21;
		            32'b000000000000000000001???????????: y <= 32'd20;
		            32'b00000000000000000001????????????: y <= 32'd19;
		            32'b0000000000000000001?????????????: y <= 32'd18;
		            32'b000000000000000001??????????????: y <= 32'd17;
		            32'b00000000000000001???????????????: y <= 32'd16;
		            32'b0000000000000001????????????????: y <= 32'd15;
		            32'b000000000000001?????????????????: y <= 32'd14;
		            32'b00000000000001??????????????????: y <= 32'd13;
		            32'b0000000000001???????????????????: y <= 32'd12;
		            32'b000000000001????????????????????: y <= 32'd11;
		            32'b00000000001?????????????????????: y <= 32'd10;
		            32'b0000000001??????????????????????: y <= 32'd9;
		            32'b000000001???????????????????????: y <= 32'd8;
		            32'b00000001????????????????????????: y <= 32'd7;
		            32'b0000001?????????????????????????: y <= 32'd6;
		            32'b000001??????????????????????????: y <= 32'd5;
		            32'b00001???????????????????????????: y <= 32'd4;
		            32'b0001????????????????????????????: y <= 32'd3;
		            32'b001?????????????????????????????: y <= 32'd2;
		            32'b01??????????????????????????????: y <= 32'd1;
		            32'b1???????????????????????????????: y <= 32'd0;
		        endcase
			end
			`CLO_CONTROL:begin
				case(~a)
					32'b00000000000000000000000000000000: y <= 32'd32;
		            32'b00000000000000000000000000000001: y <= 32'd31;
		            32'b0000000000000000000000000000001?: y <= 32'd30;
		            32'b000000000000000000000000000001??: y <= 32'd29;
		            32'b00000000000000000000000000001???: y <= 32'd28;
		            32'b0000000000000000000000000001????: y <= 32'd27;
		            32'b000000000000000000000000001?????: y <= 32'd26;
		            32'b00000000000000000000000001??????: y <= 32'd25;
		            32'b0000000000000000000000001???????: y <= 32'd24;
		            32'b000000000000000000000001????????: y <= 32'd23;
		            32'b00000000000000000000001?????????: y <= 32'd22;
		            32'b0000000000000000000001??????????: y <= 32'd21;
		            32'b000000000000000000001???????????: y <= 32'd20;
		            32'b00000000000000000001????????????: y <= 32'd19;
		            32'b0000000000000000001?????????????: y <= 32'd18;
		            32'b000000000000000001??????????????: y <= 32'd17;
		            32'b00000000000000001???????????????: y <= 32'd16;
		            32'b0000000000000001????????????????: y <= 32'd15;
		            32'b000000000000001?????????????????: y <= 32'd14;
		            32'b00000000000001??????????????????: y <= 32'd13;
		            32'b0000000000001???????????????????: y <= 32'd12;
		            32'b000000000001????????????????????: y <= 32'd11;
		            32'b00000000001?????????????????????: y <= 32'd10;
		            32'b0000000001??????????????????????: y <= 32'd9;
		            32'b000000001???????????????????????: y <= 32'd8;
		            32'b00000001????????????????????????: y <= 32'd7;
		            32'b0000001?????????????????????????: y <= 32'd6;
		            32'b000001??????????????????????????: y <= 32'd5;
		            32'b00001???????????????????????????: y <= 32'd4;
		            32'b0001????????????????????????????: y <= 32'd3;
		            32'b001?????????????????????????????: y <= 32'd2;
		            32'b01??????????????????????????????: y <= 32'd1;
		            32'b1???????????????????????????????: y <= 32'd0;
		        endcase
			end
			`MUL_CONTROL:begin
				{nop,y} <= $signed(a)*$signed(b);
			end
			`MADD_CONTROL:begin
				{hi_alu_out,lo_alu_out} <= $signed(a)*$signed(b) + {hi_in,lo_in};
			end
			`MADDU_CONTROL:begin
				{hi_alu_out,lo_alu_out} <= a*b + {hi_in,lo_in};
			end
			`MSUB_CONTROL:begin
				{hi_alu_out,lo_alu_out} <= $signed(a)*$signed(b) - {hi_in,lo_in};
			end
			`MSUBU_CONTROL:begin
				{hi_alu_out,lo_alu_out} <= a*b - {hi_in,lo_in};
			end
			default : y <= 32'b0;
		endcase	
	end

	always @(*) begin
		case (alucontrol)
			`ADD_CONTROL: overflow <= a[31] & b[31] & ~y[31] | ~a[31] & ~b[31] & y[31];
			`SUB_CONTROL: overflow <= ((a[31]&&!b[31])&&!y[31])||((!a[31]&&b[31])&&y[31]);
			`ADDU_CONTROL:overflow <= 0;
			`SUBU_CONTROL:overflow <= 0;
			default: overflow <= 0;
        endcase
	end
endmodule
