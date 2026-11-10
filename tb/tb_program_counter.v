
`timescale 1ns/1ps

module tb_program_counter;

    reg clk;
    reg reset;
    reg enable;
    reg [31:0] next_pc;

    wire [31:0] pc;

    integer errors;
    integer tests;

    program_counter uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .next_pc(next_pc),
        .pc(pc)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    task check_pc;
        input [31:0] expected_pc;
        input [255:0] test_name;
        begin
            tests = tests + 1;

            if (pc !== expected_pc) begin
                $display("FAIL: %0s | Expected=%h | Actual=%h",
                         test_name, expected_pc, pc);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | PC=%h", test_name, pc);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/program_counter_wave.vcd");
        $dumpvars(0, tb_program_counter);

        clk = 0;
        reset = 0;
        enable = 1;
        next_pc = 32'b0;
        errors = 0;
        tests = 0;

        $display("-----------------------------------");
        $display("PROGRAM COUNTER TESTING");
        $display("-----------------------------------");

        // Test 1: Synchronous reset
        reset = 1;
        next_pc = 32'h00000100;
        @(posedge clk);
        #1;
        check_pc(32'h00000000, "Synchronous reset");

        // Test 2: First sequential address
        reset = 0;
        next_pc = 32'h00000004;
        @(posedge clk);
        #1;
        check_pc(32'h00000004, "Sequential PC update");

        // Test 3: Second sequential address
        next_pc = 32'h00000008;
        @(posedge clk);
        #1;
        check_pc(32'h00000008, "Second sequential update");

        // Test 4: Branch target
        next_pc = 32'h00000020;
        @(posedge clk);
        #1;
        check_pc(32'h00000020, "Branch target loading");

        // Test 5: Jump target
        next_pc = 32'h00000100;
        @(posedge clk);
        #1;
        check_pc(32'h00000100, "Jump target loading");

        // Test 6: PC holds between clock edges
        next_pc = 32'h00000200;
        #2;
        check_pc(32'h00000100, "PC stable before rising edge");

        // Test 7: PC updates at rising edge
        @(posedge clk);
        #1;
        check_pc(32'h00000200, "PC update at rising edge");

        // Test 8: Disable PC update
        enable = 0;
        next_pc = 32'h00000300;
        @(posedge clk);
        #1;
        check_pc(32'h00000200, "PC holds when enable is low");

        // Test 9: PC remains held for another cycle
        next_pc = 32'h00000400;
        @(posedge clk);
        #1;
        check_pc(32'h00000200, "PC holds across multiple cycles");

        // Test 10: Re-enable PC update
        enable = 1;
        next_pc = 32'h00000500;
        @(posedge clk);
        #1;
        check_pc(32'h00000500, "PC updates after re-enable");

        // Test 11: Reset has priority over disabled enable
        reset = 1;
        enable = 0;
        next_pc = 32'h00000600;
        @(posedge clk);
        #1;
        check_pc(32'h00000000, "Reset priority over enable");

        // Test 12: Reset after normal operation
        reset = 0;
        enable = 1;
        next_pc = 32'h00000004;
        @(posedge clk);
        #1;
        check_pc(32'h00000004, "Reset recovery and normal update");

        $display("-----------------------------------");
        $display("PROGRAM COUNTER TESTING COMPLETED");
        $display("Total tests : %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("-----------------------------------");

        $finish;

    end

endmodule
