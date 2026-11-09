
module program_counter (

    input wire clk,
    input wire reset,

    input wire [31:0] next_pc,

    output reg [31:0] pc

);

    // Update the Program Counter on the rising edge
    always @(posedge clk) begin

        // Synchronous active-high reset
        if (reset) begin
            pc <= 32'b0;
        end

        // Load the next instruction address
        else begin
            pc <= next_pc;
        end

    end

endmodule
