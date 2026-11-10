
module performance_monitor (
    input  wire        clk,
    input  wire        reset,

    input  wire        retire_valid,
    input  wire        stall_event,
    input  wire        redirect_event,

    output reg  [31:0] cycle_count,
    output reg  [31:0] retired_count,
    output reg  [31:0] stall_count,
    output reg  [31:0] redirect_count
);

    // All counters are cleared synchronously by reset.
    // Events are counted on the rising clock edge.

    always @(posedge clk) begin

        if (reset) begin

            cycle_count    <= 32'd0;
            retired_count  <= 32'd0;
            stall_count    <= 32'd0;
            redirect_count <= 32'd0;

        end
        else begin

            // Count every active processor clock cycle.
            cycle_count <= cycle_count + 32'd1;

            // Count valid retired instructions only.
            if (retire_valid)
                retired_count <= retired_count + 32'd1;

            // Count load-use stall events.
            if (stall_event)
                stall_count <= stall_count + 32'd1;

            // Count taken branches and jump redirects.
            if (redirect_event)
                redirect_count <= redirect_count + 32'd1;

        end

    end

endmodule
