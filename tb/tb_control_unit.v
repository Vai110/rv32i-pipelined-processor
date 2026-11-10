
`timescale 1ns/1ps

module tb_control_unit;

    reg instruction_valid;

    reg is_r_type;
    reg is_i_type;
    reg is_load;
    reg is_store;
    reg is_branch;
    reg is_jal;
    reg is_jalr;
    reg is_lui;
    reg is_auipc;

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire [1:0] alu_a_sel;

    wire branch;
    wire jump;
    wire jalr;

    wire [1:0] alu_op;
    wire [1:0] wb_sel;

    wire uses_rs1;
    wire uses_rs2;

    integer tests = 0;
    integer errors = 0;

    control_unit uut (
        .instruction_valid(instruction_valid),

        .is_r_type(is_r_type),
        .is_i_type(is_i_type),
        .is_load(is_load),
        .is_store(is_store),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_lui(is_lui),
        .is_auipc(is_auipc),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_a_sel(alu_a_sel),

        .branch(branch),
        .jump(jump),
        .jalr(jalr),

        .alu_op(alu_op),
        .wb_sel(wb_sel),

        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2)
    );

    task check_controls;
        input valid;
        input [8:0] instruction_class;
        input [14:0] expected;
        input [255:0] test_name;

        reg [14:0] actual;

        begin
            instruction_valid = valid;

            {
                is_r_type, is_i_type, is_load,
                is_store, is_branch, is_jal,
                is_jalr, is_lui, is_auipc
            } = instruction_class;

            #10;

            actual = {
                reg_write, mem_read, mem_write, alu_src,
                alu_a_sel,
                branch, jump, jalr,
                alu_op, wb_sel,
                uses_rs1, uses_rs2
            };

            tests = tests + 1;

            if (actual !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %015b", expected);
                $display("Actual  : %015b", actual);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/control_unit_wave.vcd");
        $dumpvars(0, tb_control_unit);

        $display("-----------------------------------");
        $display("CONTROL UNIT TESTING");
        $display("-----------------------------------");

        // R-type: rs1 operation rs2
        check_controls(1'b1, 9'b100000000,
            {1'b1,1'b0,1'b0,1'b0,2'b00,
             1'b0,1'b0,1'b0,2'b10,2'b00,1'b1,1'b1},
            "R-type control signals");

        // I-type: rs1 operation immediate
        check_controls(1'b1, 9'b010000000,
            {1'b1,1'b0,1'b0,1'b1,2'b00,
             1'b0,1'b0,1'b0,2'b10,2'b00,1'b1,1'b0},
            "I-type control signals");

        // Load: rs1 + immediate
        check_controls(1'b1, 9'b001000000,
            {1'b1,1'b1,1'b0,1'b1,2'b00,
             1'b0,1'b0,1'b0,2'b00,2'b01,1'b1,1'b0},
            "Load control signals");

        // Store: rs1 + immediate
        check_controls(1'b1, 9'b000100000,
            {1'b0,1'b0,1'b1,1'b1,2'b00,
             1'b0,1'b0,1'b0,2'b00,2'b00,1'b1,1'b1},
            "Store control signals");

        // Branch: compare rs1 and rs2
        check_controls(1'b1, 9'b000010000,
            {1'b0,1'b0,1'b0,1'b0,2'b00,
             1'b1,1'b0,1'b0,2'b01,2'b00,1'b1,1'b1},
            "Branch control signals");

        // JAL: PC+4 link writeback
        check_controls(1'b1, 9'b000001000,
            {1'b1,1'b0,1'b0,1'b0,2'b00,
             1'b0,1'b1,1'b0,2'b00,2'b10,1'b0,1'b0},
            "JAL control signals");

        // JALR: rs1 + immediate target
        check_controls(1'b1, 9'b000000100,
            {1'b1,1'b0,1'b0,1'b1,2'b00,
             1'b0,1'b1,1'b1,2'b00,2'b10,1'b1,1'b0},
            "JALR control signals");

        // LUI: zero + immediate
        check_controls(1'b1, 9'b000000010,
            {1'b1,1'b0,1'b0,1'b1,2'b10,
             1'b0,1'b0,1'b0,2'b00,2'b00,1'b0,1'b0},
            "LUI control signals");

        // AUIPC: PC + immediate
        check_controls(1'b1, 9'b000000001,
            {1'b1,1'b0,1'b0,1'b1,2'b01,
             1'b0,1'b0,1'b0,2'b00,2'b00,1'b0,1'b0},
            "AUIPC control signals");

        // Invalid instruction
        check_controls(1'b0, 9'b000000000,
            15'b0,
            "Invalid instruction defaults");

        // Invalid instruction must suppress every side effect
        check_controls(1'b0, 9'b111111111,
            15'b0,
            "Invalid instruction suppresses all controls");

        $display("-----------------------------------");
        $display("TESTS COMPLETED");
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
