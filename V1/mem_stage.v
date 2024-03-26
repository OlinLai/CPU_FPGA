`include "define.vh"

module mem_stage(
    input   wire                        cpu_rst_n,

    input   wire                        cp0_we_i,       // write enable for CP0
    input   wire    [`REG_ADDR_BUS]     cp0_waddr_i,    // write address for CP0
    input   wire    [`REG_BUS]          cp0_wdata_i,    // write data for CP0
    input   wire                        wb2mem_cp0_we,  // Forwarding CP0: write enable
    input   wire    [`REG_ADDR_BUS]     wb2mem_cp0_wa,  // Forwarding CP0: write address
    input   wire    [`REG_BUS]          wb2mem_cp0_wd,  // Forwarding CP0: write data

    input   wire    [`INST_ADDR_BUS]    mem_pc_i,       // PC value
    input   wire                        mem_in_delay_i, // this instruction in delay slot
    input   wire    [`EXC_CODE_BUS]     mem_exccode_i,  // exception type

    input   wire    [`WORD_BUS]         cp0_status,     // Status value in CP0
    input   wire    [`WORD_BUS]         cp0_cause,      // Cause value in CP0
    
    input   wire    [`ALUOP_BUS]        mem_aluop_i,    // operation code
    input   wire    [`REG_ADDR_BUS]     mem_wa_i,       // writing address of target register
    input   wire                        mem_wreg_i,     // write enable of target register
    input   wire    [`REG_BUS]          mem_wd_i,       // writing data of target register or address
    input   wire                        mem_mreg_i,     // enable: from memory to register
    input   wire    [`REG_BUS]          mem_din_i,      // writing data of memory
    input   wire                        mem_whilo_i,    // wrting enable of HILO register
    input   wire    [`DOUBLE_REG_BUS]   mem_hilo_i,     // writng data of HILO register

    output  wire                        cp0_we_o,       // wrtie enable for CP0
    output  wire    [`REG_ADDR_BUS]     cp0_waddr_o,    // write address for CP0
    output  wire    [`REG_BUS]          cp0_wdata_o,    // write data for CP0

    output  wire    [`INST_ADDR_BUS]    cp0_pc,         // PC value
    output  wire                        cp0_in_delay,   // this instruction in delay slot
    output  wire    [`EXC_CODE_BUS]     cp0_exccode,    // exception type

    /* Send to Wrtie Back Stage */
    output  wire    [`REG_ADDR_BUS]     mem_wa_o,       // writing address of target register
    output  wire                        mem_wreg_o,     // wrting enable of target register
    output  wire    [`REG_BUS]          mem_dreg_o,     // wrting data of targer register
    output  wire                        mem_mreg_o,     // enable: from memory to register 
    output  wire    [`BSEL_BUS]         dre,            // read enable of data memory
    output  wire                        mem_whilo_o,    // writing enable of HILO register
    output  wire    [`DOUBLE_REG_BUS]   mem_hilo_o,     // writing data of HILO register

    /* Send to data memory */
    output  wire                        dce,            // enable: data memory
    output  wire    [`INST_ADDR_BUS]    daddr,          // address of data memory
    output  wire    [`BSEL_BUS]         we,             // write enable: data memory
    output  wire    [`REG_BUS]          din             // writing data
    );

    // Instruction: access memory
    wire inst_lb = (mem_aluop_i == `MINIMIPS32_LB);
    wire inst_lw = (mem_aluop_i == `MINIMIPS32_LW);
    wire inst_sb = (mem_aluop_i == `MINIMIPS32_SB);
    wire inst_sw = (mem_aluop_i == `MINIMIPS32_SW);

    // If not, pass it to next stage(write back)
    assign mem_wa_o     = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_wa_i;
    assign mem_wreg_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_wreg_i;
    assign mem_dreg_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_wd_i;
    assign mem_whilo_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_whilo_i;
    assign mem_hilo_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_hilo_i;
    assign mem_mreg_o   = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_mreg_i;
    assign cp0_we_o     = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V : cp0_we_i;
    assign cp0_waddr_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : cp0_waddr_i;
    assign cp0_wdata_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : cp0_wdata_i;

    /* Status and Cause */
    wire    [`WORD_BUS]     status;
    wire    [`WORD_BUS]     cause;

    // Forwarding for CP0
    assign status = (wb2mem_cp0_we == `WRITE_ENABLE && wb2mem_cp0_wa == `CP0_STATUS) ? wb2mem_cp0_wd : cp0_status;
    assign cause  = (wb2mem_cp0_we == `WRITE_ENABLE && wb2mem_cp0_wa == `CP0_CAUSE)  ? wb2mem_cp0_wd : cp0_cause;

    // Pass them to CP0
    assign cp0_in_delay = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : mem_in_delay_i;
    assign cp0_exccode  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            ((status[15:10] & cause[15:10]) != 8'h00 && status[1] == 1'b0 && status[0] == 1'b1) ? `EXC_INT : mem_exccode_i;
    assign cp0_pc       = (cpu_rst_n == `RST_ENABLE) ? `PC_INIT : mem_pc_i;
    

    // Address of accessed memory
    assign daddr = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : mem_wd_i;

    // Byte Enable
    assign dre[3] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                        ((inst_lb & (daddr[1:0] == 2'b00))  | inst_lw);
    assign dre[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                        ((inst_lb & (daddr[1:0] == 2'b01))  | inst_lw);
    assign dre[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                        ((inst_lb & (daddr[1:0] == 2'b10))  | inst_lw);
    assign dre[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                        ((inst_lb & (daddr[1:0] == 2'b11))  | inst_lw);


    // Enable: data memory
    assign dce = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                    (inst_lb | inst_lw | inst_sb | inst_sw);

    // Choose which byte to write
    assign we[3] = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V :
                        ((inst_sb & (daddr[1:0] == 2'b00)) | inst_sw);
    assign we[2] = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V :
                        ((inst_sb & (daddr[1:0] == 2'b01)) | inst_sw);
    assign we[1] = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V :
                        ((inst_sb & (daddr[1:0] == 2'b10)) | inst_sw);
    assign we[0] = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V :
                        ((inst_sb & (daddr[1:0] == 2'b11)) | inst_sw);
    
    // Determine data need to be written
    wire [`WORD_BUS] din_reverse = {mem_din_i[7:0], mem_din_i[15:8], mem_din_i[23:16], mem_din_i[31:24]};
    wire [`WORD_BUS] din_byte = {4{mem_din_i[7:0]}};

    assign din = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                    (we == 4'b1111) ? din_reverse :
                    (we == 4'b1000) ? din_byte :
                    (we == 4'b0100) ? din_byte :
                    (we == 4'b0010) ? din_byte :
                    (we == 4'b0001) ? din_byte : `ZERO_WORD;

endmodule
