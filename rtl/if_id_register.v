
module if_id_register (

    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,

    input wire valid_in,

    // Branch prediction metadata
    input wire predicted_taken_in,
    output reg predicted_taken_out,

    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,
    input wire [31:0] instruction_in,

    output reg valid_out,

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instruction_out

);

    always @(posedge clk) begin

        // Reset has the highest priority.
        if (reset) begin

            valid_out <= 1'b0;
            predicted_taken_out <= 1'b0;

            pc_out <= 32'b0;
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'h00000013;

        end

        // Flush inserts an invalid bubble.
        else if (flush) begin

            valid_out <= 1'b0;
            predicted_taken_out <= 1'b0;

            pc_out <= 32'b0;
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'h00000013;

        end

        // Capture a new instruction and its metadata.
        else if (enable) begin

            valid_out <= valid_in;
            predicted_taken_out <= predicted_taken_in;

            pc_out <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instruction_out <= instruction_in;

        end

        // Otherwise, hold all previous values.

    end

endmodule
