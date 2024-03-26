`define INST_ADDR_BUS 31:0
`define INST_BUS 31:0
`define WORD_BUS 31:0
`define RST_ENABLE 1'b0
`define CHIP_DISABLE 1'b0
`define CHIP_ENABLE 1'b1
`define PC_INIT 32'h0000_0000
`define ZERO_WORD  32'h0000_0000
`define ZERO_DWORD  64'h0000_0000_0000_0000
`define DOUBLE_REG_BUS 63:0 // data bidwidth of hilo register
`define REG_BUS 31:0 // data bidwidth of register
`define REG_ADDR_BUS 4:0
`define BSEL_BUS  3:0  // bidwidth of data rom selecter
`define REG_NUM 32
`define ALUTYPE_BUS 2:0
`define ALUOP_BUS 7:0
`define UPPER_ENABLE 1'b1
`define SIGNED_EXT 1'b1
`define RT_ENABLE 1'b1 
`define SHIFT_ENABLE 1'b1
`define IMM_ENABLE 1'b1
`define READ_ENABLE 1'b1
`define WRITE_ENABLE 1'b1
`define WRITE_DISABLE 1'b0
`define REG_ZERO 5'b00000
`define NOP 3'b000
`define FALSE_V 1'b0
`define MREG_ENABLE 1'b1 
`define JUMP_BUS 25:0
`define JTSEL_BUS 1:0


// Parameters for stall
`define STALL_BUS   3 : 0
`define STOP        1'b1
`define NOSTOP      1'b0

// Parameters for division
`define DIV_FREE        2'b00   // Prepare for division
`define DIV_BY_ZERO     2'b01   // Determine by 0 or not
`define DIV_ON          2'b10   // Division start state
`define DIV_END         2'b11   // Division end   state
`define DIV_READY       1'b1    // Division operate end signal
`define DIV_NOT_READY   1'b0    // Division operate not end signal
`define DIV_START       1'b1    // Division start signal
`define DIV_STOP        1'b0    // Divison not start signal

// operation type
`define JUMP        3'b101
`define NOP         3'b000
`define ARITH       3'b001 
`define LOGIC       3'b010
`define MOVE        3'b011
`define SHIFT       3'b100
`define PRIVILEGE   3'b110

// operation code
`define MINIMIPS32_LUI      8'h05
`define MINIMIPS32_MFHI     8'h0C
`define MINIMIPS32_MFLO     8'h0D
`define MINIMIPS32_SLL      8'h11
`define MINIMIPS32_MULT     8'h14
`define MINIMIPS32_ADD      8'h18
`define MINIMIPS32_ADDIU    8'h19
`define MINIMIPS32_SUBU     8'h1B
`define MINIMIPS32_AND      8'h1C
`define MINIMIPS32_ORI      8'h1D
`define MINIMIPS32_SLT      8'h26
`define MINIMIPS32_SLTIU    8'h27
`define MINIMIPS32_LB       8'h90
`define MINIMIPS32_LW       8'h92
`define MINIMIPS32_SB       8'h98
`define MINIMIPS32_SW       8'h9A
`define MINIMIPS32_J        8'h2C
`define MINIMIPS32_JR       8'h2D
`define MINIMIPS32_JAL      8'h2E
`define MINIMIPS32_BEQ      8'h30
`define MINIMIPS32_BNE      8'h31
`define MINIMIPS32_DIV      8'h16
`define MINIMIPS32_SYSCALL  8'h86
`define MINIMIPS32_ERET     8'h87
`define MINIMIPS32_MFC0     8'h8C
`define MINIMIPS32_MTC0     8'h8D


/* For Exception */
// CP0
`define CP0_INT_BUS     7:0     // the bidwidth of interrupt signal
`define CP0_BADVADDR    8       // the address of BadVAddr register
`define CP0_STATUS      12      // the address of Status register
`define CP0_CAUSE       13      // the address of Cause register
`define CP0_EPC         14      // the address of EPC register


// Exception Parameters
`define EXC_CODE_BUS    4:0     //  the width of exception type
`define EXC_INT         5'b00   //  code of interrupt exception
`define EXC_SYS         5'h08   //  code of systerm call exception
`define EXC_OV          5'h0C   //  code of integer overflow
`define EXC_NONE        5'h10   //  No exception
`define EXC_ERET        5'h11   //  ERET exception
`define EXC_ADDR        32'h100 //  entrance address of exception solving programm
`define EXC_INT_ADDR    32'h040 //  entrance address of interrupt exception programm
`define NOFLUSH         1'b0    //  Don't flush the pipeline
`define FLUSH           1'b1    //  Flush the pipeline






