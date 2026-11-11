
module rv32i_top #(
    parameter PROGRAM_WORDS = 256
) (
    input  wire        clk,
    input  wire        reset,

    output wire [31:0] pc_out,

    // Writeback observability
    output wire        wb_reg_write,
    output wire [4:0]  wb_rd,
    output wire [31:0] wb_data
);

    // ============================================================
    // IF STAGE - INSTRUCTION FETCH
    // ============================================================

    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instruction_if;
    wire [31:0] pc_plus4_if;

    wire pc_write;
    wire if_id_write;
    wire hazard_id_ex_flush;

    wire redirect;

    // Instructions outside the configured program are invalid.
    wire fetch_valid;

    assign fetch_valid = (pc < (PROGRAM_WORDS * 4));

    assign pc_plus4_if = pc + 32'd4;
    assign pc_out = pc;

    program_counter PC (
        .clk(clk),
        .reset(reset),
        .enable(pc_write),
        .next_pc(next_pc),
        .pc(pc)
    );

    instruction_memory IMEM (
        .address(pc),
        .instruction(instruction_if)
    );

    // IF/ID pipeline register

    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_instruction;
    wire if_id_valid;

    if_id_register IF_ID (
        .clk(clk),
        .reset(reset),
        .enable(if_id_write),
        .flush(redirect),

        .valid_in(fetch_valid),
        .valid_out(if_id_valid),

        .pc_in(pc),
        .pc_plus4_in(pc_plus4_if),
        .instruction_in(instruction_if),

        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .instruction_out(if_id_instruction)
    );

    // ============================================================
    // ID STAGE - INSTRUCTION DECODE
    // ============================================================

    wire [6:0] id_opcode;
    wire [4:0] id_rd;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [6:0] id_funct7;

    wire id_is_r_type;
    wire id_is_i_type;
    wire id_is_load;
    wire id_is_store;
    wire id_is_branch;
    wire id_is_jal;
    wire id_is_jalr;
    wire id_is_lui;
    wire id_is_auipc;

    wire id_illegal_instruction;
    wire id_instruction_valid;

    instruction_decoder DECODER (
        .instruction(if_id_instruction),
        .opcode(id_opcode),
        .rd(id_rd),
        .funct3(id_funct3),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .funct7(id_funct7),
        .is_r_type(id_is_r_type),
        .is_i_type(id_is_i_type),
        .is_load(id_is_load),
        .is_store(id_is_store),
        .is_branch(id_is_branch),
        .is_jal(id_is_jal),
        .is_jalr(id_is_jalr),
        .is_lui(id_is_lui),
        .is_auipc(id_is_auipc),
        .illegal_instruction(id_illegal_instruction),
        .instruction_valid(id_instruction_valid)
    );

    // Immediate generator

    wire [31:0] id_immediate;

    immediate_generator IMM_GEN (
        .instruction(if_id_instruction),
        .immediate(id_immediate)
    );

    // Main control unit

    wire id_reg_write;
    wire id_mem_read;
    wire id_mem_write;
    wire id_alu_src;

    wire [1:0] id_alu_a_sel;

    wire id_branch;
    wire id_jump;
    wire id_jalr;

    wire [1:0] id_alu_op;
    wire [1:0] id_wb_sel;

    wire id_uses_rs1;
    wire id_uses_rs2;

    control_unit CONTROL (
        .instruction_valid(id_instruction_valid),
        .is_r_type(id_is_r_type),
        .is_i_type(id_is_i_type),
        .is_load(id_is_load),
        .is_store(id_is_store),
        .is_branch(id_is_branch),
        .is_jal(id_is_jal),
        .is_jalr(id_is_jalr),
        .is_lui(id_is_lui),
        .is_auipc(id_is_auipc),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src(id_alu_src),
        .alu_a_sel(id_alu_a_sel),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr),
        .alu_op(id_alu_op),
        .wb_sel(id_wb_sel),
        .uses_rs1(id_uses_rs1),
        .uses_rs2(id_uses_rs2)
    );

    // Register file

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    register_file REG_FILE (
        .clk(clk),
        .read_addr1(id_rs1),
        .read_data1(id_rs1_data),
        .read_addr2(id_rs2),
        .read_data2(id_rs2_data),
        .write_enable(wb_reg_write),
        .write_addr(wb_rd),
        .write_data(wb_data)
    );

    // ALU control

    wire [3:0] id_alu_control;

    alu_control ALU_CTRL (
        .alu_op(id_alu_op),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .is_r_type(id_is_r_type),
        .alu_control(id_alu_control)
    );

    // ============================================================
    // LOAD-USE HAZARD DETECTION
    // ============================================================

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc_plus4;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_immediate;

    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;

    wire [1:0] id_ex_alu_a_sel;
    wire id_ex_alu_src;

    wire id_ex_uses_rs1;
    wire id_ex_uses_rs2;

    wire [3:0] id_ex_alu_control;

    wire id_ex_mem_read;
    wire id_ex_mem_write;
    wire id_ex_reg_write;

    wire [1:0] id_ex_wb_sel;

    wire id_ex_branch;
    wire id_ex_jump;
    wire id_ex_jalr;

    wire [2:0] id_ex_funct3;

    wire id_ex_valid;

    hazard_detection_unit HAZARD_UNIT (
        .id_ex_mem_read(id_ex_mem_read && id_ex_valid),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .if_id_uses_rs1(id_uses_rs1),
        .if_id_uses_rs2(id_uses_rs2),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .id_ex_flush(hazard_id_ex_flush)
    );

    // ============================================================
    // ID/EX PIPELINE REGISTER
    // ============================================================

    id_ex_register ID_EX (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(hazard_id_ex_flush | redirect),

        .valid_in(if_id_valid && id_instruction_valid),
        .valid_out(id_ex_valid),

        .pc_in(if_id_pc),
        .pc_plus4_in(if_id_pc_plus4),

        .rs1_data_in(id_rs1_data),
        .rs2_data_in(id_rs2_data),
        .immediate_in(id_immediate),

        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),

        .alu_a_sel_in(id_alu_a_sel),
        .alu_src_in(id_alu_src),

        .uses_rs1_in(id_uses_rs1),
        .uses_rs2_in(id_uses_rs2),

        .alu_control_in(id_alu_control),

        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .reg_write_in(id_reg_write),
        .wb_sel_in(id_wb_sel),

        .branch_in(id_branch),
        .jump_in(id_jump),
        .jalr_in(id_jalr),
        .funct3_in(id_funct3),

        .pc_out(id_ex_pc),
        .pc_plus4_out(id_ex_pc_plus4),

        .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data),
        .immediate_out(id_ex_immediate),

        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),

        .alu_a_sel_out(id_ex_alu_a_sel),
        .alu_src_out(id_ex_alu_src),

        .uses_rs1_out(id_ex_uses_rs1),
        .uses_rs2_out(id_ex_uses_rs2),

        .alu_control_out(id_ex_alu_control),

        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .reg_write_out(id_ex_reg_write),
        .wb_sel_out(id_ex_wb_sel),

        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump),
        .jalr_out(id_ex_jalr),
        .funct3_out(id_ex_funct3)
    );

    // ============================================================
    // EX STAGE - FORWARDING
    // ============================================================

    // EX/MEM pipeline signals

    wire [31:0] ex_mem_pc_plus4;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data;

    wire [4:0] ex_mem_rd;

    wire ex_mem_mem_read;
    wire ex_mem_mem_write;

    wire [2:0] ex_mem_funct3;

    wire ex_mem_reg_write;
    wire [1:0] ex_mem_wb_sel;
    wire ex_mem_valid;

    // MEM/WB pipeline signals

    wire [31:0] mem_wb_pc_plus4;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;

    wire [4:0] mem_wb_rd;

    wire mem_wb_reg_write;
    wire [1:0] mem_wb_wb_sel;
    wire mem_wb_valid;

    // Forwarding control

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit FORWARD_UNIT (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write && ex_mem_valid),
        .ex_mem_mem_read(ex_mem_mem_read),

        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write && mem_wb_valid),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Writeback data selection

    reg [31:0] writeback_data_mux;

    always @(*) begin
        case (mem_wb_wb_sel)
            2'b00:
                writeback_data_mux = mem_wb_alu_result;

            2'b01:
                writeback_data_mux = mem_wb_mem_data;

            2'b10:
                writeback_data_mux = mem_wb_pc_plus4;

            default:
                writeback_data_mux = 32'b0;
        endcase
    end

    // EX/MEM forwarding value
    // JAL/JALR forward PC+4 rather than the ALU result.

    wire [31:0] ex_mem_forward_data;

    assign ex_mem_forward_data =
        (ex_mem_wb_sel == 2'b10)
        ? ex_mem_pc_plus4
        : ex_mem_alu_result;

    // Forwarded source operands

    reg [31:0] forwarded_rs1;
    reg [31:0] forwarded_rs2;

    always @(*) begin
        case (forward_a)
            2'b00:
                forwarded_rs1 = id_ex_rs1_data;

            2'b10:
                forwarded_rs1 = ex_mem_forward_data;

            2'b01:
                forwarded_rs1 = writeback_data_mux;

            default:
                forwarded_rs1 = id_ex_rs1_data;
        endcase

        case (forward_b)
            2'b00:
                forwarded_rs2 = id_ex_rs2_data;

            2'b10:
                forwarded_rs2 = ex_mem_forward_data;

            2'b01:
                forwarded_rs2 = writeback_data_mux;

            default:
                forwarded_rs2 = id_ex_rs2_data;
        endcase
    end

    // ALU operand selection

    reg [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;

    always @(*) begin
        case (id_ex_alu_a_sel)
            2'b00:
                alu_operand_a = forwarded_rs1;

            2'b01:
                alu_operand_a = id_ex_pc;

            2'b10:
                alu_operand_a = 32'b0;

            default:
                alu_operand_a = forwarded_rs1;
        endcase
    end

    assign alu_operand_b =
        id_ex_alu_src
        ? id_ex_immediate
        : forwarded_rs2;

    // ALU

    wire [31:0] alu_result;
    wire alu_zero;

    alu ALU (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_control(id_ex_alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ============================================================
    // EX STAGE - BRANCH AND JUMP CONTROL
    // ============================================================

    wire branch_taken;

    wire ex_branch_enable;
    wire ex_jump_enable;

    assign ex_branch_enable = id_ex_branch && id_ex_valid;
    assign ex_jump_enable = id_ex_jump && id_ex_valid;

    branch_decision_unit BRANCH_UNIT (
        .branch_enable(ex_branch_enable),
        .funct3(id_ex_funct3),
        .rs1_data(forwarded_rs1),
        .rs2_data(forwarded_rs2),
        .branch_taken(branch_taken)
    );

    // Redirect only for a valid instruction.

    assign redirect =
        (ex_branch_enable && branch_taken) ||
        ex_jump_enable;

    // Next PC selection

    wire [31:0] redirect_target;

    next_pc_logic NEXT_PC (
        .pc(id_ex_pc),
        .branch_imm(id_ex_immediate),
        .jal_imm(id_ex_immediate),
        .jalr_imm(id_ex_immediate),
        .rs1_data(forwarded_rs1),
        .branch_enable(ex_branch_enable),
        .branch_taken(branch_taken),
        .jump(ex_jump_enable),
        .jalr(id_ex_jalr && id_ex_valid),
        .next_pc(redirect_target)
    );

    assign next_pc = redirect
                   ? redirect_target
                   : pc_plus4_if;

    // ============================================================
    // EX/MEM PIPELINE REGISTER
    // ============================================================

    ex_mem_register EX_MEM (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(1'b0),

        .valid_in(id_ex_valid),
        .valid_out(ex_mem_valid),

        .pc_plus4_in(id_ex_pc_plus4),
        .alu_result_in(alu_result),
        .rs2_data_in(forwarded_rs2),

        .rd_in(id_ex_rd),

        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),

        .funct3_in(id_ex_funct3),

        .reg_write_in(id_ex_reg_write),
        .wb_sel_in(id_ex_wb_sel),

        .pc_plus4_out(ex_mem_pc_plus4),
        .alu_result_out(ex_mem_alu_result),
        .rs2_data_out(ex_mem_rs2_data),

        .rd_out(ex_mem_rd),

        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),

        .funct3_out(ex_mem_funct3),

        .reg_write_out(ex_mem_reg_write),
        .wb_sel_out(ex_mem_wb_sel)
    );

    // ============================================================
    // MEM STAGE - DATA MEMORY
    // ============================================================

    wire [31:0] mem_read_data;

    data_memory DMEM (
        .clk(clk),
        .mem_read(ex_mem_mem_read && ex_mem_valid),
        .mem_write(ex_mem_mem_write && ex_mem_valid),
        .funct3(ex_mem_funct3),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_rs2_data),
        .read_data(mem_read_data)
    );

    // ============================================================
    // MEM/WB PIPELINE REGISTER
    // ============================================================

    mem_wb_register MEM_WB (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(1'b0),

        .valid_in(ex_mem_valid),
        .valid_out(mem_wb_valid),

        .pc_plus4_in(ex_mem_pc_plus4),
        .alu_result_in(ex_mem_alu_result),
        .mem_data_in(mem_read_data),

        .rd_in(ex_mem_rd),
        .reg_write_in(ex_mem_reg_write),
        .wb_sel_in(ex_mem_wb_sel),

        .pc_plus4_out(mem_wb_pc_plus4),
        .alu_result_out(mem_wb_alu_result),
        .mem_data_out(mem_wb_mem_data),

        .rd_out(mem_wb_rd),
        .reg_write_out(mem_wb_reg_write),
        .wb_sel_out(mem_wb_wb_sel)
    );

    // ============================================================
    // WB STAGE - REGISTER WRITEBACK
    // ============================================================

    assign wb_reg_write =
        mem_wb_valid &&
        mem_wb_reg_write &&
        (mem_wb_rd != 5'd0);

    assign wb_rd = mem_wb_rd;
    assign wb_data = writeback_data_mux;

    // ============================================================
    // PERFORMANCE MONITOR
    // ============================================================

    wire [31:0] cycle_count;
    wire [31:0] retired_count;
    wire [31:0] stall_count;
    wire [31:0] redirect_count;

    performance_monitor PERF_MONITOR (
        .clk(clk),
        .reset(reset),

        .retire_valid(mem_wb_valid),
        .stall_event(hazard_id_ex_flush),
        .redirect_event(redirect),

        .cycle_count(cycle_count),
        .retired_count(retired_count),
        .stall_count(stall_count),
        .redirect_count(redirect_count)
    );

endmodule
