
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
    integer stall_count;

    rv32i_top dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_data(wb_data)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Monitor pipeline and hazard signals
    always @(negedge clk) begin
        if (!reset) begin

            $display(
                "PC=%h IFID=%h ID_EX_RD=%0d ID_EX_MEMREAD=%b HAZARD_FLUSH=%b PC_WRITE=%b IFID_WRITE=%b WB_EN=%b WB_RD=%0d WB_DATA=%h",
                dut.pc,
                dut.if_id_instruction,
                dut.id_ex_rd,
                dut.id_ex_mem_read,
                dut.hazard_id_ex_flush,
                dut.pc_write,
                dut.if_id_write,
                wb_reg_write,
                wb_rd,
                wb_data
            );

            // Count load-use stall cycles
            if (dut.hazard_id_ex_flush === 1'b1) begin
                stall_count = stall_count + 1;
                $display("LOAD-USE HAZARD DETECTED: Stall %0d",
                         stall_count);
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

            case (write_count)

                1: begin
                    if (wb_rd !== 5'd1 || wb_data !== 32'd100) begin
                        $display("ERROR: Expected x1 = 100");
                        errors = errors + 1;
                    end
                end

                2: begin
                    if (wb_rd !== 5'd2 || wb_data !== 32'd7) begin
                        $display("ERROR: Expected x2 = 7");
                        errors = errors + 1;
                    end
                end

                3: begin
                    if (wb_rd !== 5'd3 || wb_data !== 32'd14) begin
                        $display("ERROR: Expected x3 = 14");
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

    // Main test sequence
    initial begin

        reset       = 1'b1;
        write_count = 0;
        errors      = 0;
        cycles      = 0;
        stall_count = 0;

        // ----------------------------------------------------
        // PROGRAM INITIALIZATION
        // ----------------------------------------------------

        // ADDI x1, x0, 100
        dut.IMEM.memory[0] = 32'h06400093;

        // LW x2, 0(x1)
        dut.IMEM.memory[1] = 32'h0000A103;

        // ADD x3, x2, x2
        dut.IMEM.memory[2] = 32'h002101B3;

        // ----------------------------------------------------
        // DATA MEMORY INITIALIZATION
        // ----------------------------------------------------

        // Store value 7 at address 100.
        // Little-endian representation.

        dut.DMEM.memory[100] = 8'd7;
        dut.DMEM.memory[101] = 8'd0;
        dut.DMEM.memory[102] = 8'd0;
        dut.DMEM.memory[103] = 8'd0;

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        // Allow instructions to complete.
        repeat (18) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        @(negedge clk);

        // ----------------------------------------------------
        // TEST SUMMARY
        // ----------------------------------------------------

        $display("");
        $display("======================================");
        $display(" LOAD-USE HAZARD TEST SUMMARY");
        $display("======================================");

        $display("Cycles executed : %0d", cycles);
        $display("Writebacks      : %0d", write_count);
        $display("Load-use stalls : %0d", stall_count);
        $display("Errors          : %0d", errors);

        if (write_count != 3) begin
            $display("ERROR: Expected exactly 3 writebacks");
            errors = errors + 1;
        end

        if (stall_count != 1) begin
            $display("ERROR: Expected exactly 1 load-use stall");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("ALL LOAD-USE HAZARD TESTS PASSED");
        end
        else begin
            $display("LOAD-USE HAZARD TEST FAILED");
        end

        $display("======================================");

        $finish;
    end

endmodule
