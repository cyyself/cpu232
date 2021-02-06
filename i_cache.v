`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/11 21:15:46
// Design Name: 
// Module Name: inst_sram_port
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


module I_Cache #(parameter A_WIDTH = 32,
    parameter C_INDEX = 10)(
	input clk,
	input rst,

	//cpu side
	input   wire [31:0] inst_paddr,		//p_a
	output 	wire [31:0]	instrF,			//p_din
	input 	wire [31:0] excepttypeM,	//p_flush
	output  wire [31:0] IF_pc,			
	output 	reg 	is_clear,			
	output	wire 	i_data_ok,			//p_ready

	//mem side
	output              inst_req,		//m_strobe
    output              inst_wr,
    output  wire [1:0]  inst_size,
    output  wire [31:0] inst_addr,		//m_a
    output  wire [31:0] inst_wdata,
    input   wire [31:0] inst_rdata,
    input             	inst_addr_ok,
    input             	inst_data_ok

    );
	
	reg do_mem;
    wire cache_hit, cache_miss;
	

	assign inst_wr = 1'b0;
	assign inst_size = 2'b10;
	//assign inst_addr = inst_paddr;
	assign inst_wdata = 32'b0;
	//assign i_data_ok = inst_data_ok;

	always @(posedge clk)
	begin
		if (!rst) 
			do_mem <= 1'b0;
		else if (inst_addr_ok && cache_miss)
		    do_mem <= 1'b1;
		else if (inst_data_ok)
		    do_mem <= 1'b0;
	end

	always @(posedge clk)
	begin
		if (!rst)
			is_clear <= 1'b0;
		else if (inst_data_ok)
			is_clear <= 1'b0;
		else if (|excepttypeM)
			is_clear <= 1'b1;
	end

	assign inst_req = cache_miss && !do_mem;
	assign IF_pc = cache_hit ? inst_paddr :
            (inst_data_ok) ? ((is_clear) ? 32'd0 : inst_addr) : 32'd0;
	

    localparam T_WIDTH = A_WIDTH - C_INDEX - 2;
    reg d_valid [0:(1<<C_INDEX)-1];
    reg [T_WIDTH-1:0] d_tags [0:(1<<C_INDEX)-1];
    //data
    reg [7:0] d_data1 [0:(1<<C_INDEX)-1];
    reg [7:0] d_data2 [0:(1<<C_INDEX)-1];
    reg [7:0] d_data3 [0:(1<<C_INDEX)-1];
    reg [7:0] d_data4 [0:(1<<C_INDEX)-1];
    //index(addr)
    wire [C_INDEX-1:0] index = inst_paddr[C_INDEX+1:2];
    //tag(addr)
    wire [T_WIDTH-1:0] tag = inst_paddr[A_WIDTH-1:C_INDEX+2];
    // read from cache
    wire valid = d_valid[index];
    wire [T_WIDTH-1:0] tagout = d_tags[index];
    wire [A_WIDTH-1:0] c_dout = {d_data1[index],d_data2[index],d_data3[index],d_data4[index]};

    // cache control 
    wire cache_hit = valid & (tagout == tag);
    //assign cache_hit = 1'b0;
    assign cache_miss = ~cache_hit;
    assign inst_addr = inst_paddr;

    assign i_data_ok = cache_hit | cache_miss & inst_data_ok;
    wire c_write = cache_miss & inst_data_ok;
    wire sel_out = cache_hit;
    wire [A_WIDTH-1:0] c_din = inst_rdata;
    assign instrF = (is_clear ) ? 32'd0 : 
                    sel_out? c_dout:inst_rdata;
    //assign instrF = (is_clear || IF_inst_addr_err) ? 32'd0 : inst_rdata;
 	
    genvar i;
    generate
        for (i=0;i<(1<<C_INDEX);i=i+1) begin
            always @(posedge clk) begin
                if (!rst) begin
                    d_valid[i] <= 1'b0;
                end
            end
        end
    endgenerate
    always @(posedge clk) begin
        if (rst & c_write & ~is_clear) begin
            d_valid[index] <= 1'b1;
        end
      
    end

    always @(posedge clk) begin
        if (c_write & ~is_clear) begin
            d_tags[index] <= tag;
            d_data1[index] <= c_din[31:24];
            d_data2[index] <= c_din[23:16];
            d_data3[index] <= c_din[15:8];
            d_data4[index] <= c_din[7:0];

        end
    end

endmodule
