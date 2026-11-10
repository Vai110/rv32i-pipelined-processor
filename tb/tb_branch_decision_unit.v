 
`timescale 1ns/1ps

module tb_branch_decision_unit;

    reg branch_enable;
    reg [2:0] funct3;
    reg [31:0] rs1_data;
    reg [31:0] rs2_data;

    wire branch_taken;

    integer tests = 0;
    integer errors = 0;

    branch_decision_unit uut (
        .branch_enable(branch_enable),
        .funct3(funct3),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .branch_taken(branch_taken)
    );

    task check_branch;
        input enable;
        input [2:0] test_funct3;
        input [31:0] operand1;
        input [31:0] operand2;
        input expected;
        input [255:0] test_name;

        begin
            branch_enable = enable;
            funct3 = test_funct3;
            rs1_data = operand1;
            rs2_data = operand2;

            #10;
            tests = tests + 1;

            if (branch_taken !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("rs1 = %h, rs2 = %h", operand1, operand2);
                $display("Expected = %b, Actual = %b",
                         expected, branch_taken);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/branch_decision_wave.vcd");
        $dumpvars(0, tb_branch_decision_unit);

        $display("----------------------------------------");
        $display("BRANCH DECISION UNIT TESTING");
        $display("----------------------------------------");

        // BEQ tests
        check_branch(1'b1, 3'b000, 32'd10, 32'd10,
                     1'b1, "BEQ equal operands");

        check_branch(1'b1, 3'b000, 32'd10, 32'd20,
                     1'b0, "BEQ unequal operands");

        // BNE tests
        check_branch(1'b1, 3'b001, 32'd10, 32'd20,
                     1'b1, "BNE unequal operands");

        check_branch(1'b1, 3'b001, 32'd10, 32'd10,
                     1'b0, "BNE equal operands");

        // BLT signed tests
        check_branch(1'b1, 3'b100, 32'hFFFFFFFF, 32'd1,
                     1'b1, "BLT negative one less than positive one");

        check_branch(1'b1, 3'b100, 32'd5, 32'd3,
                     1'b0, "BLT positive greater than smaller positive");

        // BGE signed tests
        check_branch(1'b1, 3'b101, 32'hFFFFFFFF, 32'd1,
                     1'b0, "BGE negative one not greater than positive one");

        check_branch(1'b1, 3'b101, 32'd5, 32'd3,
                     1'b1, "BGE positive greater than smaller positive");

        // BLTU unsigned tests
        check_branch(1'b1, 3'b110, 32'hFFFFFFFF, 32'd1,
                     1'b0, "BLTU unsigned maximum greater than one");

        check_branch(1'b1, 3'b110, 32'd1, 32'hFFFFFFFF,
                     1'b1, "BLTU one less than unsigned maximum");

        // BGEU unsigned tests
        check_branch(1'b1, 3'b111, 32'hFFFFFFFF, 32'd1,
                     1'b1, "BGEU unsigned maximum greater than one");

        check_branch(1'b1, 3'b111, 32'd1, 32'hFFFFFFFF,
                     1'b0, "BGEU one less than unsigned maximum");

        // Boundary cases
        check_branch(1'b1, 3'b100, 32'h80000000, 32'h7FFFFFFF,
                     1'b1, "BLT minimum signed value less than maximum");

        check_branch(1'b1, 3'b110, 32'h80000000, 32'h7FFFFFFF,
                     1'b0, "BLTU unsigned comparison boundary");

        // Branch disabled
        check_branch(1'b0, 3'b000, 32'd10, 32'd10,
                     1'b0, "Branch disabled");

        // Unsupported funct3
        check_branch(1'b1, 3'b010, 32'd10, 32'd10,
                     1'b0, "Unsupported branch funct3");

        $display("----------------------------------------");
        $display("TESTS COMPLETED");
        $display("Total tests : %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("----------------------------------------");

        $finish;
    end

endmodule
