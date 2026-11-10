
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

    // Monitor branch and pipeline control
    always @(negedge clk) begin
        if (!reset) begin

            $display(
                "PC=%h IFID=%h ID_EX_PC=%h BRANCH=%b TAKEN=%b REDIRECT=%b WB_EN=%b",
                dut.pc,
                dut.if_id_instruction,
                dut.id_ex_pc,
                dut.id_ex_branch,
                dut.branch_taken,
                dut.redirect,
                wb_reg_write
            );

            if (dut.redirect === 1'b1) begin
                redirect_count = redirect_count + 1;
                $display("BRANCH REDIRECT DETECTED: %0d",
                         redirect_count);
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

                5'd1: begin
                    if (wb_data !== 32'd5) begin
                        $display("ERROR: x1 expected 5");
                        errors = errors + 1;
                    end
                end

                5'd2: begin
                    if (wb_data !== 32'd5) begin
                        $display("ERROR: x2 expected 5");
                        errors = errors + 1;
                    end
                end

                5'd3: begin
                    if (wb_data !== 32'd7) begin
                        $display("ERROR: x3 expected 7; wrong-path instruction may not have been flushed");
                        errors = errors + 1;
                    end
                end

                5'd4: begin
                    if (wb_data !== 32'd9) begin
                        $display("ERROR: x4 expected 9");
                        errors = errors + 1;
                    end
                end

                default: begin
                    $display("ERROR: Unexpected register write x%0d",
                             wb_rd);
                    errors = errors + 1;
                end

            endcase
        end
    end

    // Main branch test
    initial begin

        reset = 1'b1;
        write_count = 0;
        errors = 0;
        cycles = 0;
        redirect_count = 0;

        // ------------------------------------------------
        // PROGRAM
        // ------------------------------------------------

        // ADDI x1, x0, 5
        dut.IMEM.memory[0] = 32'h00500093;

        // ADDI x2, x0, 5
        dut.IMEM.memory[1] = 32'h00500113;

        // BEQ x1, x2, +8 (TAKEN)
        dut.IMEM.memory[2] = 32'h00208463;

        // ADDI x3, x0, 99 (MUST BE FLUSHED)
        dut.IMEM.memory[3] = 32'h06300193;

        // ADDI x3, x0, 7 (BRANCH TARGET)
        dut.IMEM.memory[4] = 32'h00700193;

        // BNE x1, x2, +8 (NOT TAKEN)
        dut.IMEM.memory[5] = 32'h00209463;

        // ADDI x4, x0, 9
        dut.IMEM.memory[6] = 32'h00900213;

        // ------------------------------------------------
        // RESET
        // ------------------------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        repeat (22) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        @(negedge clk);

        // ------------------------------------------------
        // SUMMARY
        // ------------------------------------------------

        $display("");
        $display("======================================");
        $display(" BRANCH AND FLUSH TEST SUMMARY");
        $display("======================================");

        $display("Cycles executed : %0d", cycles);
        $display("Writebacks      : %0d", write_count);
        $display("Redirects       : %0d", redirect_count);
        $display("Errors          : %0d", errors);

        if (write_count != 4) begin
            $display("ERROR: Expected exactly 4 writebacks");
            errors = errors + 1;
        end

        if (redirect_count != 1) begin
            $display("ERROR: Expected exactly 1 branch redirect");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("ALL BRANCH TESTS PASSED");
        end
        else begin
            $display("BRANCH TEST FAILED");
        end

        $display("======================================");

        $finish;
    end

endmodule
