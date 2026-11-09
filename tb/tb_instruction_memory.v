
`timescale 1ns/1ps

module tb_instruction_memory;

    reg [31:0] address;
    wire [31:0] instruction;

    integer errors;

    instruction_memory uut (
        .address(address),
        .instruction(instruction)
    );

    task check_instruction;
        input [31:0] expected;
        input [255:0] test_name;

        begin
            #1;
            if (instruction !== expected) begin
                $display("FAIL: %0s | Expected = %h | Actual = %h",
                         test_name, expected, instruction);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | Instruction = %h",
                         test_name, instruction);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/instruction_memory_wave.vcd");
        $dumpvars(0, tb_instruction_memory);

        errors = 0;
        address = 32'h00000000;

        // Insert distinct instructions for simulation verification
        uut.memory[0] = 32'h00A00093;
        uut.memory[1] = 32'h01400113;
        uut.memory[2] = 32'h002081B3;
        uut.memory[3] = 32'h00302023;
        uut.memory[255] = 32'h00000013;

        $display("STARTING INSTRUCTION MEMORY TESTING");

        // Test 1: First instruction
        address = 32'h00000000;
        check_instruction(32'h00A00093, "First instruction");

        // Test 2: Second instruction
        address = 32'h00000004;
        check_instruction(32'h01400113, "Second instruction");

        // Test 3: Third instruction
        address = 32'h00000008;
        check_instruction(32'h002081B3, "Third instruction");

        // Test 4: Fourth instruction
        address = 32'h0000000C;
        check_instruction(32'h00302023, "Fourth instruction");

        // Test 5: Last valid memory entry
        address = 32'h000003FC;
        check_instruction(32'h00000013, "Last memory entry");

        // Test 6: Return to first entry
        address = 32'h00000000;
        check_instruction(32'h00A00093, "Return to first entry");

        $display("--------------------------------");
        $display("INSTRUCTION MEMORY TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;

    end

endmodule
