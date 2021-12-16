`include "header.vh" 
// Issue Module
// Responsible for decode and departure
// See README.md for instruction set description
module is(
           input wire clk,
           input wire rst,
           input wire en,

           input wire iIF_En,
           input wire[`INS_DAT_W - 1: 0] iIF_Ins,
           input wire iIF_Bj,
           input wire[`REG_DAT_W - 1: 0] iIF_Pc,
           input wire[`REG_DAT_W - 1: 0] iIF_Pjt,

           output reg oREG_En,
           output wire[`REG_ADD_W - 1: 0] oREG_Rs1,
           output wire[`REG_ADD_W - 1: 0] oREG_Rs2,
           output wire[`REG_ADD_W - 1: 0] oREG_Rd,
           output wire[`INS_OP_W - 1: 0] oREG_Op,
           output wire[`REG_DAT_W - 1: 0] oREG_Imm,
           output wire[`REG_DAT_W - 1 : 0] oREG_Pc,
           output wire oREG_Ils,

           output reg oROB_En,
           output wire oROB_Is,
           output wire[`REG_ADD_W - 1: 0] oROB_Rd,
           output wire oROB_Bj,
           output wire[`REG_DAT_W - 1: 0] oROB_Pc,
           output wire[`REG_DAT_W - 1: 0] oROB_Pjt
       );
reg[`REG_DAT_W - 1: 0] pc;
reg ils, is, bj;            // ils: Is Load or Store, bj: Is Branch or Jump
reg[`REG_DAT_W - 1: 0] pjt;

reg[`INS_OP_W - 1: 0] op; // Inner Opcode (See README.md)
reg[`REG_DAT_W - 1: 0] imm;
reg[`REG_ADD_W - 1: 0] rs1, rs2, rd;

wire[`INS_DAT_W - 1: 0] ins;
wire[6: 0] opcode; // RISC-V Instruction Opcode
wire[2: 0] funct3;
wire funct7;
assign ins = iIF_Ins;
assign opcode = ins[6: 0];
assign funct3 = ins[14: 12];
assign funct7 = ins[30];

assign oREG_Rs1 = rs1;
assign oREG_Rs2 = rs2;
assign oREG_Rd = rd;
assign oREG_Op = op;
assign oREG_Imm = imm;
assign oREG_Pc = pc;
assign oREG_Ils = ils;

assign oROB_Is = is;
assign oROB_Rd = rd;
assign oROB_Bj = bj;
assign oROB_Pc = pc;
assign oROB_Pjt = pjt;


always@(posedge clk) begin
    oREG_En <= 0;
    oROB_En <= 0;
    pc <= 0;
    ils <= 0; is <= 0; bj <= 0;
    pjt <= 0;
    op <= 0;
    imm <= 0;
    rs1 <= 0; rs2 <= 0; rd <= 0;

    if (rst) ;
    else if (en) begin
        if (iIF_En) begin
            oREG_En <= 1;
            oROB_En <= 1;

            ils <= 0;
            is <= 0;
            bj <= iIF_Bj;   // ! "is BRANCH or JUMP" is managed in IF
            pc <= iIF_Pc;
            pjt <= iIF_Pjt;

            // * Operand
            rs2 <= ins[24: 20];
            rs1 <= ins[19: 15];
            rd <= ins[11: 7];
            case (opcode)
                // * 关于 case branch 未覆盖全部情况
                // https://www.intel.com/content/www/us/en/programmable/quartushelp/13.0/mergedProjects/msgs/msgs/wvrfx_l2_veri_incomplete_case_statement.htm
                // http://www.sunburst-design.com/papers/CummingsSNUG2005Israel_SystemVerilog_UniquePriority.pdf
                7'b0110111,
                7'b0010111: begin       // U
                    imm[31: 12] <= ins[31: 12];
                    rs1 <= 0;
                    rs2 <= 0;
                end
                7'b1101111: begin       // UJ
                    // ! Immediate Operand 需要符号扩展
                    // ? 也可以用 $signed({ins[19: 12], ins[20], ins[30: 21], 1'b0}), 配合自动补充数据长度来实现
                    // ? 但是自动补充数据长度属于 warning 行为
                    imm <= {{12{ins[31]}}, ins[19: 12], ins[20], ins[30: 21], 1'b0};
                    rs1 <= 0;
                    rs2 <= 0;
                end
                7'b1100111,
                7'b0000011,
                7'b0010011: begin       // I
                    imm <= {{20{ins[31]}}, ins[31: 20]};
                    rs2 <= 0;
                end
                7'b1100011: begin       // SB for BRANCH
                    imm <= {{19{ins[31]}}, ins[31], ins[7], ins[30: 25], ins[11: 8], 1'b0};
                    rd <= 0;
                end
                7'b0100011: begin       // S for STORE
                    imm <= {{20{ins[31]}}, ins[31: 25], ins[11: 7]};
                    rd <= 0;
                    ils <= 1; is <= 1;  // ! is STORE
                end
                default: ;              // R-type Ins has no Imm
            endcase

            // * Inner Opcode
            case (opcode)                // Opcode
                // ! op == 5'b000000 时为无效指令，不应出现在后续元件中
                7'b0110111: op <= 5'b00001;         // LUI
                7'b0010111: op <= 5'b00010;         // AUIPC
                7'b1101111: op <= 5'b00011;         // JAL
                7'b1100111: op <= 5'b00100;         // JALR
                7'b1100011: begin
                    case (funct3)
                        3'b000: op <= 5'b00101;     // BEQ
                        3'b001: op <= 5'b00110;     // BNE
                        3'b100: op <= 5'b00111;     // BLT
                        3'b101: op <= 5'b01000;     // BGE
                        3'b110: op <= 5'b01001;     // BLTU
                        3'b111: op <= 5'b01010;     // BGEU
                        default: op <= 5'b00000;
                    endcase
                end
                7'b0000011: begin
                    ils <= 1;   // ! is LOAD
                    case (funct3)
                        3'b000: op <= 5'b0001;      // LB
                        3'b001: op <= 5'b0010;      // LH
                        3'b010: op <= 5'b0011;      // LW
                        3'b100: op <= 5'b0100;      // LBU
                        3'b101: op <= 5'b0101;      // LHU
                        default: op <= 5'b00000;
                    endcase
                end
                7'b0100011: begin
                    case (funct3)
                        3'b000: op <= 5'b0110;      // SB
                        3'b001: op <= 5'b0111;      // SH
                        3'b010: op <= 5'b1000;      // SW
                        default: op <= 5'b00000;
                    endcase
                end
                7'b0010011: begin
                    case (funct3)
                        3'b000: op <= 5'b01011;     // ADDI
                        3'b001: op <= 5'b01100;     // SLLI
                        3'b010: op <= 5'b01101;     // SLTI
                        3'b011: op <= 5'b01110;     // SLTIU
                        3'b100: op <= 5'b01111;     // XORI
                        3'b101: op <= funct7
                            ? 5'b10001              // SRAI
                            : 5'b10000;             // SRLI
                        3'b110: op <= 5'b10010;     // ORI
                        3'b111: op <= 5'b10011;     // ANDI
                    endcase
                end
                7'b0110011: begin
                    case (funct3)
                        3'b000: op <= funct7
                            ? 5'b10101              // ADD
                            : 5'b10100;             // SUB
                        3'b001: op <= 5'b10110;     // SLL
                        3'b010: op <= 5'b10111;     // SLT
                        3'b011: op <= 5'b11000;     // SLTU
                        3'b100: op <= 5'b11001;     // XOR
                        3'b101: op <= funct7
                            ? 5'b11011              // SRA
                            : 5'b11010;             // SRL
                        3'b110: op <= 5'b11100;     // OR
                        3'b111: op <= 5'b11101;     // AND
                    endcase
                end
                default: op <= 5'b00000;
            endcase
        end
    end
end

endmodule
