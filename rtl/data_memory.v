
module data_memory (

    input wire clk,

    input wire mem_read,
    input wire mem_write,

    input wire [2:0] funct3,

    input wire [31:0] address,
    input wire [31:0] write_data,

    output reg [31:0] read_data

);

    // 1024 bytes of byte-addressable memory
    reg [7:0] memory [0:1023];

    integer i;

    // Initialize memory to zero
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 8'b0;
        end
    end

    // Combinational read logic
    always @(*) begin

        read_data = 32'b0;

        if (mem_read) begin

            case (funct3)

                // LB: Load signed byte
                3'b000: begin
                    if (address < 32'd1024) begin
                        read_data = {
                            {24{memory[address][7]}},
                            memory[address]
                        };
                    end
                end

                // LH: Load signed halfword
                3'b001: begin
                    if (address <= 32'd1022) begin
                        read_data = {
                            {16{memory[address+1][7]}},
                            memory[address+1],
                            memory[address]
                        };
                    end
                end

                // LW: Load word
                3'b010: begin
                    if (address <= 32'd1020) begin
                        read_data = {
                            memory[address+3],
                            memory[address+2],
                            memory[address+1],
                            memory[address]
                        };
                    end
                end

                // LBU: Load unsigned byte
                3'b100: begin
                    if (address < 32'd1024) begin
                        read_data = {
                            24'b0,
                            memory[address]
                        };
                    end
                end

                // LHU: Load unsigned halfword
                3'b101: begin
                    if (address <= 32'd1022) begin
                        read_data = {
                            16'b0,
                            memory[address+1],
                            memory[address]
                        };
                    end
                end

                default: begin
                    read_data = 32'b0;
                end

            endcase

        end

    end

    // Synchronous write logic
    always @(posedge clk) begin

        if (mem_write) begin

            case (funct3)

                // SB: Store byte
                3'b000: begin
                    if (address < 32'd1024) begin
                        memory[address] <= write_data[7:0];
                    end
                end

                // SH: Store halfword
                3'b001: begin
                    if (address <= 32'd1022) begin
                        memory[address]   <= write_data[7:0];
                        memory[address+1] <= write_data[15:8];
                    end
                end

                // SW: Store word
                3'b010: begin
                    if (address <= 32'd1020) begin
                        memory[address]   <= write_data[7:0];
                        memory[address+1] <= write_data[15:8];
                        memory[address+2] <= write_data[23:16];
                        memory[address+3] <= write_data[31:24];
                    end
                end

                default: begin
                    // Unsupported store operation: no write
                end

            endcase

        end

    end

endmodule
