
module ex_mem_register (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,

    input wire [31:0] pc_plus4_in,
    input wire [31:0] alu_result_in,
    input wire [31:0] rs2_data_in,
    input wire [4:0] rd_in,

    input wire mem_read_in,
    input wire mem_write_in,
    input wire [2:0] funct3_in,

    input wire reg_write_in,
    input wire [1:0] wb_sel_in,

    output reg [31:0] pc_plus4_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0] rd_out,

    output reg mem_read_out,
    output reg mem_write_out,
    output reg [2:0] funct3_out,

    output reg reg_write_out,
    output reg [1:0] wb_sel_out
);

    always @(posedge clk) begin
        if (reset) begin
            pc_plus4_out <= 32'b0;
            alu_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            rd_out <= 5'b0;

            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            funct3_out <= 3'b0;

            reg_write_out <= 1'b0;
            wb_sel_out <= 2'b0;
        end
        else if (flush) begin
            pc_plus4_out <= 32'b0;
            alu_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            rd_out <= 5'b0;

            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            funct3_out <= 3'b0;

            reg_write_out <= 1'b0;
            wb_sel_out <= 2'b0;
        end
        else if (enable) begin
            pc_plus4_out <= pc_plus4_in;
            alu_result_out <= alu_result_in;
            rs2_data_out <= rs2_data_in;
            rd_out <= rd_in;

            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            funct3_out <= funct3_in;

            reg_write_out <= reg_write_in;
            wb_sel_out <= wb_sel_in;
        end
    end

endmodule
