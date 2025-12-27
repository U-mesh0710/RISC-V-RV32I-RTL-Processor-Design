module msrv32_machine_control (
    input clk_in,
    input reset_in,
    input illegal_instr_in,
    input misaligned_instr_in,
    input misaligned_load_in,
    input misaligned_store_in,
    input [4:0] opcode_6_to_2_in,
    input [2:0] funct3_in,
    input [6:0] funct7_in,
    input [4:0] rs1_addr_in,
    input [4:0] rs2_addr_in,
    input e_irq_in,
    input t_irq_in,
    input s_irq_in,
    input mie_in,
    input meie_in,
    input mtie_in,
    input msie_in,
    input meip_in,
    input mtip_in,

    output reg [1:0] pc_src_out,
    output reg flush_out,
    output reg trap_taken_out,
    output reg i_or_e_out,
    output reg set_cause_out,
    output reg [3:0] cause_out,
    output reg set_epc_out,
    output reg instret_inc_out,
    output reg mie_clear_out,
    output reg mie_set_out,
    output reg misaligned_exception_out
);

    // FSM states
    reg [1:0] state;
    parameter NORMAL    = 2'b00;
    parameter TRAP      = 2'b01;
    parameter INTERRUPT = 2'b10;

    // Cause codes
    parameter INSTR_ILLEGAL    = 4'b0010;
    parameter LOAD_MISALIGN    = 4'b0001;
    parameter STORE_MISALIGN   = 4'b0000;
    parameter INTERRUPT_E      = 4'b1000;

    always @(posedge clk_in or posedge reset_in) begin
        if (reset_in) begin
            state                   <= NORMAL;
            flush_out               <= 1'b0;
            trap_taken_out          <= 1'b0;
            pc_src_out              <= 2'b11;
            i_or_e_out              <= 1'b0;
            set_cause_out           <= 1'b0;
            cause_out               <= 4'b0000;
            set_epc_out             <= 1'b0;
            instret_inc_out         <= 1'b0;
            mie_clear_out           <= 1'b0;
            mie_set_out             <= 1'b0;
            misaligned_exception_out<= 1'b0;
        end else begin
            case (state)
                NORMAL: begin
                    flush_out               <= 1'b0;
                    trap_taken_out          <= 1'b0;
                    set_cause_out           <= 1'b0;
                    set_epc_out             <= 1'b0;
                    instret_inc_out         <= 1'b0;
                    misaligned_exception_out<= 1'b0;
                    if (illegal_instr_in) begin
                        flush_out      <= 1'b1;
                        trap_taken_out <= 1'b1;
                        set_cause_out  <= 1'b1;
                        cause_out      <= INSTR_ILLEGAL;
                        set_epc_out    <= 1'b1;
                        pc_src_out     <= 2'b10;
                        state          <= TRAP;
                    end else if (misaligned_instr_in || misaligned_load_in || misaligned_store_in) begin
                        flush_out      <= 1'b1;
                        trap_taken_out <= 1'b1;
                        set_cause_out  <= 1'b1;
                        cause_out      <= misaligned_load_in ? LOAD_MISALIGN :
                                          misaligned_store_in ? STORE_MISALIGN : INSTR_ILLEGAL;
                        set_epc_out    <= 1'b1;
                        pc_src_out     <= 2'b10;
                        state          <= TRAP;
                        misaligned_exception_out <= 1'b1;
                    end else if ((e_irq_in && meie_in && mie_in) || (t_irq_in && mtie_in && mie_in) || (s_irq_in && msie_in && mie_in)) begin
                        flush_out      <= 1'b1;
                        trap_taken_out <= 1'b1;
                        set_cause_out  <= 1'b1;
                        cause_out      <= INTERRUPT_E;
                        set_epc_out    <= 1'b1;
                        i_or_e_out     <= 1'b1;
                        pc_src_out     <= 2'b10;
                        state          <= INTERRUPT;
                    end else begin
                        pc_src_out     <= 2'b11;
                        instret_inc_out<= 1'b1;
                        state          <= NORMAL;
                    end
                end
                TRAP: begin
                    flush_out  <= 1'b0;
                    trap_taken_out <= 1'b0;
                    set_cause_out  <= 1'b0;
                    set_epc_out    <= 1'b0;
                    instret_inc_out<= 1'b0;
                    misaligned_exception_out <= 1'b0;
                    pc_src_out     <= 2'b01;
                    state          <= NORMAL;
                end
                INTERRUPT: begin
                    flush_out  <= 1'b0;
                    trap_taken_out <= 1'b0;
                    set_cause_out  <= 1'b0;
                    set_epc_out    <= 1'b0;
                    instret_inc_out<= 1'b0;
                    i_or_e_out     <= 1'b0;
                    pc_src_out     <= 2'b01;
                    state          <= NORMAL;
                end
            endcase
        end
    end
endmodule

