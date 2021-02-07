`define TLBP  3'b001
`define TLBR  3'b010
`define TLBWI 3'b011
`define TLBWR 3'b100
`define TLB_LINE 32
`define TLB_WIDTH 5
`define kseg0 3'b100
`define kseg1 3'b101
`define ASID 7:0
`define VPN2 31:13
`define ASID 7:0
`define GLOBAL 0
`define VALID 1
`define DIRTY 2
module TLB(
    input  wire        clk,

    input  wire [2:0]  tlb_typeM,            

    input  wire [31:0] inst_vaddr,
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

    output wire        inst_V_flag,//inst_addr_valid
    output wire        data_V_flag,//data_addr_valid
    output wire        data_D_flag,

    output wire [31:0] inst_paddr_o,
    output wire [31:0] data_paddr_o,
    output wire        inst_found,
    output wire        data_found
);

//TLB instr
wire TLBP,TLBR,TLBWI,TLBWR;

assign TLBP = (tlb_typeM ==  `TLBP);
assign TLBR = (tlb_typeM ==  `TLBR);
assign TLBWI = (tlb_typeM == `TLBWI);
assign TLBWR = (tlb_typeM == `TLBWR);

//TLB regs
reg [31:0] PageMask [`TLB_LINE-1:0];//[31:29]:0,[28:13]:Mask,[12:0]:0
reg [31:0] EntryHi0 [`TLB_LINE-1:0];//[31:13]VPN2，虚拟地址的高位,[12:8]:0,[7:0]:ASID
reg [31:0] EntryLo0 [`TLB_LINE-1:0];//[31]:0,[30]:NE,[29:6]:PFN物理地址高位,[5:3]:Cache一致性,[2]:Dirty/Writeable,[1]:Valid,[0]Global
reg [31:0] EntryLo1 [`TLB_LINE-1:0];//[31]:0,[30]:NE,[29:6]:PFN物理地址高位,[5:3]:Cache一致性,[2]:Dirty/Writeable,[1]:Valid,[0]Global

//TLB Write
wire [`TLB_WIDTH-1:0] TLB_WritePos;
wire TLB_Write_en;
assign TLB_Write_en = (TLBWI | TLBWR) & (~Index_in[5]);//阅读了龙芯给的开源代码，由于index给了六位，但超出的部分是不写入的。
assign TLB_WritePos = TLBWR ? Random_in[`TLB_WIDTH-1:0] : Index_in[`TLB_WIDTH-1:0];

wire [31:0] PageMaskTrimed;
assign PageMaskTrimed = PageMask_in & {3'd0,16'hffff,13'd0};
wire EntryG;
assign EntryG = EntryLo0_in[`GLOBAL] & EntryLo1_in[`GLOBAL];//根据MIPS文档，Lo0和Lo1的G位都为1才是Global
always @(posedge clk) begin
    if (TLB_Write_en) begin
        PageMask[TLB_WritePos] <= PageMaskTrimed;
        EntryHi0[TLB_WritePos] <= EntryHi_in  & {~PageMaskTrimed[31:13],5'd0,8'hff};
        EntryLo0[TLB_WritePos] <= {1'b0,EntryLo0_in[30:1],EntryG};
        EntryLo1[TLB_WritePos] <= {1'b0,EntryLo1_in[30:1],EntryG};
    end
end

//TLB Match
//-- Direct Sign
wire inst_direct,data_direct;
assign inst_direct = (inst_vaddr[31:30] == 2'b10);
assign data_direct = (data_vaddr_in[31:30] == 2'b10);
//-- ASID
wire [`ASID] current_ASID;
assign current_ASID = EntryHi_in[`ASID];
//-- TLB hit
//针对多匹配情况，根据龙芯LS232处理器核用户手册-V1.0 P14, 3.1.5描述，软件要控制不要让多项命中的情况发生，因此这里不做处理
//匹配采用===，这样在TLB没有初始化的情况下依然可以正常输出信号
//---- inst
wire [4:0] inst_mask_highbit [`TLB_LINE-1:0];
wire inst_hit [`TLB_LINE-1:0];
wire inst_hit_exist;
wire [`TLB_WIDTH-1:0] inst_hit_idx;
genvar i;
generate
    for(i=0;i<`TLB_LINE;i=i+1)
    begin
        assign inst_mask_highbit[i] = 
            ( (~PageMask[i][29]) & PageMask[i][28] ? 5'd28 : 5'd0) | 
            ( (~PageMask[i][27]) & PageMask[i][26] ? 5'd26 : 5'd0) | 
            ( (~PageMask[i][25]) & PageMask[i][24] ? 5'd24 : 5'd0) | 
            ( (~PageMask[i][23]) & PageMask[i][22] ? 5'd22 : 5'd0) | 
            ( (~PageMask[i][21]) & PageMask[i][20] ? 5'd20 : 5'd0) | 
            ( (~PageMask[i][19]) & PageMask[i][18] ? 5'd18 : 5'd0) | 
            ( (~PageMask[i][17]) & PageMask[i][16] ? 5'd16 : 5'd0) | 
            ( (~PageMask[i][15]) & PageMask[i][14] ? 5'd14 : 5'd0) | 
            ( (~PageMask[i][13]) ? 5'd12 : 5'd0);
        assign inst_hit[i] = 
            (//match
                (EntryHi0[i][`ASID] === current_ASID)       | 
                (  inst_vaddr[inst_mask_highbit[i]]  & EntryLo1[i][`GLOBAL])  | 
                ((~inst_vaddr[inst_mask_highbit[i]]) & EntryLo0[i][`GLOBAL])
            )
            &
            (
                ((~PageMask[i][31:13]) & EntryHi0[i][31:13]) ===
                ((~PageMask[i][31:13]) & inst_vaddr [31:13])
            )
            ;
    end
endgenerate
assign inst_hit_exist = 
    inst_hit[ 0] | inst_hit[ 1] | inst_hit[ 2] | inst_hit[ 3] |
    inst_hit[ 4] | inst_hit[ 5] | inst_hit[ 6] | inst_hit[ 7] |
    inst_hit[ 8] | inst_hit[ 9] | inst_hit[10] | inst_hit[11] |
    inst_hit[12] | inst_hit[13] | inst_hit[14] | inst_hit[15] |
    inst_hit[16] | inst_hit[17] | inst_hit[18] | inst_hit[19] |
    inst_hit[20] | inst_hit[21] | inst_hit[22] | inst_hit[23] |
    inst_hit[24] | inst_hit[25] | inst_hit[26] | inst_hit[27] |
    inst_hit[28] | inst_hit[29] | inst_hit[30] | inst_hit[31];

assign inst_hit_idx = 
    (inst_hit[ 0] ?  0 : 0) | (inst_hit[ 1] ?  1 : 0) | (inst_hit[ 2] ?  2 : 0) | (inst_hit[ 3] ?  3 : 0) |
    (inst_hit[ 4] ?  4 : 0) | (inst_hit[ 5] ?  5 : 0) | (inst_hit[ 6] ?  6 : 0) | (inst_hit[ 7] ?  7 : 0) |
    (inst_hit[ 8] ?  8 : 0) | (inst_hit[ 9] ?  9 : 0) | (inst_hit[10] ? 10 : 0) | (inst_hit[11] ? 11 : 0) |
    (inst_hit[12] ? 12 : 0) | (inst_hit[13] ? 13 : 0) | (inst_hit[14] ? 14 : 0) | (inst_hit[15] ? 15 : 0) |
    (inst_hit[16] ? 16 : 0) | (inst_hit[17] ? 17 : 0) | (inst_hit[18] ? 18 : 0) | (inst_hit[19] ? 19 : 0) |
    (inst_hit[20] ? 20 : 0) | (inst_hit[21] ? 21 : 0) | (inst_hit[22] ? 22 : 0) | (inst_hit[23] ? 23 : 0) |
    (inst_hit[24] ? 24 : 0) | (inst_hit[25] ? 25 : 0) | (inst_hit[26] ? 26 : 0) | (inst_hit[27] ? 27 : 0) |
    (inst_hit[28] ? 28 : 0) | (inst_hit[29] ? 29 : 0) | (inst_hit[30] ? 30 : 0) | (inst_hit[31] ? 31 : 0);

//主要注意的是，由于MIPS Release 1采用了奇偶页面的设计，手册上的表格页大小指的是两个页面之一的大小。但匹配的时候相当于将那个大小*2之后进行匹配

//最终的地址逻辑是按照uCore代码写的，先把uCore跑通再说吧
assign inst_paddr_o = {
    inst_direct ? 
    (
        {3'b000,inst_vaddr[28:12]}
    )
    :
    (
        inst_hit_exist ? 
        (
            (
                (inst_vaddr[inst_mask_highbit[inst_hit_idx]] ? EntryLo1[inst_hit_idx][25:6] : EntryLo0[inst_hit_idx][25:6])
                &
                {1'b1,~PageMask[inst_hit_idx][31:13]}
            )
            |
            (
                inst_vaddr[31:12]
                &
                {1'b0,PageMask[inst_hit_idx][31:13]}
            )
        )
        :
        (
            20'd0
        )
    )
    ,
    inst_vaddr[11:0]
};

assign inst_V_flag = 
    inst_direct |
    (inst_hit_exist & (inst_vaddr[inst_mask_highbit[inst_hit_idx]] ? EntryLo1[inst_hit_idx][`VALID] : EntryLo0[inst_hit_idx][`VALID]) );

//---- data
//对于TLBP指令的查找，交由data部分进行处理。
//TODO: 龙芯文档上在TLBP指令有提到TLB[i] 140，与ASID相等是or的关系，猜测是Lo0的Global位，尚不确定。
wire [4:0] data_mask_highbit [`TLB_LINE-1:0];
wire data_hit [`TLB_LINE-1:0];
wire data_hit_exist;
wire [`TLB_WIDTH-1:0] data_hit_idx;
wire [31:0] data_vaddr_tofind;
assign data_vaddr_tofind = TLBP ? EntryHi_in : data_vaddr_in;
genvar j;
generate
    for(j=0;j<`TLB_LINE;j=j+1)
    begin
        assign data_mask_highbit[j] = 
            ( (~PageMask[j][29]) & PageMask[j][28] ? 5'd28 : 5'd0) | 
            ( (~PageMask[j][27]) & PageMask[j][26] ? 5'd26 : 5'd0) | 
            ( (~PageMask[j][25]) & PageMask[j][24] ? 5'd24 : 5'd0) | 
            ( (~PageMask[j][23]) & PageMask[j][22] ? 5'd22 : 5'd0) | 
            ( (~PageMask[j][21]) & PageMask[j][20] ? 5'd20 : 5'd0) | 
            ( (~PageMask[j][19]) & PageMask[j][18] ? 5'd18 : 5'd0) | 
            ( (~PageMask[j][17]) & PageMask[j][16] ? 5'd16 : 5'd0) | 
            ( (~PageMask[j][15]) & PageMask[j][14] ? 5'd14 : 5'd0) | 
            ( (~PageMask[j][13]) ? 5'd12 : 5'd0);
        assign data_hit[j] = 
            (//match
                (EntryHi0[j][`ASID] === current_ASID)       | 
                (  data_vaddr_tofind[data_mask_highbit[j]]  & EntryLo1[j][`GLOBAL])  | 
                ((~data_vaddr_tofind[data_mask_highbit[j]]) & EntryLo0[j][`GLOBAL])
            )
            &
            (
                ((~PageMask[j][31:13]) & EntryHi0[j][31:13]) ===
                ((~PageMask[j][31:13]) & data_vaddr_tofind[31:13])
            )
            ;
    end
endgenerate
assign data_hit_exist = 
    data_hit[ 0] | data_hit[ 1] | data_hit[ 2] | data_hit[ 3] |
    data_hit[ 4] | data_hit[ 5] | data_hit[ 6] | data_hit[ 7] |
    data_hit[ 8] | data_hit[ 9] | data_hit[10] | data_hit[11] |
    data_hit[12] | data_hit[13] | data_hit[14] | data_hit[15] |
    data_hit[16] | data_hit[17] | data_hit[18] | data_hit[19] |
    data_hit[20] | data_hit[21] | data_hit[22] | data_hit[23] |
    data_hit[24] | data_hit[25] | data_hit[26] | data_hit[27] |
    data_hit[28] | data_hit[29] | data_hit[30] | data_hit[31];

assign data_hit_idx = 
    (data_hit[ 0] ?  0 : 0) | (data_hit[ 1] ?  1 : 0) | (data_hit[ 2] ?  2 : 0) | (data_hit[ 3] ?  3 : 0) |
    (data_hit[ 4] ?  4 : 0) | (data_hit[ 5] ?  5 : 0) | (data_hit[ 6] ?  6 : 0) | (data_hit[ 7] ?  7 : 0) |
    (data_hit[ 8] ?  8 : 0) | (data_hit[ 9] ?  9 : 0) | (data_hit[10] ? 10 : 0) | (data_hit[11] ? 11 : 0) |
    (data_hit[12] ? 12 : 0) | (data_hit[13] ? 13 : 0) | (data_hit[14] ? 14 : 0) | (data_hit[15] ? 15 : 0) |
    (data_hit[16] ? 16 : 0) | (data_hit[17] ? 17 : 0) | (data_hit[18] ? 18 : 0) | (data_hit[19] ? 19 : 0) |
    (data_hit[20] ? 20 : 0) | (data_hit[21] ? 21 : 0) | (data_hit[22] ? 22 : 0) | (data_hit[23] ? 23 : 0) |
    (data_hit[24] ? 24 : 0) | (data_hit[25] ? 25 : 0) | (data_hit[26] ? 26 : 0) | (data_hit[27] ? 27 : 0) |
    (data_hit[28] ? 28 : 0) | (data_hit[29] ? 29 : 0) | (data_hit[30] ? 30 : 0) | (data_hit[31] ? 31 : 0);



//主要注意的是，由于MIPS Release 1采用了奇偶页面的设计，手册上的表格页大小指的是两个页面之一的大小。但匹配的时候相当于将那个大小*2之后进行匹配

//最终的地址逻辑是按照uCore代码写的，不确定是否符合MIPS标准，先把uCore跑通再说吧

assign data_paddr_o = {
    data_direct ? 
    (
        {3'b000,data_vaddr_in[28:12]}
    )
    :
    (
        data_hit_exist & !TLBP ?
        (
            (
                (data_vaddr_in[data_mask_highbit[data_hit_idx]] ? EntryLo1[data_hit_idx][25:6] : EntryLo0[data_hit_idx][25:6])
                &
                {1'b1,~PageMask[data_hit_idx][31:13]}
            )
            |
            (
                data_vaddr_in[31:12]
                &
                {1'b0,PageMask[data_hit_idx][31:13]}
            )
        )
        :
        (
            20'd0
        )
    )
    ,
    data_vaddr_in[11:0]
};

assign inst_found = inst_direct | inst_hit_exist;
assign data_found = data_direct | data_hit_exist | TLBP;

assign data_V_flag = 
    data_direct |
    TLBP        |
    (data_hit_exist & (data_vaddr_in[data_mask_highbit[data_hit_idx]] ? EntryLo1[data_hit_idx][`VALID] : EntryLo0[data_hit_idx][`VALID]) );

assign data_D_flag = 
    data_direct |
    (data_hit_exist & (data_vaddr_in[data_mask_highbit[data_hit_idx]] ? EntryLo1[data_hit_idx][`DIRTY] : EntryLo0[data_hit_idx][`DIRTY]) );

//TLBP
assign Index_out = TLBP ? 
    (
        data_hit_exist ? 
        (
            {27'd0,data_hit_idx}
        )
        :
        (
            {1'b1,31'd0}
        )
    ) 
    :
    32'd0;

//TLBR
assign PageMask_out = TLBR ? PageMask[TLB_WritePos] : 32'd0;
assign EntryHi_out = TLBR ? EntryHi0[TLB_WritePos] : 32'd0;
assign EntryLo0_out = TLBR? EntryLo0[TLB_WritePos] : 32'd0;
assign EntryLo1_out = TLBR? EntryLo1[TLB_WritePos] : 32'd0;
//TODO: NE
endmodule