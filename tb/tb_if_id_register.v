
`timescale 1ns/1ps

module tb_if_id_register;

    reg clk;
    reg reset;
    reg enable;
    reg flush;
    reg valid_in;

    reg predicted_taken_in;
    wire predicted_taken_out;

    reg [31:0] pc_in;
    reg [31:0] pc_plus4_in;
    reg [31:0] instruction_in;

    wire valid_out;
    wire [31:0] pc_out;
    wire [31:0] pc_plus4_out;
    wire [31:0] instruction_out;

    integer errors;

    if_id_register DUT (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),

        .valid_in(valid_in),

        .predicted_taken_in(predicted_taken_in),
        .predicted_taken_out(predicted_taken_out),

        .pc_in(pc_in),
        .pc_plus4_in(pc_plus4_in),
        .instruction_in(instruction_in),

        .valid_out(valid_out),

        .pc_out(pc_out),
        .pc_plus4_out(pc_plus4_out),
        .instruction_out(instruction_out)
    );

    always #5 clk = ~clk;

    task check;
        input expected_valid;
        input expected_prediction;
        input [31:0] expected_pc;
        input [31:0] expected_pc_plus4;
        input [31:0] expected_instruction;
        input [255:0] test_name;
        begin
            #1;

            if (
                valid_out !== expected_valid ||
                predicted_taken_out !== expected_prediction ||
                pc_out !== expected_pc ||
                pc_plus4_out !== expected_pc_plus4 ||
                instruction_out !== expected_instruction
            ) begin

                $display("FAIL: %0s", test_name);
                $display(" valid: expected=%b actual=%b",
                         expected_valid, valid_out);
                $display(" prediction: expected=%b actual=%b",
                         expected_prediction, predicted_taken_out);
                $display(" pc: expected=%h actual=%h",
                         expected_pc, pc_out);
                $display(" pc+4: expected=%h actual=%h",
                         expected_pc_plus4, pc_plus4_out);
                $display(" instruction: expected=%h actual=%h",
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
        reset = 1;
        enable = 0;
        flush = 0;
        valid_in = 0;

        predicted_taken_in = 0;

        pc_in = 0;
        pc_plus4_in = 0;
        instruction_in = 32'h00000013;

        errors = 0;

        $display("----------------------------------");
        $display("IF/ID REGISTER TESTING");
        $display("----------------------------------");

        // Test 1: Reset.
        @(negedge clk);
        check(0, 0, 0, 0, 32'h00000013, "Reset");

        // Test 2: Capture instruction and not-taken prediction.
        reset = 0;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 0;
        pc_in = 32'h100;
        pc_plus4_in = 32'h104;
        instruction_in = 32'h00500093;

        @(posedge clk);
        check(1, 0, 32'h100, 32'h104,
              32'h00500093, "Capture not-taken prediction");

        // Test 3: Capture taken prediction.
        @(negedge clk);
        predicted_taken_in = 1;
        pc_in = 32'h200;
        pc_plus4_in = 32'h204;
        instruction_in = 32'h00208463;

        @(posedge clk);
        check(1, 1, 32'h200, 32'h204,
              32'h00208463, "Capture taken prediction");

        // Test 4: Hold all fields.
        @(negedge clk);
        enable = 0;
        predicted_taken_in = 0;
        pc_in = 32'h300;
        pc_plus4_in = 32'h304;
        instruction_in = 32'h00100113;

        @(posedge clk);
        check(1, 1, 32'h200, 32'h204,
              32'h00208463, "Hold prediction and instruction");

        // Test 5: Flush.
        @(negedge clk);
        flush = 1;

        @(posedge clk);
        check(0, 0, 0, 0, 32'h00000013, "Flush");

        // Test 6: Flush priority over enable.
        @(negedge clk);
        flush = 1;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 1;
        pc_in = 32'h400;
        pc_plus4_in = 32'h404;
        instruction_in = 32'h00500193;

        @(posedge clk);
        check(0, 0, 0, 0, 32'h00000013,
              "Flush priority over enable");

        // Test 7: Capture after flush.
        @(negedge clk);
        flush = 0;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 1;
        pc_in = 32'h500;
        pc_plus4_in = 32'h504;
        instruction_in = 32'h00600213;

        @(posedge clk);
        check(1, 1, 32'h500, 32'h504,
              32'h00600213, "Capture after flush");

        // Test 8: Reset clears all fields.
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        check(0, 0, 0, 0, 32'h00000013,
              "Reset clears prediction and instruction");

        $display("----------------------------------");
        $display("TOTAL ERRORS: %0d", errors);

        if (errors == 0)
            $display("ALL IF/ID REGISTER TESTS PASSED");
        else
            $display("IF/ID REGISTER TESTS FAILED");

        $display("----------------------------------");

        $finish;

    end

endmodule
