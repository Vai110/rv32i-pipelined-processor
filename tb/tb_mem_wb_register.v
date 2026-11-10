
`timescale 1ns/1ps

module tb_mem_wb_register;

    reg clk;
    reg reset;
    reg enable;
    reg flush;

    reg [31:0] pc_plus4_in;
    reg [31:0] alu_result_in;
    reg [31:0] mem_data_in;
    reg [4:0] rd_in;

    reg reg_write_in;
    reg [1:0] wb_sel_in;

    wire [31:0] pc_plus4_out;
    wire [31:0] alu_result_out;
    wire [31:0] mem_data_out;
    wire [4:0] rd_out;

    wire reg_write_out;
    wire [1:0] wb_sel_out;

    integer errors = 0;
    integer tests = 0;

    reg [132:0] actual;
    reg [132:0] expected;

    mem_wb_register uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .flush(flush),

        .pc_plus4_in(pc_plus4_in),
        .alu_result_in(alu_result_in),
        .mem_data_in(mem_data_in),
        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .wb_sel_in(wb_sel_in),

        .pc_plus4_out(pc_plus4_out),
        .alu_result_out(alu_result_out),
        .mem_data_out(mem_data_out),
        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .wb_sel_out(wb_sel_out)
    );

    always #5 clk = ~clk;

    task check_result;
        input [132:0] expected_value;
        input [255:0] test_name;
        begin
            tests = tests + 1;

            actual = {
                pc_plus4_out,
                alu_result_out,
                mem_data_out,
                rd_out,
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
        $dumpfile("simulation/waveforms/mem_wb_wave.vcd");
        $dumpvars(0, tb_mem_wb_register);

        clk = 0;
        reset = 0;
        enable = 0;
        flush = 0;

        pc_plus4_in = 0;
        alu_result_in = 0;
        mem_data_in = 0;
        rd_in = 0;
        reg_write_in = 0;
        wb_sel_in = 0;

        $display("-------------------------------------");
        $display("MEM/WB REGISTER TESTING STARTED");
        $display("-------------------------------------");

        // Test 1: Reset
        @(negedge clk);
        reset = 1;
        @(posedge clk);
        #1;

        check_result(133'b0, "Reset clears all outputs");

        // Test 2: Capture all signals
        @(negedge clk);
        reset = 0;
        enable = 1;

        pc_plus4_in = 32'h00001004;
        alu_result_in = 32'h12345678;
        mem_data_in = 32'hAABBCCDD;
        rd_in = 5'd10;
        reg_write_in = 1;
        wb_sel_in = 2'b01;

        @(posedge clk);
        #1;

        check_result(
            {32'h00001004, 32'h12345678, 32'hAABBCCDD,
             5'd10, 1'b1, 2'b01},
            "Capture data and control signals"
        );

        // Test 3: Stall
        @(negedge clk);
        enable = 0;

        pc_plus4_in = 32'hDEADBEEF;
        alu_result_in = 32'hFFFFFFFF;
        mem_data_in = 32'h11111111;
        rd_in = 5'd31;
        reg_write_in = 0;
        wb_sel_in = 2'b10;

        @(posedge clk);
        #1;

        check_result(
            {32'h00001004, 32'h12345678, 32'hAABBCCDD,
             5'd10, 1'b1, 2'b01},
            "Stall holds previous values"
        );

        // Test 4: Flush
        @(negedge clk);
        enable = 1;
        flush = 1;

        @(posedge clk);
        #1;

        check_result(133'b0, "Flush inserts bubble");

        // Test 5: Flush priority over enable
        @(negedge clk);
        pc_plus4_in = 32'h00002004;
        alu_result_in = 32'h87654321;
        mem_data_in = 32'h55555555;
        rd_in = 5'd15;
        reg_write_in = 1;
        wb_sel_in = 2'b10;

        flush = 1;
        enable = 1;

        @(posedge clk);
        #1;

        check_result(133'b0, "Flush priority over enable");

        // Test 6: Capture after flush
        @(negedge clk);
        flush = 0;
        enable = 1;

        pc_plus4_in = 32'h00003004;
        alu_result_in = 32'h0000002A;
        mem_data_in = 32'h00000055;
        rd_in = 5'd7;
        reg_write_in = 1;
        wb_sel_in = 2'b00;

        @(posedge clk);
        #1;

        check_result(
            {32'h00003004, 32'h0000002A, 32'h00000055,
             5'd7, 1'b1, 2'b00},
            "Capture after flush"
        );

        $display("-------------------------------------");
        $display("MEM/WB REGISTER TESTING COMPLETED");
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
