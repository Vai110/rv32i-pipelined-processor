
`timescale 1ns/1ps

module tb_performance_monitor;

    reg clk;
    reg reset;

    reg retire_valid;
    reg stall_event;
    reg redirect_event;

    wire [31:0] cycle_count;
    wire [31:0] retired_count;
    wire [31:0] stall_count;
    wire [31:0] redirect_count;

    integer errors;

    performance_monitor DUT (
        .clk(clk),
        .reset(reset),

        .retire_valid(retire_valid),
        .stall_event(stall_event),
        .redirect_event(redirect_event),

        .cycle_count(cycle_count),
        .retired_count(retired_count),
        .stall_count(stall_count),
        .redirect_count(redirect_count)
    );

    // 10 ns clock period.
    always #5 clk = ~clk;

    task check_counter;
        input [31:0] actual;
        input [31:0] expected;
        input [200*8-1:0] test_name;

        begin
            if (actual !== expected) begin
                $display("FAIL: %0s | Expected=%0d Actual=%0d",
                         test_name, expected, actual);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s = %0d",
                         test_name, actual);
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;

        retire_valid = 0;
        stall_event = 0;
        redirect_event = 0;

        errors = 0;

        // Apply reset.
        repeat (2) @(negedge clk);
        reset = 0;

        // Cycle 1: normal instruction retires.
        retire_valid = 1;
        @(negedge clk);

        // Cycle 2: load-use stall.
        retire_valid = 0;
        stall_event = 1;
        @(negedge clk);

        // Cycle 3: normal instruction retires.
        stall_event = 0;
        retire_valid = 1;
        @(negedge clk);

        // Cycle 4: taken branch redirect.
        retire_valid = 0;
        redirect_event = 1;
        @(negedge clk);

        // Cycle 5: jump redirect.
        redirect_event = 1;
        @(negedge clk);

        // Cycle 6: normal instruction retires.
        redirect_event = 0;
        retire_valid = 1;
        @(negedge clk);

        // Cycle 7: no event.
        retire_valid = 0;
        @(negedge clk);

        // Cycle 8: normal instruction retires.
        retire_valid = 1;
        @(negedge clk);

        // Disable all event inputs.
        retire_valid = 0;

        // Check all counters.
        $display("");
        $display("================================");
        $display(" PERFORMANCE MONITOR TEST");
        $display("================================");

        check_counter(cycle_count,    32'd8, "Cycle count");
        check_counter(retired_count,  32'd4, "Retired count");
        check_counter(stall_count,    32'd1, "Stall count");
        check_counter(redirect_count, 32'd2, "Redirect count");

        $display("");
        if (errors == 0) begin
            $display("ALL PERFORMANCE MONITOR TESTS PASSED");
        end
        else begin
            $display("PERFORMANCE MONITOR TESTS FAILED");
        end

        $display("Total errors: %0d", errors);
        $display("================================");

        $finish;

    end

endmodule
