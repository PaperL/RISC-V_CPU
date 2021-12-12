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
           input wire iDC_Rw,        // 0:R, 1:W
           input wire[`MEM_ADD_W - 1: 0] iDC_Add,
           input wire[`MEM_DAT_W - 1: 0] iDC_Dat,
           output reg oDC_En,
           output wire[`MEM_DAT_W - 1: 0] oDC_Dat,

           output wire oRAM_Rw,      // read/write select (read: 1, write: 0)
           output wire[16: 0] oRAM_Add,
           output wire[`MEM_DAT_W - 1: 0] oRAM_Dat,
           input wire[`MEM_DAT_W - 1: 0] iRAM_Dat
          );

reg switch; // 0:IC, 1:DC
reg icw;    // IC is Waiting

reg[`MEM_ADD_W - 1: 0] IC_Add;
reg DC_Rw;
reg[`MEM_ADD_W - 1: 0] DC_Add;
reg[`MEM_DAT_W - 1: 0] DC_Dat;

assign oRAM_Rw = switch ? DC_Rw : 1'b1; // IC always Read
assign oRAM_Add = switch ? DC_Add[16 : 0] : IC_Add[16 : 0];
assign oRAM_Dat = DC_Dat;

assign oDC_Dat = iRAM_Dat;
assign oIC_Dat = iRAM_Dat;

always @(posedge clk) begin
    if (rst) begin
        switch <= 0;    icw <= 0;
        IC_Add <= 0;
        DC_Rw <= 0; DC_Add <= 0; DC_Dat <= 0;

        oIC_En <= 0; oDC_En <= 0;
    end
    else if (en) begin
        oIC_En <= 0;
        switch <= iDC_En;   // DC 优先
        if(switch == 0) begin
            if(icw)begin
                icw <= 0;
                oIC_En <= 1;
            end
        end
        oDC_En <= (switch == 1) ? 1 : 0;
        
        if (iIC_En) begin
            IC_Add <= iIC_Add;
            icw <= 1;
        end
        if (iDC_En) begin
            DC_Rw <= ~iDC_Rw; // ! RAM 中 0 为 Write 与其他元件相反
            DC_Add <= iDC_Add;
            DC_Dat <= iDC_Dat;
        end
    end
end
endmodule
