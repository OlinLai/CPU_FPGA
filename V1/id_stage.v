`include "define.vh"

module id_stage(
    /*  INPUT  */
    input   wire                        cpu_rst_n,  // reset
    input   wire    [`INST_ADDR_BUS]    id_pc_i,
    input   wire    [`INST_BUS]         id_inst_i,  // instruction from inst_rom
    input   wire    [`REG_BUS]          rd1,        // data from port1 of general register
    input   wire    [`REG_BUS]          rd2,        // data from port2 of general register


    /* INPUT: Exception */
    input   wire                    id_in_delay_i,  // whether the current instruction in delay slot
    input   wire                    flush_im,       // flush the instruction from inst_rom

    /* INPUT: Write back signal from EXE stage */
    input   wire                    exe2id_wreg,    // write enable for general register
    input   wire    [`REG_ADDR_BUS] exe2id_wa,      // address of target register
    input   wire    [`REG_BUS]      exe2id_wd,      // data of target register
    input   wire                    exe2id_mreg,    // Enable signal from memory to register

    /* INPUT: Write back signal from MEM stage */
    input   wire                    mem2id_wreg,    // write enable for general register
    input   wire    [`REG_ADDR_BUS] mem2id_wa,      // address of target register
    input   wire    [`REG_BUS]      mem2id_wd,      // data of target register
    input   wire                    mem2id_mreg,    // Enable signal from memory to register


    /* INPUT: Address of Next Instruction */
    input   wire    [`INST_ADDR_BUS] pc_plus_4,

    /* OUTPUT: Exception */
    output  wire    [`REG_ADDR_BUS]     cp0_addr,       // address of register in CP0
    output  wire    [`INST_ADDR_BUS]    id_pc_o,        // PC value
    output  wire                        id_in_delay_o,  // whether the current instruction in delay slot?
    output  wire                        next_delay_o,   // whether the next instruction in delay slot?
    output  wire    [`EXC_CODE_BUS]     id_exccode_o,   // the code of exception type


    /* OUTPUT: Request for install */
    output  wire                    stallreq_id,     // stall signal

    /* OUTPUT: Target Address of JUMP/Branch Instruction */
    output  wire    [`INST_ADDR_BUS] jump_addr_1,   // from J, JAL
    output  wire    [`INST_ADDR_BUS] jump_addr_2,   // from BEQ, BNE
    output  wire    [`INST_ADDR_BUS] jump_addr_3,   // from JR
    output  wire    [`JTSEL_BUS]     jtsel,
    output  wire    [`INST_ADDR_BUS] ret_addr,

    /*  OUTPUT  */
    output  wire    [`ALUTYPE_BUS]  id_alutype_o,   // the type of instruction
    output  wire    [`ALUOP_BUS]    id_aluop_o,     // the operate code of instruction
    output  wire                    id_whilo_o,     // write enable signal for HILO register
    output  wire                    id_mreg_o,      // enbale signal: from memory to register
    output  wire    [`REG_ADDR_BUS] id_wa_o,        // address of target register
    output  wire                    id_wreg_o,      // write enable signal for general register
    output  wire    [`REG_BUS]      id_din_o,       // data need to be written in data_rom

    /*  OUTPUT  */
    output  wire    [`REG_BUS]      id_src1_o,      // the source data1
    output  wire    [`REG_BUS]      id_src2_o,      // the source data2

    /*  OUTPUT  */
    output  wire                    rreg1,        // read enable signal for general register(port1)      
    output  wire    [`REG_ADDR_BUS] ra1,          // read address of general register(port1)
    output  wire                    rreg2,        // read enable signal for general register(port2) 
    output  wire    [`REG_ADDR_BUS] ra2           // read address of general register(port2)
    );

    // Reorganize instruction based on little-endian mode
    wire [`INST_BUS] id_inst = (flush_im == `FLUSH) ? `ZERO_WORD : {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};

    // Extract information from each segment
    /* 
        I-instruction: op + rs + rt +     imm
        R-instruction: op + rs + rt + rd + sa + func
    */                 
    wire [5:0] op   = id_inst[31:26]; // function of instruction
    wire [4:0] rs   = id_inst[25:21]; // source register, one operand
    wire [4:0] rt   = id_inst[20:16]; // I: target register, saving result; R: source register, one operand
    /*I-inst*/
    wire [15:0] imm = id_inst[15:0];  // immediate number, one operand
    
    /*R-inst*/
    wire [4:0] rd   = id_inst[15:11]; // target register, saving result
    wire [4:0] sa   = id_inst[10:6];  // only for shift instruction, others are 0
    wire [5:0] func = id_inst[5:0];   // function of instruction, op = 0
     
    /* ----- Level 1: determine the instruction requiring decoding ----- */
    // R-instruction
    wire inst_R     = ~|op;
    wire inst_add   = inst_R & (func == 6'b10_0000);
    wire inst_subu  = inst_R & (func == 6'b10_0011);
    wire inst_slt   = inst_R & (func == 6'b10_1010);
    wire inst_and   = inst_R & (func == 6'b10_0100);
    wire inst_mult  = inst_R & (func == 6'b01_1000);
    wire inst_mfhi  = inst_R & (func == 6'b01_0000);
    wire inst_mflo  = inst_R & (func == 6'b01_0010);
    wire inst_sll   = inst_R & (func == 6'b00_0000);
    wire inst_jr    = inst_R & (func == 6'b00_1000);
    wire inst_div   = inst_R & (func == 6'b01_1010);
    
    // I-instruction
    wire inst_ori   = (op == 6'b00_1101);
    wire inst_lui   = (op == 6'b00_1111);
    wire inst_addiu = (op == 6'b00_1001);
    wire inst_sltiu = (op == 6'b00_1011);
    wire inst_lb    = (op == 6'b10_0000);
    wire inst_lw    = (op == 6'b10_0011);
    wire inst_sb    = (op == 6'b10_1000);
    wire inst_sw    = (op == 6'b10_1011);
    wire inst_j     = (op == 6'b00_0010);
    wire inst_jal   = (op == 6'b00_0011);
    wire inst_beq   = (op == 6'b00_0100);
    wire inst_bne   = (op == 6'b00_0101);
    
    // Exception
    wire inst_syscall   = inst_R & (func == 6'b00_1100);
    wire inst_eret      = (op == 6'b01_0000) & (func == 6'b01_1000);
    wire inst_mfc0      = (op == 6'b01_0000) & (~id_inst[23]);
    wire inst_mtc0      = (op == 6'b01_0000) & (id_inst[23]);

    /* ----- Level 2: determine control signal based on level 1 ----- */
    // type of operation
    assign id_alutype_o[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                            (inst_sll | inst_j | inst_jal | inst_jr | inst_beq | inst_bne |
                             inst_syscall | inst_eret | inst_mtc0);
    assign id_alutype_o[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                            (inst_and | inst_mfhi | inst_mflo | inst_ori | inst_lui | 
                             inst_syscall | inst_eret | inst_mfc0 | inst_mtc0);
    assign id_alutype_o[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_add | inst_subu | inst_slt | inst_mfhi | inst_mflo |
                            inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw |
                            inst_j | inst_jal | inst_jr | inst_beq | inst_bne | inst_mfc0);
    
    // code of operation
    assign id_aluop_o[7] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : 
                            (inst_lb | inst_lw | inst_sb | inst_sw |
                            inst_syscall | inst_eret | inst_mfc0 | inst_mtc0);
    assign id_aluop_o[6] = 1'b0;
    assign id_aluop_o[5] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_slt | inst_sltiu | inst_j | inst_jal | inst_jr | inst_beq | inst_bne);
    assign id_aluop_o[4] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_add | inst_subu | inst_and | inst_mult | inst_sll |
                            inst_ori | inst_addiu | inst_lb | inst_lw | inst_sb | inst_sw |
                            inst_beq | inst_bne | inst_div);
    assign id_aluop_o[3] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_add | inst_subu | inst_and | inst_mfhi | inst_mflo |
                            inst_ori | inst_addiu | inst_sb | inst_sw | inst_j | inst_jal | inst_jr |
                            inst_mfc0 | inst_mtc0);
    assign id_aluop_o[2] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_slt | inst_and | inst_mult | inst_mfhi | inst_mflo |
                            inst_ori | inst_lui | inst_sltiu | inst_j | inst_jal | inst_jr | inst_div |
                            inst_syscall | inst_eret | inst_mfc0 | inst_mtc0);
    assign id_aluop_o[1] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_subu | inst_slt | inst_sltiu | inst_lw | inst_sw | inst_jal | inst_div |
                            inst_syscall | inst_eret);
    assign id_aluop_o[0] = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                            (inst_subu | inst_mflo |inst_sll |
                            inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_jr | inst_bne |
                            inst_eret | inst_mtc0);
    
    // write enable for General-purpose register
    assign id_wreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                        (inst_add | inst_subu | inst_slt | inst_and | inst_mfhi | inst_mflo | inst_sll |
                        inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_jal | inst_mfc0);
    
    // write enable for HILO register
    assign id_whilo_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_mult | inst_div);

    // shift enable
    wire shift = inst_sll;

    // immediate operand enable
    wire immsel = inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw;

    // select target register
    wire rstel = inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw;

    // signed expand enbale
    wire sext = inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw;

    wire upper = inst_lui;

    // enable signal: from memory to register
    assign id_mreg_o = (cpu_rst_n == `RST_ENABLE) ? 1'b0 : (inst_lb | inst_lw); 
    
    // read enable： port1 of General-purpose register
    assign rreg1 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                    (inst_add | inst_subu | inst_slt | inst_and | inst_mult |
                    inst_ori | inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw |
                    inst_jr  | inst_beq   | inst_bne | inst_div);
    
    // read enable: port2  of General-purpose register
    assign rreg2 = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                    (inst_add | inst_subu | inst_slt | inst_and | inst_mult | inst_sll | inst_sb | inst_sw |
                     inst_beq   | inst_bne | inst_div | inst_mtc0);
    
    // address of reading
    assign ra1 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rs;
    assign ra2 = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : rt;

    // get immediate operand
    wire [31:0] imm_ext = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (upper == `UPPER_ENABLE) ? (imm << 16) :
                                (sext == `SIGNED_EXT) ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};
    
    // address of writing (rt or rd)
    assign id_wa_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD : (rstel == `RT_ENABLE || inst_mfc0) ? rt : 
                        (inst_jal) ? 5'b11_111 : rd;   // JAL instruction: Record target return address in Register 31

    // Select signal for source operand
    wire [1:0] fwrd1 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 :
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra1 && rreg1 == `READ_ENABLE) ? 2'b10 :
                        (rreg1 == `READ_ENABLE) ? 2'b11 : 2'b00;
    
    wire [1:0] fwrd2 = (cpu_rst_n == `RST_ENABLE) ? 2'b00 :
                        (exe2id_wreg == `WRITE_ENABLE && exe2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b01 :
                        (mem2id_wreg == `WRITE_ENABLE && mem2id_wa == ra2 && rreg2 == `READ_ENABLE) ? 2'b10 :
                        (rreg2 == `READ_ENABLE) ? 2'b11 : 2'b00;
    
    // data need to be written into memory
    assign id_din_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (fwrd2 == 2'b01) ? exe2id_wd :
                        (fwrd2 == 2'b10) ? mem2id_wd :
                        (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    
    // source operand1
    assign id_src1_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (shift == `SHIFT_ENABLE) ? {27'b0, sa} :
                        (fwrd1 == 2'b01) ? exe2id_wd :
                        (fwrd1 == 2'b10) ? mem2id_wd :
                        (fwrd1 == 2'b11) ? rd1 : `ZERO_WORD;
    
    // source operand2
    assign id_src2_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (immsel == `IMM_ENABLE) ? imm_ext :
                        (fwrd2 == 2'b01) ? exe2id_wd :
                        (fwrd2 == 2'b10) ? mem2id_wd :
                        (fwrd2 == 2'b11) ? rd2 : `ZERO_WORD;
    
    wire equ = (cpu_rst_n == `RST_ENABLE) ? 1'b0 :
                (inst_beq) ? (id_src1_o == id_src2_o) :
                (inst_bne) ? (id_src1_o != id_src2_o) : 1'b0;
    
    assign jtsel[1] = inst_jr | (inst_beq & equ) | (inst_bne & equ);
    assign jtsel[0] = inst_j  | inst_jal | (inst_beq & equ) | (inst_bne & equ);

    // Jump/Branch Address
    wire [`INST_ADDR_BUS]   pc_plus_8   = pc_plus_4 + 32'h4;
    wire [`JUMP_BUS]        instr_index = id_inst[25:0];   // J-type instruction
    wire [`INST_ADDR_BUS]   imm_jump    = {{14{imm[15]}}, imm, 2'b00};

    assign jump_addr_1 = {pc_plus_4[31:28], instr_index, 2'b00};
    assign jump_addr_2 = {pc_plus_4 + imm_jump};
    assign jump_addr_3 = id_src1_o;
    assign ret_addr    = pc_plus_8;

    // Stall request
    wire    reg1_exe_depend = (exe2id_wreg == `WRITE_ENABLE) && (exe2id_wa == ra1) && (rreg1 == `READ_ENABLE);  // Load-Dependence-Regsiter1: ID-EXE
    wire    reg2_exe_depend = (exe2id_wreg == `WRITE_ENABLE) && (exe2id_wa == ra2) && (rreg2 == `READ_ENABLE);  // Load-Dependence-Regsiter2: ID-EXE
    
    wire    reg1_mem_depend = (mem2id_wreg == `WRITE_ENABLE) && (mem2id_wa == ra1) && (rreg1 == `READ_ENABLE);  // Load-Dependence-Regsiter1: ID-MEM
    wire    reg2_mem_depend = (mem2id_wreg == `WRITE_ENABLE) && (mem2id_wa == ra2) && (rreg2 == `READ_ENABLE);  // Load-Dependence-Regsiter2: ID-MEM


    assign stallreq_id = (cpu_rst_n == `RST_ENABLE) ? `NOSTOP : 
                            ((reg1_exe_depend || reg2_exe_depend) && (exe2id_mreg)) ? `STOP :
                            ((reg1_mem_depend || reg2_mem_depend) && (mem2id_mreg)) ? `STOP : `NOSTOP;


    // Exception
    assign id_pc_o          =   (cpu_rst_n == `RST_ENABLE) ? `PC_INIT : id_pc_i;
    assign id_in_delay_o    =   (cpu_rst_n == `RST_ENABLE) ? `FALSE_V : id_in_delay_i; 

    assign next_delay_o = (cpu_rst_n == `RST_ENABLE) ? `FALSE_V :
                            (inst_j | inst_jr | inst_jal | inst_beq | inst_bne);
    
    assign id_exccode_o = (cpu_rst_n == `RST_ENABLE) ? `EXC_NONE : 
                            (inst_syscall) ? `EXC_SYS :
                            (inst_eret) ? `EXC_ERET : `EXC_NONE;
    
    assign  cp0_addr = (cpu_rst_n == `RST_ENABLE) ? `REG_ZERO : rd;

endmodule
