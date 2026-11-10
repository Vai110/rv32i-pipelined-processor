
module mem_wb_register (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,

    input wire [31:0] pc_plus4_in,
    input wire [31:0] alu_result_in,
    input wire [31:0] mem_data_in,
    input wire [4:0] rd_in,

    input wire reg_write_in,
    input wire [1:0] wb_sel_in,

    output reg [31:0] pc_plus4_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_data_out,
    output reg [4:0] rd_out,

    output reg reg_write_out,
    output reg [1:0] wb_sel_out
);

    always @(posedge clk) begin
        if (reset) begin
            pc_plus4_out <= 32'b0;
            alu_result_out <= 32'b0;
            mem_data_out <= 32'b0;
            rd_out <= 5'b0;

            reg_write_out <= 1'b0;
            wb_sel_out <= 2'b0;
        end
        else if (flush) begin
            pc_plus4_out <= 32'b0;
            alu_result_out <= 32'b0;
            mem_data_out <= 32'b0;
            rd_out <= 5'b0;

            reg_write_out <= 1'b0;
            wb_sel_out <= 2'b0;
        end
        else if (enable) begin
            pc_plus4_out <= pc_plus4_in;
            alu_result_out <= alu_result_in;
            mem_data_out <= mem_data_in;
            rd_out <= rd_in;

            reg_write_out <= reg_write_in;
            wb_sel_out <= wb_sel_in;
        end
    end

endmodule
