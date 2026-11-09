
`timescale 1ns/1ps

module tb_immediate_generator;

    reg  [31:0] instruction;
    wire [31:0] immediate;

    integer errors;

    immediate_generator uut (
        .instruction(instruction),
        .immediate(immediate)
    );

    task check_result;
        input [31:0] expected;
        input [255:0] test_name;
        begin
            #10;

            if (immediate !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %h", expected);
                $display("Actual:   %h", immediate);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | Immediate = %h",
                         test_name, immediate);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/immediate_generator_wave.vcd");
        $dumpvars(0, tb_immediate_generator);

        errors = 0;
        instruction = 32'b0;

        $display("----------------------------------------");
        $display("STARTING IMMEDIATE GENERATOR TESTING");
        $display("----------------------------------------");

        // TEST 1: I-type positive immediate
        // ADDI x5, x1, 25
        instruction = 32'h01908293;
        check_result(32'h00000019, "I-type positive immediate");

        // TEST 2: I-type negative immediate
        // ADDI x5, x1, -5
        instruction = 32'hFFB08293;
        check_result(32'hFFFFFFFB, "I-type negative immediate");

        // TEST 3: S-type positive immediate
        // SW x5, 12(x1)
        instruction = 32'h0050A623;
        check_result(32'h0000000C, "S-type positive immediate");

        // TEST 4: S-type negative immediate
        // SW x5, -8(x1)
        instruction = 32'hFE50AC23;
        check_result(32'hFFFFFFF8, "S-type negative immediate");

        // TEST 5: B-type positive offset
        // BEQ x1, x2, 16
        instruction = 32'h00208863;
        check_result(32'h00000010, "B-type positive offset");

        // TEST 6: B-type negative offset
        // BEQ x1, x2, -16
        instruction = 32'hFE2088E3;
        check_result(32'hFFFFFFF0, "B-type negative offset");

        // TEST 7: U-type LUI
        // LUI x5, 0x12345
        instruction = 32'h123452B7;
        check_result(32'h12345000, "U-type LUI");

        // TEST 8: U-type AUIPC
        // AUIPC x5, 0x12345
        instruction = 32'h12345297;
        check_result(32'h12345000, "U-type AUIPC");

        // TEST 9: J-type positive offset
        // JAL x1, 100
        instruction = 32'h064000EF;
        check_result(32'h00000064, "J-type positive offset");

        // TEST 10: J-type negative offset
        // JAL x1, -100
        instruction = 32'hF9DFF0EF;
        check_result(32'hFFFFFF9C, "J-type negative offset");

        // TEST 11: Unsupported opcode
        instruction = 32'h00000033;
        check_result(32'h00000000, "Unsupported opcode");

        $display("----------------------------------------");
        $display("IMMEDIATE GENERATOR TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("----------------------------------------");

        $finish;

    end

endmodule
