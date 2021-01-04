`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/10 15:35:25
// Design Name: 
// Module Name: LLbit_reg
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


module LLbit_reg(
    input wire clk,
    input wire rst,
    
    //when an exception occurs, flash = 1, otherwise flash = 0
    input wire flush,

    // write operation
    input wire LLbit_i,
    input wire we,
   
    output  reg LLbit_o
    );

    always @ (posedge clk) begin
      if ( rst == 1'b1 ) begin
        LLbit_o <= 1'b0;
      end else if (flush == 1'b1) begin
        LLbit_o <= 1'b0;
      end else if ( we == 1'b1) begin
        LLbit_o <= LLbit_i;
    end
    end

endmodule
