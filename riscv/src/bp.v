`include "header.vh"

module bp (input wire clk,
           input wire rst,
           input wire en,

           input wire iIC_En,
           input wire[`INS_DAT_W - 1: 0] iIC_Ins,

           input wire[`REG_DAT_W - 1: 0] iIF_Pc,
           output reg oIF_En,
           output wire[`REG_DAT_W - 1: 0] oIF_Pcn
          );
reg[`REG_DAT_W - 1: 0] PCN;
assign oIF_Pcn = PCN;

always @(posedge clk) begin
    if (rst) begin
        PCN <= 0;
    end
    else if (en) begin
        if (iIC_En) begin
            PCN <= iIF_Pc + 4;
            oIF_En <= 1;
        end
        else oIF_En <= 0;
    end
end

initial begin
    oIF_En = 1;
end

endmodule
