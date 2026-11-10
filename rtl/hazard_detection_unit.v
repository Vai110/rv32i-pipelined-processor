
module hazard_detection_unit (

    // Instruction currently in ID/EX (EX stage)
    input wire id_ex_mem_read,
    input wire [4:0] id_ex_rd,

    // Instruction currently in IF/ID (ID stage)
    input wire [4:0] if_id_rs1,
    input wire [4:0] if_id_rs2,
    input wire if_id_uses_rs1,
    input wire if_id_uses_rs2,

    // Pipeline control outputs
    output reg pc_write,
    output reg if_id_write,
    output reg id_ex_flush

);

    always @(*) begin

        // Default: normal pipeline operation
        pc_write = 1'b1;
        if_id_write = 1'b1;
        id_ex_flush = 1'b0;

        // Load-use hazard detection
        if (id_ex_mem_read &&
            (id_ex_rd != 5'd0) &&
            (
                (if_id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                (if_id_uses_rs2 && (id_ex_rd == if_id_rs2))
            )
        ) begin

            // Stall PC
            pc_write = 1'b0;

            // Hold IF/ID instruction
            if_id_write = 1'b0;

            // Insert bubble into ID/EX
            id_ex_flush = 1'b1;

        end

    end

endmodule
