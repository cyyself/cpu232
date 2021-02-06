`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 		 Ã–Ã¬ÂµÃ‘
// Module Name:    D_Cache
// Create Date:    09:42 06/10/2014
//
// Design Name: 	 Ã–Â±Â½Ã“ÃÃ ÃÂ¬16KB D_Cache
//						 n = 14, k = 5;
//						 tag = 18'b[31:14] index = 9'b[13:5] offset = 5'b[4:2];
//
// CacheÃÂ´Â²ÃŸÃ‚Ã”:		 ÃÂ´Â»Ã˜Â·Â¨+ÃÂ´Â·Ã–Ã…Ã¤Â·Â¨
//	cache: 1_word + 11_index write back
//////////////////////////////////////////////////////////////////////////////////
module	D_Cache #(parameter A_WIDTH = 32,
	parameter C_INDEX = 10)(
	input clk,
	input rst,
	//cpu side
	input 				memwriteM,			//p_rw
	input wire [3:0] 	sel,				//p_wen
	input wire [1:0]	data_sram_size,		//P_size
	input wire [31:0]	data_paddr,			//p_a
	input wire [31:0] 	writedata2M,		//p_dout
	input wire 			memenM,				//p_strobe
	output wire [31:0]	readdataM,			//p_din
	output 				cache_ready,

	//mem side
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

	localparam		CPU_EXEC	=	0;
	localparam		WR_DRAM		=	1;
	localparam		RD_DRAM		=	2;


	localparam T_WIDTH = A_WIDTH - C_INDEX -2;	//tag width:
	localparam C_WIDTH = 32 + T_WIDTH + 2;
	//cache interface
	// dram side(write)
	wire 					dram_wr_req;		//	request writing data to dram
	wire 		[31:0]		dram_wr_addr;		//	write data address
	wire		[31:0]		dram_wr_data;		//	write data
	wire					dram_wr_val;		//	write a word valid
	// dram side(read)
	wire 					dram_rd_req;		//	request reading data from dram
	wire 		[31:0]		dram_rd_addr;		//	read data address
	wire					dram_rd_val;	//	read a word valid

	//cache memery
	//reg 	[52:0]			D_SRAM[(1<<C_INDEX)-1:0];
	reg 					d_valid [0:(1<<C_INDEX)-1];
	reg 					d_dirty [0:(1<<C_INDEX)-1];
	reg 	[T_WIDTH-1:0]	d_tags 	[0:(1<<C_INDEX)-1];
	reg 	[7:0]			d_data1	[0:(1<<C_INDEX)-1];
	reg 	[7:0]			d_data2	[0:(1<<C_INDEX)-1];
	reg 	[7:0]			d_data3	[0:(1<<C_INDEX)-1];
	reg 	[7:0]			d_data4	[0:(1<<C_INDEX)-1];

	//sign in cache
	reg		[1:0]			state;						// FSM
	//wire 	[C_WIDTH-1:0]	D_SRAM_block;				// { val(1), dirty(1), tag(21), data(32) }
	wire					cache_hit,dirty;						// dirty bit
	wire 	[T_WIDTH-1:0]	tagout;
	wire    [31:0]			c_out;

	//cache å†…ç´¢å¼?
	wire [C_INDEX-1:0] 	index 	= 	data_paddr[C_INDEX+1:2];
	wire [T_WIDTH-1:0] 	tag 	= 	data_paddr[A_WIDTH-1:C_INDEX+2];
	wire 				valid	= 	d_valid[index];

	//read from cache
	//assign	D_SRAM_block	=	{d_valid[index],d_dirty[index],d_tags[index],d_data1[index],d_data2[index],d_data3[index],d_data4[index]};
	assign	tagout			=	d_tags[index];
	assign	c_out 			= 	{d_data1[index],d_data2[index],d_data3[index],d_data4[index]};

	//cache control
	assign	cache_hit 		= 	valid & (tag==tagout) & memenM;
	assign	dirty			=	d_dirty[index];
	assign	dram_wr_addr	=	{tagout,index,2'b00};
	assign	dram_rd_addr	=	data_paddr;

	assign cache_ready		=	memenM & cache_hit;

	assign readdataM		=	cache_hit ? c_out : data_rdata;

	assign data_req  = (dram_rd_req ) || (dram_wr_req);
	assign data_wr 	 = dram_wr_req ? 1 : 0;
	assign data_addr = dram_wr_req ? dram_wr_addr : 
						dram_rd_req ?  dram_rd_addr : 32'b0;
	assign data_wdata = dram_wr_data;
	//assign dram_rd_data = data_rdata;
	assign dram_wr_val = dram_wr_req ? data_data_ok : 0;
	assign dram_rd_val = dram_rd_req ? data_data_ok : 0; 
 
	assign data_wen = 4'b1111;
	assign data_size = 2'b10;

// cpu/dram writes data_cache	å†™cache
	genvar i;
	generate
	for (i=0;i<(1<<C_INDEX);i=i+1) begin : clear_cache
		always @(posedge clk) begin
			if (rst) begin
				d_valid[i] <= 1'b0;
			end
		end
	end
	endgenerate
	always@(posedge clk)
	begin
		if(!rst) begin
			if(dram_rd_val)	// dram write cache block
			begin
				//D_SRAM[index]	<=	{1'b1, 1'b0, data_paddr[31:13],data_rdata};
				d_valid[index]  <=  1'b1;
				d_dirty[index]	<=  1'b0;
				d_tags[index]	<=  tag;
				d_data1[index]	<=	data_rdata[31:24];
				d_data2[index]	<=	data_rdata[23:16];
				d_data3[index]	<=	data_rdata[15:8];
				d_data4[index]	<=	data_rdata[7:0];

			end
			else if( cache_hit & memenM & memwriteM )		//hit å¹¶ä¸” å†™cache
			begin
				// wirte dirty bit
				//D_SRAM[index][51] 	<=	1'b1;
				d_dirty[index]		<=  1'b1;
				case (sel)
					4'b1111:begin//sw
						d_data1[index] <= writedata2M[31:24];
						d_data2[index] <= writedata2M[23:16];
						d_data3[index] <= writedata2M[15:8];
						d_data4[index] <= writedata2M[7:0];
					end
					4'b1110:begin//sw
						d_data1[index] <= writedata2M[31:24];
						d_data2[index] <= writedata2M[23:16];
						d_data3[index] <= writedata2M[15:8];
						
					end
					4'b1100:begin//sh
						d_data1[index] <= writedata2M[31:24];
						d_data2[index] <= writedata2M[23:16];
					end
					4'b0011:begin//sh
						d_data3[index] <= writedata2M[15:8];
						d_data4[index] <= writedata2M[7:0];
					end
					4'b0111:begin//sw
						d_data2[index] <= writedata2M[23:16];
						d_data3[index] <= writedata2M[15:8];
						d_data4[index] <= writedata2M[7:0];
					end
					4'b1000:begin//sb
						d_data1[index] <= writedata2M[31:24];
					end
					4'b0100:begin
						d_data2[index] <= writedata2M[23:16];
					end
					4'b0010:begin
						d_data3[index] <= writedata2M[15:8];
					end
					4'b0001:begin
						d_data4[index] <= writedata2M[7:0];
					end

				default: ;
				endcase
			end
		end
	end

	// data_cache writes dram 	cacheå†™å†…å­˜çš„æ•°æ®
	//assign dram_wr_data = D_SRAM[index][31:0];
	assign dram_wr_data =c_out;

	// data_cache state machine
	always@(posedge clk)
	begin
		if(rst)
			state	<=	CPU_EXEC;
		else
			case(state)
				CPU_EXEC:if( ~cache_hit & dirty & memenM )			// dirty block write back to dram
							state	<=	WR_DRAM;
						else if( ~cache_hit & memenM )		   	// request new block from dram
							state	<=	RD_DRAM;
						else
							state	<=	CPU_EXEC;
				WR_DRAM:if(dram_wr_val & dram_wr_req)
							state	<=	RD_DRAM;
						else
							state	<=	WR_DRAM;
				RD_DRAM:if(dram_rd_val & dram_rd_req)
							state	<=	CPU_EXEC;	
						else
							state	<=	RD_DRAM;
				default:	state	<=	CPU_EXEC;	
			endcase
	end

	// dram write/read request
	assign	dram_wr_req	=	( WR_DRAM == state ) ? 1 : 0;
	assign	dram_rd_req	=	( RD_DRAM == state ) ? 1 : 0;

endmodule