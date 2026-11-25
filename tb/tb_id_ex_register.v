`timescale 1ns/1ps

module tb_id_ex_register;

    reg clk, reset, enable, flush;
    reg valid_in;
    reg predicted_taken_in;

    wire valid_out;
    wire predicted_taken_out;

    reg [31:0] pc_in, pc_plus4_in;
    reg [31:0] rs1_data_in, rs2_data_in;
    reg [31:0] immediate_in;

    reg [4:0] rs1_in, rs2_in, rd_in;

    reg [1:0] alu_a_sel_in;
    reg alu_src_in;

    reg uses_rs1_in, uses_rs2_in;

    reg [3:0] alu_control_in;

    reg mem_read_in, mem_write_in;

    reg reg_write_in;
    reg [1:0] wb_sel_in;

    reg branch_in, jump_in, jalr_in;
    reg [2:0] funct3_in;

    wire [31:0] pc_out, pc_plus4_out;
    wire [31:0] rs1_data_out, rs2_data_out;
    wire [31:0] immediate_out;

    wire [4:0] rs1_out, rs2_out, rd_out;

    wire [1:0] alu_a_sel_out;
    wire alu_src_out;

    wire uses_rs1_out, uses_rs2_out;

    wire [3:0] alu_control_out;

    wire mem_read_out, mem_write_out;

    wire reg_write_out;
    wire [1:0] wb_sel_out;

    wire branch_out, jump_out, jalr_out;
    wire [2:0] funct3_out;

    integer errors;

    id_ex_register DUT (

        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),

        .valid_in(valid_in),
        .valid_out(valid_out),

        .predicted_taken_in(predicted_taken_in),
        .predicted_taken_out(predicted_taken_out),

        .pc_in(pc_in),
        .pc_plus4_in(pc_plus4_in),

        .rs1_data_in(rs1_data_in),
        .rs2_data_in(rs2_data_in),

        .immediate_in(immediate_in),

        .rs1_in(rs1_in),
        .rs2_in(rs2_in),
        .rd_in(rd_in),

        .alu_a_sel_in(alu_a_sel_in),
        .alu_src_in(alu_src_in),

        .uses_rs1_in(uses_rs1_in),
        .uses_rs2_in(uses_rs2_in),

        .alu_control_in(alu_control_in),

        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),

        .reg_write_in(reg_write_in),
        .wb_sel_in(wb_sel_in),

        .branch_in(branch_in),
        .jump_in(jump_in),
        .jalr_in(jalr_in),
        .funct3_in(funct3_in),

        .pc_out(pc_out),
        .pc_plus4_out(pc_plus4_out),

        .rs1_data_out(rs1_data_out),
        .rs2_data_out(rs2_data_out),

        .immediate_out(immediate_out),

        .rs1_out(rs1_out),
        .rs2_out(rs2_out),
        .rd_out(rd_out),

        .alu_a_sel_out(alu_a_sel_out),
        .alu_src_out(alu_src_out),

        .uses_rs1_out(uses_rs1_out),
        .uses_rs2_out(uses_rs2_out),

        .alu_control_out(alu_control_out),

        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),

        .reg_write_out(reg_write_out),
        .wb_sel_out(wb_sel_out),

        .branch_out(branch_out),
        .jump_out(jump_out),
        .jalr_out(jalr_out),
        .funct3_out(funct3_out)

    );

    always #5 clk = ~clk;

    task check;
        input expected_valid;
        input expected_prediction;
        input [31:0] expected_pc;
        input [31:0] expected_immediate;
        input [4:0] expected_rd;
        input expected_branch;
        input expected_jump;
        input [2:0] expected_funct3;
        input [255:0] test_name;

        begin

            #1;

            if (
                valid_out !== expected_valid ||
                predicted_taken_out !== expected_prediction ||
                pc_out !== expected_pc ||
                immediate_out !== expected_immediate ||
                rd_out !== expected_rd ||
                branch_out !== expected_branch ||
                jump_out !== expected_jump ||
                funct3_out !== expected_funct3
            ) begin

                $display("FAIL: %0s", test_name);

                $display("valid: expected=%b actual=%b",
                         expected_valid, valid_out);

                $display("prediction: expected=%b actual=%b",
                         expected_prediction, predicted_taken_out);

                $display("PC: expected=%h actual=%h",
                         expected_pc, pc_out);

                $display("Immediate: expected=%h actual=%h",
                         expected_immediate, immediate_out);

                $display("RD: expected=%h actual=%h",
                         expected_rd, rd_out);

                $display("Branch: expected=%b actual=%b",
                         expected_branch, branch_out);

                $display("Jump: expected=%b actual=%b",
                         expected_jump, jump_out);

                $display("funct3: expected=%b actual=%b",
                         expected_funct3, funct3_out);

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

        rs1_data_in = 0;
        rs2_data_in = 0;
        immediate_in = 0;

        rs1_in = 0;
        rs2_in = 0;
        rd_in = 0;

        alu_a_sel_in = 0;
        alu_src_in = 0;

        uses_rs1_in = 0;
        uses_rs2_in = 0;

        alu_control_in = 0;

        mem_read_in = 0;
        mem_write_in = 0;

        reg_write_in = 0;
        wb_sel_in = 0;

        branch_in = 0;
        jump_in = 0;
        jalr_in = 0;
        funct3_in = 0;

        errors = 0;

        $display("----------------------------------");
        $display("ID/EX REGISTER TESTING");
        $display("----------------------------------");

        // Test 1: Reset.
        @(posedge clk);
        check(0, 0, 0, 0, 0, 0, 0, 0, "Reset");

        // Test 2: Capture not-taken prediction.
        @(negedge clk);

        reset = 0;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 0;

        pc_in = 32'h100;
        pc_plus4_in = 32'h104;

        rs1_data_in = 32'hAABBCCDD;
        rs2_data_in = 32'h11223344;

        immediate_in = 32'h00000010;

        rs1_in = 5'd1;
        rs2_in = 5'd2;
        rd_in = 5'd5;

        alu_a_sel_in = 2'b00;
        alu_src_in = 1;

        uses_rs1_in = 1;
        uses_rs2_in = 1;

        alu_control_in = 4'b0010;

        mem_read_in = 0;
        mem_write_in = 0;

        reg_write_in = 1;
        wb_sel_in = 2'b00;

        branch_in = 1;
        jump_in = 0;
        jalr_in = 0;
        funct3_in = 3'b000;

        @(posedge clk);

        check(1, 0, 32'h100, 32'h10, 5'd5,
              1, 0, 3'b000, "Capture not-taken prediction");

        // Test 3: Capture taken prediction.
        @(negedge clk);

        predicted_taken_in = 1;
        pc_in = 32'h200;
        pc_plus4_in = 32'h204;
        immediate_in = 32'h00000020;
        rd_in = 5'd10;
        branch_in = 0;
        jump_in = 1;
        funct3_in = 3'b001;

        @(posedge clk);

        check(1, 1, 32'h200, 32'h20, 5'd10,
              0, 1, 3'b001, "Capture taken prediction");

        // Test 4: Hold all register values.
        @(negedge clk);

        enable = 0;

        predicted_taken_in = 0;
        pc_in = 32'h300;
        immediate_in = 32'h00000030;
        rd_in = 5'd15;
        branch_in = 1;
        jump_in = 0;

        @(posedge clk);

        check(1, 1, 32'h200, 32'h20, 5'd10,
              0, 1, 3'b001, "Hold all register values");

        // Test 5: Flush.
        @(negedge clk);

        flush = 1;

        @(posedge clk);

        check(0, 0, 0, 0, 0, 0, 0, 0, "Flush");

        // Test 6: Flush priority over enable.
        @(negedge clk);

        flush = 1;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 1;

        pc_in = 32'h400;
        immediate_in = 32'h40;
        rd_in = 5'd20;
        branch_in = 1;
        jump_in = 1;
        funct3_in = 3'b010;

        @(posedge clk);

        check(0, 0, 0, 0, 0, 0, 0, 0,
              "Flush priority over enable");

        // Test 7: Capture after flush.
        @(negedge clk);

        flush = 0;
        enable = 1;
        valid_in = 1;
        predicted_taken_in = 1;

        pc_in = 32'h500;
        immediate_in = 32'h50;
        rd_in = 5'd25;
        branch_in = 1;
        jump_in = 0;
        funct3_in = 3'b100;

        @(posedge clk);

        check(1, 1, 32'h500, 32'h50, 5'd25,
              1, 0, 3'b100, "Capture after flush");

        // Test 8: Reset clears metadata and data.
        @(negedge clk);

        reset = 1;

        @(posedge clk);

        check(0, 0, 0, 0, 0, 0, 0, 0,
              "Reset clears all fields");

        $display("----------------------------------");
        $display("TOTAL ERRORS: %0d", errors);

        if (errors == 0)
            $display("ALL ID/EX REGISTER TESTS PASSED");
        else
            $display("ID/EX REGISTER TESTS FAILED");

        $display("----------------------------------");

        $finish;

    end

endmodule
