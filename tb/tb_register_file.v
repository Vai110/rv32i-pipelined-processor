
`timescale 1ns/1ps

module tb_register_file;

    // Testbench signals
    reg clk;

    reg [4:0] read_addr1;
    reg [4:0] read_addr2;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    reg write_enable;
    reg [4:0] write_addr;
    reg [31:0] write_data;

    integer errors;

    // Instantiate the Register File
    register_file uut (
        .clk(clk),
        .read_addr1(read_addr1),
        .read_data1(read_data1),
        .read_addr2(read_addr2),
        .read_data2(read_data2),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    // Generate clock: 10 ns period
    always #5 clk = ~clk;

    // Task to write into a register
    task write_register;
        input [4:0] address;
        input [31:0] data;
        begin
            @(negedge clk);
            write_enable = 1'b1;
            write_addr = address;
            write_data = data;

            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    // Task to check both read ports
    task check_read;
        input [4:0] address1;
        input [4:0] address2;
        input [31:0] expected1;
        input [31:0] expected2;
        begin
            read_addr1 = address1;
            read_addr2 = address2;
            #1;

            if ((read_data1 !== expected1) ||
                (read_data2 !== expected2)) begin

                $display("FAIL: Read addresses x%0d and x%0d",
                         address1, address2);

                $display("Expected: %h, %h",
                         expected1, expected2);

                $display("Actual:   %h, %h",
                         read_data1, read_data2);

                errors = errors + 1;

            end else begin

                $display("PASS: x%0d = %h, x%0d = %h",
                         address1, read_data1,
                         address2, read_data2);

            end
        end
    endtask

    // Main test sequence
    initial begin

        $dumpfile("simulation/waveforms/register_file_wave.vcd");
        $dumpvars(0, tb_register_file);

        // Initialize testbench
        clk = 1'b0;
        errors = 0;

        read_addr1 = 0;
        read_addr2 = 0;

        write_enable = 0;
        write_addr = 0;
        write_data = 0;

        $display("--------------------------------");
        $display("STARTING REGISTER FILE TESTING");
        $display("--------------------------------");

        // TEST 1: Write into x1 and x2
        $display("\nTEST 1: Basic register writes");

        write_register(5'd1, 32'd100);
        write_register(5'd2, 32'd200);

        check_read(5'd1, 5'd2, 32'd100, 32'd200);

        // TEST 2: Simultaneous reading
        $display("\nTEST 2: Dual read ports");

        check_read(5'd1, 5'd2, 32'd100, 32'd200);

        // TEST 3: Verify x0
        $display("\nTEST 3: x0 must always return zero");

        check_read(5'd0, 5'd1, 32'd0, 32'd100);

        // TEST 4: Attempt to write into x0
        $display("\nTEST 4: Attempt write to x0");

        write_register(5'd0, 32'd999);

        check_read(5'd0, 5'd2, 32'd0, 32'd200);

        // TEST 5: Write disabled
        $display("\nTEST 5: Write enable disabled");

        @(negedge clk);
        write_enable = 1'b0;
        write_addr = 5'd1;
        write_data = 32'd999;

        @(posedge clk);
        #1;

        check_read(5'd1, 5'd2, 32'd100, 32'd200);

        // TEST 6: Overwrite existing register
        $display("\nTEST 6: Overwrite register x1");

        write_register(5'd1, 32'd500);

        check_read(5'd1, 5'd2, 32'd500, 32'd200);

        // TEST 7: Access the last register
        $display("\nTEST 7: Access register x31");

        write_register(5'd31, 32'hABCDEF12);

        check_read(5'd31, 5'd1,
                   32'hABCDEF12, 32'd500);

        // Final report
        $display("\n--------------------------------");
        $display("REGISTER FILE TESTING COMPLETED");
        $display("Total errors: %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("--------------------------------");

        $finish;

    end

endmodule
