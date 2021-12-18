`include "header.vh" 
// Instruction Fetch Module
module ifet (input wire clk,
             input wire rst,
             input wire en,   // ROB is Full

             output reg oIC_En,
             output wire[`REG_DAT_W - 1: 0] oIC_Pc,
             input wire iIC_En,
             input wire[`INS_DAT_W - 1: 0] iIC_Ins,

             output wire[`REG_DAT_W - 1: 0] oBP_Pc,
             input wire iBP_En,
             input wire[`REG_DAT_W - 1: 0] iBP_Pjt,

             output reg oIS_En,
             output wire[`INS_DAT_W - 1: 0] oIS_Ins,
             output wire oIS_Bj,
             output wire[`REG_DAT_W - 1: 0] oIS_Pc,
             output wire[`REG_DAT_W - 1: 0] oIS_Pjt,

             input wire iROB_Mp,                        // Misprediction
             input wire[`REG_DAT_W - 1: 0] iROB_Rpc     // Right PC
            );
reg[`REG_DAT_W - 1: 0] PC, pcb;
// PC; Instruction's PC which is ready to be send to IS(PC Backup)
reg bj; // Is Branch or Jump
reg[`INS_DAT_W - 1: 0] INS; // Instruction Metadata
// * 0: Idle;
// * 1: Waiting for IC;
// * 2: Waiting for BP;
// * 3: Waiting for IC and abandon useless input;
reg[1: 0] status;

assign oIC_Pc = PC;
assign oBP_Pc = PC;
assign oIS_Ins = INS;
assign oIS_Bj = bj;
assign oIS_Pc = pcb;
assign oIS_Pjt = PC;
// Predicted Jump Target is the current PC
// when the previous instruction is sent to IS

// Local Information
wire[`REG_DAT_W - 1: 0]JalJt;  // JAL Instruction's Jump Target
assign JalJt = PC + {{12{iIC_Ins[31]}},
                     iIC_Ins[19: 12],
                     iIC_Ins[20],
                     iIC_Ins[30: 21],
                     1'b0};
wire[6: 0] opcode;
assign opcode = iIC_Ins[6: 0];

always @(posedge clk) begin
    if (rst || iROB_Mp) begin
        PC <= iROB_Mp ? iROB_Rpc : 0;
        bj <= 0; pcb <= 0;
        INS <= 0;
        status <= 0;
        oIC_En <= 0;
        oIS_En <= 0;
    end
    else if (en) begin
        bj <= 0;
        oIC_En <= 0;
        oIS_En <= 0;

        case (status)
            0: begin    // Idle
                status <= 3;
                oIC_En <= 1;
                pcb <= PC;
            end
            1: begin    // Waiting for IC
                if (iIC_En == 1) begin
                    INS <= iIC_Ins;
                    case (opcode)
                        7'b1100011:             // Branch
                            status <= 2;
                        7'b1101111: begin   // ! JAL
                            status <= 0;
                            oIS_En <= 1;
                            bj <= 0;        // ! 后面不考虑 JAL 故此处必须为 0
                            PC <= JalJt;
                        end
                        default: begin  // JALR or BRANCH or other
                            status <= 0;
                            oIS_En <= 1;
                            bj <= (opcode == 7'b1100111) ? 1 : 0;
                            PC <= PC + 4;
                        end
                    endcase
                end
            end
            2: begin    // Waiting for BP
                status <= 0;
                oIS_En <= 1;
                bj <= 1;
                PC <= iBP_Pjt;
            end
            3: begin
                status <= 1;
                // ? 在 status == 0 的下一个 clk 如果 IC 有输入代表是被精确终端打断的指令, 需要无视
            end
        endcase
    end
end
endmodule
