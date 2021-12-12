`include "header.vh" 
// Data Cache Module
module dc (
           input wire clk,
           input wire rst,
           input wire en,

           input wire iLSB_En,
           input wire iLSB_Rw,           // 0:R, 1:W
           input wire[2: 0] iLSB_Len,
           input wire[`MEM_ADD_W - 1: 0] iLSB_Add,
           input wire[`REG_DAT_W - 1: 0] iLSB_Dat,
           output reg oLSB_En,
           output wire[`REG_DAT_W - 1: 0] oLSB_Dat,

           output wire oMC_En,
           output wire oMC_Rw,           // 0:R, 1:W
           output wire[`MEM_ADD_W - 1: 0] oMC_Add,
           output reg[`MEM_DAT_W - 1: 0] oMC_Dat,
           input wire iMC_En,
           input wire[`MEM_DAT_W - 1: 0] iMC_Dat
       );

reg[2: 0] cnt, len;
reg operating, rw;
reg[`MEM_ADD_W - 1: 0] addr;
reg[`REG_DAT_W - 1: 0] dat;

assign oMC_En = operating;
assign oMC_Rw = rw;
assign oMC_Add = addr;

assign oLSB_Dat = dat;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0; len <= 0;
        operating <= 0; rw <= 0;
        addr <= 0; dat <= 0;
        oLSB_En <= 0;
        oMC_Dat <= 0;
    end
    else if (en) begin
        operating <= 0;
        oLSB_En <= 0;

        if (iLSB_En) begin
            cnt <= 1;
            addr <= iLSB_Add;
            operating <= 1;
            rw <= iLSB_Rw;
            dat <= iLSB_Rw ? iLSB_Dat : 0;
        end
        else if (cnt != 0) begin
            // TODO 优先级高于 IC 的 DC 可以连续读写 MEM 而不用等 MC 返回完成信号
            if (iMC_En) begin
                operating <= 1;
                cnt <= cnt + 1;
                addr <= addr + 1;
                if (rw) begin   // Write
                    case (cnt)
                        1: dat[7: 0] <= iMC_Dat;
                        2: dat[15: 8] <= iMC_Dat;
                        3: dat[23: 16] <= iMC_Dat;
                        4: dat[31: 24] <= iMC_Dat;
                        default: ;
                    endcase
                end
                else begin      // Read
                    case (cnt)
                        1: oMC_Dat <= dat[7: 0];
                        2: oMC_Dat <= dat[15: 8];
                        3: oMC_Dat <= dat[23: 16];
                        4: oMC_Dat <= dat[31: 24];
                        default: ;
                    endcase
                end
                if (cnt == len) begin    // Finish
                    operating <= 0;
                    cnt <= 0;
                    oLSB_En <= 1;
                end
            end
        end
    end
end

endmodule
