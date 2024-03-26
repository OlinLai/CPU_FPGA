`include "define.vh"

module wb_stage(
    input   wire        cpu_rst_n,

    input   wire                        cp0_we_i,
    input   wire    [`REG_ADDR_BUS]     cp0_waddr_i,
    input   wire    [`REG_BUS]          cp0_wdata_i,

    input   wire    [`REG_ADDR_BUS]     wb_wa_i,
    input   wire                        wb_wreg_i,
    input   wire    [`REG_BUS]          wb_dreg_i,
    input   wire                        wb_mreg_i,
    input   wire    [`BSEL_BUS]         wb_dre_i,
    input   wire                        wb_whilo_i,
    input   wire    [`DOUBLE_REG_BUS]   wb_hilo_i,

    input   wire    [`WORD_BUS]         dm,

    output  wire                        cp0_we_o,
    output  wire    [`REG_ADDR_BUS]     cp0_waddr_o,
    output  wire    [`REG_BUS]          cp0_wdata_o,

    output  wire    [`REG_ADDR_BUS]     wb_wa_o,
    output  wire                        wb_wreg_o,
    output  wire    [`REG_BUS]          wb_wd_o,
    output  wire                        wb_whilo_o,
    output  wire    [`DOUBLE_REG_BUS]   wb_hilo_o
    );

    // pass them to register directly
    assign wb_wa_o    =  (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD  : wb_wa_i;
    assign wb_wreg_o  =  (cpu_rst_n == `RST_ENABLE) ? `FALSE_V    : wb_wreg_i;
    assign wb_whilo_o =  (cpu_rst_n == `RST_ENABLE) ? `FALSE_V    : wb_whilo_i;
    assign wb_hilo_o  =  (cpu_rst_n == `RST_ENABLE) ? `ZERO_DWORD : wb_hilo_i;

    // Pass them to CP0 directly
    assign cp0_we_o     = cp0_we_i;
    assign cp0_waddr_o  = cp0_waddr_i;
    assign cp0_wdata_o  = cp0_wdata_i;

    // select the specific byte of data which is from memory
    wire    [`WORD_BUS] data = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                                    (wb_dre_i == 4'b1111) ? {dm[7:0], dm[15:8], dm[23:16], dm[31:24]} :
                                    (wb_dre_i == 4'b1000) ? {{24{dm[31]}}, dm[31:24]} :
                                    (wb_dre_i == 4'b0100) ? {{24{dm[23]}}, dm[23:16]} :
                                    (wb_dre_i == 4'b0010) ? {{24{dm[15]}}, dm[15:8]}  :
                                    (wb_dre_i == 4'b0001) ? {{24{dm[7]}},  dm[7:0]}   : `ZERO_WORD;
    
    // Select: data or wb_dreg_i (memory data or exe data)
    assign wb_wd_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (wb_mreg_i == `MREG_ENABLE) ? data : wb_dreg_i;
    

endmodule
