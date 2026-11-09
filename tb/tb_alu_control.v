
`timescale 1ns/1ps

module tb_alu_control;

    reg [1:0] alu_op;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg is_r_type;

    wire [3:0] alu_control;

    integer tests = 0;
    integer errors = 0;

    alu_control uut (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .is_r_type(is_r_type),
        .alu_control(alu_control)
    );

    task check_operation;
        input [1:0] test_alu_op;
        input [2:0] test_funct3;
        input [6:0] test_funct7;
        input test_is_r_type;
        input [3:0] expected;
        input [255:0] test_name;

        begin
            alu_op = test_alu_op;
            funct3 = test_funct3;
            funct7 = test_funct7;
            is_r_type = test_is_r_type;

            #10;
            tests = tests + 1;

            if (alu_control !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("Expected ALU control: %04b", expected);
                $display("Actual ALU control  : %04b", alu_control);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | ALU control = %04b",
                         test_name, alu_control);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/alu_control_wave.vcd");
        $dumpvars(0, tb_alu_control);

        $display("--------------------------------------");
        $display("ALU CONTROL UNIT TESTING");
        $display("--------------------------------------");

        // Address calculation
        check_operation(2'b00, 3'b000, 7'b0000000, 1'b0,
                        4'b0000, "Address calculation ADD");

        // R-type arithmetic
        check_operation(2'b10, 3'b000, 7'b0000000, 1'b1,
                        4'b0000, "R-type ADD");

        check_operation(2'b10, 3'b000, 7'b0100000, 1'b1,
                        4'b0001, "R-type SUB");

        check_operation(2'b10, 3'b111, 7'b0000000, 1'b1,
                        4'b0010, "R-type AND");

        check_operation(2'b10, 3'b110, 7'b0000000, 1'b1,
                        4'b0011, "R-type OR");

        check_operation(2'b10, 3'b100, 7'b0000000, 1'b1,
                        4'b0100, "R-type XOR");

        check_operation(2'b10, 3'b001, 7'b0000000, 1'b1,
                        4'b0101, "R-type SLL");

        check_operation(2'b10, 3'b101, 7'b0000000, 1'b1,
                        4'b0110, "R-type SRL");

        check_operation(2'b10, 3'b101, 7'b0100000, 1'b1,
                        4'b0111, "R-type SRA");

        check_operation(2'b10, 3'b010, 7'b0000000, 1'b1,
                        4'b1000, "R-type SLT");

        check_operation(2'b10, 3'b011, 7'b0000000, 1'b1,
                        4'b1001, "R-type SLTU");

        // I-type: ensure immediate bits are not mistaken for SUB
        check_operation(2'b10, 3'b000, 7'b0100000, 1'b0,
                        4'b0000, "I-type ADDI with immediate upper bits");

        // I-type shifts
        check_operation(2'b10, 3'b001, 7'b0000000, 1'b0,
                        4'b0101, "I-type SLLI");

        check_operation(2'b10, 3'b101, 7'b0100000, 1'b0,
                        4'b0111, "I-type SRAI");

        // Branch comparisons
        check_operation(2'b01, 3'b000, 7'b0000000, 1'b0,
                        4'b0001, "BEQ comparison");

        check_operation(2'b01, 3'b001, 7'b0000000, 1'b0,
                        4'b0001, "BNE comparison");

        check_operation(2'b01, 3'b100, 7'b0000000, 1'b0,
                        4'b1000, "BLT comparison");

        check_operation(2'b01, 3'b101, 7'b0000000, 1'b0,
                        4'b1000, "BGE comparison");

        check_operation(2'b01, 3'b110, 7'b0000000, 1'b0,
                        4'b1001, "BLTU comparison");

        check_operation(2'b01, 3'b111, 7'b0000000, 1'b0,
                        4'b1001, "BGEU comparison");

        // Reserved category
        check_operation(2'b11, 3'b000, 7'b0000000, 1'b0,
                        4'b0000, "Reserved ALU operation");

        $display("--------------------------------------");
        $display("TESTS COMPLETED");
        $display("Total tests : %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("--------------------------------------");

        $finish;
    end

endmodule
