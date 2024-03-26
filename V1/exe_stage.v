`include "define.vh"
`include "Division.v"

module exe_stage(
    
    /* INPUT */
    input   wire            cpu_clk_50M,
    input   wire            cpu_rst_n,

    input   wire    [`REG_ADDR_BUS]     cp0_addr_i,     // targer address of CP0
    input   wire    [`REG_BUS]          cp0_data_i,     // data from CP0

    /* Forwarding for cp0 */
    input   wire                        mem2exe_cp0_we, // write enable for CP0 from mem
    input   wire    [`REG_ADDR_BUS]     mem2exe_cp0_wa, // write address for CP0 from mem
    input   wire    [`REG_BUS]          mem2exe_cp0_wd, // write data for CP0 from mem
    input   wire                        wb2exe_cp0_we,  // write enable for CP0 from wb
    input   wire    [`REG_ADDR_BUS]     wb2exe_cp0_wa,  // write address for CP0 from wb
    input   wire    [`REG_BUS]          wb2exe_cp0_wd,  // write data for CP0 from wb

    input   wire    [`INST_ADDR_BUS]    exe_pc_i,       // PC value
    input   wire                        exe_in_delay_i, // whether this instruction in delay slot
    input   wire    [`EXC_CODE_BUS]     exe_exccode_i,  // exception type
    
    input   wire    [`ALUTYPE_BUS]      exe_alutype_i,  // type of operate
    input   wire    [`ALUOP_BUS]        exe_aluop_i,    // opreate code
    input   wire    [`REG_BUS]          exe_src1_i,     // source data1
    input   wire    [`REG_BUS]          exe_src2_i,     // source data2
    input   wire    [`REG_ADDR_BUS]     exe_wa_i,       // address of target register
    input   wire                        exe_wreg_i,     // write enable of target register
    input   wire                        exe_mreg_i,     // enable: from memory to register
    input   wire    [`REG_BUS]          exe_din_i,      // data need to be written in memory
    input   wire                        exe_whilo_i,    // write enable of HILO register

    input   wire    [`REG_BUS]          hi_i,           // HI from HILO register
    input   wire    [`REG_BUS]          lo_i,           // LO from HILO register

    input   wire    [`REG_BUS]          ret_addr,

    /* HI, LO from MEM stage */
    input   wire                        mem2exe_whilo,
    input   wire    [`DOUBLE_REG_BUS]   mem2exe_hilo,

    /* HI, LO from WB stage */
    input   wire                        wb2exe_whilo,
    input   wire    [`DOUBLE_REG_BUS]   wb2exe_hilo,

    /* OUPUT */
    output  wire                        stallreq_exe,

    output  wire                        cp0_re_o,       // read enable for CP0
    output  wire    [`REG_ADDR_BUS]     cp0_raddr_o,    // read address for CP0
    output  wire                        cp0_we_o,       // write enable for CP0
    output  wire    [`REG_ADDR_BUS]     cp0_waddr_o,    // write address for CP0
    output  wire    [`REG_BUS]          cp0_wdata_o,    // write data for CP0

    output  wire    [`INST_ADDR_BUS]    exe_pc_o,       // PC value
    output  wire                        exe_in_delay_o, // whether current instruction in delay slot
    output  wire    [`EXC_CODE_BUS]     exe_exccode_o,  // exception type

    output  wire    [`ALUOP_BUS]        exe_aluop_o,    // type of operation
    output  wire    [`REG_ADDR_BUS]     exe_wa_o,       // address of target register
    output  wire                        exe_wreg_o,     // write enable of target register
    output  wire    [`REG_BUS]          exe_wd_o,       // data need to be written in target register
    output  wire                        exe_mreg_o,     // enable: from memory to register
    output  wire    [`REG_BUS]          exe_din_o,      // data need to be written into memory
    output  wire                        exe_whilo_o,    // write enable of HILO register
    output  wire    [`DOUBLE_REG_BUS]   exe_hilo_o      // data need to be written in HILO register
    );

    // pass it to next stage directly
    assign exe_aluop_o      = (cpu_rst_n == `RST_ENABLE) ? 8'b0 : exe_aluop_i;
    assign exe_mreg_o       = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_mreg_i;
    assign exe_din_o        = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : exe_din_i;
    assign exe_whilo_o      = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_whilo_i;
    assign exe_pc_o         = (cpu_rst_n == `RST_ENABLE) ? `PC_INIT : exe_pc_i;
    assign exe_in_delay_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_in_delay_i;

    //  pass it to next stage directly: write data to register
    assign exe_wa_o     = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_wa_i;
    assign exe_wreg_o   = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : exe_wreg_i;

    // immediate variables
    wire    [`REG_BUS]              logic_res;  // results of logic operation
    wire    [`REG_BUS]              shift_res;  // results of shift operation
    wire    [`REG_BUS]              move_res;   // results of movement operation
    wire    [`REG_BUS]              hi_t;       // results for HI register
    wire    [`REG_BUS]              lo_t;       // results for LO register
    wire    [`REG_BUS]              arith_res;  // results of arithmetic
    wire    [`REG_BUS]              mem_res;    // results of memory
    wire    [`DOUBLE_REG_BUS]       mul_res;    // results of multiply

    // Saving the latest value in CP0
    wire    [`REG_BUS]  cp0_t;

    // For CP0
    assign cp0_we_o = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V : 
                        (exe_aluop_i == `MINIMIPS32_MTC0) ? 1'b1 : 1'b0;
    
    assign  cp0_wdata_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_MTC0) ? exe_src2_i : `ZERO_WORD;
    
    assign cp0_waddr_o = (cpu_rst_n == `RST_ENABLE) ? `REG_ZERO : cp0_addr_i;
    
    assign cp0_re_o = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V : 
                        (exe_aluop_i == `MINIMIPS32_MFC0) ? 1'b1 : 1'b0;
    
    assign cp0_raddr_o = (cpu_rst_n == `RST_ENABLE) ? `REG_ZERO : cp0_addr_i;

    // For CP0: Any data dependence? Saving the lates value in CP0
    assign cp0_t = (cp0_re_o != `READ_ENABLE) ? `ZERO_WORD:
                    (mem2exe_cp0_we == `WRITE_ENABLE && mem2exe_cp0_wa == cp0_raddr_o) ? mem2exe_cp0_wd :
                    (wb2exe_cp0_we == `WRITE_ENABLE && wb2exe_cp0_wa == cp0_raddr_o) ? wb2exe_cp0_wd : cp0_data_i;


    // logic
    assign logic_res = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_AND) ? (exe_src1_i & exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_ORI) ? (exe_src1_i | exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_LUI) ? (exe_src2_i ) : `ZERO_WORD;
    
    // shift
    assign shift_res = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_SLL) ? (exe_src2_i << exe_src1_i) : `ZERO_WORD;

    // movement
    assign hi_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : 
                    (mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[63:32] :
                    (wb2exe_whilo == `WRITE_ENABLE) ? wb2exe_hilo[63:32] : hi_i;

    assign lo_t = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                    (mem2exe_whilo == `WRITE_ENABLE) ? mem2exe_hilo[31:0] :
                    (wb2exe_whilo == `WRITE_ENABLE) ? wb2exe_hilo[31:0] : lo_i;

    assign move_res = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_MFHI) ? hi_t :
                            (exe_aluop_i == `MINIMIPS32_MFLO) ? lo_t : 
                            (exe_aluop_i == `MINIMIPS32_MFC0) ? cp0_t : `ZERO_WORD;
    
    // arithmetic
    assign arith_res = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_ADD)   ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_LB)    ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_LW)    ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_SB)    ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_SW)    ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_ADDIU) ? (exe_src1_i + exe_src2_i) :
                            (exe_aluop_i == `MINIMIPS32_SUBU)  ? (exe_src1_i + (~exe_src2_i) + 1) :
                            (exe_aluop_i == `MINIMIPS32_SLT)   ? (($signed(exe_src1_i) < $signed(exe_src2_i)) ? 32'b1 : 32'b0) :
                            (exe_aluop_i == `MINIMIPS32_SLTIU)   ? ((exe_src1_i < exe_src2_i) ? 32'b1 : 32'b0) : `ZERO_WORD;
    
    // multiply
    assign mul_res = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_MULT) ? ($signed(exe_src1_i) * $signed(exe_src2_i)) : `ZERO_WORD;


    // Any Overflow Exception ?
    wire    [31:0]  exe_src2_t  =   (exe_aluop_i == `MINIMIPS32_SUBU) ? ((~exe_src2_i) + 1) : exe_src2_i;
    wire    [31:0]  arith_tmp   =   exe_src1_i + exe_src2_t;
    wire    ov  = (!exe_src1_i[31] && !exe_src2_t[31] && arith_tmp[31]) || (exe_src1_i[31] && exe_src2_t[31] && !arith_tmp[31]);

    assign exe_exccode_o = (cpu_rst_n == `RST_ENABLE) ? `EXC_NONE : 
                            ((exe_aluop_i == `MINIMIPS32_ADD) && (ov)) ? `EXC_OV : exe_exccode_i;


    // division
    wire                        signed_div_i;
    wire    [`REG_BUS]          div_opdata1;
    wire    [`REG_BUS]          div_opdata2;
    wire                        div_start;
    wire                        div_ready;
    wire    [`DOUBLE_REG_BUS]   div_res;

    assign stallreq_exe = (cpu_rst_n == `RST_ENABLE) ? `NOSTOP :
                            ((exe_aluop_i == `MINIMIPS32_DIV) && (div_ready == `DIV_NOT_READY)) ? `STOP : `NOSTOP;
    
    assign div_opdata1 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_DIV) ? exe_src1_i : `ZERO_WORD;
    
    assign div_opdata2 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_aluop_i == `MINIMIPS32_DIV) ? exe_src2_i : `ZERO_WORD;

    assign div_start = (cpu_rst_n == `RST_ENABLE) ? `DIV_STOP :
                        ((exe_aluop_i == `MINIMIPS32_DIV) && (div_ready == `DIV_NOT_READY)) ? `DIV_START : `DIV_STOP;

    assign signed_div_i = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (exe_aluop_i == `MINIMIPS32_DIV) ? 1'b1 : 1'b0;
    
    Division u1_Division(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),
        
        .signed_div_i   (signed_div_i),
        .div_opdata1    (div_opdata1),
        .div_opdata2    (div_opdata2),
        .div_start      (div_start),

        .div_ready      (div_ready),
        .div_res        (div_res)
    );

    // Output
    assign exe_hilo_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (exe_aluop_i == `MINIMIPS32_MULT) ? mul_res:
                        (exe_aluop_i == `MINIMIPS32_DIV) ? div_res : `ZERO_WORD;

    assign exe_wd_o  = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exe_alutype_i == `LOGIC) ? logic_res :
                            (exe_alutype_i == `SHIFT) ? shift_res :
                            (exe_alutype_i == `MOVE)  ? move_res  :
                            (exe_alutype_i == `ARITH) ? arith_res : 
                            (exe_alutype_i == `JUMP)  ? ret_addr  : `ZERO_WORD;

endmodule
