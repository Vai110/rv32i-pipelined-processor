
`timescale 1ns/1ps

module tb_hazard_detection_unit;

    reg id_ex_mem_read;
    reg [4:0] id_ex_rd;

    reg [4:0] if_id_rs1;
    reg [4:0] if_id_rs2;
    reg if_id_uses_rs1;
    reg if_id_uses_rs2;

    wire pc_write;
    wire if_id_write;
    wire id_ex_flush;

    integer tests;
    integer errors;

    hazard_detection_unit dut (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),
        .if_id_uses_rs1(if_id_uses_rs1),
        .if_id_uses_rs2(if_id_uses_rs2),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .id_ex_flush(id_ex_flush)
    );

    task check_result;
        input expected_pc_write;
        input expected_if_id_write;
        input expected_id_ex_flush;
        input [255:0] test_name;
        begin
            #10;
            tests = tests + 1;

            if (pc_write !== expected_pc_write ||
                if_id_write !== expected_if_id_write ||
                id_ex_flush !== expected_id_ex_flush) begin

                $display("FAIL: %s", test_name);
                $display("Expected: PC=%b IF_ID=%b ID_EX_FLUSH=%b",
                         expected_pc_write,
                         expected_if_id_write,
                         expected_id_ex_flush);

                $display("Actual:   PC=%b IF_ID=%b ID_EX_FLUSH=%b",
                         pc_write,
                         if_id_write,
                         id_ex_flush);

                errors = errors + 1;
            end
            else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        tests = 0;
        errors = 0;

        id_ex_mem_read = 0;
        id_ex_rd = 0;

        if_id_rs1 = 0;
        if_id_rs2 = 0;
        if_id_uses_rs1 = 0;
        if_id_uses_rs2 = 0;

        $dumpfile("simulation/waveforms/hazard_detection_unit_wave.vcd");
        $dumpvars(0, tb_hazard_detection_unit);

        $display("-----------------------------------");
        $display("HAZARD DETECTION UNIT TESTING");
        $display("-----------------------------------");

        // Test 1: Normal operation
        check_result(1, 1, 0, "Normal pipeline operation");

        // Test 2: Load-use dependency through rs1
        id_ex_mem_read = 1;
        id_ex_rd = 5'd5;
        if_id_rs1 = 5'd5;
        if_id_uses_rs1 = 1;
        check_result(0, 0, 1, "Load-use hazard through rs1");

        // Test 3: Load-use dependency through rs2
        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd5;
        if_id_uses_rs1 = 1;
        if_id_uses_rs2 = 1;
        check_result(0, 0, 1, "Load-use hazard through rs2");

        // Test 4: Both source registers match
        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd5;
        check_result(0, 0, 1, "Both source registers match");

        // Test 5: No matching source register
        if_id_rs1 = 5'd2;
        if_id_rs2 = 5'd3;
        check_result(1, 1, 0, "No register dependency");

        // Test 6: Destination is x0
        id_ex_rd = 5'd0;
        if_id_rs1 = 5'd0;
        if_id_rs2 = 5'd0;
        check_result(1, 1, 0, "No hazard from x0");

        // Test 7: Not a load instruction
        id_ex_mem_read = 0;
        id_ex_rd = 5'd5;
        if_id_rs1 = 5'd5;
        check_result(1, 1, 0, "No hazard without memory read");

        // Test 8: rs1 matches but is not used
        id_ex_mem_read = 1;
        id_ex_rd = 5'd5;
        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd2;
        if_id_uses_rs1 = 0;
        if_id_uses_rs2 = 1;
        check_result(1, 1, 0, "Unused rs1 does not cause hazard");

        // Test 9: rs2 matches but is not used
        if_id_rs1 = 5'd2;
        if_id_rs2 = 5'd5;
        if_id_uses_rs1 = 1;
        if_id_uses_rs2 = 0;
        check_result(1, 1, 0, "Unused rs2 does not cause hazard");

        // Test 10: rs2 dependency while rs1 is unused
        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd5;
        if_id_uses_rs1 = 0;
        if_id_uses_rs2 = 1;
        check_result(0, 0, 1, "Used rs2 detects hazard");

        // Test 11: Load writes another destination
        id_ex_rd = 5'd7;
        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd6;
        if_id_uses_rs1 = 1;
        if_id_uses_rs2 = 1;
        check_result(1, 1, 0, "Different destination register");

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
