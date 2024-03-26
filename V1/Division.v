`include "define.vh"

module Division(
    input   wire                            cpu_clk_50M,
    input   wire                            cpu_rst_n,

    input   wire                            signed_div_i,
    input   wire    [`REG_BUS]              div_opdata1,    // operand1
    input   wire    [`REG_BUS]              div_opdata2,    // operand2
    input   wire                            div_start,      // Start flag for division

    output  reg                             div_ready,
    output  reg     [`DOUBLE_REG_BUS]       div_res         // Results for division
    );

    wire    [34:0]  div_temp;
    wire    [34:0]  div_temp0;
    wire    [34:0]  div_temp1;
    wire    [34:0]  div_temp2;
    wire    [34:0]  div_temp3;
    wire    [1:0]   mul_cnt;

    reg     [5:0]   cnt;    // Record the number of division rounds

    reg     [65:0]  dividend;
    reg     [1:0]   state;
    reg     [33:0]  divisor;
    reg     [31:0]  temp_op1;
    reg     [31:0]  temp_op2;
    
    wire    [33:0]  divisor_temp;
    wire    [33:0]  divisor2;
    wire    [33:0]  divisor3;

    assign  divisor_temp = temp_op2;
    assign  divisor2     = divisor_temp << 1;
    assign  divisor3     = divisor2 + divisor;

    // Remainder - (n * dividend), n = 0, 1, 2, 3
    assign div_temp0 = {3'b0, dividend[63:32]} - {3'b0, `ZERO_WORD};
    assign div_temp1 = {3'b0, dividend[63:32]} - {1'b0, divisor};
    assign div_temp2 = {3'b0, dividend[63:32]} - {1'b0, divisor2};
    assign div_temp3 = {3'b0, dividend[63:32]} - {1'b0, divisor3};
    
    // Top bit equals to 0 -> Positive
    assign div_temp = (div_temp3[34] == 1'b0) ? div_temp3 :
                        (div_temp2[34] == 1'b0) ? div_temp2 : div_temp1;
    
    assign mul_cnt = {div_temp[34] == 1'b0} ? 2'b11 :
                        {div_temp2[34] == 1'b0} ? 2'b10 : 2'b01;
    
    always@(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE)begin
            state       <= `DIV_FREE;
            div_ready   <= `DIV_NOT_READY;
            div_res     <= {`ZERO_WORD, `ZERO_WORD};
        end
        else begin
            case(state)
                /* (1) Start division: Divisor is 0
                   (2) Start divsion: Divisor is not 0
                   (3) No division*/
                `DIV_FREE: begin
                    if(div_start == `DIV_START)begin
                        if(div_opdata2 == `ZERO_WORD)begin
                            state <= `DIV_BY_ZERO;
                        end
                        else begin
                            state   <= `DIV_ON;
                            cnt     <= 6'b00_0000;
                            if(div_opdata1[31] == 1'b1) begin   // Negative
                                temp_op1    = ~div_opdata1 + 1'b1;
                                dividend    =  temp_op1;
                            end
                            else begin
                                temp_op1    = div_opdata1;
                                dividend    =  temp_op1;
                            end

                            if(div_opdata2[31] == 1'b1) begin   // Negative
                                temp_op2    = ~div_opdata2 + 1'b1;
                                divisor     =  temp_op2;
                            end
                            else begin
                                temp_op2    = div_opdata2;
                                divisor     =  temp_op2;
                            end
                        end
                    end
                    else begin  // No division
                        div_ready   <=  `DIV_NOT_READY;
                        div_res     <=  {`ZERO_WORD, `ZERO_WORD};
                    end
                end

                /* Go into DivEnd directly, divison end, return 0 */
                `DIV_BY_ZERO: begin
                    dividend    <=  {`ZERO_WORD, `ZERO_WORD};
                    state       <=  `DIV_END;
                end

                `DIV_ON:begin
                    if(cnt != 6'b10_0010)begin  // Not end yet
                        if(div_temp[34] == 1'b1)begin   //Negative
                            dividend    <=  {dividend, 2'b00};
                        end
                        else begin
                            dividend    <=  {div_temp[31:0], dividend[31:0], mul_cnt};
                        end

                        cnt <= cnt + 2'd2;
                    end
                    else begin  // End
                        if((div_opdata1[31] ^ div_opdata2[31]) == 1'b1)begin
                            dividend[31:0]  <=  (~dividend[31:0] + 1'b1);
                        end
                        if((div_opdata1[31] ^ dividend[65]) == 1'b1)begin
                            dividend[65:34]  <=  (~dividend[65:34] + 1'b1);
                        end
                        state   <=  `DIV_END;
                        cnt     <=  6'b00_0000;
                    end 
                end

                `DIV_END:begin
                    div_res     <=  {dividend[65:34], dividend[31:0]};
                    div_ready   <=  `DIV_READY;
                    if(div_start == `DIV_STOP)begin
                        state       <=  `DIV_FREE;
                        div_ready   <=  `DIV_NOT_READY;
                        div_res     <=  {`ZERO_WORD, `ZERO_WORD};
                    end
                end
            endcase
        end
    end
endmodule
