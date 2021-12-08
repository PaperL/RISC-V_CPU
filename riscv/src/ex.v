`include "header.vh" 
// Execution Module
module ex (
           input wire clk,
           input wire rst,
           input wire en,

           input wire iRS_En,
           input wire[`INS_OP_W - 1: 0] iRS_Op,
           input wire[`REG_DAT_W - 1: 0] iRS_Pc,
           input wire[`REG_DAT_W - 1: 0] iRS_Imm,
           input wire[`REG_DAT_W - 1: 0] iRS_Vs1,
           input wire[`REG_DAT_W - 1: 0] iRS_Vs2,
           input wire[`ROB_ADD_W - 1: 0] iRS_Qd,

           output wire oRS_En,
           output wire[`ROB_ADD_W - 1: 0] oRS_Qd,
           output wire[`REG_DAT_W - 1: 0] oRS_Vd,

           output wire oLSB_En,
           output wire[`ROB_ADD_W - 1: 0] oLSB_Qd,
           output wire[`REG_DAT_W - 1: 0] oLSB_Vd,


           output wire oROB_En,
           output wire[`ROB_ADD_W - 1: 0] oROB_Qd,
           output wire[`REG_DAT_W - 1: 0] oROB_Vd,
           output wire[`REG_DAT_W - 1: 0] oROB_Jt

       );

reg exOut;

reg[`REG_DAT_W - 1: 0] v;
reg[`REG_DAT_W - 1: 0] jt;

wire[`INS_OP_W - 1: 0] op; assign op = iRS_Op;
wire[`REG_DAT_W - 1: 0] pc; assign pc = iRS_Pc;
wire[`REG_DAT_W - 1: 0] imm; assign imm = iRS_Imm;
wire[`REG_DAT_W - 1: 0] vs1; assign vs1 = iRS_Vs1;
wire[`REG_DAT_W - 1: 0] vs2; assign vs2 = iRS_Vs2;
wire[`ROB_ADD_W - 1: 0] qd; assign qd = iRS_Qd;

assign oRS_En = exOut;
assign oRS_Qd = qd;
assign oRS_Vd = v;
assign oLSB_En = exOut;
assign oLSB_Qd = qd;
assign oLSB_Vd = v;
assign oROB_En = exOut;
assign oROB_Qd = qd;
assign oROB_Vd = v;
assign oROB_Jt = jt;


always @(posedge clk) begin
    if (rst) begin
        exOut <= 0;
        v <= 0; jt <= 0;
    end
    else if (en) begin
        exOut <= 0;
        v <= 0; jt <= 0;

        // Calculation
        if (iRS_En) begin
            exOut <= 1;

            case (op)
                5'b00001:                       // LUI
                    v <= imm;
                5'b00010:                       // AUIPC
                    v <= pc + imm;
                5'b00100:                       // JALR
                    v <= pc + 4;
                5'b01011:                       // ADDI
                    v <= vs1 + imm;
                5'b01100:                       // SLLI
                    v <= vs1 << imm;
                5'b01101:                       // SLTI
                    v <= ($signed(vs1) < $signed(imm)) ? 1 : 0;
                5'b01110:                       // SLTIU
                    v <= (vs1 < imm) ? 1 : 0;
                5'b01111:                       // XORI
                    v <= vs1 ^ imm;
                5'b10000:                       // SRLI
                    v <= vs1 >> imm[5: 0];
                5'b10001:                       // SRAI
                    v <= vs1 >>> imm[5: 0];
                5'b10010:                       // ORI
                    v <= vs1 | imm;
                5'b10011:                       // ANDI
                    v <= vs1 & imm;
                5'b10100:                       // ADD
                    v <= vs1 + vs2;
                5'b10101:                       // SUB
                    v <= vs1 - vs2;
                5'b10110:                       // SLL
                    v <= vs1 << vs2;
                5'b10111:                       // SLT
                    v <= ($signed(vs1) < $signed(vs2)) ? 1 : 0;
                5'b11000:                       // SLTU
                    v <= (vs1 < vs2) ? 1 : 0;
                5'b11001:                       // XOR
                    v <= vs1 ^ vs2;
                5'b11010:                       // SRL
                    v <= vs1 >> vs2;
                5'b11011:                       // SRA
                    v <= vs1 >>> vs2;
                5'b11100:                       // OR
                    v <= vs1 | vs2;
                5'b11101:                       // AND
                    v <= vs1 & vs2;
            endcase

            // Jump
            case (op)
                5'b00100:   // JALR
                    jt <= vs1 + imm;
                5'b00101:   // BEQ
                    jt <= (vs1 == vs2) ? (pc + imm) : pc + 4;
                5'b00110:   // BNE
                    jt <= (vs1 != vs2) ? (pc + imm) : pc + 4;
                5'b00111:   // BLT
                    jt <= ($signed(vs1) < $signed(vs2)) ? (pc + imm) : pc + 4;
                5'b01000:   // BGE
                    jt <= ($signed(vs1) > $signed(vs2)) ? (pc + imm) : pc + 4;
                5'b01001:   // BLTU
                    jt <= (vs1 < vs2) ? (pc + imm) : pc + 4;
                5'b01010:   // BGEU
                    jt <= (vs1 > vs2) ? (pc + imm) : pc + 4;
            endcase
        end
    end
end

endmodule
