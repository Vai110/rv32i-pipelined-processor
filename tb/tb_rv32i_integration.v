
`timescale 1ns/1ps

module tb_rv32i_integration;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire wb_reg_write;
    wire [4:0] wb_rd;
    wire [31:0] wb_data;

    integer errors = 0;
    integer writeback_count = 0;
    integer stall_count = 0;
    integer redirect_count = 0;
    integer i;

    reg [31:0] observed [0:31];

    rv32i_top dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data)
    );

    always #5 clk = ~clk;

    // R-type instruction encoder
    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    // I-type instruction encoder
    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    // S-type instruction encoder
    function [31:0] enc_s;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3,
                     imm[4:0], opcode};
        end
    endfunction

    // B-type instruction encoder
    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        begin
            enc_b = {imm[12], imm[10:5], rs2, rs1,
                     funct3, imm[4:1], imm[11], 7'b1100011};
        end
    endfunction

    // J-type instruction encoder
    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0] rd;
        begin
            enc_j = {imm[20], imm[10:1], imm[11],
                     imm[19:12], rd, 7'b1101111};
        end
    endfunction

    // ==========================================
    // PIPELINE MONITOR
    // ==========================================

    always @(negedge clk) begin
        if (!reset) begin

            if (wb_reg_write) begin
                observed[wb_rd] = wb_data;
                writeback_count = writeback_count + 1;

                $display("WRITEBACK: x%0d = %08h",
                         wb_rd, wb_data);
            end

            if (dut.hazard_id_ex_flush) begin
                stall_count = stall_count + 1;
                $display("LOAD-USE STALL");
            end

            if (dut.redirect) begin
                redirect_count = redirect_count + 1;
                $display("CONTROL REDIRECT: PC=%08h", pc_out);
            end
        end
    end

    // ==========================================
    // REGISTER CHECK
    // ==========================================

    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;
        begin
            if (observed[reg_num] !== expected) begin
                $display("FAIL: x%0d expected %08h got %08h",
                         reg_num, expected, observed[reg_num]);
                errors = errors + 1;
            end
            else begin
                $display("PASS: x%0d = %08h",
                         reg_num, observed[reg_num]);
            end
        end
    endtask

    // ==========================================
    // MEMORY CHECK
    // ==========================================

    task check_memory;
        input integer address;
        input [7:0] expected;
        begin
            if (dut.DMEM.memory[address] !== expected) begin
                $display("FAIL: MEM[%0d] expected %02h got %02h",
                         address, expected,
                         dut.DMEM.memory[address]);
                errors = errors + 1;
            end
            else begin
                $display("PASS: MEM[%0d] = %02h",
                         address, expected);
            end
        end
    endtask

    // ==========================================
    // MAIN TEST
    // ==========================================

    initial begin

        clk = 0;
        reset = 1;

        for (i = 0; i < 32; i = i + 1)
            observed[i] = 32'b0;

        // --------------------------------------
        // ARITHMETIC AND LOGICAL OPERATIONS
        // --------------------------------------

        // 0: ADDI x1, x0, 128
        dut.IMEM.memory[0] = enc_i(12'd128, 0, 3'b000, 1, 7'b0010011);

        // 1: ADDI x2, x0, 10
        dut.IMEM.memory[1] = enc_i(12'd10, 0, 3'b000, 2, 7'b0010011);

        // 2: ADDI x3, x2, 5
        dut.IMEM.memory[2] = enc_i(12'd5, 2, 3'b000, 3, 7'b0010011);

        // 3: ADD x4, x2, x3
        dut.IMEM.memory[3] = enc_r(7'b0000000, 3, 2, 3'b000, 4, 7'b0110011);

        // 4: SUB x5, x4, x2
        dut.IMEM.memory[4] = enc_r(7'b0100000, 2, 4, 3'b000, 5, 7'b0110011);

        // 5: ANDI x6, x4, 15
        dut.IMEM.memory[5] = enc_i(12'd15, 4, 3'b111, 6, 7'b0010011);

        // 6: ORI x7, x6, 16
        dut.IMEM.memory[6] = enc_i(12'd16, 6, 3'b110, 7, 7'b0010011);

        // 7: XORI x8, x7, 3
        dut.IMEM.memory[7] = enc_i(12'd3, 7, 3'b100, 8, 7'b0010011);

        // --------------------------------------
        // STORE, LOAD AND LOAD-USE HAZARD
        // --------------------------------------

        // 8: SW x8, 0(x1)
        dut.IMEM.memory[8] = enc_s(12'd0, 8, 1, 3'b010, 7'b0100011);

        // 9: LW x9, 0(x1)
        dut.IMEM.memory[9] = enc_i(12'd0, 1, 3'b010, 9, 7'b0000011);

        // 10: ADDI x10, x9, 1
        dut.IMEM.memory[10] = enc_i(12'd1, 9, 3'b000, 10, 7'b0010011);

        // 11: ADDI x11, x0, 27
        dut.IMEM.memory[11] = enc_i(12'd27, 0, 3'b000, 11, 7'b0010011);

        // --------------------------------------
        // CONDITIONAL BRANCHES AND FLUSH
        // --------------------------------------

        // 12: BEQ x10, x11, +8 (taken)
        dut.IMEM.memory[12] = enc_b(13'd8, 11, 10, 3'b000);

        // 13: ADDI x12, x0, 99 (must be flushed)
        dut.IMEM.memory[13] = enc_i(12'd99, 0, 3'b000, 12, 7'b0010011);

        // 14: BNE x10, x11, +8 (not taken)
        dut.IMEM.memory[14] = enc_b(13'd8, 11, 10, 3'b001);

        // 15: ADDI x13, x0, 7
        dut.IMEM.memory[15] = enc_i(12'd7, 0, 3'b000, 13, 7'b0010011);

        // --------------------------------------
        // JAL
        // --------------------------------------

        // 16: JAL x14, +8
        dut.IMEM.memory[16] = enc_j(21'd8, 14);

        // 17: ADDI x15, x0, 99 (must be flushed)
        dut.IMEM.memory[17] = enc_i(12'd99, 0, 3'b000, 15, 7'b0010011);

        // --------------------------------------
        // JALR
        // --------------------------------------

        // 18: ADDI x17, x0, 88
        dut.IMEM.memory[18] = enc_i(12'd88, 0, 3'b000, 17, 7'b0010011);

        // 19: JALR x18, 0(x17)
        dut.IMEM.memory[19] = enc_i(12'd0, 17, 3'b000, 18, 7'b1100111);

        // 20: ADDI x19, x0, 99 (must be flushed)
        dut.IMEM.memory[20] = enc_i(12'd99, 0, 3'b000, 19, 7'b0010011);

        // 21: ADDI x20, x0, 99 (must be flushed)
        dut.IMEM.memory[21] = enc_i(12'd99, 0, 3'b000, 20, 7'b0010011);

        // 22: ADDI x21, x0, 42
        dut.IMEM.memory[22] = enc_i(12'd42, 0, 3'b000, 21, 7'b0010011);

        // --------------------------------------
        // RESET RELEASE
        // --------------------------------------

        #12;
        reset = 0;

        repeat (45) @(negedge clk);

        // ======================================
        // REGISTER VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" INTEGRATION REGISTER VERIFICATION");
        $display("======================================");

        check_register(0,  32'd0);
        check_register(1,  32'd128);
        check_register(2,  32'd10);
        check_register(3,  32'd15);
        check_register(4,  32'd25);
        check_register(5,  32'd15);
        check_register(6,  32'd9);
        check_register(7,  32'd25);
        check_register(8,  32'd26);
        check_register(9,  32'd26);
        check_register(10, 32'd27);
        check_register(11, 32'd27);

        // Wrong-path instructions must not execute
        check_register(12, 32'd0);
        check_register(15, 32'd0);
        check_register(19, 32'd0);
        check_register(20, 32'd0);

        check_register(13, 32'd7);
        check_register(14, 32'd68);
        check_register(17, 32'd88);
        check_register(18, 32'd80);
        check_register(21, 32'd42);

        // ======================================
        // MEMORY VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" INTEGRATION MEMORY VERIFICATION");
        $display("======================================");

        check_memory(128, 8'h1a);
        check_memory(129, 8'h00);
        check_memory(130, 8'h00);
        check_memory(131, 8'h00);

        // ======================================
        // PIPELINE VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" PIPELINE VERIFICATION");
        $display("======================================");

        $display("Writebacks : %0d", writeback_count);
        $display("Stalls     : %0d", stall_count);
        $display("Redirects  : %0d", redirect_count);

        if (writeback_count != 16) begin
            $display("FAIL: Expected 16 writebacks");
            errors = errors + 1;
        end

        if (stall_count != 1) begin
            $display("FAIL: Expected 1 load-use stall");
            errors = errors + 1;
        end

        if (redirect_count != 3) begin
            $display("FAIL: Expected 3 redirects");
            errors = errors + 1;
        end

        // ======================================
        // FINAL SUMMARY
        // ======================================

        $display("");
        $display("======================================");
        $display(" INTEGRATION TEST SUMMARY");
        $display("======================================");

        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("ALL INTEGRATION TESTS PASSED");
        else
            $display("INTEGRATION TESTS FAILED");

        $display("======================================");

        $finish;

    end

endmodule
