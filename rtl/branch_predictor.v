module branch_predictor #(
    parameter ENTRIES = 16
) (
    input wire clk,
    input wire reset,

    // Fetch-stage prediction lookup
    input wire [31:0] query_pc,
    output wire predict_taken,

    // Execute-stage branch outcome update
    input wire update_en,
    input wire [31:0] update_pc,
    input wire actual_taken
);

    reg [1:0] history [0:ENTRIES-1];

    wire [3:0] query_index;
    wire [3:0] update_index;

    integer i;

    assign query_index = query_pc[5:2];
    assign update_index = update_pc[5:2];

    // MSB determines the prediction.
    assign predict_taken = history[query_index][1];

    always @(posedge clk) begin

        if (reset) begin

            // Weakly not taken.
            for (i = 0; i < ENTRIES; i = i + 1)
                history[i] <= 2'b01;

        end

        else if (update_en) begin

            if (actual_taken) begin

                // Saturating increment.
                if (history[update_index] != 2'b11)
                    history[update_index] <=
                        history[update_index] + 2'b01;

            end

            else begin

                // Saturating decrement.
                if (history[update_index] != 2'b00)
                    history[update_index] <=
                        history[update_index] - 2'b01;

            end

        end

    end

endmodule
