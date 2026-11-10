
`timescale 1ns/1ps

module tb_ex_mem_register;

    reg clk;
    reg reset;
    reg enable;
    reg flush;

    reg [31:0] pc_plus4_in;
    reg [31:0] alu_result_in;
    reg [31:0] rs2_data_in;
    reg [4:0] rd_in;

    reg mem_read_in;
    reg mem_write_in;
    reg [2:0] funct3_in;

    reg reg_write_in;
    reg [1:0] wb_sel_in;

    wire [31:0] pc_plus4_out;
    wire [31:0] alu_result_out;
    wire [31:0] rs2_data_out;
    wire [4:0] rd_out;

    wire mem_read_out;
    wire mem_write_out;
    wire [2:0] funct3_out;

    wire reg_write_out;
    wire [1:0] wb_sel_out;

    integer errors = 0;
    integer tests = 0;

    reg [151:0] actual;
    reg [151:0] expected;

    ex_mem_register uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),

        .pc_plus4_in(pc_plus4_in),
        .alu_result_in(alu_result_in),
        .rs2_data_in(rs2_data_in),
        .rd_in(rd_in),

        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .funct3_in(funct3_in),

        .reg_write_in(reg_write_in),
        .wb_sel_in(wb_sel_in),

        .pc_plus4_out(pc_plus4_out),
        .alu_result_out(alu_result_out),
        .rs2_data_out(rs2_data_out),
        .rd_out(rd_out),

        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),
        .funct3_out(funct3_out),

        .reg_write_out(reg_write_out),
        .wb_sel_out(wb_sel_out)
    );

    always #5 clk = ~clk;

    task check_result;
        input [151:0] expected_value;
        input [255:0] test_name;
        begin
            tests = tests + 1;

            actual = {
                pc_plus4_out,
                alu_result_out,
                rs2_data_out,
                rd_out,
                mem_read_out,
                mem_write_out,
                funct3_out,
                reg_write_out,
                wb_sel_out
            };

            expected = expected_value;

            if (actual !== expected) begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %h", expected);
                $display("Actual:   %h", actual);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("simulation/waveforms/ex_mem_wave.vcd");
        $dumpvars(0, tb_ex_mem_register);

        clk = 0;
        reset = 0;
        enable = 0;
        flush = 0;

        pc_plus4_in = 0;
        alu_result_in = 0;
        rs2_data_in = 0;
        rd_in = 0;
        mem_read_in = 0;
        mem_write_in = 0;
        funct3_in = 0;
        reg_write_in = 0;
        wb_sel_in = 0;

        $display("-------------------------------------");
        $display("EX/MEM REGISTER TESTING STARTED");
        $display("-------------------------------------");

        // Test 1: Reset
        @(negedge clk);
        reset = 1;
        @(posedge clk);
        #1;

        check_result(152'b0, "Reset clears all outputs");

        // Test 2: Capture all signals
        @(negedge clk);
        reset = 0;
        enable = 1;

        pc_plus4_in = 32'h00001004;
        alu_result_in = 32'h12345678;
        rs2_data_in = 32'hAABBCCDD;
        rd_in = 5'd10;

        mem_read_in = 1;
        mem_write_in = 0;
        funct3_in = 3'b010;
        reg_write_in = 1;
        wb_sel_in = 2'b01;

        @(posedge clk);
        #1;

        check_result(
            {32'h00001004, 32'h12345678, 32'hAABBCCDD,
             5'd10, 1'b1, 1'b0, 3'b010, 1'b1, 2'b01},
            "Capture data and control signals"
        );

        // Test 3: Stall
        @(negedge clk);
        enable = 0;

        pc_plus4_in = 32'hDEADBEEF;
        alu_result_in = 32'hFFFFFFFF;
        rs2_data_in = 32'h11111111;
        rd_in = 5'd31;

        mem_read_in = 0;
        mem_write_in = 1;
        funct3_in = 3'b000;
        reg_write_in = 0;
        wb_sel_in = 2'b10;

        @(posedge clk);
        #1;

        check_result(
            {32'h00001004, 32'h12345678, 32'hAABBCCDD,
             5'd10, 1'b1, 1'b0, 3'b010, 1'b1, 2'b01},
            "Stall holds previous values"
        );

        // Test 4: Flush
        @(negedge clk);
        enable = 1;
        flush = 1;

        @(posedge clk);
        #1;

        check_result(152'b0, "Flush inserts bubble");

        // Test 5: Flush priority over enable
        @(negedge clk);
        pc_plus4_in = 32'h00002004;
        alu_result_in = 32'h87654321;
        rs2_data_in = 32'h55555555;
        rd_in = 5'd15;

        mem_read_in = 1;
        mem_write_in = 1;
        funct3_in = 3'b001;
        reg_write_in = 1;
        wb_sel_in = 2'b10;

        flush = 1;
        enable = 1;

        @(posedge clk);
        #1;

        check_result(152'b0, "Flush priority over enable");

        // Test 6: Capture after flush
        @(negedge clk);
        flush = 0;
        enable = 1;

        pc_plus4_in = 32'h00003004;
        alu_result_in = 32'h0000002A;
        rs2_data_in = 32'h00000055;
        rd_in = 5'd7;

        mem_read_in = 0;
        mem_write_in = 1;
        funct3_in = 3'b010;
        reg_write_in = 0;
        wb_sel_in = 2'b00;

        @(posedge clk);
        #1;

        check_result(
            {32'h00003004, 32'h0000002A, 32'h00000055,
             5'd7, 1'b0, 1'b1, 3'b010, 1'b0, 2'b00},
            "Capture after flush"
        );

        $display("-------------------------------------");
        $display("EX/MEM REGISTER TESTING COMPLETED");
        $display("Total tests: %0d", tests);
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        $display("-------------------------------------");

        $finish;
    end

endmodule
