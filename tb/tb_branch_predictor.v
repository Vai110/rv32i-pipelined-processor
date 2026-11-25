
`timescale 1ns/1ps

module tb_branch_predictor;

    reg clk;
    reg reset;

    reg [31:0] query_pc;
    wire predict_taken;

    reg update_en;
    reg [31:0] update_pc;
    reg actual_taken;

    integer errors;

    branch_predictor DUT (
        .clk(clk),
        .reset(reset),
        .query_pc(query_pc),
        .predict_taken(predict_taken),
        .update_en(update_en),
        .update_pc(update_pc),
        .actual_taken(actual_taken)
    );

    always #5 clk = ~clk;

    task check_prediction;
        input expected;
        input [255:0] test_name;
        begin
            #1;
            if (predict_taken !== expected) begin
                $display("FAIL: %0s | Expected=%b Actual=%b",
                         test_name, expected, predict_taken);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    task update_branch;
        input [31:0] pc;
        input outcome;
        begin
            @(negedge clk);
            update_pc = pc;
            actual_taken = outcome;
            update_en = 1'b1;

            @(negedge clk);
            update_en = 1'b0;
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;
        query_pc = 0;
        update_en = 0;
        update_pc = 0;
        actual_taken = 0;
        errors = 0;

        $display("----------------------------------");
        $display("BRANCH PREDICTOR TESTING");
        $display("----------------------------------");

        // Reset predictor.
        repeat (2) @(negedge clk);
        reset = 0;

        // Test 1: Initial state is weakly not taken.
        query_pc = 32'h00000000;
        check_prediction(1'b0, "Initial prediction: not taken");

        // Test 2: One taken update: 01 -> 10.
        update_branch(32'h00000000, 1'b1);
        query_pc = 32'h00000000;
        check_prediction(1'b1, "One taken update predicts taken");

        // Test 3: Saturate at strongly taken.
        update_branch(32'h00000000, 1'b1);
        update_branch(32'h00000000, 1'b1);
        update_branch(32'h00000000, 1'b1);
        query_pc = 32'h00000000;
        check_prediction(1'b1, "Taken counter saturates at 11");

        // Test 4: First not-taken update: 11 -> 10.
        update_branch(32'h00000000, 1'b0);
        query_pc = 32'h00000000;
        check_prediction(1'b1, "One not-taken update retains taken");

        // Test 5: Second not-taken update: 10 -> 01.
        update_branch(32'h00000000, 1'b0);
        query_pc = 32'h00000000;
        check_prediction(1'b0, "Two not-taken updates predict not taken");

        // Test 6: Saturate at strongly not taken.
        update_branch(32'h00000000, 1'b0);
        update_branch(32'h00000000, 1'b0);
        query_pc = 32'h00000000;
        check_prediction(1'b0, "Not-taken counter saturates at 00");

        // Test 7: Different index starts independently.
        query_pc = 32'h00000004;
        check_prediction(1'b0, "Independent BHT entry initialization");

        // Test 8: Update second entry.
        update_branch(32'h00000004, 1'b1);
        query_pc = 32'h00000004;
        check_prediction(1'b1, "Second BHT entry updates independently");

        // Test 9: First entry remains unchanged.
        query_pc = 32'h00000000;
        check_prediction(1'b0, "First BHT entry remains unchanged");

        // Test 10: Reset restores initial state.
        @(negedge clk);
        reset = 1'b1;

        @(negedge clk);
        reset = 1'b0;

        query_pc = 32'h00000004;
        check_prediction(1'b0, "Reset restores weakly not-taken state");

        $display("----------------------------------");
        $display("TOTAL ERRORS: %0d", errors);

        if (errors == 0)
            $display("ALL BRANCH PREDICTOR TESTS PASSED");
        else
            $display("BRANCH PREDICTOR TESTS FAILED");

        $display("----------------------------------");

        $finish;

    end

endmodule
