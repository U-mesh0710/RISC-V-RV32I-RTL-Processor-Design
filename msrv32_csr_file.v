module msrv32_csr_file (
    input clk_in,
    input rst_in,
    input wr_en_in,
    input [11:0] csr_addr_in,
    input [2:0] csr_op_in,
    input [4:0] csr_uimm_in,
    input [31:0] csr_data_in,
    input [31:0] pc_in,
    input [31:0] iadder_in,
    input e_irq_in,
    input t_irq_in,
    input s_irq_in,
    input i_or_e_in,
    input set_cause_in,
    input [3:0] cause_in,
    input set_epc_in,
    input instret_inc_in,
    input mie_clear_in,
    input mie_set_in,
    input misaligned_exception_in,
    input [63:0] real_time_in,
    output wire mie_out,
    output wire meie_out,
    output wire mtie_out,
    output wire msie_out,
    output wire meip_out,
    output wire mtip_out,
    output wire msip_out,
    output reg [31:0] csr_data_out,
    output reg [31:0] epc_out,
    output reg [31:0] trap_address_out
);

    // Internal registers
    reg [31:0] mstatus, mie, mtvec, mscratch, mepc, mcause, mtval, mip;
    reg [63:0] mcycle, minstret;

    // Write logic
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            mstatus   <= 32'h0;
            mie       <= 32'h0;
            mtvec     <= 32'h0;
            mscratch  <= 32'h0;
            mepc      <= 32'h0;
            mcause    <= 32'h0;
            mtval     <= 32'h0;
            mip       <= 32'h0;
            mcycle    <= 64'h0;
            minstret  <= 64'h0;
            epc_out   <= 32'h0;
            trap_address_out <= 32'h0;
        end else begin
            if (wr_en_in) begin
                case (csr_addr_in)
                    12'h300: mstatus   <= csr_data_in;
                    12'h304: mie       <= csr_data_in;
                    12'h305: mtvec     <= csr_data_in;
                    12'h340: mscratch  <= csr_data_in;
                    12'h341: mepc      <= csr_data_in;
                    12'h342: mcause    <= csr_data_in;
                    12'h343: mtval     <= csr_data_in;
                    12'h344: mip       <= csr_data_in;
                    default: ; // Ignore others
                endcase
            end

            mcycle <= mcycle + 1;
            if (instret_inc_in)
                minstret <= minstret + 1;

            if (set_epc_in) begin
                epc_out <= pc_in;
                mepc    <= pc_in;
            end
            if (set_cause_in) begin
                mcause <= {28'b0, cause_in};
            end
            if (i_or_e_in)
                trap_address_out <= mtvec;
            else if (set_cause_in)
                trap_address_out <= mtvec;
        end
    end

    // CSR Read Logic
    always @(*) begin
        case (csr_addr_in)
            12'h300: csr_data_out = mstatus;
            12'h304: csr_data_out = mie;
            12'h305: csr_data_out = mtvec;
            12'h340: csr_data_out = mscratch;
            12'h341: csr_data_out = mepc;
            12'h342: csr_data_out = mcause;
            12'h343: csr_data_out = mtval;
            12'h344: csr_data_out = mip;
            default: csr_data_out = 32'h0;
        endcase
    end

    // Output assignments as wire (continuous assignment OK)
    assign mie_out   = mie[0];
    assign meie_out  = mie[11];
    assign mtie_out  = mie[7];
    assign msie_out  = mie[3];
    assign meip_out  = mip[11];
    assign mtip_out  = mip[7];
    assign msip_out  = mip[3];
endmodule

