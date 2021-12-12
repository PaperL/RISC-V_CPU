`include "header.vh" 
// Instruction Cache Module
module ic (input wire clk,
           input wire rst,
           input wire en,

           input wire iIF_En,
           input wire[`REG_DAT_W - 1: 0] iIF_Pc,
           output wire oIF_En,
           output wire[`INS_DAT_W - 1: 0] oIF_Ins,

           output wire oMC_En,
           output wire[`MEM_ADD_W - 1: 0] oMC_Add,
           input wire iMC_En,
           input wire[`MEM_DAT_W - 1: 0] iMC_Dat,

           output wire oBP_En,
           output wire[`INS_DAT_W - 1: 0] oBP_Ins
          );

reg[2: 0] cnt;
reg reading;
reg[`MEM_ADD_W - 1: 0] addr;
reg out;
reg[`INS_DAT_W - 1: 0] ins;

assign oMC_En = reading;
assign oMC_Add = addr;

assign oBP_En = out;
assign oIF_En = out;
assign oBP_Ins = ins;
assign oIF_Ins = ins;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        reading <= 0; addr <= 0;
        out <= 0; ins <= 0;
    end
    else if (en) begin
        reading <= 0;
        out <= 0;

        if (iIF_En) begin
            cnt <= 1;
            addr <= iIF_Pc;
            reading <= 1;
        end
        else if (cnt != 0) begin
            if (iMC_En) begin
                reading <= 1;
                cnt <= cnt + 1;
                addr <= addr + 1;
                case (cnt)
                    1: ins[7: 0] <= iMC_Dat;
                    2: ins[15: 8] <= iMC_Dat;
                    3: ins[23: 16] <= iMC_Dat;
                    4: ins[31: 24] <= iMC_Dat;
                    default: ;
                endcase
                if (cnt == 4) begin // Finish
                    reading <= 0;
                    cnt <= 0;
                    out <= 1;
                end
            end
        end
    end
end

endmodule
