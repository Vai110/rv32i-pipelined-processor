
module register_file (
    input wire clk,

    input wire [4:0] read_addr1,
    output wire [31:0] read_data1,

    input wire [4:0] read_addr2,
    output wire [31:0] read_data2,

    input wire write_enable,
    input wire [4:0] write_addr,
    input wire [31:0] write_data
);

    reg [31:0] registers [0:31];

    // Read port 1 with writeback bypass
    assign read_data1 = (read_addr1 == 5'd0)
                        ? 32'b0
                        : (write_enable && (write_addr == read_addr1)
                           && (write_addr != 5'd0))
                          ? write_data
                          : registers[read_addr1];

    // Read port 2 with writeback bypass
    assign read_data2 = (read_addr2 == 5'd0)
                        ? 32'b0
                        : (write_enable && (write_addr == read_addr2)
                           && (write_addr != 5'd0))
                          ? write_data
                          : registers[read_addr2];

    // Synchronous register write
    always @(posedge clk) begin
        if (write_enable && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule
