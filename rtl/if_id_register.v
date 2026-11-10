module if_id_register (

    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,

    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,
    input wire [31:0] instruction_in,

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instruction_out

);

    always @(posedge clk) begin

        // Reset has the highest priority
        if (reset) begin

            pc_out <= 32'b0;
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'h00000013;

        end

        // Flush inserts a NOP into the pipeline
        else if (flush) begin

            pc_out <= 32'b0;
            pc_plus4_out <= 32'b0;
            instruction_out <= 32'h00000013;

        end

        // Enable allows new data to enter
        else if (enable) begin

            pc_out <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instruction_out <= instruction_in;

        end

        // Otherwise, hold the previous values

    end

endmodule
