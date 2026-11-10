
`timescale 1ns/1ps

module tb_rv32i_top;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire wb_reg_write;
    wire [4:0] wb_rd;
    wire [31:0] wb_data;

    integer write_count;
    integer errors;
    integer cycles;
    integer redirect_count;

    rv32i_top dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Monitor jump and redirect signals
    always @(negedge clk) begin
        if (!reset) begin

            $display(
                "PC=%h ID_EX_PC=%h JUMP=%b JALR=%b REDIRECT=%b WB_EN=%b WB_RD=%0d WB_DATA=%h",
                dut.pc,
                dut.id_ex_pc,
                dut.id_ex_jump,
                dut.id_ex_jalr,
                dut.redirect,
                wb_reg_write,
                wb_rd,
                wb_data
            );

            if (dut.redirect === 1'b1) begin
                redirect_count = redirect_count + 1;

                $display(
                    "JUMP REDIRECT DETECTED: %0d TARGET=%h",
                    redirect_count,
                    dut.redirect_target
                );
            end
        end
    end

    // Monitor register writeback
    always @(negedge clk) begin
        if (!reset && wb_reg_write) begin

            write_count = write_count + 1;

            $display(
                "WRITEBACK %0d: x%0d = %0d (0x%08h)",
                write_count,
                wb_rd,
                wb_data,
                wb_data
            );

            case (wb_rd)

                5'd4: begin
                    if (wb_data !== 32'd25) begin
                        $display("ERROR: Expected x4 = 25");
                        errors = errors + 1;
                    end
                end

                5'd5: begin
                    if (wb_data !== 32'd8) begin
                        $display("ERROR: JAL link address should be 8");
                        errors = errors + 1;
                    end
                end

                5'd2: begin
                    if (wb_data !== 32'd7) begin
                        $display("ERROR: Expected x2 = 7");
                        errors = errors + 1;
                    end
                end

                5'd6: begin
                    if (wb_data !== 32'd20) begin
                        $display("ERROR: JALR link address should be 20");
                        errors = errors + 1;
                    end
                end

                5'd8: begin
                    if (wb_data !== 32'd11) begin
                        $display("ERROR: Expected x8 = 11");
                        errors = errors + 1;
                    end
                end

                5'd7: begin
                    $display("ERROR: Wrong-path instruction wrote to x7");
                    errors = errors + 1;
                end

                default: begin
                    $display("ERROR: Unexpected write to x%0d", wb_rd);
                    errors = errors + 1;
                end

            endcase
        end
    end

    // Main JAL/JALR test
    initial begin

        reset = 1'b1;
        write_count = 0;
        errors = 0;
        cycles = 0;
        redirect_count = 0;

        // ---------------------------------------------
        // PROGRAM
        // ---------------------------------------------

        // Address 0x00:
        // ADDI x4, x0, 25
        dut.IMEM.memory[0] = 32'h01900213;

        // Address 0x04:
        // JAL x5, +8
        dut.IMEM.memory[1] = 32'h008002ef;

        // Address 0x08:
        // ADDI x7, x0, 99 (MUST BE FLUSHED)
        dut.IMEM.memory[2] = 32'h06300393;

        // Address 0x0C:
        // ADDI x2, x0, 7
        dut.IMEM.memory[3] = 32'h00700113;

        // Address 0x10:
        // JALR x6, 0(x4)
        // x4 = 25, target = 24 after clearing bit 0
        dut.IMEM.memory[4] = 32'h00020367;

        // Address 0x14:
        // ADDI x7, x0, 99 (MUST BE FLUSHED)
        dut.IMEM.memory[5] = 32'h06300393;

        // Address 0x18:
        // ADDI x8, x0, 11
        dut.IMEM.memory[6] = 32'h00b00413;

        // ---------------------------------------------
        // RESET
        // ---------------------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        repeat (22) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        @(negedge clk);

        // ---------------------------------------------
        // SUMMARY
        // ---------------------------------------------

        $display("");
        $display("======================================");
        $display(" JAL / JALR TEST SUMMARY");
        $display("======================================");

        $display("Cycles executed : %0d", cycles);
        $display("Writebacks      : %0d", write_count);
        $display("Jump redirects  : %0d", redirect_count);
        $display("Errors          : %0d", errors);

        if (write_count != 5) begin
            $display("ERROR: Expected exactly 5 writebacks");
            errors = errors + 1;
        end

        if (redirect_count != 2) begin
            $display("ERROR: Expected exactly 2 jump redirects");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("ALL JAL/JALR TESTS PASSED");
        end
        else begin
            $display("JAL/JALR TEST FAILED");
        end

        $display("======================================");

        $finish;
    end

endmodule
