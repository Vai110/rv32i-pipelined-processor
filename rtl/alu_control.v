
module alu_control (

    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire is_r_type,

    output reg [3:0] alu_control

);

    always @(*) begin

        // Default operation: ADD
        alu_control = 4'b0000;

        case (alu_op)

            // 00: Address calculation / PC arithmetic
            2'b00: begin
                alu_control = 4'b0000;
            end

            // 01: Branch comparison
            2'b01: begin

                case (funct3)

                    // BEQ, BNE
                    3'b000, 3'b001:
                        alu_control = 4'b0001; // SUB

                    // BLT, BGE
                    3'b100, 3'b101:
                        alu_control = 4'b1000; // SLT

                    // BLTU, BGEU
                    3'b110, 3'b111:
                        alu_control = 4'b1001; // SLTU

                    default:
                        alu_control = 4'b0000;

                endcase
            end

            // 10: R-type and I-type arithmetic
            2'b10: begin

                case (funct3)

                    // ADD / SUB / ADDI
                    3'b000: begin
                        if (is_r_type && (funct7 == 7'b0100000))
                            alu_control = 4'b0001; // SUB
                        else
                            alu_control = 4'b0000; // ADD
                    end

                    // SLL / SLLI
                    3'b001:
                        alu_control = 4'b0101;

                    // SLT / SLTI
                    3'b010:
                        alu_control = 4'b1000;

                    // SLTU / SLTIU
                    3'b011:
                        alu_control = 4'b1001;

                    // XOR / XORI
                    3'b100:
                        alu_control = 4'b0100;

                    // SRL / SRA / SRLI / SRAI
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'b0111; // SRA
                        else
                            alu_control = 4'b0110; // SRL
                    end

                    // OR / ORI
                    3'b110:
                        alu_control = 4'b0011;

                    // AND / ANDI
                    3'b111:
                        alu_control = 4'b0010;

                    default:
                        alu_control = 4'b0000;

                endcase
            end

            // Reserved ALU operation category
            default: begin
                alu_control = 4'b0000;
            end

        endcase
    end

endmodule
