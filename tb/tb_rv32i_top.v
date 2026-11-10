
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

    rv32i_top dut (
        .clk        (clk),
        .reset      (reset),
        .pc_out     (pc_out),
        .wb_reg_write(wb_reg_write),
        .wb_rd      (wb_rd),
        .wb_data    (wb_data)
    );

    // Clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // DEBUG: Observe instructions and pipeline control signals.
    always @(negedge clk) begin
        if (!reset) begin
            $display(
                "PC=%h IFID=%h ID_EX_RD=%0d ID_EX_MEMREAD=%b ID_EX_REGWRITE=%b ID_EX_JUMP=%b REDIRECT=%b HAZARD_FLUSH=%b PC_WRITE=%b IFID_WRITE=%b EX_MEM_RD=%0d MEM_WB_RD=%0d WB_EN=%b WB_DATA=%h",
                dut.pc,
                dut.if_id_instruction,
                dut.id_ex_rd,
                dut.id_ex_mem_read,
                dut.id_ex_reg_write,
                dut.id_ex_jump,
                dut.redirect,
                dut.hazard_id_ex_flush,
                dut.pc_write,
                dut.if_id_write,
                dut.ex_mem_rd,
                dut.mem_wb_rd,
                dut.wb_reg_write,
                dut.wb_data
            );
        end
    end

    // Observe register writeback.
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

            case (write_count)

                1: begin
                    if (wb_rd !== 5'd1 || wb_data !== 32'd5) begin
                        $display("ERROR: Expected x1 = 5");
                        errors = errors + 1;
                    end
                end

                2: begin
                    if (wb_rd !== 5'd2 || wb_data !== 32'd8) begin
                        $display("ERROR: Expected x2 = 8");
                        errors = errors + 1;
                    end
                end

                3: begin
                    if (wb_rd !== 5'd3 || wb_data !== 32'd13) begin
                        $display("ERROR: Expected x3 = 13");
                        errors = errors + 1;
                    end
                end

                default: begin
                    $display("ERROR: Unexpected extra register write");
                    errors = errors + 1;
                end

            endcase
        end
    end

    // Main test sequence.
    initial begin
        reset       = 1'b1;
        write_count = 0;
        errors      = 0;
        cycles      = 0;

        // ADDI x1, x0, 5
        dut.IMEM.memory[0] = 32'h00500093;

        // ADDI x2, x1, 3
        dut.IMEM.memory[1] = 32'h00308113;

        // ADD x3, x1, x2
        dut.IMEM.memory[2] = 32'h002081B3;

        // Hold reset for two clock cycles.
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        // Allow instructions to pass through all five stages.
        repeat (15) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        @(negedge clk);

        // Test summary.
        $display("");
        $display("======================================");
        $display(" RV32I-PLUS PROCESSOR TEST SUMMARY");
        $display("======================================");
        $display("Cycles executed : %0d", cycles);
        $display("Writebacks      : %0d", write_count);
        $display("Errors          : %0d", errors);

        if (write_count != 3) begin
            $display("ERROR: Expected exactly 3 writebacks");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("ALL PROCESSOR TESTS PASSED");
        end
        else begin
            $display("PROCESSOR TEST FAILED");
        end

        $display("======================================");

        $finish;
    end

endmodule
