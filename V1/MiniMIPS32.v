`include "define.vh"
`include "if_stage.v"
`include "reg_ifid.v"
`include "id_stage.v"
`include "reg_idexe.v"
`include "exe_stage.v"
`include "reg_exemem.v"
`include "mem_stage.v"
`include "reg_memwb.v"
`include "wb_stage.v"
`include "regfile.v"
`include "reg_CP0.v"
`include "hilo.v"
`include "scu.v"


module MiniMIPS32(
    input   wire        cpu_clk_50M,
    input   wire        cpu_rst_n,

    /* Port0: Interruption */
    //input   wire   [`CP0_INT_BUS]       int_i,

    /* Port1: Instruction Memory */
    input   wire    [`INST_BUS]         inst,
    output  wire                        ice,
    output  wire    [`INST_ADDR_BUS]    iaddr,

    /* Port2: Data Memory */
    input   wire    [`WORD_BUS]         dm,
    output  wire                        dce,
    output  wire    [`INST_ADDR_BUS]    daddr,
    output  wire    [`BSEL_BUS]         we,
    output  wire    [`INST_BUS]         din
    );
    
    // Connect: id_stage - if_stage
    wire    [`INST_ADDR_BUS]    jump_addr_1;
    wire    [`INST_ADDR_BUS]    jump_addr_2;
    wire    [`INST_ADDR_BUS]    jump_addr_3;
    wire    [`JTSEL_BUS]        jtsel;

    // Connect: if_stage - reg_ifid
    wire    [`INST_ADDR_BUS]    pc;
    wire    [`INST_ADDR_BUS]    pc_plus_4;

    // Connect: reg_ifid - id_stage
    wire    [`INST_ADDR_BUS]    id_pc_i;
    wire    [`INST_ADDR_BUS]    id_pc_plus4_i;

    // Connect: id_stage - General Register
    wire                        re1;
    wire    [`REG_ADDR_BUS]     ra1;
    wire    [`REG_BUS]          rd1;
    wire                        re2;
    wire    [`REG_ADDR_BUS]     ra2;
    wire    [`REG_BUS]          rd2;

    // Connect: id_stage - reg_idexe
    wire    [`ALUOP_BUS]        id_aluop_o;
    wire    [`ALUTYPE_BUS]      id_alutype_o;
    wire    [`REG_BUS]          id_src1_o;
    wire    [`REG_BUS]          id_src2_o;
    wire                        id_wreg_o;
    wire    [`REG_ADDR_BUS]     id_wa_o;
    wire                        id_whilo_o;
    wire                        id_mreg_o;
    wire    [`REG_BUS]          id_din_o;
    wire    [`INST_ADDR_BUS]    id_ret_addr_o;
    wire    [`REG_ADDR_BUS]     id_cp0_addr;
    wire    [`INST_ADDR_BUS]    id_pc_o;
    wire                        id_in_delay_o;
    wire                        next_delay_o;
    wire    [`EXC_CODE_BUS]     id_exccode_o;
    wire                        exe_next_delay_o;

    //Connect: reg_idexe - exe_stage
    wire    [`ALUOP_BUS]        exe_aluop_i;
    wire    [`ALUTYPE_BUS]      exe_alutype_i;
    wire    [`REG_BUS]          exe_src1_i;
    wire    [`REG_BUS]          exe_src2_i;
    wire                        exe_wreg_i;
    wire    [`REG_ADDR_BUS]     exe_wa_i;
    wire                        exe_whilo_i;
    wire                        exe_mreg_i;
    wire    [`REG_BUS]          exe_din_i;
    wire    [`INST_ADDR_BUS]    exe_ret_addr_i;
    wire    [`REG_ADDR_BUS]     exe_cp0_addr_i;
    wire    [`INST_ADDR_BUS]    exe_pc_i;
    wire                        exe_in_delay_i;
    wire    [`EXC_CODE_BUS]     exe_exccode;

    // Connect: exe_stage - HILO
    wire    [`REG_BUS]          exe_hi_i;
    wire    [`REG_BUS]          exe_lo_i;

    // Connect: exe_stage - reg_exemem
    wire    [`ALUOP_BUS]        exe_aluop_o;
    wire                        exe_wreg_o;
    wire    [`REG_ADDR_BUS]     exe_wa_o;
    wire    [`REG_BUS]          exe_wd_o;
    wire                        exe_mreg_o;
    wire    [`REG_BUS]          exe_din_o;
    wire                        exe_whilo_o;
    wire    [`DOUBLE_REG_BUS]   exe_hilo_o;
    wire                        exe_cp0_we_o;
    wire    [`REG_ADDR_BUS]     exe_cp0_waddr_o;
    wire    [`REG_BUS]          exe_cp0_wdata_o;
    wire    [`INST_ADDR_BUS]    exe_pc_o;
    wire                        exe_in_delay_o;
    wire    [`EXC_CODE_BUS]     exe_exccode_o;

    // Connect: reg_exemem - mem_stage
    wire    [`ALUOP_BUS]        mem_aluop_i;
    wire                        mem_wreg_i;
    wire    [`REG_ADDR_BUS]     mem_wa_i;
    wire    [`REG_BUS]          mem_wd_i;
    wire                        mem_mreg_i;
    wire    [`REG_BUS]          mem_din_i;
    wire                        mem_whilo_i;
    wire    [`DOUBLE_REG_BUS]   mem_hilo_i;
    wire                        mem_cp0_we_i;
    wire    [`REG_ADDR_BUS]     mem_cp0_waddr_i;
    wire    [`REG_BUS]          mem_cp0_wdata_i;
    wire    [`INST_ADDR_BUS]    mem_pc_i;
    wire                        mem_in_delay_i;
    wire    [`EXC_CODE_BUS]     mem_exccode_i;

    // Connect: mem_stage - reg_memwb
    wire                        mem_wreg_o;
    wire    [`REG_ADDR_BUS]     mem_wa_o;
    wire    [`REG_BUS]          mem_dreg_o;
    wire                        mem_mreg_o;
    wire    [`BSEL_BUS]         mem_dre_o;
    wire                        mem_whilo_o;
    wire    [`DOUBLE_REG_BUS]   mem_hilo_o;
    wire                        mem_cp0_we_o;
    wire    [`REG_ADDR_BUS]     mem_cp0_waddr_o;
    wire    [`REG_BUS]          mem_cp0_wdata_o;

    // Connect: reg_memwb - wb_stage
    wire                        wb_wreg_i;
    wire    [`REG_ADDR_BUS]     wb_wa_i;
    wire    [`REG_BUS]          wb_dreg_i;
    wire    [`BSEL_BUS]         wb_dre_i;
    wire                        wb_mreg_i;
    wire                        wb_whilo_i;
    wire    [`DOUBLE_REG_BUS]   wb_hilo_i;
    wire                        wb_cp0_we_i;
    wire    [`REG_ADDR_BUS]     wb_cp0_waddr_i;
    wire    [`REG_BUS]          wb_cp0_wdata_i;

    // Connect: wb_stage - General Register
    wire                        wb_wreg_o;
    wire    [`REG_ADDR_BUS]     wb_wa_o;
    wire    [`REG_BUS]          wb_wd_o;

    // Connect: wb_stage - HILO register
    wire                        wb_whilo_o;
    wire    [`DOUBLE_REG_BUS]   wb_hilo_o;

    // Connect: scu - reg_exemem/reg_idexe/reg_ifid/if_stage
    wire    [`STALL_BUS]        stall;
    
    // Connect: id_stage/exe_stage - scu
    wire                        stallreq_id;
    wire                        stallreq_exe;

    // From CP0
    wire                        flush;
    wire                        flush_im;
    wire    [`REG_BUS]          cp0_excaddr;
    wire    [`REG_BUS]          cp0_data;
    wire    [`REG_BUS]          status;
    wire    [`REG_BUS]          cause;

    // Connect: exe_stage  -  CP0
    wire                    exe_cp0_re_o;
    wire    [`REG_ADDR_BUS] exe_cp0_raddr_o;

    // Connect: mem_stage  -  CP0
    wire    [`INST_ADDR_BUS]    mem_cp0_pc_o;
    wire                        mem_cp0_in_delay_o;
    wire    [`EXC_CODE_BUS]     mem_cp0_exccode_o;

    // Connect； wb_stage - CP0
    wire                        wb_cp0_we_o;
    wire    [`REG_ADDR_BUS]     wb_cp0_waddr_o;
    wire    [`REG_BUS]          wb_cp0_wdata_o;


    if_stage u1_stage_if(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .flush          (flush),
        .cp0_excaddr    (cp0_excaddr),

        .stall          (stall),

        .jump_addr_1    (jump_addr_1),
        .jump_addr_2    (jump_addr_2),
        .jump_addr_3    (jump_addr_3),
        .jtsel          (jtsel),

        .pc_plus_4      (pc_plus_4),

        .pc             (pc),
        .ice            (ice),
        .iaddr          (iaddr)
    );

    
    reg_ifid u1_reg_ifid(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),
        .if_pc          (pc),
        .if_pc_plus4    (pc_plus_4),

        .flush          (flush),

        .stall          (stall),

        .id_pc_plus4    (id_pc_plus4_i),
        .id_pc          (id_pc_i)
    );

    
    id_stage u1_stage_id(
        .cpu_rst_n      (cpu_rst_n),
        .id_pc_i        (id_pc_i),
        .id_inst_i      (inst),
        .rd1            (rd1),
        .rd2            (rd2),
        
        .id_in_delay_i  (exe_next_delay_o),
        .flush_im       (flush_im),

        .exe2id_wreg    (exe_wreg_o),
        .exe2id_wa      (exe_wa_o),
        .exe2id_wd      (exe_wd_o),
        .exe2id_mreg    (exe_mreg_o),
        .mem2id_wreg    (mem_wreg_o),
        .mem2id_wa      (mem_wa_o),
        .mem2id_wd      (mem_dreg_o),
        .mem2id_mreg    (mem_mreg_o),

        .pc_plus_4      (id_pc_plus4_i),

        .cp0_addr       (id_cp0_addr),
        .id_pc_o        (id_pc_o),
        .id_in_delay_o  (id_in_delay_o),
        .next_delay_o   (next_delay_o),
        .id_exccode_o   (id_exccode_o),

        .jump_addr_1    (jump_addr_1),
        .jump_addr_2    (jump_addr_2),
        .jump_addr_3    (jump_addr_3),
        .jtsel          (jtsel),
        .ret_addr       (id_ret_addr_o),


        .rreg1          (re1),
        .rreg2          (re2),
        .ra1            (ra1),
        .ra2            (ra2),

        .stallreq_id    (stallreq_id),

        .id_aluop_o     (id_aluop_o),
        .id_alutype_o   (id_alutype_o),
        .id_src1_o      (id_src1_o),
        .id_src2_o      (id_src2_o),
        .id_wa_o        (id_wa_o),
        .id_wreg_o      (id_wreg_o),
        .id_whilo_o     (id_whilo_o),
        .id_mreg_o      (id_mreg_o),
        .id_din_o       (id_din_o)
    );

    regfile u1_regfile(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .we             (wb_wreg_o),
        .wa             (wb_wa_o),
        .wd             (wb_wd_o),

        .re1            (re1),
        .ra1            (ra1),
        .rd1            (rd1),
        .re2            (re2),
        .ra2            (ra2),
        .rd2            (rd2)
    );


    reg_idexe u1_reg_idexe(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .stall          (stall),

        .id_cp0_addr    (id_cp0_addr),
        .id_pc          (id_pc_o),
        .id_in_delay    (id_in_delay_o),
        .next_delay_i   (next_delay_o),
        .id_exccode     (id_exccode_o),
        .flush          (flush),

        .id_alutype     (id_alutype_o),
        .id_aluop       (id_aluop_o),
        .id_src1        (id_src1_o),
        .id_src2        (id_src2_o),
        .id_wa          (id_wa_o),
        .id_wreg        (id_wreg_o),
        .id_whilo       (id_whilo_o),
        .id_mreg        (id_mreg_o),
        .id_din         (id_din_o),
        .id_ret_addr    (id_ret_addr_o),

        .exe_cp0_addr   (exe_cp0_addr_i),
        .exe_pc         (exe_pc_i),
        .exe_in_delay   (exe_in_delay_i),
        .next_delay_o   (exe_next_delay_o),
        .exe_exccode    (exe_exccode),

        .exe_ret_addr   (exe_ret_addr_i),
        .exe_alutype    (exe_alutype_i),
        .exe_aluop      (exe_aluop_i),
        .exe_src1       (exe_src1_i),
        .exe_src2       (exe_src2_i),
        .exe_wa         (exe_wa_i),
        .exe_wreg       (exe_wreg_i),
        .exe_whilo      (exe_whilo_i),
        .exe_mreg       (exe_mreg_i),
        .exe_din        (exe_din_i)
    );

    exe_stage u1_stage_exe(
        .cpu_clk_50M        (cpu_clk_50M),  
        .cpu_rst_n          (cpu_rst_n),

        .cp0_addr_i         (exe_cp0_addr_i),
        .cp0_data_i         (cp0_data),

        .mem2exe_cp0_we     (mem_cp0_we_i),
        .mem2exe_cp0_wa     (mem_cp0_waddr_i),
        .mem2exe_cp0_wd     (mem_cp0_wdata_i),
        .wb2exe_cp0_we      (wb_cp0_we_o),
        .wb2exe_cp0_wa      (wb_cp0_waddr_o),
        .wb2exe_cp0_wd      (wb_cp0_wdata_o),

        .exe_pc_i           (exe_pc_i),
        .exe_in_delay_i     (exe_in_delay_i),
        .exe_exccode_i      (exe_exccode),

        .exe_alutype_i      (exe_alutype_i),
        .exe_aluop_i        (exe_aluop_i),
        .exe_src1_i         (exe_src1_i),
        .exe_src2_i         (exe_src2_i),
        .exe_wa_i           (exe_wa_i),
        .exe_wreg_i         (exe_wreg_i),
        .exe_whilo_i        (exe_whilo_i),
        .exe_mreg_i         (exe_mreg_i),
        .exe_din_i          (exe_din_i),

        .hi_i               (exe_hi_i),
        .lo_i               (exe_lo_i),

        .ret_addr           (exe_ret_addr_i),

        .mem2exe_whilo      (mem_whilo_o),
        .mem2exe_hilo       (mem_hilo_o),
        .wb2exe_whilo       (wb_whilo_o),
        .wb2exe_hilo        (wb_hilo_o),
        
        .stallreq_exe       (stallreq_exe),

        .cp0_re_o       (exe_cp0_re_o),
        .cp0_raddr_o    (exe_cp0_raddr_o),
        .cp0_we_o       (exe_cp0_we_o),
        .cp0_waddr_o    (exe_cp0_waddr_o),
        .cp0_wdata_o    (exe_cp0_wdata_o),

        .exe_pc_o       (exe_pc_o),
        .exe_in_delay_o (exe_in_delay_o),
        .exe_exccode_o  (exe_exccode_o),

        .exe_aluop_o    (exe_aluop_o),
        .exe_wa_o       (exe_wa_o),
        .exe_wreg_o     (exe_wreg_o),
        .exe_wd_o       (exe_wd_o),
        .exe_mreg_o     (exe_mreg_o),
        .exe_din_o      (exe_din_o),
        .exe_whilo_o    (exe_whilo_o),
        .exe_hilo_o     (exe_hilo_o)
    );

    
    reg_exemem  u1_reg_exemem(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .stall          (stall),

        .exe_cp0_we     (exe_cp0_we_o),
        .exe_cp0_waddr  (exe_cp0_waddr_o),
        .exe_cp0_wdata  (exe_cp0_wdata_o),

        .flush          (flush),
        .exe_pc         (exe_pc_o),
        .exe_in_delay   (exe_in_delay_o),
        .exe_exccode    (exe_exccode_o),

        .exe_aluop      (exe_aluop_o),
        .exe_wa         (exe_wa_o),
        .exe_wreg       (exe_wreg_o),
        .exe_wd         (exe_wd_o),
        .exe_mreg       (exe_mreg_o),
        .exe_din        (exe_din_o),
        .exe_whilo      (exe_whilo_o),
        .exe_hilo       (exe_hilo_o),
        
        .mem_cp0_we     (mem_cp0_we_i),
        .mem_cp0_waddr  (mem_cp0_waddr_i),
        .mem_cp0_wdata  (mem_cp0_wdata_i),
        .mem_pc         (mem_pc_i),
        .mem_in_delay   (mem_in_delay_i),
        .mem_exccode    (mem_exccode_i),

        .mem_aluop      (mem_aluop_i),
        .mem_wa         (mem_wa_i),
        .mem_wreg       (mem_wreg_i),
        .mem_wd         (mem_wd_i),
        .mem_mreg       (mem_mreg_i),
        .mem_din        (mem_din_i),
        .mem_whilo      (mem_whilo_i),
        .mem_hilo       (mem_hilo_i)
    );

    mem_stage u1_stage_mem(
        .cpu_rst_n      (cpu_rst_n),

        .cp0_we_i       (mem_cp0_we_i),
        .cp0_waddr_i    (mem_cp0_waddr_i),
        .cp0_wdata_i    (mem_cp0_wdata_i),
        .wb2mem_cp0_we  (wb_cp0_we_o),
        .wb2mem_cp0_wa  (wb_cp0_waddr_o),
        .wb2mem_cp0_wd  (wb_cp0_wdata_o),

        .mem_pc_i       (mem_pc_i),
        .mem_in_delay_i (mem_in_delay_i),
        .mem_exccode_i  (mem_exccode_i),

        .cp0_status     (status),
        .cp0_cause      (cause),

        .mem_aluop_i    (mem_aluop_i),
        .mem_wa_i       (mem_wa_i),
        .mem_wreg_i     (mem_wreg_i),
        .mem_wd_i       (mem_wd_i),
        .mem_mreg_i     (mem_mreg_i),
        .mem_din_i      (mem_din_i),
        .mem_whilo_i    (mem_whilo_i),
        .mem_hilo_i     (mem_hilo_i),

        .cp0_we_o       (mem_cp0_we_o),
        .cp0_waddr_o    (mem_cp0_waddr_o),
        .cp0_wdata_o    (mem_cp0_wdata_o),

        .cp0_pc         (mem_cp0_pc_o),
        .cp0_in_delay   (mem_cp0_in_delay_o),
        .cp0_exccode    (mem_cp0_exccode_o),

        .mem_wa_o       (mem_wa_o),
        .mem_wreg_o     (mem_wreg_o),
        .mem_dreg_o     (mem_dreg_o),
        .mem_mreg_o     (mem_mreg_o),
        .dre            (mem_dre_o),
        .mem_whilo_o    (mem_whilo_o),
        .mem_hilo_o     (mem_hilo_o),
        .dce            (dce),
        .daddr          (daddr),
        .we             (we),
        .din            (din)
    );

    

    reg_memwb u1_reg_memwb(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .mem_cp0_we     (mem_cp0_we_o),
        .mem_cp0_waddr  (mem_cp0_waddr_o),
        .mem_cp0_wdata  (mem_cp0_wdata_o),

        .flush(flush),

        .mem_wa         (mem_wa_o),
        .mem_wreg       (mem_wreg_o),
        .mem_dreg       (mem_dreg_o),
        .mem_mreg       (mem_mreg_o),
        .mem_dre        (mem_dre_o),
        .mem_whilo      (mem_whilo_o),
        .mem_hilo       (mem_hilo_o),

        .wb_cp0_we      (wb_cp0_we_i),
        .wb_cp0_waddr   (wb_cp0_waddr_i),
        .wb_cp0_wdata   (wb_cp0_wdata_i),

        .wb_wa          (wb_wa_i),
        .wb_wreg        (wb_wreg_i),
        .wb_dreg        (wb_dreg_i),
        .wb_mreg        (wb_mreg_i),
        .wb_dre         (wb_dre_i),
        .wb_hilo        (wb_hilo_i),
        .wb_whilo       (wb_whilo_i)
    );

    wb_stage u1_stage_wb(
        .cpu_rst_n      (cpu_rst_n),

        .cp0_we_i       (wb_cp0_we_i),
        .cp0_waddr_i    (wb_cp0_waddr_i),
        .cp0_wdata_i    (wb_cp0_wdata_i),

        .wb_wa_i        (wb_wa_i),
        .wb_wreg_i      (wb_wreg_i),
        .wb_dreg_i      (wb_dreg_i),
        .wb_mreg_i      (wb_mreg_i),
        .wb_dre_i       (wb_dre_i),
        .wb_hilo_i      (wb_hilo_i),
        .wb_whilo_i     (wb_whilo_i),

        .dm             (dm),

        .cp0_we_o       (wb_cp0_we_o),
        .cp0_waddr_o    (wb_cp0_waddr_o),
        .cp0_wdata_o    (wb_cp0_wdata_o),

        .wb_wa_o        (wb_wa_o),
        .wb_wreg_o      (wb_wreg_o),
        .wb_wd_o        (wb_wd_o),
        .wb_whilo_o     (wb_whilo_o),
        .wb_hilo_o      (wb_hilo_o)      
    );

    reg_CP0 u1_reg_CP0(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .re             (exe_cp0_re_o),
        .raddr          (exe_cp0_raddr_o),
        .we             (wb_cp0_we_o),
        .waddr          (wb_cp0_waddr_o),
        .wdata          (wb_cp0_wdata_o),
        .int_i          (8'h00),

        .pc_i           (mem_cp0_pc_o),
        .in_delay_i     (mem_cp0_in_delay_o),
        .exccode_i      (mem_cp0_exccode_o),

        .flush          (flush),
        .flush_im       (flush_im),
        .cp0_excaddr    (cp0_excaddr),
        
        .data_o         (cp0_data),
        .status_o       (status),
        .cause_o        (cause)
    );

    scu u1_scu(
        .cpu_rst_n      (cpu_rst_n),
        .stallreq_id    (stallreq_id),
        .stallreq_exe   (stallreq_exe),

        .stall          (stall)
    );


    hilo hilo0(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (cpu_rst_n),

        .we             (wb_whilo_o),
        .hi_i           (wb_hilo_o[63:32]),
        .lo_i           (wb_hilo_o[31:0]),

        .hi_o           (exe_hi_i),
        .lo_o           (exe_lo_i)
    );


endmodule
