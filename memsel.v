`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/15 15:47:47
// Design Name: 
// Module Name: memsel
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
module memsel(
	input wire[31:0] pc,
	input wire[5:0] op,
	input wire[31:0] addr,//equal aluoutM
	input wire[31:0] writedata,readdata, 
	// output wire memwrite,
	output reg [3:0] sel, 
	output reg[31:0] writedata2,finaldata,bad_addr,
	output reg adelM,adesM,
	(*mark_debug = "true"*)output reg[1:0] size

    );
	
	always @(*) begin
		bad_addr <= pc;//previous: pc - 8
		adesM <= 1'b0;
		adelM <= 1'b0;
		writedata2 <= writedata;
		case (op)
			`LWL,`LWR:begin
				size <= 2'b10;
				sel <= 4'b1111;
				end
			`LW,`LL:begin
				size <= 2'b10;
				if(addr[1:0] != 2'b00) begin
					adelM <= 1'b1;
					bad_addr <= addr;
					sel <= 4'b0000;
				end else begin
                    sel <= 4'b1111;
                end
			end
			`LB,`LBU:begin
				size <= 2'b00;
				case (addr[1:0])
					2'b11:sel <= 4'b1000;
					2'b10:sel <= 4'b0100;
					2'b01:sel <= 4'b0010;
					2'b00:sel <= 4'b0001;
					default : /* default */;
				endcase
			end
			`LH,`LHU:begin
				size <= 2'b01;
                case (addr[1:0])
					2'b10:sel <= 4'b1100;
					2'b00:sel <= 4'b0011;
					default :begin
                        adelM <= 1'b1;
                        bad_addr <= addr;
						sel <= 4'b0000;
					end 
				endcase
			end
			`SW,`SC:begin 
				size <= 2'b10;
				if(addr[1:0] == 2'b00) begin
					/* code */
					sel <= 4'b1111;
				end else begin 
					adesM <= 1'b1;
					bad_addr <= addr;
					sel <= 4'b0000;
				end
			end
			`SWL:begin 
				size <= 2'b10;
				case (addr[1:0])
					2'b00:begin
							sel <= 4'b0001;
							writedata2 <= {24'b0,writedata[31:24]};
						end
					2'b01:begin 
							sel <= 4'b0011;
							writedata2 <= {16'b0,writedata[31:16]};
						end
					2'b10:begin 
							sel <= 4'b0111;
							writedata2 <= {8'b0,writedata[31:8]};
						end
					2'b11:begin 
							sel <= 4'b1111;
							writedata2 <= writedata;
						end
					default : /* default */;
				endcase
			end
			`SWR:begin 
				size <= 2'b10;
				case (addr[1:0])
					2'b00:begin 
							sel <= 4'b1111;
							writedata2 <= writedata;
						end
					2'b01:begin 
							sel <= 4'b1110;
							writedata2 <= {writedata[23:0],8'b0};
						end
					2'b10:begin 
							sel <= 4'b1100;
							writedata2 <= {writedata[15:0],16'b0};
						end
					2'b11:begin 
							sel <= 4'b1000;
							writedata2 <=  {writedata[7:0],24'b0};
						end
					default : /* default */;
				endcase
			end
			`SH:begin
				size <= 2'b01;
				writedata2 <= {writedata[15:0],writedata[15:0]};
				case (addr[1:0])
					2'b10:sel <= 4'b1100;
					2'b00:sel <= 4'b0011;
					default :begin 
						adesM <= 1'b1;
						bad_addr <= addr;
						sel <= 4'b0000;
					end 
				endcase
			end
			`SB:begin
				size <= 2'b00;
				writedata2 <= {writedata[7:0],writedata[7:0],writedata[7:0],writedata[7:0]};
				case (addr[1:0])
					2'b11:sel <= 4'b1000;
					2'b10:sel <= 4'b0100;
					2'b01:sel <= 4'b0010;
					2'b00:sel <= 4'b0001;
					default : /* default */;
				endcase
			end
			
			default : sel <= 4'b0000;
		endcase
		// bad_addr <= pc - 8;
		case (op)
			`LW, `LL:begin 
				if(addr[1:0] == 2'b00) begin
					/* code */
					finaldata <= readdata;
				end
			end
			`LWL:begin
				case (addr[1:0])
					2'b00: finaldata <= {readdata[7:0],writedata[23:0]};
					2'b01: finaldata <= {readdata[15:0],writedata[15:0]};
					2'b10: finaldata <= {readdata[23:0],writedata[7:0]};
					2'b11: finaldata <= readdata;
					default : /* default */;		        
				endcase
			end
			`LWR:begin
				case (addr[1:0])
					2'b00: finaldata <=  readdata;
					2'b01: finaldata <= {writedata[31:24],readdata[31:8]};
					2'b10: finaldata <= {writedata[31:16],readdata[31:16]};
					2'b11: finaldata <= {writedata[31:8],readdata[31:24]};
					default : /* default */;		        
				endcase
			end
			`LB:begin 
				case (addr[1:0])
					2'b11: finaldata <= {{24{readdata[31]}},readdata[31:24]};
					2'b10: finaldata <= {{24{readdata[23]}},readdata[23:16]};
					2'b01: finaldata <= {{24{readdata[15]}},readdata[15:8]};
					2'b00: finaldata <= {{24{readdata[7]}},readdata[7:0]};
					default : /* default */;		        
				endcase
			end
			`LBU:begin 
				case (addr[1:0])
					2'b11: finaldata <= {{24{1'b0}},readdata[31:24]};
					2'b10: finaldata <= {{24{1'b0}},readdata[23:16]};
					2'b01: finaldata <= {{24{1'b0}},readdata[15:8]};
					2'b00: finaldata <= {{24{1'b0}},readdata[7:0]};
					default : /* default */;
				endcase
			end
			`LH:begin 
				case (addr[1:0])
					2'b10: finaldata <= {{16{readdata[31]}},readdata[31:16]};
					2'b00: finaldata <= {{16{readdata[15]}},readdata[15:0]};
					default :;
				endcase
			end
			`LHU:begin 
				case (addr[1:0])
					2'b10: finaldata <= {{16{1'b0}},readdata[31:16]};
					2'b00: finaldata <= {{16{1'b0}},readdata[15:0]};
					default :;
				endcase
			end
			default : finaldata <= `ZeroWord;
		endcase
	end
	
endmodule
