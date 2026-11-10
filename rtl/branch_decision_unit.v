
module branch_decision_unit (

    input wire branch_enable,

    input wire [2:0] funct3,

    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,

    output reg branch_taken

);

    always @(*) begin

        // Default: branch not taken
        branch_taken = 1'b0;

        if (branch_enable) begin

            case (funct3)

                // BEQ: Equal
                3'b000:
                    branch_taken = (rs1_data == rs2_data);

                // BNE: Not equal
                3'b001:
                    branch_taken = (rs1_data != rs2_data);

                // BLT: Signed less than
                3'b100:
                    branch_taken =
                        ($signed(rs1_data) < $signed(rs2_data));

                // BGE: Signed greater than or equal
                3'b101:
                    branch_taken =
                        ($signed(rs1_data) >= $signed(rs2_data));

                // BLTU: Unsigned less than
                3'b110:
                    branch_taken = (rs1_data < rs2_data);

                // BGEU: Unsigned greater than or equal
                3'b111:
                    branch_taken = (rs1_data >= rs2_data);

                default:
                    branch_taken = 1'b0;

            endcase
        end
    end

endmodule
