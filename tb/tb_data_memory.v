
`timescale 1ns/1ps

module tb_data_memory;

    reg clk;
    reg mem_read;
    reg mem_write;
    reg [2:0] funct3;
    reg [31:0] address;
    reg [31:0] write_data;

    wire [31:0] read_data;

    integer errors;

    data_memory uut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Task: Check memory read output
    task check_read;
        input [31:0] expected;
        input [255:0] test_name;

        begin
            #1;

            if (read_data !== expected) begin
                $display("FAIL: %0s | Expected = %h | Actual = %h",
                         test_name, expected, read_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | Read data = %h",
                         test_name, read_data);
            end
        end
    endtask

    // Task: Perform a synchronous memory write
    task store_data;
        input [2:0] operation;
        input [31:0] location;
        input [31:0] value;

        begin
            @(negedge clk);

            funct3 = operation;
            address = location;
            write_data = value;
            mem_write = 1;

            @(posedge clk);
            #1;

            mem_write = 0;
        end
    endtask

    initial begin

        $dumpfile("simulation/waveforms/data_memory_wave.vcd");
        $dumpvars(0, tb_data_memory);

        // Initialize signals
        clk = 0;
        mem_read = 0;
        mem_write = 0;
        funct3 = 0;
        address = 0;
        write_data = 0;
        errors = 0;

        $display("STARTING DATA MEMORY TESTING");

        // Test 1: Store a word
        store_data(3'b010, 32'h00000100, 32'h12345678);

        // Test 2: Load the stored word
        funct3 = 3'b010;
        address = 32'h00000100;
        mem_read = 1;
        check_read(32'h12345678, "LW: Load word");

        // Test 3: Load first byte signed
        funct3 = 3'b000;
        check_read(32'h00000078, "LB: Positive byte");

        // Test 4: Load unsigned byte
        funct3 = 3'b100;
        check_read(32'h00000078, "LBU: Unsigned byte");

        // Test 5: Load second byte
        funct3 = 3'b100;
        address = 32'h00000101;
        check_read(32'h00000056, "LBU: Second byte");

        // Test 6: Load third byte
        address = 32'h00000102;
        check_read(32'h00000034, "LBU: Third byte");

        // Test 7: Load fourth byte
        address = 32'h00000103;
        check_read(32'h00000012, "LBU: Fourth byte");

        // Test 8: Store a signed negative byte
        mem_read = 0;
        store_data(3'b000, 32'h00000110, 32'h000000F0);

        // Test 9: LB sign extension
        mem_read = 1;
        funct3 = 3'b000;
        address = 32'h00000110;
        check_read(32'hFFFFFFF0, "LB: Sign extension");

        // Test 10: LBU zero extension
        funct3 = 3'b100;
        check_read(32'h000000F0, "LBU: Zero extension");

        // Test 11: Store and load halfword
        mem_read = 0;
        store_data(3'b001, 32'h00000120, 32'h0000ABCD);

        mem_read = 1;
        funct3 = 3'b001;
        address = 32'h00000120;
        check_read(32'hFFFFABCD, "LH: Sign extension");

        // Test 12: LHU zero extension
        funct3 = 3'b101;
        check_read(32'h0000ABCD, "LHU: Zero extension");

        // Test 13: Store a second word
        mem_read = 0;
        store_data(3'b010, 32'h00000130, 32'hDEADBEEF);

        // Test 14: Read enable disabled
        mem_read = 0;
        funct3 = 3'b010;
        address = 32'h00000130;
        check_read(32'h00000000, "Read disabled");

        // Test 15: Load stored word again
        mem_read = 1;
        check_read(32'hDEADBEEF, "LW: Stored word");

        // Test 16: Write disabled must not modify memory
        mem_read = 0;
        mem_write = 0;
        funct3 = 3'b010;
        address = 32'h00000140;
        write_data = 32'hCAFEBABE;

        @(posedge clk);
        #1;

        mem_read = 1;
        check_read(32'h00000000, "Write disabled");

        // Test 17: Out-of-range read
        address = 32'h00000400;
        funct3 = 3'b010;
        check_read(32'h00000000, "Out-of-range read");

        // Final test summary
        $display("--------------------------------");
        $display("DATA MEMORY TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;

    end

endmodule
