`include "define.vh"

module if_stage(
    /*  INPUT   */
    input   wire    cpu_clk_50M,   // clock of cpu
    input   wire    cpu_rst_n,     // reset of cpu

    /* INPUT: Exception */
    input   wire                    flush,          // the signal of flushing the pipeline
    input   wire [`INST_ADDR_BUS]   cp0_excaddr,    // the entrance address of exception solving program

    /*  INPUT: PC Address from Jump/Branch Instruction */
    input   wire [`INST_ADDR_BUS]   jump_addr_1,    // from J, JAL
    input   wire [`INST_ADDR_BUS]   jump_addr_2,    // from BEQ, BNE
    input   wire [`INST_ADDR_BUS]   jump_addr_3,    // from JR
    input   wire [`JTSEL_BUS]       jtsel,          // select signal

    /* INPUT: Stall */
    input   wire    [`STALL_BUS]    stall,


    /*  OUTPUT */
    output   wire [`INST_ADDR_BUS]   pc_plus_4,     // Next instruction
    
    /*  OUTPUT   */
    output                           ice,   // enable signal of inst_RAM
    output  reg  [`INST_ADDR_BUS]    pc,    // pc register
    output  wire [`INST_ADDR_BUS]    iaddr  // address of instruction
    );


    assign pc_plus_4 = (cpu_rst_n == `RST_ENABLE) ? `PC_INIT : pc +32'h4;


    wire [`INST_ADDR_BUS] pc_next;
    assign  pc_next = (jtsel == 2'b00) ? pc_plus_4 :
                        (jtsel == 2'b01) ? jump_addr_1 :
                        (jtsel == 2'b10) ? jump_addr_3 :
                        (jtsel == 2'b11) ? jump_addr_2 : `PC_INIT;

    // ice
    reg ce;
    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE)
            ce <= `CHIP_DISABLE;
        else
            ce <= `CHIP_ENABLE;
    end
    
    assign ice = (stall[1] || flush) ? 0 : ce;  // Stall or not

    // pc
    always @(posedge cpu_clk_50M) begin
        if (ce == `CHIP_DISABLE)
            pc <= `PC_INIT;
        else begin
            if(flush)                       // Exception: PC should be the entrance of exception solving
                pc <= cp0_excaddr;
            else if(stall[0] == `NOSTOP)    // Stall or not: If stall, pc keep the same
                pc <= pc_next;
        end
    end

    // address of instruction
    assign iaddr = (ice == `CHIP_DISABLE) ? `PC_INIT : pc;
    
endmodule
