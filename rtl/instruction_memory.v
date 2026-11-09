
module instruction_memory (

    input wire [31:0] address,

    output wire [31:0] instruction

);

    // 256 entries, each 32 bits wide
    reg [31:0] memory [0:255];

    // Combinational instruction read
    assign instruction = memory[address[9:2]];

    // Initialize memory with NOP instructions
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'h00000013;
        end
    end

endmodule
