`include "header.vh" 
// Instruction Cache Module
module ic (input wire clk,
           input wire rst,
           input wire en,

           input wire iIF_En,
           input wire[`REG_DAT_W - 1: 0] iIF_Pc,
           output wire oIF_En,
           output wire[`INS_DAT_W - 1: 0] oIF_Ins,

           output reg oMC_En,
           output reg[`MEM_ADD_W - 1: 0] oMC_Pc,
           input wire iMC_En,
           input wire[`INS_DAT_W - 1: 0] iMC_Ins,

           output wire oBP_En,
           output wire[`INS_DAT_W - 1: 0] oBP_Ins
          );
// Cache Data
reg cEn[`IC_S - 1: 0];
reg[(`INS_DAT_W - `IC_ADD_W) - 1: 0] cTag[`IC_S - 1: 0];
reg[`INS_DAT_W - 1: 0] cIns[`IC_S - 1: 0];

// IO
wire[`IC_ADD_W - 1: 0] iIndex;
assign iIndex = iIF_Pc[`IC_ADD_W - 1: 0];
wire[(`INS_DAT_W - `IC_ADD_W) - 1: 0] iTag;
assign iTag = iIF_Pc[`INS_DAT_W - 1: `IC_ADD_W];

reg out;
reg[`INS_DAT_W - 1: 0] ins;

assign oBP_En = out;
assign oIF_En = out;
assign oBP_Ins = ins;
assign oIF_Ins = ins;

// Local Information
reg[`IC_ADD_W - 1: 0] index;

wire[`INS_DAT_W - 1: 0] ci;
assign ci = cIns[iIndex];

wire isLBU; // BUG IO Sleep 功能中的 LBU 指令出现异常
assign isLBU = (ci[6: 0] == 7'b0000011 || ci[6: 0] == 7'b0100011);

integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `IC_S; i = i + 1) begin
            cEn[i] <= 0;
            cTag[i] <= 0; cIns[i] <= 0;
        end

        out <= 0; ins <= 0;
        oMC_En <= 0; oMC_Pc <= 0;

        index <= 0;
    end
    else if (en) begin
        oMC_En <= 0;
        out <= 0;

        if (iIF_En) begin
            if (cEn[iIndex] && (cTag[iIndex] == iTag) && (!isLBU)) begin
                out <= 1;
                ins <= ci;
            end
            else begin
                oMC_En <= 1;
                oMC_Pc <= iIF_Pc;
                index <= iIndex;
                cEn[iIndex] <= 0;   // ! 防止中断后的紧跟 iIF_En
                cTag[iIndex] = iIF_Pc[`INS_DAT_W - 1: `IC_ADD_W];
            end
        end
        if (iMC_En) begin
            out <= 1;
            ins <= iMC_Ins;
            cEn[index] <= 1;
            cIns[index] <= iMC_Ins;
        end
    end
end

endmodule
