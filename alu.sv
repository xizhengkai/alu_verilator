// alu.sv
typedef enum logic [1:0] {
     add     = 2'h1,
     sub     = 2'h2,
     nop     = 2'h0
} operation_t /*verilator public*/;

module alu #(
        parameter WIDTH = 6
) (
        input  logic clk,
        input  logic rst,

        input  operation_t       op_in,
        input  [WIDTH-1:0]      a_in,
        input  [WIDTH-1:0]      b_in,
        input  logic             in_valid,

        output logic [WIDTH-1:0] out,
        output logic             out_valid
);

    // 输入寄存器
    operation_t           op_in_r;
    logic [WIDTH-1:0]     a_in_r;
    logic [WIDTH-1:0]     b_in_r;
    logic                  in_valid_r;
    logic [WIDTH-1:0]     result;

    // 寄存器化输入
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            op_in_r     <= nop;       // 修复 Verilator 枚举报错
            a_in_r      <= '0;
            b_in_r      <= '0;
            in_valid_r  <= 1'b0;
        end else begin
            op_in_r    <= op_in;
            a_in_r     <= a_in;
            b_in_r     <= b_in;
            in_valid_r <= in_valid;
        end
    end

    // 组合逻辑计算
    always_comb begin
        result = '0;
        if (in_valid_r) begin
            case (op_in_r)
                add: result = a_in_r + b_in_r;
                sub: result = a_in_r + (~b_in_r + 1'b1); // 2's 补减法
                default: result = '0;
            endcase
        end
    end

    // 输出寄存器
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out       <= '0;
            out_valid <= 1'b0;
        end else begin
            out       <= result;
            out_valid <= in_valid_r;
        end
    end

endmodule
