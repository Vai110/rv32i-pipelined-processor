
`timescale 1ns/1ps

module tb_rv32i_top;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire wb_reg_write;
    wire [4:0] wb_rd;
    wire [31:0] wb_data;

    integer errors = 0;
    integer writeback_count = 0;
    integer stall_count = 0;
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

    // ==========================================
    // WRITEBACK AND HAZARD MONITOR
    // ==========================================

    always @(negedge clk) begin
        if (!reset) begin

            if (wb_reg_write) begin
                observed[wb_rd] = wb_data;
                writeback_count = writeback_count + 1;

                $display(
                    "WRITEBACK: x%0d = %08h",
                    wb_rd, wb_data
                );
            end

            if (dut.hazard_id_ex_flush) begin
                stall_count = stall_count + 1;
                $display("LOAD-USE STALL DETECTED");
            end

        end
    end

    // ==========================================
    // LOAD DIAGNOSTIC MONITOR
    // ==========================================

    always @(negedge clk) begin
        if (!reset && dut.ex_mem_mem_read) begin

            $display(
                "LOAD DEBUG: ADDR=%08h FUNCT3=%03b MEM=%02h READ=%08h WB_SEL=%02b",
                dut.ex_mem_alu_result,
                dut.ex_mem_funct3,
                dut.DMEM.memory[dut.ex_mem_alu_result],
                dut.mem_read_data,
                dut.mem_wb_wb_sel
            );

        end
    end

    // ==========================================
    // REGISTER CHECK TASK
    // ==========================================

    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;

        begin
            if (observed[reg_num] !== expected) begin

                $display(
                    "FAIL: x%0d expected %08h, got %08h",
                    reg_num, expected, observed[reg_num]
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: x%0d = %08h",
                    reg_num, observed[reg_num]
                );

            end
        end
    endtask

    // ==========================================
    // MEMORY CHECK TASK
    // ==========================================

    task check_memory;
        input integer address;
        input [7:0] expected;

        begin
            if (dut.DMEM.memory[address] !== expected) begin

                $display(
                    "FAIL: MEM[%0d] expected %02h, got %02h",
                    address,
                    expected,
                    dut.DMEM.memory[address]
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: MEM[%0d] = %02h",
                    address, expected
                );

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

        // ======================================
        // INSTRUCTION PROGRAM
        // ======================================

        // x1 = 128
        dut.IMEM.memory[0]  = 32'h08000093;

        // x2 = -128
        dut.IMEM.memory[1]  = 32'hf8000113;

        // SB x2, 0(x1)
        dut.IMEM.memory[2]  = 32'h00208023;

        // LB x3, 0(x1)
        dut.IMEM.memory[3]  = 32'h00008183;

        // ADDI x10, x3, 1
        dut.IMEM.memory[4]  = 32'h00118513;

        // LBU x4, 0(x1)
        dut.IMEM.memory[5]  = 32'h0000c203;

        // x5 = -2
        dut.IMEM.memory[6]  = 32'hffe00293;

        // SH x5, 2(x1)
        dut.IMEM.memory[7]  = 32'h00509123;

        // LH x6, 2(x1)
        dut.IMEM.memory[8]  = 32'h00209303;

        // LHU x7, 2(x1)
        dut.IMEM.memory[9]  = 32'h0020d383;

        // LUI x8, 0x12345
        dut.IMEM.memory[10] = 32'h12345437;

        // ADDI x8, x8, 0x678
        dut.IMEM.memory[11] = 32'h67840413;

        // SW x8, 4(x1)
        dut.IMEM.memory[12] = 32'h0080a223;

        // LW x9, 4(x1)
        dut.IMEM.memory[13] = 32'h0040a483;

        // SB x2, 10(x1)
        dut.IMEM.memory[14] = 32'h00208523;

        // LB x11, 10(x1)
        dut.IMEM.memory[15] = 32'h00a08583;

        // ======================================
        // RESET RELEASE
        // ======================================

        #12;
        reset = 0;

        repeat (35) @(negedge clk);

        // ======================================
        // REGISTER VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" REGISTER VERIFICATION");
        $display("======================================");

        check_register(1,  32'd128);
        check_register(2,  32'hffffff80);
        check_register(3,  32'hffffff80);
        check_register(10, 32'hffffff81);
        check_register(4,  32'h00000080);
        check_register(5,  32'hfffffffe);
        check_register(6,  32'hfffffffe);
        check_register(7,  32'h0000fffe);
        check_register(8,  32'h12345678);
        check_register(9,  32'h12345678);
        check_register(11, 32'hffffff80);

        // ======================================
        // MEMORY VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" DATA MEMORY VERIFICATION");
        $display("======================================");

        check_memory(128, 8'h80);

        check_memory(130, 8'hfe);
        check_memory(131, 8'hff);

        check_memory(132, 8'h78);
        check_memory(133, 8'h56);
        check_memory(134, 8'h34);
        check_memory(135, 8'h12);

        check_memory(138, 8'h80);

        // ======================================
        // PIPELINE VERIFICATION
        // ======================================

        $display("");
        $display("======================================");
        $display(" PIPELINE VERIFICATION");
        $display("======================================");

        $display("Writebacks observed : %0d", writeback_count);
        $display("Load-use stalls     : %0d", stall_count);

        if (writeback_count != 12) begin
            $display("FAIL: Expected 12 register writebacks");
            errors = errors + 1;
        end

        if (stall_count != 1) begin
            $display("FAIL: Expected exactly 1 load-use stall");
            errors = errors + 1;
        end

        // ======================================
        // FINAL SUMMARY
        // ======================================

        $display("");
        $display("======================================");
        $display(" LOAD / STORE TEST SUMMARY");
        $display("======================================");

        $display("Writebacks : %0d", writeback_count);
        $display("Stalls     : %0d", stall_count);
        $display("Errors     : %0d", errors);

        if (errors == 0)
            $display("ALL LOAD/STORE TESTS PASSED");
        else
            $display("LOAD/STORE TESTS FAILED");

        $display("======================================");

        $finish;

    end

endmodule
