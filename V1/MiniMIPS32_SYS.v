`timescale 1ns / 1ps
`include "define.vh"


module MiniMIPS32_SYS(
    input   wire    sys_clk_100M,
    input   wire    sys_rst_n,

    output  wire    ice
    );

    wire                        cpu_clk_50M;
    wire    [`INST_ADDR_BUS]    iaddr;
    //wire                        ice;
    wire    [`INST_BUS]         inst;
    wire                        dce;
    wire    [`INST_ADDR_BUS]    daddr;
    wire    [`BSEL_BUS]         we;
    wire    [`INST_BUS]         din;
    wire    [`INST_BUS]         dout;

    clk_wiz_0 u1_clk_wiz_0
   (
    // Clock out ports
    .clk_out1_50M(cpu_clk_50M),     // output clk_out1_50M
    // Status and control signals
    .reset(1'b0), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1_100M(sys_clk_100M));      // input clk_in1_100M

    ROM_inst u1_ROM_inst (
        .clka   (cpu_clk_50M),  // input wire clka
        .ena    (ice),          // input wire ena
        .addra  (iaddr[12:2]),  // input wire [10 : 0] addra
        .douta  (inst)          // output wire [31 : 0] douta
    );

    MiniMIPS32 u1_MiniMIPS32(
        .cpu_clk_50M    (cpu_clk_50M),
        .cpu_rst_n      (sys_rst_n),

        .ice            (ice),
        .iaddr          (iaddr),
        .inst           (inst),

        .dce            (dce),
        .daddr          (daddr),
        .we             (we),
        .din            (din),
        .dm             (dout)
    );

    RAM_data u1_RAM_data (
        .clka   (cpu_clk_50M),  // input wire clka
        .ena    (dce),          // input wire ena
        .wea    (we),           // input wire [3 : 0] wea
        .addra  (daddr[12:2]),  // input wire [10 : 0] addra
        .dina   (din),          // input wire [31 : 0] dina
        .douta  (dout)          // output wire [31 : 0] douta
    );


endmodule
