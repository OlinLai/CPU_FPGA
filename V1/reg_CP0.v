`include "define.vh"

module reg_CP0(
    input   wire            cpu_clk_50M,
    input   wire            cpu_rst_n,

    input   wire                        we,         // write enable
    input   wire                        re,         // read enable
    input   wire    [`REG_ADDR_BUS]     raddr,      // read address
    input   wire    [`REG_ADDR_BUS]     waddr,      // write address
    input   wire    [`REG_BUS]          wdata,      // write data
    input   wire    [`CP0_INT_BUS]      int_i,      // hard interrupt signal

    input   wire    [`INST_ADDR_BUS]    pc_i,       // Exception victim 
    input   wire                        in_delay_i, // whether in delay slot
    input   wire    [`EXC_CODE_BUS]     exccode_i,  // exception type

    output  wire                        flush,      // flush the pipeline
    output  reg                         flush_im,   // flush the instruction fetched
    output  wire    [`REG_BUS]          cp0_excaddr,// the entrance of exception solving program    

    output  wire    [`REG_BUS]          data_o,     // read data
    output  wire    [`REG_BUS]          status_o,   // Value in Status Register
    output  wire    [`REG_BUS]          cause_o     // Value in Causse Register
    );

    reg [`REG_BUS]  badvaddr;   // Register BadVaddr
    reg [`REG_BUS]  status;     // Register Status
    reg [`REG_BUS]  cause;      // Register Cause
    reg [`REG_BUS]  epc;        // Register EPC

    assign status_o = status;
    assign cause_o  = cause;

    // If exception, flush
    assign flush = (cpu_rst_n == `RST_ENABLE) ? `NOFLUSH : 
                    (exccode_i != `EXC_NONE) ? `FLUSH : `NOFLUSH;
    
    // Flush instruction ROM
    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE)begin
            flush_im <= `NOFLUSH;
        end
        else
            flush_im <= flush;
    end

    // Solving Exception
    task do_exc;begin
        if(status[1] == 1'b0)begin
            if(in_delay_i)begin
                cause[31]   <= 1'b1;
                epc         <= pc_i - 3'd4;
            end
            else begin
                cause[31]   <= 1'b1;
                epc         <= pc_i;
            end
        end

        status[1]   <= 1'b1;
        cause[6:2]  <= exccode_i;
    end
    endtask

    // Solving ERET
    task do_eret;begin
        status[1]   <= 1'b0;
    end
    endtask

    // The entrance of Exception Solving Program
    assign cp0_excaddr = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                            (exccode_i == `EXC_INT) ? `EXC_INT_ADDR :
                            (exccode_i == `EXC_ERET && waddr == `CP0_EPC && we == `WRITE_ENABLE) ? wdata :
                            (exccode_i == `EXC_ERET) ? epc :
                            (exccode_i != `EXC_NONE) ? `EXC_ADDR : `ZERO_WORD;
    
    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE)begin
            badvaddr    <=  `ZERO_WORD;
            status      <=  32'h1000_0000;  //  status[28] == 1, which represents enable CP0
            cause       <=  `ZERO_WORD;
            epc         <=  `ZERO_WORD;
        end
        else begin
            cause[15:10] <= int_i;
            case(exccode_i)
                `EXC_NONE:begin             
                    if(we == `WRITE_ENABLE)begin        // If no exception and write inst, write data
                        case(waddr)
                            `CP0_BADVADDR:  badvaddr    <=  wdata;
                            `CP0_STATUS:    status      <=  wdata;
                            `CP0_CAUSE:     cause       <=  wdata;
                            `CP0_EPC:       epc         <=  wdata;
                        endcase
                    end
                end

                `EXC_ERET:begin     // ERET instruction
                    do_eret();
                end

                default:
                    do_exc();   // Solving exception
            endcase
        end
    end


    // Read Register
    assign data_o = (cpu_rst_n == `RST_ENABLE) ? `ZERO_WORD :
                        (re != `READ_ENABLE) ? `ZERO_WORD :
                        (raddr == `CP0_BADVADDR) ? badvaddr :
                        (raddr == `CP0_STATUS) ? status :
                        (raddr == `CP0_CAUSE) ? cause :
                        (raddr == `CP0_EPC) ? epc : `ZERO_WORD;

endmodule
