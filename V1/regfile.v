`include "define.vh"

module regfile(
    input   wire                        cpu_clk_50M,
    input   wire                        cpu_rst_n,

    // write port
    input   wire    [`REG_ADDR_BUS]     wa,  // address
    input   wire    [`REG_BUS]          wd,  // data
    input   wire                        we,  // write enable

    // read port 1
    input   wire    [`REG_ADDR_BUS]     ra1, // address
    input   wire                        re1, // read enable
    output  reg     [`REG_BUS]          rd1, // output data

    // read port 2
    input   wire    [`REG_ADDR_BUS]     ra2, // address
    input   wire                        re2, // read enable
    output  reg     [`REG_BUS]          rd2  // output data
    );

    // 32 registers
    reg [`REG_BUS]  regs[0: `REG_NUM-1];
    integer i;

    // write port
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE)begin
            for(i=0; i<31; i=i+1)begin
                regs[i] <= `ZERO_WORD;
            end
        end
        else begin
            if ((we == `WRITE_ENABLE) && (wa != 5'h0))
                regs[wa] <= wd;
        end
    end

    // read port1
    always@(*)begin
        if (cpu_rst_n == `RST_ENABLE)
            rd1 <= `ZERO_WORD;
        else if (ra1 == `REG_ZERO)   // No.0 register
            rd1 <= `ZERO_WORD;
        else if ((ra1 == wa) && (we ==`WRITE_ENABLE) && (re1 == `READ_ENABLE)) // Forward: WB2ID
            rd1 <= wd;
        else if (re1 == `READ_ENABLE)  // read enable
            rd1 <= regs[ra1];
        else
            rd1 <= `ZERO_WORD;
    end

    // read port2
    always@(*)begin
        if (cpu_rst_n == `RST_ENABLE)
            rd2 <= `ZERO_WORD;
        else if (ra2 == `REG_ZERO)   // No.0 register
            rd2 <= `ZERO_WORD;
        else if ((ra2 == wa) && (we ==`WRITE_ENABLE) && (re2 == `READ_ENABLE)) // Forward: WB2ID
            rd2 <= wd;
        else if (re2 == `READ_ENABLE)  // read enable
            rd2 <= regs[ra2];
        else
            rd2 <= `ZERO_WORD;
    end
    
endmodule
