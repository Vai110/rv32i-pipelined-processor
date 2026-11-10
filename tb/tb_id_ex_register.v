
`timescale 1ns/1ps

module tb_id_ex_register;

    reg clk, reset, enable, flush;

    reg [31:0] pc_in, pc_plus4_in;
    reg [31:0] rs1_data_in, rs2_data_in, immediate_in;

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
    wire [31:0] rs1_data_out, rs2_data_out, immediate_out;

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

    integer tests;
    integer errors;

    id_ex_register uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),

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

    // Exact output width:
    // 160 + 15 + 2 + 1 + 2 + 4 + 2 + 1 + 2 + 3 + 3 = 195 bits

    task check_result;
        input [194:0] expected;
        input [255:0] test_name;

        reg [194:0] actual;

        begin
            tests = tests + 1;

            actual = {
                pc_out,
                pc_plus4_out,
                rs1_data_out,
                rs2_data_out,
                immediate_out,

                rs1_out,
                rs2_out,
                rd_out,

                alu_a_sel_out,
                alu_src_out,

                uses_rs1_out,
                uses_rs2_out,

                alu_control_out,

                mem_read_out,
                mem_write_out,

                reg_write_out,
                wb_sel_out,

                branch_out,
                jump_out,
                jalr_out,
                funct3_out
            };

            if (actual !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %h", expected);
                $display("Actual  : %h", actual);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    localparam [194:0] ZERO_OUTPUT = 195'b0;
    localparam [194:0] BUBBLE_OUTPUT = 195'b0;

    initial begin

        clk = 0;
        reset = 0;
        enable = 0;
        flush = 0;

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

        tests = 0;
        errors = 0;

        $dumpfile("simulation/waveforms/id_ex_wave.vcd");
        $dumpvars(0, tb_id_ex_register);

        $display("-------------------------------------");
        $display("ID/EX REGISTER TESTING STARTED");
        $display("-------------------------------------");

        // Test 1: Reset
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;

        check_result(ZERO_OUTPUT, "Reset clears all outputs");

        // Test 2: Capture all data and control signals
        @(negedge clk);

        reset = 0;
        enable = 1;

        pc_in = 32'h00001000;
        pc_plus4_in = 32'h00001004;

        rs1_data_in = 32'h0000000A;
        rs2_data_in = 32'h00000014;
        immediate_in = 32'h00000020;

        rs1_in = 5'd5;
        rs2_in = 5'd6;
        rd_in = 5'd7;

        alu_a_sel_in = 2'b00;
        alu_src_in = 1'b0;

        uses_rs1_in = 1'b1;
        uses_rs2_in = 1'b1;

        alu_control_in = 4'b0000;

        mem_read_in = 0;
        mem_write_in = 0;

        reg_write_in = 1;
        wb_sel_in = 2'b00;

        branch_in = 0;
        jump_in = 0;
        jalr_in = 0;
        funct3_in = 3'b000;

        @(posedge clk);
        #1;

        check_result({
            32'h00001000,
            32'h00001004,
            32'h0000000A,
            32'h00000014,
            32'h00000020,

            5'd5, 5'd6, 5'd7,

            2'b00,
            1'b0,

            1'b1, 1'b1,

            4'b0000,

            1'b0, 1'b0,

            1'b1,
            2'b00,

            1'b0, 1'b0, 1'b0,
            3'b000
        }, "Capture data and control signals");

        // Test 3: Stall / hold
        @(negedge clk);

        enable = 0;

        pc_in = 32'h00002000;
        pc_plus4_in = 32'h00002004;

        rs1_data_in = 32'hAAAAAAAA;
        rs2_data_in = 32'hBBBBBBBB;
        immediate_in = 32'h00000100;

        rd_in = 5'd12;
        reg_write_in = 0;

        @(posedge clk);
        #1;

        check_result({
            32'h00001000,
            32'h00001004,
            32'h0000000A,
            32'h00000014,
            32'h00000020,

            5'd5, 5'd6, 5'd7,

            2'b00,
            1'b0,

            1'b1, 1'b1,

            4'b0000,

            1'b0, 1'b0,

            1'b1,
            2'b00,

            1'b0, 1'b0, 1'b0,
            3'b000
        }, "Stall holds every output");

        // Test 4: Flush
        @(negedge clk);

        enable = 1;
        flush = 1;

        @(posedge clk);
        #1;

        check_result(BUBBLE_OUTPUT, "Flush inserts bubble");

        // Test 5: Flush priority over enable
        @(negedge clk);

        flush = 1;
        enable = 1;

        pc_in = 32'h00003000;
        pc_plus4_in = 32'h00003004;

        rs1_data_in = 32'h00000011;
        rs2_data_in = 32'h00000022;
        immediate_in = 32'h00000040;

        rs1_in = 5'd1;
        rs2_in = 5'd2;
        rd_in = 5'd3;

        alu_a_sel_in = 2'b01;
        alu_src_in = 1'b1;

        uses_rs1_in = 1'b0;
        uses_rs2_in = 1'b0;

        alu_control_in = 4'b0010;

        mem_read_in = 1;
        mem_write_in = 1;

        reg_write_in = 1;
        wb_sel_in = 2'b01;

        branch_in = 1;
        jump_in = 1;
        jalr_in = 1;
        funct3_in = 3'b100;

        @(posedge clk);
        #1;

        check_result(BUBBLE_OUTPUT, "Flush priority over enable");

        // Test 6: Capture after flush
        @(negedge clk);

        flush = 0;
        enable = 1;

        @(posedge clk);
        #1;

        check_result({
            32'h00003000,
            32'h00003004,
            32'h00000011,
            32'h00000022,
            32'h00000040,

            5'd1, 5'd2, 5'd3,

            2'b01,
            1'b1,

            1'b0, 1'b0,

            4'b0010,

            1'b1, 1'b1,

            1'b1,
            2'b01,

            1'b1, 1'b1, 1'b1,
            3'b100
        }, "Capture after flush");

        $display("-------------------------------------");
        $display("ID/EX REGISTER TESTING COMPLETED");
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
