`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:CPU璁捐涓哄皬绔ā锟�?
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.h"

module godson_cpu_mid(
	input wire[4:0] interrupt_i,
	input wire coreclock,areset_n,
	input wire nmi,

	 // axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata,

	//EJTAG 
	input wire EJTAG_TCK,
	input wire EJTAG_TDI,
	input wire EJTAG_TMS,
	input wire EJTAG_TRST,
	input wire EJTAG_TDO,
	input wire prrst_to_core,
	input wire testmode
    );

	// the follow definitions are between controller and datapath.
	// also use some of them  link the IPcores
	// fetch stage
	wire[31:0] pcF;
	wire[31:0] instrF;
	wire[7:0] exceptF; 
	// decode stage
	wire [31:0] instrD;
	wire pcsrcD,jumpD,jalD,jrD,balD,jalrD,branchD,branch_likely,equalD,invalidD;
	wire [1:0] hilo_weD;
	wire [7:0] alucontrolD;

	// execute stage
	wire regdstE,alusrcE;
	wire memtoregE,regwriteE;
	wire flushE,stallE;

	// mem stage
	wire memwriteM,memenM;
	wire[31:0] aluoutM;
	wire[31:0] writedata2M,excepttypeM;
	wire cp0weM;
	wire[31:0] readdataM;
	wire [3:0] sel;
	wire [1:0] data_sram_size;
	wire memtoregM,regwriteM;
	wire stallM,flushM;
	wire[5:0] opM;

	// writeback stage
	wire memtoregW,regwriteW;
	wire [31:0] pcW;
	wire [4:0] writeregW;
	wire [31:0] resultW;
	wire flushW;


	//cache mux signal
	wire cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,m_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
	wire[31:0] mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;// size not use
	wire[3:0] m_sel,d_wen;
	wire stallreq_from_if,stallreq_from_mem;

	//trace parameters
	assign debug_wb_pc = pcW;
	assign debug_wb_rf_wen = {4{regwriteW}};// the soft interrupt need to be solved 
	assign debug_wb_rf_wnum = writeregW;
	assign debug_wb_rf_wdata = resultW;

	//莽卤禄SRAM忙沤楼氓聫拢
	wire        inst_req;
    wire        inst_wr;
    wire [1:0]  inst_size;

    wire [31:0] inst_addr;
    wire [31:0] inst_wdata;
    wire [31:0] inst_rdata;
    wire        inst_addr_ok;
    wire        inst_data_ok;
    
    
    wire        data_req;
    wire        data_wr;
    wire [1:0]  data_size;
	wire [3:0]  data_wen;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire        data_addr_ok;
    wire        data_data_ok;


    wire [31:0]		IF_pc;
    wire 		is_clear;
    wire 		i_data_ok;
	//tlb
	wire[31:0] cp0_entryHi,cp0_pageMask,cp0_entryLo0,cp0_entryLo1,cp0_index,cp0_random;
	wire[31:0] tlb_entryHi,tlb_pageMask,tlb_entryLo0,tlb_entryLo1,tlb_index;
	wire[2:0] tlb_typeM;
	wire[31:0] inst_paddr;
	wire[31:0] data_paddr;
	wire inst_found,inst_V_flag,data_found,data_D_flag,data_V_flag;
	wire LLbit_weW;
	wire LLbit_o;
	controller c(
		coreclock,~areset_n,
		//decode stage
		instrD,
		equalD,stallD,
		pcsrcD,branchD,branch_likely,jumpD,
		jalD,jrD,balD,jalrD,
		alucontrolD,
		hilo_weD,
		invalidD,

		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	

		//mem stage
		memtoregM,memwriteM,memenM,
		regwriteM,cp0weM,
		stallM,flushM,
		tlb_typeM,
		opM,
		//write back stage
		memtoregW,regwriteW,
		flushW,
		LLbit_weW,
		LLbit_o
		);
	datapath dp(
		interrupt_i,
		coreclock,~areset_n,
		//fetch stage
		pcF,
		instrF,
		inst_found,
		inst_V_flag,
		//decode stage
		pcsrcD,branchD,branch_likely,
		jumpD,jalD,jrD,balD,jalrD,
		equalD,stallD,
		instrD,
		alucontrolD,
		hilo_weD,
		invalidD,
		
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		flushE,stallE,
		//mem stage
		memenM,
		memwriteM,
		memtoregM,
		regwriteM,
		aluoutM,writedata2M,data_sram_size,
		readdataM,
		sel,
		cp0weM,stallM,flushM,excepttypeM,		
		tlb_typeM,
		data_V_flag,
		data_D_flag,
		data_found,
		cp0_entryHi,cp0_pageMask,cp0_entryLo0,cp0_entryLo1,cp0_index,cp0_random,
		tlb_entryHi,tlb_pageMask,tlb_entryLo0,tlb_entryLo1,tlb_index,
		opM,

		//writeback stage
		memtoregW,
		regwriteW,
		pcW,
		writeregW,
		resultW,
		flushW,
		LLbit_weW,
		LLbit_o,
		
		stallreq_from_if,stallreq_from_mem,
		is_clear,i_data_ok,
		IF_pc,
		exceptF
	    );
	
	TLB tlb(
		.clk 			(coreclock),
		.tlb_typeM		(tlb_typeM),
		.inst_vaddr 	(pcF),
		.data_vaddr_in 	(aluoutM),
		.EntryHi_in 	(cp0_entryHi),
		.PageMask_in 	(cp0_pageMask),
		.EntryLo0_in 	(cp0_entryLo0),
		.EntryLo1_in 	(cp0_entryLo1),
		.Index_in 		(cp0_index),
		.Random_in		(cp0_random),

		.EntryHi_out 	(tlb_entryHi),
		.PageMask_out 	(tlb_pageMask),
		.EntryLo0_out 	(tlb_entryLo0),
		.EntryLo1_out 	(tlb_entryLo1),
		.Index_out 		(tlb_index),
		.inst_V_flag 	(inst_V_flag),

		.data_V_flag 	(data_V_flag),
		.data_D_flag 	(data_D_flag),

		.inst_paddr_o 	(inst_paddr),
		.data_paddr_o 	(data_paddr),
		.inst_found 	(inst_found),
		.data_found 	(data_found)
	);

	wire cache_ready;
	wire flag ;
	wire dram_memen,confreg_memen;
	//茅艙?猫娄聛盲驴庐忙锟�??
	//assign stallreq_from_if = ~inst_data_ok ;  //盲赂?盲录拧氓藛聽
	assign stallreq_from_if = ~i_data_ok ;  //盲赂?盲录拧氓藛聽
	//assign stallreq_from_mem = ~ data_data_ok & memenM; //盲赂?盲录拧氓藛聽
	
	wire stall1,stall2;
	assign stall1 = (dram_memen  & ~cache_ready);				//cache dram鐨勬殏锟�?
	assign stall2 = (confreg_memen  & flag & ~data_data_ok);	//confreg 鐨勬殏锟�?
	assign stallreq_from_mem = stall1 || stall2; //盲赂?盲录拧氓藛聽 


	//assign flag = 1'b1;
	assign flag = 1;//(aluoutM[31:29] == 3'b101) ? 1 : 0;
	assign dram_memen = (memenM & ~(|excepttypeM)) ? (flag ? 0 : 1) : 0;
	assign confreg_memen = (memenM & ~(|excepttypeM)) ? (flag ? 1 : 0) : 0;
	assign readdataM = flag ? confreg_readdataM : dram_readdataM;

	wire  dram_data_req ;
	wire  dram_data_wr ;
	wire [3:0] dram_data_wen ;
	wire [1:0] dram_data_size ;
	wire [31:0] dram_data_addr ;
	wire [31:0] dram_data_wdata ;
	wire [31:0] dram_readdataM;

	wire confreg_data_req;
	wire confreg_data_wr;
	wire [3:0] confreg_data_wen;
	wire [1:0] confreg_data_size;
	wire [31:0] confreg_data_addr;
	wire [31:0] confreg_data_wdata;
	wire [31:0] confreg_readdataM;
	//ok
	I_Cache i_cache(
		.clk(coreclock),
		.rst(areset_n),
		.inst_paddr(inst_paddr),
		.instrF(instrF),
		.excepttypeM(excepttypeM),
		.IF_pc(IF_pc),
		.is_clear(is_clear),
		.i_data_ok(i_data_ok),

		.inst_req		(inst_req),
	    .inst_wr 		(inst_wr),
	    .inst_size 		(inst_size),
	    .inst_addr 		(inst_addr),
	    .inst_wdata 	(inst_wdata),
	    .inst_rdata 	(inst_rdata),
	    .inst_addr_ok 	(inst_addr_ok),
	    .inst_data_ok 	(inst_data_ok)
		);
	D_Cache d_cache(
		//cpu side
		.clk 			(coreclock),
		.rst 			(~areset_n),
		.memwriteM 		(memwriteM),
	 	.sel 			(sel),
		.data_sram_size (data_sram_size),
		.data_paddr 	(data_paddr),
		.writedata2M 	(writedata2M),
		.memenM 		(dram_memen),
	 	.readdataM 		(dram_readdataM),
	 	.cache_ready	(cache_ready),

	 	//mem side
	    .data_req          (dram_data_req    ),
	    .data_wr           (dram_data_wr     ),
		.data_wen          (dram_data_wen    ),
	    .data_size         (dram_data_size   ),
	    .data_addr         (dram_data_addr   ),
	    .data_wdata        (dram_data_wdata  ),
	    .data_rdata        (data_rdata  ),
	    .data_addr_ok      (data_addr_ok),
	    .data_data_ok      (data_data_ok)
		);

	//
	d_confreg_port d_confreg_port(
		//cpu side
		.clk 			(coreclock),
		.rst 			(areset_n),
		.memwriteM 		(memwriteM),
	 	.sel 			(sel),
		.data_sram_size (data_sram_size),
		.aluoutM 		(data_paddr),
		.writedata2M 	(writedata2M),
		.memenM 		(confreg_memen),
	 	.readdataM 		(confreg_readdataM),

	 	//mem side
	    .data_req          (confreg_data_req    ),
	    .data_wr           (confreg_data_wr     ),
		.data_wen          (confreg_data_wen    ),
	    .data_size         (confreg_data_size   ),
	    .data_addr         (confreg_data_addr   ),
	    .data_wdata        (confreg_data_wdata  ),
	    .data_rdata        (data_rdata  ),
	    .data_addr_ok      (data_addr_ok),
	    .data_data_ok      (data_data_ok)
		);

	assign data_req = flag ? confreg_data_req : dram_data_req;
	assign data_wr = flag ? confreg_data_wr : dram_data_wr;
	assign data_wen = flag ? confreg_data_wen  : dram_data_wen;
	assign data_size = flag ? confreg_data_size : dram_data_size;
	assign data_addr = flag ? confreg_data_addr : dram_data_addr;
	assign data_wdata = flag ? confreg_data_wdata : dram_data_wdata;

	axi_interface interface(
	.clk               (coreclock         ), 
    .resetn            (areset_n     ), 

    //inst sram-like 
    .inst_req          (inst_req    ),
    .inst_wr           (inst_wr     ),
    .inst_size         (inst_size   ),
    .inst_addr         (inst_addr   ),
    .inst_wdata        (inst_wdata  ),
    .inst_rdata        (inst_rdata  ),
    .inst_addr_ok      (inst_addr_ok),
    .inst_data_ok      (inst_data_ok),
    
    //data sram-like 
    .data_req          (data_req    ),
    .data_wr           (data_wr     ),
	.data_wen          (data_wen    ),
    .data_size         (data_size   ),
    .data_addr         (data_addr   ),
    .data_wdata        (data_wdata  ),
    .data_rdata        (data_rdata  ),
    .data_addr_ok      (data_addr_ok),
    .data_data_ok      (data_data_ok),

    //axi
    //ar
    .arid       ( arid        ),
    .araddr     ( araddr      ),
    .arlen      ( arlen       ),
    .arsize     ( arsize      ),
    .arburst    ( arburst     ),
    .arlock     ( arlock      ),
    .arcache    ( arcache     ),
    .arprot     ( arprot      ),
    .arvalid    ( arvalid     ),
    .arready    ( arready     ),
	
    .rid        ( rid         ),
    .rdata      ( rdata       ),
    .rresp      ( rresp       ),
    .rlast      ( rlast       ),
    .rvalid     ( rvalid      ),
    .rready     ( rready      ),
	
    .awid       ( awid        ),
    .awaddr     ( awaddr      ),
    .awlen      ( awlen       ),
    .awsize     ( awsize      ),
    .awburst    ( awburst     ),
    .awlock     ( awlock      ),
    .awcache    ( awcache     ),
    .awprot     ( awprot      ),
    .awvalid    ( awvalid     ),
    .awready    ( awready     ),
	
    .wid        ( wid         ),
    .wdata      ( wdata       ),
    .wstrb      ( wstrb       ),
    .wlast      ( wlast       ),
    .wvalid     ( wvalid      ),
    .wready     ( wready      ),
	
    .bid        ( bid         ),
    .bresp      ( bresp       ),
    .bvalid     ( bvalid      ),
    .bready     ( bready      )
	);
endmodule
