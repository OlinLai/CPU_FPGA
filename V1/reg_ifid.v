`include "define.vh"

module reg_ifid(
    /* INPUT */
    input   wire                        cpu_clk_50M,
    input   wire                        cpu_rst_n,
    input   wire    [`INST_ADDR_BUS]    if_pc,  // pc from if_stage
    input   wire    [`INST_ADDR_BUS]    if_pc_plus4, 

    /* INPUT: flush */
    input   wire                        flush,      // Flush the pipeline

    /* INPUT: stall */
    input   wire    [`STALL_BUS]        stall,

    /* OUTPUT */
    output  reg     [`INST_ADDR_BUS]    id_pc,   // pc to id_stage
    output  reg     [`INST_ADDR_BUS]    id_pc_plus4
    );

    always @(posedge cpu_clk_50M) begin
        if(cpu_rst_n == `RST_ENABLE || flush) begin
            id_pc       <= `ZERO_WORD;    // Reset
            id_pc_plus4 <= `ZERO_WORD;    // Reset
        end 
        else if(stall[1] == `STOP && stall[2] == `NOSTOP)begin  // Stall for IF not for ID
            id_pc       <= `ZERO_WORD;    // Reset
            id_pc_plus4 <= `ZERO_WORD;    // Reset
        end
        else if(stall[1] == `NOSTOP)begin
            id_pc       <= if_pc;
            id_pc_plus4 <= if_pc_plus4;
        end
    end

endmodule
