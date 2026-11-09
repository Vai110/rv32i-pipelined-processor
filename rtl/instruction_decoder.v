
module instruction_decoder (

    input wire [31:0] instruction,

    // Extracted instruction fields
    output wire [6:0] opcode,
    output wire [4:0] rd,
    output wire [2:0] funct3,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [6:0] funct7,

    // Instruction classification
    output wire is_r_type,
    output wire is_i_type,
    output wire is_load,
    output wire is_store,
    output wire is_branch,
    output wire is_jal,
    output wire is_jalr,
    output wire is_lui,
    output wire is_auipc,

    // Instruction status
    output wire illegal_instruction,
    output wire instruction_valid

);

    // --------------------------------
    // 1. Extract instruction fields
    // --------------------------------

    assign opcode = instruction[6:0];

    assign rd     = instruction[11:7];

    assign funct3 = instruction[14:12];

    assign rs1    = instruction[19:15];

    assign rs2    = instruction[24:20];

    assign funct7 = instruction[31:25];


    // --------------------------------
    // 2. Instruction classification
    // --------------------------------

    assign is_r_type = (opcode == 7'b0110011);

    assign is_i_type = (opcode == 7'b0010011);

    assign is_load   = (opcode == 7'b0000011);

    assign is_store  = (opcode == 7'b0100011);

    assign is_branch = (opcode == 7'b1100011);

    assign is_jal    = (opcode == 7'b1101111);

    assign is_jalr   = (opcode == 7'b1100111);

    assign is_lui    = (opcode == 7'b0110111);

    assign is_auipc  = (opcode == 7'b0010111);


    // --------------------------------
    // 3. Illegal opcode detection
    // --------------------------------

    assign illegal_instruction =
        !(is_r_type ||
          is_i_type ||
          is_load   ||
          is_store  ||
          is_branch ||
          is_jal    ||
          is_jalr   ||
          is_lui    ||
          is_auipc);


    // --------------------------------
    // 4. R-type instruction validation
    // --------------------------------

    wire valid_r_type;

    assign valid_r_type =
        (funct7 == 7'b0000000) ||

        ((funct7 == 7'b0100000) &&
         ((funct3 == 3'b000) ||
          (funct3 == 3'b101)));


    // --------------------------------
    // 5. I-type arithmetic validation
    // --------------------------------

    wire valid_i_type;

    assign valid_i_type =
        (funct3 == 3'b000) ||
        (funct3 == 3'b010) ||
        (funct3 == 3'b011) ||
        (funct3 == 3'b100) ||
        (funct3 == 3'b110) ||
        (funct3 == 3'b111) ||

        ((funct3 == 3'b001) &&
         (instruction[31:25] == 7'b0000000)) ||

        ((funct3 == 3'b101) &&
         ((instruction[31:25] == 7'b0000000) ||
          (instruction[31:25] == 7'b0100000)));


    // --------------------------------
    // 6. Load instruction validation
    // --------------------------------

    wire valid_load;

    assign valid_load =
        (funct3 == 3'b000) ||  // LB
        (funct3 == 3'b001) ||  // LH
        (funct3 == 3'b010) ||  // LW
        (funct3 == 3'b100) ||  // LBU
        (funct3 == 3'b101);    // LHU


    // --------------------------------
    // 7. Store instruction validation
    // --------------------------------

    wire valid_store;

    assign valid_store =
        (funct3 == 3'b000) ||  // SB
        (funct3 == 3'b001) ||  // SH
        (funct3 == 3'b010);    // SW


    // --------------------------------
    // 8. Branch instruction validation
    // --------------------------------

    wire valid_branch;

    assign valid_branch =
        (funct3 == 3'b000) ||  // BEQ
        (funct3 == 3'b001) ||  // BNE
        (funct3 == 3'b100) ||  // BLT
        (funct3 == 3'b101) ||  // BGE
        (funct3 == 3'b110) ||  // BLTU
        (funct3 == 3'b111);    // BGEU


    // --------------------------------
    // 9. JALR instruction validation
    // --------------------------------

    wire valid_jalr;

    assign valid_jalr = (funct3 == 3'b000);


    // --------------------------------
    // 10. Complete instruction validation
    // --------------------------------

    assign instruction_valid =

        (is_r_type && valid_r_type) ||

        (is_i_type && valid_i_type) ||

        (is_load && valid_load) ||

        (is_store && valid_store) ||

        (is_branch && valid_branch) ||

        is_jal ||

        (is_jalr && valid_jalr) ||

        is_lui ||

        is_auipc;

endmodule
