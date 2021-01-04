module TLB(
	input  wire        clk,
	input  wire[2:0]   tlb_typeM, 	   	
	input  wire [31:0] inst_vaddr,//come from
	input  wire [31:0] data_vaddr_in,
	input  wire [31:0] EntryHi_in,
	input  wire [31:0] PageMask_in,
	input  wire [31:0] EntryLo0_in,
	input  wire [31:0] EntryLo1_in,
	input  wire [31:0] Index_in,
	input  wire [31:0] Random_in,
	output wire [31:0] EntryHi_out,
	output wire [31:0] PageMask_out,
	output wire [31:0] EntryLo0_out,
	output wire [31:0] EntryLo1_out,
	output wire [31:0] Index_out,

	output wire        inst_V_flag,
	output wire        data_V_flag,
	output wire        data_D_flag,

	output wire [31:0] inst_paddr_o,
	output wire [31:0] data_paddr_o,
	output wire        inst_found,
	output wire        data_found
);

//close TLB
// assign inst_paddr = inst_vaddr;
// assign data_paddr = data_vaddr_in;


//open TLB

wire [31:0] inst_paddr;
wire [31:0] data_paddr;
assign inst_paddr_o = (inst_vaddr[31:29]==3'b100) ? {3'b000,inst_paddr[28:0]} :
					(inst_vaddr[31:29]==3'b101) ? {3'b000,inst_paddr[28:0]} : inst_paddr;

assign data_paddr_o = (data_vaddr_in[31:29]==3'b100) ? {3'b000,data_paddr[28:0]} :
					(data_vaddr_in[31:29]==3'b101) ? {3'b000,data_paddr[28:0]} : data_paddr;


reg [31:0] TLB_EntryHi [31:0];
reg [31:0] TLB_PageMask [31:0];
reg [31:0] TLB_EntryLo0 [31:0];
reg [31:0] TLB_EntryLo1 [31:0];
wire [31:0] inst_find;
wire [31:0] data_find;
wire [31:0] data_vaddr;
wire TLBP,TLBR,TLBWI,TLBWR;

assign TLBP = (tlb_typeM == 3'b001) ? 1'b1 : 1'b0;
assign TLBR = (tlb_typeM == 3'b010) ? 1'b1 : 1'b0;
assign TLBWI = (tlb_typeM == 3'b011) ? 1'b1 : 1'b0;
assign TLBWR = (tlb_typeM == 3'b100) ? 1'b1 : 1'b0;

assign data_vaddr = (TLBP) ? EntryHi_in : data_vaddr_in;
	
always @(posedge clk)
begin
	if (TLBWI)
	begin
		TLB_EntryHi[Index_in[4:0]][31:13] <= EntryHi_in[31:13];
		TLB_EntryHi[Index_in[4:0]][12] <= EntryLo0_in[0] & EntryLo1_in[0];
		TLB_EntryHi[Index_in[4:0]][11:0] <= EntryHi_in[11:0];
		TLB_PageMask[Index_in[4:0]] <= PageMask_in;
		TLB_EntryLo0[Index_in[4:0]] <= {EntryLo0_in[31:1],1'b0};
		TLB_EntryLo1[Index_in[4:0]] <= {EntryLo1_in[31:1],1'b0};
	end
	else if(TLBWR)
	begin
		TLB_EntryHi[Random_in[4:0]][31:13] <= EntryHi_in[31:13];
		TLB_EntryHi[Random_in[4:0]][12] <= EntryLo0_in[0] & EntryLo1_in[0];
		TLB_EntryHi[Random_in[4:0]][11:0] <= EntryHi_in[11:0];
		TLB_PageMask[Random_in[4:0]] <= PageMask_in;
		TLB_EntryLo0[Random_in[4:0]] <= {EntryLo0_in[31:1],1'b0};
		TLB_EntryLo1[Random_in[4:0]] <= {EntryLo1_in[31:1],1'b0};
	end
end
	
genvar i;
generate 
	for (i = 0; i < 32; i = i + 1)
	begin : label1
		assign inst_find[i] = ((inst_vaddr[31:13] & ~TLB_PageMask[i][31:13]) == (TLB_EntryHi[i][31:13] & ~TLB_PageMask[i][31:13])) && (TLB_EntryHi[i][12] || TLB_EntryHi[i][7:0] == EntryHi_in[7:0]) === 1'b1; 
		assign data_find[i] = ((data_vaddr[31:13] & ~TLB_PageMask[i][31:13]) == (TLB_EntryHi[i][31:13] & ~TLB_PageMask[i][31:13])) && (TLB_EntryHi[i][12] || TLB_EntryHi[i][7:0] == EntryHi_in[7:0]) === 1'b1;		
	end
endgenerate
	
	assign inst_found = |inst_find || inst_vaddr[31] == 1'b1;
	assign data_found = |data_find || data_vaddr[31] == 1'b1;
	
	
	assign inst_paddr[11:0] = inst_vaddr[11:0];
	assign inst_paddr[31:12] = (inst_vaddr[31] == 1'b1) ? {inst_vaddr[31:12]} :
	                      ({20{inst_find[0]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[0][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[0][25:6])) |
						   {20{inst_find[1]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[1][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[1][25:6])) |
						   {20{inst_find[2]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[2][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[2][25:6])) |
						   {20{inst_find[3]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[3][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[3][25:6])) |
						   {20{inst_find[4]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[4][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[4][25:6])) |
						   {20{inst_find[5]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[5][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[5][25:6])) |
						   {20{inst_find[6]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[6][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[6][25:6])) |
						   {20{inst_find[7]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[7][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[7][25:6])) |
						   {20{inst_find[8]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[8][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[8][25:6])) |
						   {20{inst_find[9]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[9][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[9][25:6])) |
						   {20{inst_find[10]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[10][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[10][25:6])) |
						   {20{inst_find[11]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[11][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[11][25:6])) |
						   {20{inst_find[12]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[12][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[12][25:6])) |
						   {20{inst_find[13]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[13][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[13][25:6])) |
						   {20{inst_find[14]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[14][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[14][25:6])) |
						   {20{inst_find[15]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[15][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[15][25:6])) |
						   {20{inst_find[16]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[16][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[16][25:6])) |
						   {20{inst_find[17]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[17][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[17][25:6])) |
						   {20{inst_find[18]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[18][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[18][25:6])) |
						   {20{inst_find[19]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[19][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[19][25:6])) |
						   {20{inst_find[20]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[20][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[20][25:6])) |
						   {20{inst_find[21]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[21][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[21][25:6])) |
						   {20{inst_find[22]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[22][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[22][25:6])) |
						   {20{inst_find[23]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[23][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[23][25:6])) |
						   {20{inst_find[24]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[24][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[24][25:6])) |
						   {20{inst_find[25]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[25][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[25][25:6])) |
						   {20{inst_find[26]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[26][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[26][25:6])) |
						   {20{inst_find[27]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[27][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[27][25:6])) |
						   {20{inst_find[28]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[28][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[28][25:6])) |
						   {20{inst_find[29]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[29][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[29][25:6])) |
						   {20{inst_find[30]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[30][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[30][25:6])) |
						   {20{inst_find[31]}} & (({20{~inst_vaddr[12]}} & TLB_EntryLo0[31][25:6]) | ({20{inst_vaddr[12]}} & TLB_EntryLo1[31][25:6])) );
	
	assign inst_V_flag = (inst_vaddr[31] == 1'b1) ? 1'b1 :
	                (inst_find[0] & ((~inst_vaddr[12] & TLB_EntryLo0[0][1]) | (inst_vaddr[12] & TLB_EntryLo1[0][1])) |
					 inst_find[1] & ((~inst_vaddr[12] & TLB_EntryLo0[1][1]) | (inst_vaddr[12] & TLB_EntryLo1[1][1])) |
					 inst_find[2] & ((~inst_vaddr[12] & TLB_EntryLo0[2][1]) | (inst_vaddr[12] & TLB_EntryLo1[2][1])) |
					 inst_find[3] & ((~inst_vaddr[12] & TLB_EntryLo0[3][1]) | (inst_vaddr[12] & TLB_EntryLo1[3][1])) |
					 inst_find[4] & ((~inst_vaddr[12] & TLB_EntryLo0[4][1]) | (inst_vaddr[12] & TLB_EntryLo1[4][1])) |
					 inst_find[5] & ((~inst_vaddr[12] & TLB_EntryLo0[5][1]) | (inst_vaddr[12] & TLB_EntryLo1[5][1])) |
					 inst_find[6] & ((~inst_vaddr[12] & TLB_EntryLo0[6][1]) | (inst_vaddr[12] & TLB_EntryLo1[6][1])) |
					 inst_find[7] & ((~inst_vaddr[12] & TLB_EntryLo0[7][1]) | (inst_vaddr[12] & TLB_EntryLo1[7][1])) |
					 inst_find[8] & ((~inst_vaddr[12] & TLB_EntryLo0[8][1]) | (inst_vaddr[12] & TLB_EntryLo1[8][1])) |
					 inst_find[9] & ((~inst_vaddr[12] & TLB_EntryLo0[9][1]) | (inst_vaddr[12] & TLB_EntryLo1[9][1])) |
					 inst_find[10] & ((~inst_vaddr[12] & TLB_EntryLo0[10][1]) | (inst_vaddr[12] & TLB_EntryLo1[10][1])) |
					 inst_find[11] & ((~inst_vaddr[12] & TLB_EntryLo0[11][1]) | (inst_vaddr[12] & TLB_EntryLo1[11][1])) |
					 inst_find[12] & ((~inst_vaddr[12] & TLB_EntryLo0[12][1]) | (inst_vaddr[12] & TLB_EntryLo1[12][1])) |
					 inst_find[13] & ((~inst_vaddr[12] & TLB_EntryLo0[13][1]) | (inst_vaddr[12] & TLB_EntryLo1[13][1])) |
					 inst_find[14] & ((~inst_vaddr[12] & TLB_EntryLo0[14][1]) | (inst_vaddr[12] & TLB_EntryLo1[14][1])) |
					 inst_find[15] & ((~inst_vaddr[12] & TLB_EntryLo0[15][1]) | (inst_vaddr[12] & TLB_EntryLo1[15][1])) |
					 inst_find[16] & ((~inst_vaddr[12] & TLB_EntryLo0[16][1]) | (inst_vaddr[12] & TLB_EntryLo1[16][1])) |
					 inst_find[17] & ((~inst_vaddr[12] & TLB_EntryLo0[17][1]) | (inst_vaddr[12] & TLB_EntryLo1[17][1])) |
					 inst_find[18] & ((~inst_vaddr[12] & TLB_EntryLo0[18][1]) | (inst_vaddr[12] & TLB_EntryLo1[18][1])) |
					 inst_find[19] & ((~inst_vaddr[12] & TLB_EntryLo0[19][1]) | (inst_vaddr[12] & TLB_EntryLo1[19][1])) |
					 inst_find[20] & ((~inst_vaddr[12] & TLB_EntryLo0[20][1]) | (inst_vaddr[12] & TLB_EntryLo1[20][1])) |
					 inst_find[21] & ((~inst_vaddr[12] & TLB_EntryLo0[21][1]) | (inst_vaddr[12] & TLB_EntryLo1[21][1])) |
					 inst_find[22] & ((~inst_vaddr[12] & TLB_EntryLo0[22][1]) | (inst_vaddr[12] & TLB_EntryLo1[22][1])) |
					 inst_find[23] & ((~inst_vaddr[12] & TLB_EntryLo0[23][1]) | (inst_vaddr[12] & TLB_EntryLo1[23][1])) |
					 inst_find[24] & ((~inst_vaddr[12] & TLB_EntryLo0[24][1]) | (inst_vaddr[12] & TLB_EntryLo1[24][1])) |
					 inst_find[25] & ((~inst_vaddr[12] & TLB_EntryLo0[25][1]) | (inst_vaddr[12] & TLB_EntryLo1[25][1])) |
					 inst_find[26] & ((~inst_vaddr[12] & TLB_EntryLo0[26][1]) | (inst_vaddr[12] & TLB_EntryLo1[26][1])) |
					 inst_find[27] & ((~inst_vaddr[12] & TLB_EntryLo0[27][1]) | (inst_vaddr[12] & TLB_EntryLo1[27][1])) |
					 inst_find[28] & ((~inst_vaddr[12] & TLB_EntryLo0[28][1]) | (inst_vaddr[12] & TLB_EntryLo1[28][1])) |
					 inst_find[29] & ((~inst_vaddr[12] & TLB_EntryLo0[29][1]) | (inst_vaddr[12] & TLB_EntryLo1[29][1])) |
					 inst_find[30] & ((~inst_vaddr[12] & TLB_EntryLo0[30][1]) | (inst_vaddr[12] & TLB_EntryLo1[30][1])) |
					 inst_find[31] & ((~inst_vaddr[12] & TLB_EntryLo0[31][1]) | (inst_vaddr[12] & TLB_EntryLo1[31][1])) );
					 
	
	assign data_paddr[11:0] = data_vaddr[11:0];
	assign data_paddr[31:12] = (data_vaddr[31] == 1'b1) ? {data_vaddr[31:12]} :
	                      ({20{data_find[0]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[0][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[0][25:6])) |
						   {20{data_find[1]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[1][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[1][25:6])) |
						   {20{data_find[2]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[2][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[2][25:6])) |
						   {20{data_find[3]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[3][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[3][25:6])) |
						   {20{data_find[4]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[4][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[4][25:6])) |
						   {20{data_find[5]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[5][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[5][25:6])) |
						   {20{data_find[6]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[6][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[6][25:6])) |
						   {20{data_find[7]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[7][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[7][25:6])) |
						   {20{data_find[8]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[8][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[8][25:6])) |
						   {20{data_find[9]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[9][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[9][25:6])) |
						   {20{data_find[10]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[10][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[10][25:6])) |
						   {20{data_find[11]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[11][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[11][25:6])) |
						   {20{data_find[12]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[12][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[12][25:6])) |
						   {20{data_find[13]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[13][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[13][25:6])) |
						   {20{data_find[14]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[14][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[14][25:6])) |
						   {20{data_find[15]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[15][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[15][25:6])) |
						   {20{data_find[16]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[16][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[16][25:6])) |
						   {20{data_find[17]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[17][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[17][25:6])) |
						   {20{data_find[18]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[18][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[18][25:6])) |
						   {20{data_find[19]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[19][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[19][25:6])) |
						   {20{data_find[20]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[20][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[20][25:6])) |
						   {20{data_find[21]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[21][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[21][25:6])) |
						   {20{data_find[22]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[22][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[22][25:6])) |
						   {20{data_find[23]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[23][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[23][25:6])) |
						   {20{data_find[24]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[24][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[24][25:6])) |
						   {20{data_find[25]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[25][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[25][25:6])) |
						   {20{data_find[26]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[26][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[26][25:6])) |
						   {20{data_find[27]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[27][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[27][25:6])) |
						   {20{data_find[28]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[28][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[28][25:6])) |
						   {20{data_find[29]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[29][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[29][25:6])) |
						   {20{data_find[30]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[30][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[30][25:6])) |
						   {20{data_find[31]}} & (({20{~data_vaddr[12]}} & TLB_EntryLo0[31][25:6]) | ({20{data_vaddr[12]}} & TLB_EntryLo1[31][25:6])) );
	
	assign data_V_flag = (data_vaddr[31] == 1'b1) ? 1'b1 :
	                (data_find[0] & ((~data_vaddr[12] & TLB_EntryLo0[0][1]) | (data_vaddr[12] & TLB_EntryLo1[0][1])) |
					 data_find[1] & ((~data_vaddr[12] & TLB_EntryLo0[1][1]) | (data_vaddr[12] & TLB_EntryLo1[1][1])) |
					 data_find[2] & ((~data_vaddr[12] & TLB_EntryLo0[2][1]) | (data_vaddr[12] & TLB_EntryLo1[2][1])) |
					 data_find[3] & ((~data_vaddr[12] & TLB_EntryLo0[3][1]) | (data_vaddr[12] & TLB_EntryLo1[3][1])) |
					 data_find[4] & ((~data_vaddr[12] & TLB_EntryLo0[4][1]) | (data_vaddr[12] & TLB_EntryLo1[4][1])) |
					 data_find[5] & ((~data_vaddr[12] & TLB_EntryLo0[5][1]) | (data_vaddr[12] & TLB_EntryLo1[5][1])) |
					 data_find[6] & ((~data_vaddr[12] & TLB_EntryLo0[6][1]) | (data_vaddr[12] & TLB_EntryLo1[6][1])) |
					 data_find[7] & ((~data_vaddr[12] & TLB_EntryLo0[7][1]) | (data_vaddr[12] & TLB_EntryLo1[7][1])) |
					 data_find[8] & ((~data_vaddr[12] & TLB_EntryLo0[8][1]) | (data_vaddr[12] & TLB_EntryLo1[8][1])) |
					 data_find[9] & ((~data_vaddr[12] & TLB_EntryLo0[9][1]) | (data_vaddr[12] & TLB_EntryLo1[9][1])) |
					 data_find[10] & ((~data_vaddr[12] & TLB_EntryLo0[10][1]) | (data_vaddr[12] & TLB_EntryLo1[10][1])) |
					 data_find[11] & ((~data_vaddr[12] & TLB_EntryLo0[11][1]) | (data_vaddr[12] & TLB_EntryLo1[11][1])) |
					 data_find[12] & ((~data_vaddr[12] & TLB_EntryLo0[12][1]) | (data_vaddr[12] & TLB_EntryLo1[12][1])) |
					 data_find[13] & ((~data_vaddr[12] & TLB_EntryLo0[13][1]) | (data_vaddr[12] & TLB_EntryLo1[13][1])) |
					 data_find[14] & ((~data_vaddr[12] & TLB_EntryLo0[14][1]) | (data_vaddr[12] & TLB_EntryLo1[14][1])) |
					 data_find[15] & ((~data_vaddr[12] & TLB_EntryLo0[15][1]) | (data_vaddr[12] & TLB_EntryLo1[15][1])) |
					 data_find[16] & ((~data_vaddr[12] & TLB_EntryLo0[16][1]) | (data_vaddr[12] & TLB_EntryLo1[16][1])) |
					 data_find[17] & ((~data_vaddr[12] & TLB_EntryLo0[17][1]) | (data_vaddr[12] & TLB_EntryLo1[17][1])) |
					 data_find[18] & ((~data_vaddr[12] & TLB_EntryLo0[18][1]) | (data_vaddr[12] & TLB_EntryLo1[18][1])) |
					 data_find[19] & ((~data_vaddr[12] & TLB_EntryLo0[19][1]) | (data_vaddr[12] & TLB_EntryLo1[19][1])) |
					 data_find[20] & ((~data_vaddr[12] & TLB_EntryLo0[20][1]) | (data_vaddr[12] & TLB_EntryLo1[20][1])) |
					 data_find[21] & ((~data_vaddr[12] & TLB_EntryLo0[21][1]) | (data_vaddr[12] & TLB_EntryLo1[21][1])) |
					 data_find[22] & ((~data_vaddr[12] & TLB_EntryLo0[22][1]) | (data_vaddr[12] & TLB_EntryLo1[22][1])) |
					 data_find[23] & ((~data_vaddr[12] & TLB_EntryLo0[23][1]) | (data_vaddr[12] & TLB_EntryLo1[23][1])) |
					 data_find[24] & ((~data_vaddr[12] & TLB_EntryLo0[24][1]) | (data_vaddr[12] & TLB_EntryLo1[24][1])) |
					 data_find[25] & ((~data_vaddr[12] & TLB_EntryLo0[25][1]) | (data_vaddr[12] & TLB_EntryLo1[25][1])) |
					 data_find[26] & ((~data_vaddr[12] & TLB_EntryLo0[26][1]) | (data_vaddr[12] & TLB_EntryLo1[26][1])) |
					 data_find[27] & ((~data_vaddr[12] & TLB_EntryLo0[27][1]) | (data_vaddr[12] & TLB_EntryLo1[27][1])) |
					 data_find[28] & ((~data_vaddr[12] & TLB_EntryLo0[28][1]) | (data_vaddr[12] & TLB_EntryLo1[28][1])) |
					 data_find[29] & ((~data_vaddr[12] & TLB_EntryLo0[29][1]) | (data_vaddr[12] & TLB_EntryLo1[29][1])) |
					 data_find[30] & ((~data_vaddr[12] & TLB_EntryLo0[30][1]) | (data_vaddr[12] & TLB_EntryLo1[30][1])) |
					 data_find[31] & ((~data_vaddr[12] & TLB_EntryLo0[31][1]) | (data_vaddr[12] & TLB_EntryLo1[31][1])) );
					 
	assign data_D_flag = (data_vaddr[31] == 1'b1) ? 1'b1 :
	                (data_find[0] & ((~data_vaddr[12] & TLB_EntryLo0[0][2]) | (data_vaddr[12] & TLB_EntryLo1[0][2])) |
					 data_find[1] & ((~data_vaddr[12] & TLB_EntryLo0[1][2]) | (data_vaddr[12] & TLB_EntryLo1[1][2])) |
					 data_find[2] & ((~data_vaddr[12] & TLB_EntryLo0[2][2]) | (data_vaddr[12] & TLB_EntryLo1[2][2])) |
					 data_find[3] & ((~data_vaddr[12] & TLB_EntryLo0[3][2]) | (data_vaddr[12] & TLB_EntryLo1[3][2])) |
					 data_find[4] & ((~data_vaddr[12] & TLB_EntryLo0[4][2]) | (data_vaddr[12] & TLB_EntryLo1[4][2])) |
					 data_find[5] & ((~data_vaddr[12] & TLB_EntryLo0[5][2]) | (data_vaddr[12] & TLB_EntryLo1[5][2])) |
					 data_find[6] & ((~data_vaddr[12] & TLB_EntryLo0[6][2]) | (data_vaddr[12] & TLB_EntryLo1[6][2])) |
					 data_find[7] & ((~data_vaddr[12] & TLB_EntryLo0[7][2]) | (data_vaddr[12] & TLB_EntryLo1[7][2])) |
					 data_find[8] & ((~data_vaddr[12] & TLB_EntryLo0[8][2]) | (data_vaddr[12] & TLB_EntryLo1[8][2])) |
					 data_find[9] & ((~data_vaddr[12] & TLB_EntryLo0[9][2]) | (data_vaddr[12] & TLB_EntryLo1[9][2])) |
					 data_find[10] & ((~data_vaddr[12] & TLB_EntryLo0[10][2]) | (data_vaddr[12] & TLB_EntryLo1[10][2])) |
					 data_find[11] & ((~data_vaddr[12] & TLB_EntryLo0[11][2]) | (data_vaddr[12] & TLB_EntryLo1[11][2])) |
					 data_find[12] & ((~data_vaddr[12] & TLB_EntryLo0[12][2]) | (data_vaddr[12] & TLB_EntryLo1[12][2])) |
					 data_find[13] & ((~data_vaddr[12] & TLB_EntryLo0[13][2]) | (data_vaddr[12] & TLB_EntryLo1[13][2])) |
					 data_find[14] & ((~data_vaddr[12] & TLB_EntryLo0[14][2]) | (data_vaddr[12] & TLB_EntryLo1[14][2])) |
					 data_find[15] & ((~data_vaddr[12] & TLB_EntryLo0[15][2]) | (data_vaddr[12] & TLB_EntryLo1[15][2])) |
					 data_find[16] & ((~data_vaddr[12] & TLB_EntryLo0[16][2]) | (data_vaddr[12] & TLB_EntryLo1[16][2])) |
					 data_find[17] & ((~data_vaddr[12] & TLB_EntryLo0[17][2]) | (data_vaddr[12] & TLB_EntryLo1[17][2])) |
					 data_find[18] & ((~data_vaddr[12] & TLB_EntryLo0[18][2]) | (data_vaddr[12] & TLB_EntryLo1[18][2])) |
					 data_find[19] & ((~data_vaddr[12] & TLB_EntryLo0[19][2]) | (data_vaddr[12] & TLB_EntryLo1[19][2])) |
					 data_find[20] & ((~data_vaddr[12] & TLB_EntryLo0[20][2]) | (data_vaddr[12] & TLB_EntryLo1[20][2])) |
					 data_find[21] & ((~data_vaddr[12] & TLB_EntryLo0[21][2]) | (data_vaddr[12] & TLB_EntryLo1[21][2])) |
					 data_find[22] & ((~data_vaddr[12] & TLB_EntryLo0[22][2]) | (data_vaddr[12] & TLB_EntryLo1[22][2])) |
					 data_find[23] & ((~data_vaddr[12] & TLB_EntryLo0[23][2]) | (data_vaddr[12] & TLB_EntryLo1[23][2])) |
					 data_find[24] & ((~data_vaddr[12] & TLB_EntryLo0[24][2]) | (data_vaddr[12] & TLB_EntryLo1[24][2])) |
					 data_find[25] & ((~data_vaddr[12] & TLB_EntryLo0[25][2]) | (data_vaddr[12] & TLB_EntryLo1[25][2])) |
					 data_find[26] & ((~data_vaddr[12] & TLB_EntryLo0[26][2]) | (data_vaddr[12] & TLB_EntryLo1[26][2])) |
					 data_find[27] & ((~data_vaddr[12] & TLB_EntryLo0[27][2]) | (data_vaddr[12] & TLB_EntryLo1[27][2])) |
					 data_find[28] & ((~data_vaddr[12] & TLB_EntryLo0[28][2]) | (data_vaddr[12] & TLB_EntryLo1[28][2])) |
					 data_find[29] & ((~data_vaddr[12] & TLB_EntryLo0[29][2]) | (data_vaddr[12] & TLB_EntryLo1[29][2])) |
					 data_find[30] & ((~data_vaddr[12] & TLB_EntryLo0[30][2]) | (data_vaddr[12] & TLB_EntryLo1[30][2])) |
					 data_find[31] & ((~data_vaddr[12] & TLB_EntryLo0[31][2]) | (data_vaddr[12] & TLB_EntryLo1[31][2])) );
	
	assign EntryHi_out = (TLBR) ? TLB_EntryHi[Index_in[4:0]] & 32'hffffefff : 32'h0;
	assign PageMask_out = (TLBR) ? TLB_PageMask[Index_in[4:0]] : 32'h0;
	assign EntryLo0_out = (TLBR) ? TLB_EntryLo0[Index_in[4:0]] | {31'd0,TLB_EntryHi[Index_in[4:0]][12]} : 32'h0;
	assign EntryLo1_out = (TLBR) ? TLB_EntryLo1[Index_in[4:0]] | {31'd0,TLB_EntryHi[Index_in[4:0]][12]} : 32'h0;
	assign Index_out = (TLBP) ? ((!(|data_find)) ? {1'b1,Index_in[30:0]} :
						({32{data_find[0]}} & {27'd0,5'd0}) |
						({32{data_find[1]}} & {27'd0,5'd1}) |
						({32{data_find[2]}} & {27'd0,5'd2}) |
						({32{data_find[3]}} & {27'd0,5'd3}) |
						({32{data_find[4]}} & {27'd0,5'd4}) |
						({32{data_find[5]}} & {27'd0,5'd5}) |
						({32{data_find[6]}} & {27'd0,5'd6}) |
						({32{data_find[7]}} & {27'd0,5'd7}) |
						({32{data_find[8]}} & {27'd0,5'd8}) |
						({32{data_find[9]}} & {27'd0,5'd9}) |
						({32{data_find[10]}} & {27'd0,5'd10}) |
						({32{data_find[11]}} & {27'd0,5'd11}) |
						({32{data_find[12]}} & {27'd0,5'd12}) |
						({32{data_find[13]}} & {27'd0,5'd13}) |
						({32{data_find[14]}} & {27'd0,5'd14}) |
						({32{data_find[15]}} & {27'd0,5'd15}) |
						({32{data_find[16]}} & {27'd0,5'd16}) |
						({32{data_find[17]}} & {27'd0,5'd17}) |
						({32{data_find[18]}} & {27'd0,5'd18}) |
						({32{data_find[19]}} & {27'd0,5'd19}) |
						({32{data_find[20]}} & {27'd0,5'd20}) |
						({32{data_find[21]}} & {27'd0,5'd21}) |
						({32{data_find[22]}} & {27'd0,5'd22}) |
						({32{data_find[23]}} & {27'd0,5'd23}) |
						({32{data_find[24]}} & {27'd0,5'd24}) |
						({32{data_find[25]}} & {27'd0,5'd25}) |
						({32{data_find[26]}} & {27'd0,5'd26}) |
						({32{data_find[27]}} & {27'd0,5'd27}) |
						({32{data_find[28]}} & {27'd0,5'd28}) |
						({32{data_find[29]}} & {27'd0,5'd29}) |
						({32{data_find[30]}} & {27'd0,5'd30}) |
						({32{data_find[31]}} & {27'd0,5'd31}) )	: 32'h0;

endmodule