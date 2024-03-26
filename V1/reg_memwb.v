`include "define.vh"

module reg_memwb(
    input   wire        cpu_clk_50M,
    input   wire        cpu_rst_n,

    input   wire                        mem_cp0_we,     // write enable for CP0
    input   wire    [`REG_ADDR_BUS]     mem_cp0_waddr,  // write address for CP0
    input   wire    [`REG_BUS]          mem_cp0_wdata,  // write data for CP0

    input   wire                        flush,

    input   wire    [`REG_ADDR_BUS]     mem_wa,         // writing address of target register
    input   wire                        mem_wreg,       // wrting enable of target register
    input   wire    [`REG_BUS]          mem_dreg,       // wrting data of targer register
    input   wire                        mem_mreg,       // enable: from memory to register 
    input   wire    [`BSEL_BUS]         mem_dre,        // read enable of data memory
    input   wire                        mem_whilo,      // writing enable of HILO register
    input   wire    [`DOUBLE_REG_BUS]   mem_hilo,       // writing data of HILO register

    output  reg                         wb_cp0_we,      // write enable for CP0
    output  reg     [`REG_ADDR_BUS]     wb_cp0_waddr,   // write address for CP0
    output  reg     [`REG_BUS]          wb_cp0_wdata,   // write data for CP0

    output   reg    [`REG_ADDR_BUS]     wb_wa,         // writing address of target register
    output   reg                        wb_wreg,       // wrting enable of target register
    output   reg    [`REG_BUS]          wb_dreg,       // wrting data of targer register
    output   reg                        wb_mreg,       // enable: from memory to register 
    output   reg    [`BSEL_BUS]         wb_dre,        // read enable of data memory
    output   reg                        wb_whilo,      // writing enable of HILO register
    output   reg    [`DOUBLE_REG_BUS]   wb_hilo      // writing data of HILO register
    );

    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE || flush)begin
            wb_wa       <= `REG_ZERO;
            wb_wreg     <= `WRITE_DISABLE;
            wb_dreg     <= `ZERO_WORD;
            wb_mreg     <= `WRITE_DISABLE;
            wb_dre      <= 4'b0;
            wb_whilo    <= `WRITE_DISABLE;
            wb_hilo     <= `ZERO_DWORD;

            wb_cp0_we       <= `FALSE_V;
            wb_cp0_waddr    <=  `ZERO_WORD;
            wb_cp0_wdata    <=  `ZERO_WORD;
        end
        else begin
            wb_wa       <= mem_wa;
            wb_wreg     <= mem_wreg;
            wb_dreg     <= mem_dreg;
            wb_mreg     <= mem_mreg;
            wb_dre      <= mem_dre;
            wb_whilo    <= mem_whilo;
            wb_hilo     <= mem_hilo;

            wb_cp0_we       <=  mem_cp0_we;
            wb_cp0_waddr    <=  mem_cp0_waddr;  
            wb_cp0_wdata    <=  mem_cp0_wdata;
        end
    end

endmodule
