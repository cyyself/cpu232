`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/07/22 16:13:32
// Design Name: 
// Module Name: d_confreg_port
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


module d_confreg_port(
	input clk,
	input rst,

	input 				memwriteM,
	input wire [3:0] 	sel,
	input wire [1:0]	data_sram_size,
	input wire [31:0]	aluoutM,
	input wire [31:0] 	writedata2M,
	input wire 			memenM,
	output wire [31:0]	readdataM,


	output              data_req,
    output              data_wr,
    output	wire [3:0]	data_wen,
    output  wire [1:0]  data_size,
    output  wire [31:0] data_addr,
    output  wire [31:0] data_wdata,
    input 	wire [31:0] data_rdata,
    input             data_addr_ok,
    input             data_data_ok
    );

	assign data_wr = memwriteM;
	assign data_wen = sel;
	assign data_size = data_sram_size;
	assign data_addr = (aluoutM[31:16] != 16'hbfaf) ? aluoutM : {16'h1faf,aluoutM[15:0]};
	assign data_wdata = writedata2M;
	assign readdataM = data_rdata;

	reg do_mem;
	always @(posedge clk)
	begin
		if (!rst) 
			do_mem <= 1'b0;
		else if (data_data_ok)
		    do_mem <= 1'b0;
	end
	assign data_req =  memenM&& !do_mem;

	//assign data_req = ~memenM ? 0 : data_data_ok ? 0 : 1;

endmodule
