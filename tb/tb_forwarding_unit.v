
`timescale 1ns/1ps

module tb_forwarding_unit;

    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;

    reg [4:0] ex_mem_rd;
    reg ex_mem_reg_write;
    reg ex_mem_mem_read;

    reg [4:0] mem_wb_rd;
    reg mem_wb_reg_write;

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    integer errors;
    integer tests;

    forwarding_unit dut (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    task check_result;
        input [1:0] expected_a;
        input [1:0] expected_b;
        input [255:0] test_name;
        begin
            #10;
            tests = tests + 1;

            if (forward_a !== expected_a ||
                forward_b !== expected_b) begin
                $display("FAIL: %s", test_name);
                $display("Expected A=%b B=%b | Got A=%b B=%b",
                         expected_a, expected_b,
                         forward_a, forward_b);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        errors = 0;
        tests = 0;

        id_ex_rs1 = 0;
        id_ex_rs2 = 0;
        ex_mem_rd = 0;
        ex_mem_reg_write = 0;
        ex_mem_mem_read = 0;
        mem_wb_rd = 0;
        mem_wb_reg_write = 0;

        $dumpfile("simulation/waveforms/forwarding_unit_wave.vcd");
        $dumpvars(0, tb_forwarding_unit);

        $display("-----------------------------------");
        $display("FORWARDING UNIT TESTING");
        $display("-----------------------------------");

        // Test 1: No dependencies
        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd2;
        check_result(2'b00, 2'b00, "No forwarding required");

        // Test 2: Forward operand A from EX/MEM
        ex_mem_rd = 5'd1;
        ex_mem_reg_write = 1;
        check_result(2'b10, 2'b00, "EX/MEM forwarding to operand A");

        // Test 3: Forward operand B from EX/MEM
        ex_mem_rd = 5'd2;
        check_result(2'b00, 2'b10, "EX/MEM forwarding to operand B");

        // Test 4: Forward both operands from EX/MEM
        id_ex_rs1 = 5'd3;
        id_ex_rs2 = 5'd3;
        ex_mem_rd = 5'd3;
        check_result(2'b10, 2'b10, "EX/MEM forwarding to both operands");

        // Test 5: Forward operand A from MEM/WB
        ex_mem_rd = 5'd8;
        mem_wb_rd = 5'd3;
        mem_wb_reg_write = 1;
        check_result(2'b01, 2'b01, "MEM/WB forwarding to both operands");

        // Test 6: EX/MEM priority over MEM/WB
        ex_mem_rd = 5'd3;
        check_result(2'b10, 2'b10, "EX/MEM priority over MEM/WB");

        // Test 7: Do not forward from EX/MEM load
        ex_mem_mem_read = 1;
        check_result(2'b01, 2'b01, "Load excluded from EX/MEM forwarding");

        // Test 8: No forwarding from MEM/WB if write disabled
        ex_mem_rd = 5'd8;
        ex_mem_reg_write = 0;
        ex_mem_mem_read = 0;
        mem_wb_reg_write = 0;
        check_result(2'b00, 2'b00, "MEM/WB write disabled");

        // Test 9: Never forward x0 from EX/MEM
        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1;
        id_ex_rs1 = 5'd0;
        id_ex_rs2 = 5'd0;
        check_result(2'b00, 2'b00, "EX/MEM x0 protection");

        // Test 10: Never forward x0 from MEM/WB
        ex_mem_reg_write = 0;
        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1;
        check_result(2'b00, 2'b00, "MEM/WB x0 protection");

        // Test 11: EX/MEM disabled, MEM/WB active
        id_ex_rs1 = 5'd7;
        id_ex_rs2 = 5'd9;
        ex_mem_rd = 5'd7;
        ex_mem_reg_write = 0;
        mem_wb_rd = 5'd9;
        mem_wb_reg_write = 1;
        check_result(2'b00, 2'b01, "Independent forwarding sources");

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
