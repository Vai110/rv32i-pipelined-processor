
`timescale 1ns/1ps

module tb_if_id_register;

    reg clk;
    reg reset;
    reg enable;
    reg flush;
    reg valid_in;

    reg [31:0] pc_in;
    reg [31:0] pc_plus4_in;
    reg [31:0] instruction_in;

    wire valid_out;

    wire [31:0] pc_out;
    wire [31:0] pc_plus4_out;
    wire [31:0] instruction_out;

    integer tests;
    integer errors;

    if_id_register uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .pc_in(pc_in),
        .pc_plus4_in(pc_plus4_in),
        .instruction_in(instruction_in),
        .pc_out(pc_out),
        .pc_plus4_out(pc_plus4_out),
        .instruction_out(instruction_out)
    );

    always #5 clk = ~clk;

    task check_result;
        input expected_valid;
        input [31:0] expected_pc;
        input [31:0] expected_pc_plus4;
        input [31:0] expected_instruction;
        input [255:0] test_name;

        begin
            tests = tests + 1;

            if ((valid_out !== expected_valid) ||
                (pc_out !== expected_pc) ||
                (pc_plus4_out !== expected_pc_plus4) ||
                (instruction_out !== expected_instruction)) begin

                $display("FAIL: %0s", test_name);
                $display("Expected valid: %b | Actual: %b",
                         expected_valid, valid_out);
                $display("Expected PC: %h | Actual: %h",
                         expected_pc, pc_out);
                $display("Expected PC+4: %h | Actual: %h",
                         expected_pc_plus4, pc_plus4_out);
                $display("Expected instruction: %h | Actual: %h",
                         expected_instruction, instruction_out);

                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 0;
        enable = 0;
        flush = 0;
        valid_in = 0;

        pc_in = 0;
        pc_plus4_in = 0;
        instruction_in = 0;

        tests = 0;
        errors = 0;

        $dumpfile("simulation/waveforms/if_id_wave.vcd");
        $dumpvars(0, tb_if_id_register);

        $display("-------------------------------------");
        $display("IF/ID REGISTER TESTING STARTED");
        $display("-------------------------------------");

        // Test 1: Reset
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;
        check_result(0, 0, 0, 32'h00000013,
                     "Reset clears register and validity");

        // Test 2: Normal valid instruction transfer
        @(negedge clk);
        reset = 0;
        enable = 1;
        valid_in = 1;

        pc_in = 32'h00001000;
        pc_plus4_in = 32'h00001004;
        instruction_in = 32'h002081B3;

        @(posedge clk);
        #1;
        check_result(1, 32'h00001000, 32'h00001004,
                     32'h002081B3,
                     "Valid instruction transfer");

        // Test 3: Capture updated instruction
        @(negedge clk);

        pc_in = 32'h00001004;
        pc_plus4_in = 32'h00001008;
        instruction_in = 32'h00410233;

        @(posedge clk);
        #1;
        check_result(1, 32'h00001004, 32'h00001008,
                     32'h00410233,
                     "Capture updated instruction");

        // Test 4: Stall / hold
        @(negedge clk);
        enable = 0;
        valid_in = 0;

        pc_in = 32'h00002000;
        pc_plus4_in = 32'h00002004;
        instruction_in = 32'h003100B3;

        @(posedge clk);
        #1;
        check_result(1, 32'h00001004, 32'h00001008,
                     32'h00410233,
                     "Stall holds instruction and validity");

        // Test 5: Flush
        @(negedge clk);
        enable = 1;
        flush = 1;

        @(posedge clk);
        #1;
        check_result(0, 0, 0, 32'h00000013,
                     "Flush clears validity and inserts NOP");

        // Test 6: Flush has priority over enable
        @(negedge clk);
        flush = 1;
        enable = 1;
        valid_in = 1;

        pc_in = 32'h00003000;
        pc_plus4_in = 32'h00003004;
        instruction_in = 32'h005202B3;

        @(posedge clk);
        #1;
        check_result(0, 0, 0, 32'h00000013,
                     "Flush priority over enable");

        // Test 7: Reset has priority over flush
        @(negedge clk);
        reset = 1;
        flush = 1;

        @(posedge clk);
        #1;
        check_result(0, 0, 0, 32'h00000013,
                     "Reset priority over flush");

        // Test 8: Capture after reset
        @(negedge clk);
        reset = 0;
        flush = 0;
        enable = 1;
        valid_in = 1;

        pc_in = 32'h00004000;
        pc_plus4_in = 32'h00004004;
        instruction_in = 32'h00000013;

        @(posedge clk);
        #1;
        check_result(1, 32'h00004000, 32'h00004004,
                     32'h00000013,
                     "Normal operation after reset");

        // Test 9: Explicit invalid bubble transfer
        @(negedge clk);
        valid_in = 0;
        instruction_in = 32'h00000013;

        @(posedge clk);
        #1;
        check_result(0, 32'h00004000, 32'h00004004,
                     32'h00000013,
                     "Invalid NOP is identified as a bubble");

        $display("-------------------------------------");
        $display("IF/ID REGISTER TESTING COMPLETED");
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
