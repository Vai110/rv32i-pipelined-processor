module next_pc_logic (
    input wire [31:0] pc,

    input wire [31:0] branch_imm,
    input wire [31:0] jal_imm,
    input wire [31:0] jalr_imm,

    input wire [31:0] rs1_data,

    input wire branch_enable,
    input wire branch_taken,

    input wire jump,
    input wire jalr,

    output reg [31:0] next_pc
);

    always @(*) begin

        // Default: execute the next sequential instruction
        next_pc = pc + 32'd4;

        // JALR: register-indirect jump
        if (jump && jalr) begin
            next_pc = (rs1_data + jalr_imm) & 32'hFFFFFFFE;
        end

        // JAL: PC-relative unconditional jump
        else if (jump && !jalr) begin
            next_pc = pc + jal_imm;
        end

        // Conditional branch
        else if (branch_enable && branch_taken) begin
            next_pc = pc + branch_imm;
        end

    end

endmodule