
module control_unit (

    input wire instruction_valid,

    input wire is_r_type,
    input wire is_i_type,
    input wire is_load,
    input wire is_store,
    input wire is_branch,
    input wire is_jal,
    input wire is_jalr,
    input wire is_lui,
    input wire is_auipc,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,

    output reg [1:0] alu_a_sel,

    output reg branch,
    output reg jump,
    output reg jalr,

    output reg [1:0] alu_op,
    output reg [1:0] wb_sel,

    output reg uses_rs1,
    output reg uses_rs2
);

    always @(*) begin

        // Safe defaults: no side effects
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;

        alu_src   = 1'b0;
        alu_a_sel = 2'b00;

        branch = 1'b0;
        jump   = 1'b0;
        jalr   = 1'b0;

        alu_op = 2'b00;
        wb_sel = 2'b00;

        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        if (instruction_valid) begin

            // R-type: rs1 op rs2
            if (is_r_type) begin
                reg_write = 1'b1;
                alu_op    = 2'b10;

                alu_a_sel = 2'b00;
                alu_src   = 1'b0;

                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // I-type arithmetic: rs1 op immediate
            else if (is_i_type) begin
                reg_write = 1'b1;
                alu_op    = 2'b10;

                alu_a_sel = 2'b00;
                alu_src   = 1'b1;

                uses_rs1 = 1'b1;
            end

            // Load: rs1 + immediate
            else if (is_load) begin
                reg_write = 1'b1;
                mem_read  = 1'b1;

                alu_a_sel = 2'b00;
                alu_src   = 1'b1;

                wb_sel = 2'b01;
                uses_rs1 = 1'b1;
            end

            // Store: rs1 + immediate
            else if (is_store) begin
                mem_write = 1'b1;

                alu_a_sel = 2'b00;
                alu_src   = 1'b1;

                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // Branch comparison: rs1 versus rs2
            else if (is_branch) begin
                branch = 1'b1;
                alu_op = 2'b01;

                alu_a_sel = 2'b00;
                alu_src   = 1'b0;

                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // JAL: link address = PC + 4
            else if (is_jal) begin
                reg_write = 1'b1;
                jump      = 1'b1;

                wb_sel = 2'b10;
            end

            // JALR: target = rs1 + immediate
            else if (is_jalr) begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;

                alu_a_sel = 2'b00;
                alu_src   = 1'b1;

                wb_sel = 2'b10;
                uses_rs1 = 1'b1;
            end

            // LUI: zero + immediate
            else if (is_lui) begin
                reg_write = 1'b1;

                alu_a_sel = 2'b10;
                alu_src   = 1'b1;
            end

            // AUIPC: PC + immediate
            else if (is_auipc) begin
                reg_write = 1'b1;

                alu_a_sel = 2'b01;
                alu_src   = 1'b1;
            end

        end
    end

endmodule
