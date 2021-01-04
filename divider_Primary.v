`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 15:50:41
// Design Name: 
// Module Name: divider_Primary
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

module divider_Primary(

    input wire      clk,
    input wire      rst,
    input wire[7:0] op,//change the length
    input wire[31:0]opdata1_i,
    input wire[31:0]opdata2_i,
    input wire      annul_i,
    output reg[63:0]result_o,
    output reg      ready_o,
    input  wire     start_i
);
    wire signed_div_i;
    wire[32:0] div_temp;
    reg[5:0] cnt;
    reg[64:0] dividend;
    reg[1:0] state;
    reg[31:0] divisor;
    reg[31:0] temp_op1;
    reg[31:0] temp_op2;
    reg[31:0] opdata1,opdata2;
    assign signed_div_i = (op == `DIV_CONTROL) ?1'b1:
                          (op == `DIVU_CONTROL)?1'b0:1'bx;

    assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= {`ZeroWord,`ZeroWord};
        end else begin
          case (state)
            `DivFree:           begin               //DivFree
                if(start_i == `DivStart && annul_i == 1'b0) begin
                    if(opdata2_i == `ZeroWord) begin
                        state <= `DivByZero;
                    end else begin
                        state <= `DivOn;
                        cnt <= 6'b000000;
                        if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
                            temp_op1 = ~opdata1_i + 1;
                        end else begin
                            temp_op1 = opdata1_i;
                        end
                        if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
                            temp_op2 = ~opdata2_i + 1;
                        end else begin
                            temp_op2 = opdata2_i;
                        end
                        dividend <= {`ZeroWord,`ZeroWord};
              dividend[32:1] <= temp_op1;
              divisor <= temp_op2;
              opdata1 <= opdata1_i;
              opdata2 <= opdata2_i;
             end
          end else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord,`ZeroWord};
                  end
            end
            `DivByZero:     begin               //DivByZero��???
            dividend <= {`ZeroWord,`ZeroWord};
          state <= `DivEnd;
            end
            `DivOn:             begin               //DivOn��???
                if(annul_i == 1'b0) begin
                    if(cnt != 6'b100000) begin
               if(div_temp[32] == 1'b1) begin
                  dividend <= {dividend[63:0] , 1'b0};
               end else begin
                  dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
               end
               cnt <= cnt + 1;
             end else begin
               if((signed_div_i == 1'b1) && ((opdata1[31] ^ opdata2[31]) == 1'b1)) begin
                  dividend[31:0] <= (~dividend[31:0] + 1);
               end
               if((signed_div_i == 1'b1) && ((opdata1[31] ^ dividend[64]) == 1'b1)) begin
                  dividend[64:33] <= (~dividend[64:33] + 1);
               end
               state <= `DivEnd;
               cnt <= 6'b000000;
             end
                end else begin
                    state <= `DivFree;
                end
            end
            `DivEnd:            begin               //DivEnd��???
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
