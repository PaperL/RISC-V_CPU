`include "header.vh" 
// Instruction Fetch Module
module ifet (input wire clk,
             input wire rst,
             input wire en,

             output reg oIC_En,
             output wire[`REG_DAT_W - 1: 0] oIC_Pc,
             input wire iIC_En,
             input wire[`INS_DAT_W - 1: 0] iIC_Ins,

             output wire[`REG_DAT_W - 1: 0] oBP_Pc,
             input wire iBP_En,
             input wire[`REG_DAT_W - 1: 0] iBP_Pcn,

             output reg oIS_En,
             output wire[`REG_DAT_W - 1: 0] oIS_Pc,
             output wire[`INS_DAT_W - 1: 0] oIS_Ins
            );
reg[`REG_DAT_W - 1: 0] PC;
reg wIC;    // Waiting for IC
reg[`INS_DAT_W - 1: 0] INS;

assign oIC_Pc = PC;
assign oBP_Pc = PC;
assign oIS_Ins = INS;

always @(posedge clk) begin
    if (rst) begin
        PC <= 0;
        wIC <= 0;
        INS <= 0;
        oIC_En <= 0;
        oIS_En <= 0;
    end
    else if (en) begin
        if (iBP_En == 1) PC <= iBP_Pcn;
        oIC_En <= 0;
        oIS_En <= 0;

        if (wIC == 0) begin
            oIC_En <= 1;
            wIC <= 1;
        end
        else begin // wIC == 1
            if (iIC_En == 1) begin
                wIC <= 0;
                INS <= iIC_Ins;
                oIS_En <= 1;
            end
        end
    end
end
endmodule
