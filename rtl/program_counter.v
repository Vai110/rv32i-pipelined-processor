
module program_counter (

    input wire clk,
    input wire reset,
    input wire enable,

    input wire [31:0] next_pc,

    output reg [31:0] pc

);

    // Update the PC only when enabled
    always @(posedge clk) begin

        if (reset) begin
            pc <= 32'b0;
        end

        else if (enable) begin
            pc <= next_pc;
        end

        // Otherwise, retain the current PC

    end

endmodule
