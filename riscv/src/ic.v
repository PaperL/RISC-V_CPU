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

reg out;
reg[`INS_DAT_W - 1: 0] ins;

assign oBP_En = out;
assign oIF_En = out;
assign oBP_Ins = ins;
assign oIF_Ins = ins;

always @(posedge clk) begin
    if (rst) begin
        out <= 0; ins <= 0;
        oMC_En <= 0; oMC_Pc <= 0;
    end
    else if (en) begin
        oMC_En <= 0;
        out <= 0;

        if (iIF_En) begin
            oMC_En <= 1;
            oMC_Pc <= iIF_Pc;
        end
        if (iMC_En) begin
            out <= 1;
            ins <= iMC_Ins;
        end
    end
end

endmodule
