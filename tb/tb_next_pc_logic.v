`timescale 1ns/1ps

module tb_next_pc_logic;

    reg [31:0] pc;
    reg [31:0] branch_imm;
    reg [31:0] jal_imm;
    reg [31:0] jalr_imm;
    reg [31:0] rs1_data;

    reg branch_enable;
    reg branch_taken;
    reg jump;
    reg jalr;

    wire [31:0] next_pc;

    integer errors;
    integer tests;

    next_pc_logic uut (
        .pc(pc),
        .branch_imm(branch_imm),
        .jal_imm(jal_imm),
        .jalr_imm(jalr_imm),
        .rs1_data(rs1_data),
        .branch_enable(branch_enable),
        .branch_taken(branch_taken),
        .jump(jump),
        .jalr(jalr),
        .next_pc(next_pc)
    );

    task check_result;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            tests = tests + 1;

            #1;

            if (next_pc !== expected) begin
                $display("FAIL: %0s | Expected: %h | Actual: %h",
                         test_name, expected, next_pc);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | Next PC: %h",
                         test_name, next_pc);
            end
        end
    endtask

    initial begin

        errors = 0;
        tests = 0;

        pc = 32'h00001000;
        branch_imm = 32'h00000020;
        jal_imm = 32'h00000040;
        jalr_imm = 32'h00000010;
        rs1_data = 32'h00002003;

        branch_enable = 0;
        branch_taken = 0;
        jump = 0;
        jalr = 0;

        $dumpfile("simulation/waveforms/next_pc_wave.vcd");
        $dumpvars(0, tb_next_pc_logic);

        $display("-------------------------------------");
        $display("NEXT PC LOGIC TESTING STARTED");
        $display("-------------------------------------");

        // Test 1: Sequential execution
        check_result(32'h00001004, "Sequential PC + 4");

        // Test 2: Branch taken
        branch_enable = 1;
        branch_taken = 1;
        check_result(32'h00001020, "Conditional branch taken");

        // Test 3: Branch not taken
        branch_taken = 0;
        check_result(32'h00001004, "Conditional branch not taken");

        // Test 4: JAL
        branch_enable = 0;
        branch_taken = 0;
        jump = 1;
        jalr = 0;
        check_result(32'h00001040, "JAL PC-relative jump");

        // Test 5: JALR
        jalr = 1;
        check_result(32'h00002012, "JALR clears bit zero");

        // Test 6: JALR with even target
        rs1_data = 32'h00003000;
        jalr_imm = 32'h00000008;
        check_result(32'h00003008, "JALR even target");

        // Test 7: JALR priority over branch
        branch_enable = 1;
        branch_taken = 1;
        rs1_data = 32'h00004000;
        jalr_imm = 32'h00000005;
        check_result(32'h00004004, "JALR priority over branch");

        // Test 8: JAL priority over branch
        jalr = 0;
        jal_imm = 32'h00000060;
        check_result(32'h00001060, "JAL priority over branch");

        // Test 9: Branch with negative offset
        jump = 0;
        branch_imm = -32'sd16;
        pc = 32'h00001000;
        check_result(32'h00000FF0, "Branch with negative offset");

        // Test 10: Sequential execution after disabling branch
        branch_enable = 0;
        check_result(32'h00001004, "Sequential after branch disabled");

        // Test 11: JALR negative offset
        jump = 1;
        jalr = 1;
        rs1_data = 32'h00002000;
        jalr_imm = -32'sd4;
        check_result(32'h00001FFC, "JALR with negative offset");

        $display("-------------------------------------");
        $display("NEXT PC TESTING COMPLETED");
        $display("Total tests: %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("-------------------------------------");

        $finish;

    end

endmodule
