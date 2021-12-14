`include "header.vh" 
// Data Cache Module
module dc (
           input wire clk,
           input wire rst,
           input wire en,

           input wire iLSB_En,
           input wire iLSB_Rw,                   // 0:R, 1:W
           input wire[2: 0] iLSB_Len,
           input wire[`MEM_ADD_W - 1: 0] iLSB_Add,
           input wire[`REG_DAT_W - 1: 0] iLSB_Dat,
           output reg oLSB_En,
           output reg[`REG_DAT_W - 1: 0] oLSB_Dat,

           output reg oMC_En,
           output reg oMC_Rw,                   // 0:R, 1:W
           output reg[2: 0] oMC_Len,
           output reg[`MEM_ADD_W - 1: 0] oMC_Add,
           output reg[`REG_DAT_W - 1: 0] oMC_Dat,
           input wire iMC_En,
           input wire[`REG_DAT_W - 1: 0] iMC_Dat
       );

reg[2: 0] len;

always @(posedge clk) begin
    if (rst) begin
        len <= 0;
        oLSB_En <= 0; oLSB_Dat <= 0;
        oMC_En <= 0; oMC_Rw <= 0; oMC_Len <= 0;
        oMC_Add <= 0; oMC_Dat <= 0;
    end
    else if (en) begin
        oLSB_En <= 0;
        oMC_En <= 0;

        if (iLSB_En) begin
            oMC_En <= 1; oMC_Rw <= iLSB_Rw; oMC_Len <= iLSB_Len;
            oMC_Add <= iLSB_Add; oMC_Dat <= iLSB_Dat;
        end
        if (iMC_En) begin
            oLSB_En <= 1;
            oLSB_Dat <= iMC_Dat;
        end
    end
end

endmodule
