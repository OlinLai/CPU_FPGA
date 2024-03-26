`include "define.vh"

module reg_exemem(

    input   wire                        cpu_clk_50M,
    input   wire                        cpu_rst_n,

    input   wire    [`STALL_BUS]        stall,        // stall signal

    input   wire                        exe_cp0_we,   // write enable for CP0
    input   wire    [`REG_ADDR_BUS]     exe_cp0_waddr,// write address for CP0
    input   wire    [`REG_BUS]          exe_cp0_wdata,// write data for CP0

    input   wire                        flush,        // flush the pipeline
    input   wire    [`INST_ADDR_BUS]    exe_pc,       // PC value  
    input   wire                        exe_in_delay, // this instruction in delay slot  
    input   wire    [`EXC_CODE_BUS]     exe_exccode,  // exception type

    input   wire    [`ALUOP_BUS]        exe_aluop,    // type of operation
    input   wire    [`REG_ADDR_BUS]     exe_wa,       // address of target register
    input   wire                        exe_wreg,     // write enable of target register
    input   wire    [`REG_BUS]          exe_wd,       // data need to be written in target register
    input   wire                        exe_mreg,     // enable: from memory to register
    input   wire    [`REG_BUS]          exe_din,      // data need to be written into memory
    input   wire                        exe_whilo,    // write enable of HILO register
    input   wire    [`DOUBLE_REG_BUS]   exe_hilo,      // data need to be written in HILO register

    output  reg                         mem_cp0_we,    // write enable for CP0
    output  reg     [`REG_ADDR_BUS]     mem_cp0_waddr, // write address for CP0
    output  reg     [`REG_BUS]          mem_cp0_wdata, // write data for CP0
    output  reg     [`INST_ADDR_BUS]    mem_pc,        // PC value
    output  reg                         mem_in_delay,  // this instruction in delay slot
    output  reg     [`EXC_CODE_BUS]     mem_exccode,   // exception type   

    output  reg     [`ALUOP_BUS]        mem_aluop,    // type of operation
    output  reg     [`REG_ADDR_BUS]     mem_wa,       // address of target register
    output  reg                         mem_wreg,     // write enable of target register
    output  reg     [`REG_BUS]          mem_wd,       // data need to be written in target register
    output  reg                         mem_mreg,     // enable: from memory to register
    output  reg     [`REG_BUS]          mem_din,      // data need to be written into memory
    output  reg                         mem_whilo,    // write enable of HILO register
    output  reg     [`DOUBLE_REG_BUS]   mem_hilo      // data need to be written in HILO register    
    );

    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE || flush)begin
            mem_aluop       <=  `MINIMIPS32_SLL;
            mem_wa          <=  `REG_ZERO;
            mem_wreg        <=  `WRITE_DISABLE;
            mem_wd          <=  `ZERO_WORD;
            mem_mreg        <=  `WRITE_DISABLE;
            mem_din         <=  `ZERO_WORD;
            mem_whilo       <=  `WRITE_DISABLE;
            mem_hilo        <=  `ZERO_DWORD;
            mem_cp0_we      <=  `FALSE_V;
            mem_cp0_waddr   <=  `ZERO_WORD;
            mem_cp0_wdata   <=  `ZERO_WORD;
            mem_pc          <=  `PC_INIT;
            mem_in_delay    <=  `FALSE_V;
            mem_exccode     <=  `EXC_NONE;
        end
        else if(stall[3] == `STOP) begin
            mem_aluop   <=  `MINIMIPS32_SLL;
            mem_wa      <=  `REG_ZERO;
            mem_wreg    <=  `WRITE_DISABLE;
            mem_wd      <=  `ZERO_WORD;
            mem_mreg    <=  `WRITE_DISABLE;
            mem_din     <=  `ZERO_WORD;
            mem_whilo   <=  `WRITE_DISABLE;
            mem_hilo    <=  `ZERO_DWORD;
            mem_cp0_we      <=  `FALSE_V;
            mem_cp0_waddr   <=  `ZERO_WORD;
            mem_cp0_wdata   <=  `ZERO_WORD;
            mem_pc          <=  `PC_INIT;
            mem_in_delay    <=  `FALSE_V;
            mem_exccode     <=  `EXC_NONE;
        end
        else if(stall[3] == `NOSTOP) begin
            mem_aluop   <=  exe_aluop;
            mem_wa      <=  exe_wa;
            mem_wreg    <=  exe_wreg;
            mem_wd      <=  exe_wd;
            mem_mreg    <=  exe_mreg;
            mem_din     <=  exe_din;
            mem_whilo   <=  exe_whilo;
            mem_hilo    <=  exe_hilo;
            mem_cp0_we      <=  exe_cp0_we;
            mem_cp0_waddr   <=  exe_cp0_waddr;
            mem_cp0_wdata   <=  exe_cp0_wdata;
            mem_pc          <=  exe_pc;
            mem_in_delay    <=  exe_in_delay;
            mem_exccode     <=  exe_exccode;
        end
    end

endmodule
