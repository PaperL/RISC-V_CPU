`include "header.vh"
// Memory Controller Module
module mc (input wire clk,
           input wire rst,
           input wire en,

           input wire iIC_En,
           input wire[`MEM_ADD_W - 1: 0] iIC_Add,
           output reg oIC_En,
           output wire[`MEM_DAT_W - 1: 0] oIC_Dat,

           input wire iDC_En,
           input wire iDC_Rw,
           input wire[`MEM_ADD_W - 1: 0] iDC_Add,
           input wire[`MEM_DAT_W - 1: 0] iDC_Dat,
           output wire oDC_En,
           output wire[`MEM_DAT_W - 1: 0] oDC_Dat,

           output wire oRAM_Rw,            // read/write select (read: 1, write: 0)
           output wire[16: 0] oRAM_Add,
           output wire[`MEM_DAT_W - 1: 0] oRAM_Dat,
           input wire[`MEM_DAT_W - 1: 0] iRAM_Dat);

reg[`MEM_ADD_W - 1: 0] IC_add;
reg[`MEM_ADD_W - 1: 0] DC_add;

assign oRAM_Rw = 1'b1;
assign oRAM_Add = iIC_Add[16 : 0];

assign oDC_Dat = iRAM_Dat;
assign oIC_Dat = iRAM_Dat;

always @(posedge clk) begin
    if (rst) begin
        IC_add <= 0;
        DC_add <= 0;
    end
    else if (en) begin
        if (iIC_En) IC_add <= iIC_Add;
        if (iDC_En) DC_add <= iDC_Add;
        
        oIC_En <= iIC_En;
    end
end
endmodule
