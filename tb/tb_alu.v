
`timescale 1ns/1ps

module tb_alu;

    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [3:0]  alu_control;

    wire [31:0] result;
    wire        zero;

    integer errors;

    // Instantiate the ALU
    alu uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    // Task to check ALU output
    task check_result;
        input [31:0] expected_result;
        input        expected_zero;

        begin
            #10;

            if (result !== expected_result ||
                zero !== expected_zero) begin

                $display("FAIL: control=%b A=%h B=%h", 
                         alu_control, operand_a, operand_b);

                $display("Expected: result=%h zero=%b",
                         expected_result, expected_zero);

                $display("Actual:   result=%h zero=%b",
                         result, zero);

                errors = errors + 1;

            end else begin

                $display("PASS: control=%b result=%h zero=%b",
                         alu_control, result, zero);

            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/alu_wave.vcd");
        $dumpvars(0, tb_alu);

        errors = 0;

        // Test 1: ADD
        operand_a = 32'd10;
        operand_b = 32'd5;
        alu_control = 4'b0000;
        check_result(32'd15, 1'b0);

        // Test 2: SUB
        operand_a = 32'd10;
        operand_b = 32'd5;
        alu_control = 4'b0001;
        check_result(32'd5, 1'b0);

        // Test 3: AND
        operand_a = 32'h0000000F;
        operand_b = 32'h00000003;
        alu_control = 4'b0010;
        check_result(32'h00000003, 1'b0);

        // Test 4: OR
        operand_a = 32'h0000000F;
        operand_b = 32'h00000003;
        alu_control = 4'b0011;
        check_result(32'h0000000F, 1'b0);

        // Test 5: XOR
        operand_a = 32'h0000000F;
        operand_b = 32'h00000003;
        alu_control = 4'b0100;
        check_result(32'h0000000C, 1'b0);

        // Test 6: SLL
        operand_a = 32'd3;
        operand_b = 32'd2;
        alu_control = 4'b0101;
        check_result(32'd12, 1'b0);

        // Test 7: SRL
        operand_a = 32'd16;
        operand_b = 32'd2;
        alu_control = 4'b0110;
        check_result(32'd4, 1'b0);

        // Test 8: SRA - preserve sign bit
        operand_a = 32'h80000000;
        operand_b = 32'd1;
        alu_control = 4'b0111;
        check_result(32'hC0000000, 1'b0);

        // Test 9: SLT - signed comparison
        operand_a = 32'hFFFFFFFF; // -1
        operand_b = 32'd1;
        alu_control = 4'b1000;
        check_result(32'd1, 1'b0);

        // Test 10: SLTU - unsigned comparison
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'd1;
        alu_control = 4'b1001;
        check_result(32'd0, 1'b1);

        // Test 11: Zero result
        operand_a = 32'd5;
        operand_b = 32'd5;
        alu_control = 4'b0001;
        check_result(32'd0, 1'b1);

        // Test 12: Invalid control
        operand_a = 32'd10;
        operand_b = 32'd5;
        alu_control = 4'b1111;
        check_result(32'd0, 1'b1);

        // Final summary
        $display("--------------------------------");
        $display("ALU TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("--------------------------------");

        $finish;

    end

endmodule
