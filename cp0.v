`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2017/12/27 13:15:03
// Design Name:
// Module Name: cp0_reg
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
module cp0(
	input wire clk,
	input wire rst,

	input wire we_i,
	input[4:0] waddr_i,
	input[4:0] raddr_i,
	input[2:0] sel,
	input[`RegBus] data_i,

	input wire[4:0] int_i,

	input wire[`RegBus] excepttype_i,
	input wire[`RegBus] current_inst_addr_i,
	input wire is_in_delayslot_i,
	input wire[`RegBus] bad_addr_i,
	input wire memwriteM,

	output reg[`RegBus] data_o,
	output reg[`RegBus] count_o,
	output reg[`RegBus] compare_o,
	(*mark_debug = "true"*)output reg[`RegBus] status_o,
	(*mark_debug = "true"*)output reg[`RegBus] cause_o,
	output reg[`RegBus] epc_o,
	output reg[`RegBus] config_o,
	output reg[`RegBus] prid_o,
	output reg[`RegBus] ebase_o,
	output reg[`RegBus] badvaddr,
	output reg[`RegBus] config1_o,
	output reg[`RegBus] TagLo_o,
	output reg timer_int_o,
	//tlb
	input wire[2:0] tlb_typeM,
	input wire flushM,
	input wire stallM,
	output reg[31:0] cp0_entryHi,cp0_pageMask,cp0_entryLo0,cp0_entryLo1,cp0_index,cp0_random,cp0_wired,cp0_context,
	input wire[31:0] tlb_entryHi,tlb_pageMask,tlb_entryLo0,tlb_entryLo1,tlb_index
    );

	always @(posedge clk) begin
		if(rst == `RstEnable) begin
			cp0_index <= `ZeroWord;	
			cp0_wired <= `ZeroWord;
			cp0_context <= `ZeroWord;
			cp0_entryLo0 <= `ZeroWord;
			cp0_entryLo1 <= `ZeroWord;
			cp0_pageMask <= `ZeroWord;
			cp0_random <= 32'd31;
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			status_o <= 32'b00010000010100001111111100000001;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			config_o <= {1'b1,21'b0,3'b1,7'b0};
			config1_o <= {1'b0,6'd31,3'd5,3'd1,3'd0,3'd5,3'd1,3'd0,7'd0};
			// prid_o <= 32'b00000000010011000000000100000010;
			// prid_o <= 32'h004c0102;
			prid_o <= 32'h00004220;
			ebase_o <= 32'h80000000;
			timer_int_o <= `InterruptNotAssert;
			cp0_entryHi <= `ZeroWord;
		end else begin
			count_o <= count_o + 1;
			cause_o[15:10] <= {timer_int_o,~int_i};
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				/* code */
				timer_int_o <= `InterruptAssert;
			end

			cp0_random <= (cp0_random == cp0_wired || (we_i == `WriteEnable && waddr_i == `CP0_REG_WIRED)) ? 32'd31 : ( cp0_random - 1 );
			
			if(we_i == `WriteEnable) begin
				/* code */
				case (waddr_i)
					`CP0_REG_COUNT:begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:begin
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:begin
						status_o[28]      <= data_i[28];
                        status_o[22]      <= data_i[22];
                        status_o[15:8]    <= data_i[15:8];
                        status_o[4]       <= data_i[4];
                        status_o[2:0]     <= data_i[2:0];
					end
					`CP0_REG_CAUSE:begin
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EPC:begin
						epc_o <= data_i;
					end
					`CP0_REG_TagLo:begin
						TagLo_o <= data_i;
					end
					`CP0_REG_ENTRYHI:begin
						cp0_entryHi <= data_i & 32'hffffe0ff;
					end
					`CP0_REG_PAGEMASK:begin
						cp0_pageMask <= data_i & 32'h01ffe000;
					end
					`CP0_REG_ENTRYLO0:begin
						cp0_entryLo0 <= data_i & 32'h03ffffff;
					end
					`CP0_REG_ENTRYLO1:begin
						cp0_entryLo1 <= data_i & 32'h03ffffff;
					end
					`CP0_REG_INDEX:begin
						cp0_index <= data_i & 32'h0000001f;
					end
					`CP0_REG_WIRED:begin
						cp0_wired <= data_i & 32'h0000001f;
					end
					`CP0_REG_CONTEXT:begin
						cp0_context <= data_i[31:23];
					end
					`CP0_REG_EBASE:begin
						if(sel==3'b1)
						  ebase_o[29:12] <= data_i[29:12];
					end
					default : /* default */;
				endcase
			end
			case(tlb_typeM)
				3'b010:begin 
					cp0_entryHi <= tlb_entryHi;
					cp0_pageMask <= tlb_pageMask;
					cp0_entryLo0 <= tlb_entryLo0;
					cp0_entryLo1 <= tlb_entryLo1;
					end
				3'b001:begin 
					cp0_index <= tlb_index;
					end
			endcase
			case (excepttype_i)
				32'h00000001:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				32'h00000004:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					badvaddr <= bad_addr_i;
				end
				32'h00000005:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					badvaddr <= bad_addr_i;
				end
				32'h00000008:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				32'h00000009:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01001;
					
				end
				32'h0000000b:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01011;
					cause_o[29:28] <= sel[1:0]; 
				end
				32'h0000000d:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				32'h0000000a:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				32'h0000000c:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;
				end
				// 32'h0000000d:begin
				// 	if(is_in_delayslot_i == `InDelaySlot) begin
				// 		/* code */
				// 		epc_o <= current_inst_addr_i - 4;
				// 		cause_o[31] <= 1'b1;
				// 	end else begin
				// 		epc_o <= current_inst_addr_i;
				// 		cause_o[31] <= 1'b0;
				// 	end
				// 	status_o[1] <= 1'b1;
				// 	cause_o[6:2] <= 5'b01101;
				// end
				32'h0000000e:begin
					status_o[1] <= 1'b0;
				end
				32'h00000010:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 2'b1;
					cause_o[6:2] <= 5'b00010;
					badvaddr <= bad_addr_i;
					cp0_entryHi <= {current_inst_addr_i[31:12],cp0_entryHi[11:0]};
				end
				32'h00000011:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 2'b1;
					cause_o[6:2] <= 5'b00010;
					badvaddr <= bad_addr_i;
					cp0_entryHi <= {current_inst_addr_i[31:12],cp0_entryHi[11:0]};
				end
				32'h00000012:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 2'b1;
					cause_o[6:2] <= memwriteM ? 5'b00011 : 5'b00010;
					badvaddr <= data_i;
					cp0_entryHi <= {data_i[31:12],cp0_entryHi[11:0]};
					cp0_context[22:4] <= bad_addr_i[31:13];
				end
				32'h00000013:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 2'b1;
					cause_o[6:2] <= memwriteM ? 5'b00011 : 5'b00010;
					badvaddr <= data_i;
					cp0_entryHi <= {data_i[31:12],cp0_entryHi[11:0]};
					cp0_context[22:4] <= bad_addr_i[31:13];
				end
				32'h00000014:begin
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 2'b1;
					cause_o[6:2] <= 5'b00001;
					badvaddr <= bad_addr_i;
					cp0_entryHi <= {data_i[31:12],cp0_entryHi[11:0]};
					cp0_context[22:4] <= bad_addr_i[31:13];
				end
				default : /* default */;
			endcase

		end
	end

	always @(*) begin
		if(rst == `RstEnable) begin
			/* code */
			data_o <= `ZeroWord;
		end else begin
			case (raddr_i)
				`CP0_REG_COUNT:begin
					data_o <= count_o;
				end
				`CP0_REG_COMPARE:begin
					data_o <= compare_o;
				end
				`CP0_REG_STATUS:begin
					data_o <= status_o;
				end
				`CP0_REG_CAUSE:begin
					data_o <= cause_o;
				end
				`CP0_REG_EPC:begin
					data_o <= epc_o;
				end
				`CP0_REG_PRID:begin
					if(sel==3'b000)
						data_o <= prid_o;
					else 
						data_o <= ebase_o;
				end
				`CP0_REG_CONFIG:begin
					if(sel==3'b000)
						data_o <= config_o;
					else if(sel==3'b001)
						data_o <= config1_o;
					else 
						data_o <= 32'b0;
				end
				`CP0_REG_BADVADDR:begin
					data_o <= badvaddr;
				end
				`CP0_REG_INDEX:begin
					data_o <= cp0_index;
				end
				`CP0_REG_RANDOM:begin
					data_o <= {27'b0,cp0_random[4:0]};
				end
				`CP0_REG_WIRED:begin
					data_o <= cp0_wired;
				end
				`CP0_REG_CONTEXT:begin
					data_o <= cp0_context;
				end
				`CP0_REG_PAGEMASK:begin
					data_o <= cp0_pageMask;
				end
				`CP0_REG_ENTRYLO0:begin
					data_o <= cp0_entryLo0;
				end
				`CP0_REG_ENTRYLO1:begin
					data_o <= cp0_entryLo1;
				end
				`CP0_REG_ENTRYHI:begin
					data_o <= cp0_entryHi;
				end
				default : begin
					data_o <= `ZeroWord;
				end
			endcase
		end

	end

    
	// //cp0_entryHi
 //    always @(posedge clk)
 //    begin
 //        if (rst)
 //            cp0_entryHi <= 32'h00000000;
	// 	// else if (EXE_inst_invalid || EXE_inst_refill)
	// 	// 	cp0_entryHi <= {EXE_pc[31:12],cp0_entryHi[11:0]};
	// 	// else if (EXE_data_invalid || EXE_data_modified || EXE_data_refill)
	// 	// 	cp0_entryHi <= {CP0_wdata[31:12],cp0_entryHi[11:0]};
	// 	else if (tlb_typeM == 3'b010)
	// 		cp0_entryHi <= tlb_entryHi;
 //        else if (we_i && waddr_i == `CP0_REG_ENTRYHI && !flushM && !stallM)
 //            cp0_entryHi <= data_i & 32'hffffe0ff;
 //    end



	// //cp0_pageMask
	// always @(posedge clk)
 //    begin
 //        if (rst)
 //            cp0_pageMask <= 32'h00000000;
	// 	else if (tlb_typeM == 3'b010)
	// 		cp0_pageMask <= tlb_pageMask;
 //        else if ( we_i && waddr_i == `CP0_REG_PAGEMASK && !flushM && !stallM)
 //            cp0_pageMask <= data_i & 32'h01ffe000;
 //    end	
	
	// //cp0_entryLo0
	// always @(posedge clk)
 //    begin
 //        if (rst)
 //            cp0_entryLo0 <= 32'h00000000;
	// 	else if (tlb_typeM == 3'b010)
	// 		cp0_entryLo0 <= tlb_entryLo0;
 //        else if (we_i && waddr_i == `CP0_REG_ENTRYLO0 && !flushM && !stallM)
 //            cp0_entryLo0 <= data_i & 32'h03ffffff;
 //    end	

 //    //cp0_entryLo1
	// always @(posedge clk)
 //    begin
 //        if (rst)
 //            cp0_entryLo1 <= 32'h00000000;
	// 	else if (tlb_typeM == 3'b010)
	// 		cp0_entryLo1 <= tlb_entryLo1;
 //        else if (we_i && waddr_i == `CP0_REG_ENTRYLO1 && !flushM && !stallM)
 //            cp0_entryLo1 <= data_i & 32'h03ffffff;
 //    end	

 //    //cp0_index 
	// always @(posedge clk) begin 
	// 	if(rst) 
	// 		cp0_index <= 32'h00000000;
	// 	else if(tlb_typeM == 3'b001) 
	// 		cp0_index <= tlb_index;
	// 	else if(we_i && waddr_i == `CP0_REG_INDEX && !flushM && !stallM)
	// 		cp0_index <= data_i & 32'h0000001f;
	// end
endmodule
