
`timescale 1ns/1ps

module tb_instruction_decoder;

    reg [31:0] instruction;

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    wire is_r_type;
    wire is_i_type;
    wire is_load;
    wire is_store;
    wire is_branch;
    wire is_jal;
    wire is_jalr;
    wire is_lui;
    wire is_auipc;

    wire illegal_instruction;
    wire instruction_valid;

    integer errors = 0;
    integer tests = 0;

    instruction_decoder uut (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .is_r_type(is_r_type),
        .is_i_type(is_i_type),
        .is_load(is_load),
        .is_store(is_store),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .illegal_instruction(illegal_instruction),
        .instruction_valid(instruction_valid)
    );

    task check_validity;
        input [31:0] test_instruction;
        input expected_valid;
        input expected_illegal;
        input [255:0] test_name;

        begin
            instruction = test_instruction;
            #10;
            tests = tests + 1;

            if ((instruction_valid !== expected_valid) ||
                (illegal_instruction !== expected_illegal)) begin
                $display("FAIL: %0s", test_name);
                $display("  Instruction: %h", test_instruction);
                $display("  Valid: expected %b, got %b",
                         expected_valid, instruction_valid);
                $display("  Illegal opcode: expected %b, got %b",
                         expected_illegal, illegal_instruction);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("simulation/waveforms/decoder_wave.vcd");
        $dumpvars(0, tb_instruction_decoder);

        $display("-----------------------------------------");
        $display("INSTRUCTION DECODER VALIDATION");
        $display("-----------------------------------------");

        // Valid R-type instructions
        check_validity(32'h002081B3, 1'b1, 1'b0, "Valid ADD");
        check_validity(32'h407302B3, 1'b1, 1'b0, "Valid SUB");

        // Invalid R-type: unsupported funct7/funct3 combination
        check_validity(
            {7'b0100000, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011},
            1'b0, 1'b0, "Invalid R-type encoding"
        );

        // Valid I-type arithmetic
        check_validity(32'h00A10213, 1'b1, 1'b0, "Valid ADDI");
        check_validity(32'h00109113, 1'b1, 1'b0, "Valid SLLI");

        // Invalid SLLI: upper immediate bits are reserved
        check_validity(
            {7'b0000001, 5'd1, 5'd1, 3'b001, 5'd2, 7'b0010011},
            1'b0, 1'b0, "Invalid SLLI encoding"
        );

        // Loads
        check_validity(32'h00C4A403, 1'b1, 1'b0, "Valid LW");
        check_validity(
            {12'd4, 5'd1, 3'b011, 5'd2, 7'b0000011},
            1'b0, 1'b0, "Invalid load funct3"
        );

        // Stores
        check_validity(32'h0084A823, 1'b1, 1'b0, "Valid SW");
        check_validity(
            {7'd0, 5'd2, 5'd1, 3'b011, 5'd8, 7'b0100011},
            1'b0, 1'b0, "Invalid store funct3"
        );

        // Branches
        check_validity(32'h00208463, 1'b1, 1'b0, "Valid BEQ");
        check_validity(
            {7'd0, 5'd2, 5'd1, 3'b010, 5'd8, 7'b1100011},
            1'b0, 1'b0, "Invalid branch funct3"
        );

        // Jumps
        check_validity(32'h000080E7, 1'b1, 1'b0, "Valid JALR");
        check_validity(
            {12'd0, 5'd1, 3'b001, 5'd1, 7'b1100111},
            1'b0, 1'b0, "Invalid JALR funct3"
        );
        check_validity(32'h008000EF, 1'b1, 1'b0, "Valid JAL");

        // Upper immediate instructions
        check_validity(32'h123451B7, 1'b1, 1'b0, "Valid LUI");
        check_validity(32'h12345197, 1'b1, 1'b0, "Valid AUIPC");

        // Unsupported opcode
        check_validity(32'h0000007F, 1'b0, 1'b1, "Unsupported opcode");

        $display("-----------------------------------------");
        $display("TESTS COMPLETED");
        $display("Total tests : %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("-----------------------------------------");

        $finish;
    end

endmodule
