
`timescale 1ns/1ps

module tb_program_counter;

    reg clk;
    reg reset;
    reg [31:0] next_pc;

    wire [31:0] pc;

    integer errors;

    // Instantiate the Program Counter
    program_counter uut (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    // Generate clock: 10 ns period
    always #5 clk = ~clk;

    // Check task
    task check_pc;
        input [31:0] expected_pc;
        input [255:0] test_name;

        begin
            if (pc !== expected_pc) begin
                $display("FAIL: %0s | Expected = %h | Actual = %h",
                         test_name, expected_pc, pc);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | PC = %h",
                         test_name, pc);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/program_counter_wave.vcd");
        $dumpvars(0, tb_program_counter);

        clk = 0;
        reset = 0;
        next_pc = 32'b0;
        errors = 0;

        $display("STARTING PROGRAM COUNTER TESTING");

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

        // Test 4: Branch target loading
        next_pc = 32'h00000020;
        @(posedge clk);
        #1;
        check_pc(32'h00000020, "Branch target loading");

        // Test 5: Jump target loading
        next_pc = 32'h00000100;
        @(posedge clk);
        #1;
        check_pc(32'h00000100, "Jump target loading");

        // Test 6: PC holds value between clock edges
        next_pc = 32'h00000200;
        #2;
        check_pc(32'h00000100, "PC stable before rising edge");

        @(posedge clk);
        #1;
        check_pc(32'h00000200, "PC update at rising edge");

        // Test 7: Reset again
        reset = 1;
        @(posedge clk);
        #1;
        check_pc(32'h00000000, "Reset after normal operation");

        $display("--------------------------------");
        $display("PROGRAM COUNTER TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;

    end

endmodule
