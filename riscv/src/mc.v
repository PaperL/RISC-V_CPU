`include "header.vh" 
// Memory Controller Module
module mc (input wire clk,
           input wire rst,
           input wire en,

           input wire iIC_En,
           input wire[`MEM_ADD_W - 1: 0] iIC_Pc,
           output reg oIC_En,
           output wire[`INS_DAT_W - 1: 0] oIC_Ins,

           input wire iDC_En,
           input wire iDC_Rw,                                           // 0:R, 1:W
           input wire[2: 0] iDC_Len,
           input wire[`MEM_ADD_W - 1: 0] iDC_Add,
           input wire[`REG_DAT_W - 1: 0] iDC_Dat,
           output reg oDC_En,
           output wire[`REG_DAT_W - 1: 0] oDC_Dat,

           output wire oRAM_Rw,                                         // 0:R, 1:W
           output wire[`MEM_ADD_W - 1: 0] oRAM_Add,
           output reg[`MEM_DAT_W - 1: 0] oRAM_Dat,
           input wire[`MEM_DAT_W - 1: 0] iRAM_Dat
          );

reg switch; // 0:IC, 1:DC
reg iW, dW; // IC Waiting, DC Waiting, Last Operation(0:IC, 1:DC)
reg dRw;    // 0:R, 1:W
reg[`MEM_ADD_W - 1: 0] iAdd, dAdd;
reg[`REG_DAT_W - 1: 0] ins, dat;
reg[2: 0] iCnt, dCnt;
reg[2: 0] dLen;

assign oRAM_Rw = switch ? dRw : 0;
assign oRAM_Add = switch ? dAdd : iAdd;
assign oIC_Ins = ins; assign oDC_Dat = dat;

always @(posedge clk) begin
    if (rst) begin
        switch <= 0;
        iW <= 0; dW <= 0;
        dRw <= 0;
        iAdd <= 0; dAdd <= 0;
        ins <= 0; dat <= 0;
        iCnt <= 0; dCnt <= 0;
        dLen <= 0;
        oIC_En <= 0; oDC_En <= 0;
        oRAM_Dat <= 0;
    end
    else if (en) begin
        // if (oRAM_Rw) $display("mem[%0h]%0h", oRAM_Add, oRAM_Dat);

        oIC_En <= 0;
        oDC_En <= 0;

        // * Determine the next clk operation
        if (switch) begin
            if (dW) begin
                dCnt <= dCnt + 1;
                dAdd <= dAdd + 1;
            end
        end
        else begin
            if (iW) begin
                iCnt <= iCnt + 1;
                iAdd <= iAdd + 1;
            end
        end

        // * Deal with the last clk operation result
        if (switch) begin   // Last Operation is of DC
            if (dRw) begin  // 0:R, 1:W
                case (dCnt)
                    0: oRAM_Dat <= dat[15: 8];
                    1: oRAM_Dat <= dat[23: 16];
                    2: oRAM_Dat <= dat[31: 24];
                endcase
            end
            else begin
                case (dCnt)
                    1: dat[7: 0] <= iRAM_Dat;
                    2: dat[15: 8] <= iRAM_Dat;
                    3: dat[23: 16] <= iRAM_Dat;
                    4: dat[31: 24] <= iRAM_Dat;
                endcase
            end
        end
        else begin  // Last Operation is of IC
            case (iCnt)
                1: ins[7: 0] <= iRAM_Dat;
                2: ins[15: 8] <= iRAM_Dat;
                3: ins[23: 16] <= iRAM_Dat;
                4: ins[31: 24] <= iRAM_Dat;
            endcase
        end

        // * Finish Task
        if (dW && dCnt == dLen && (dLen != 0 || switch)) begin
            dCnt <= 0;
            dW <= 0;
            oDC_En <= 1;
            switch <= 0;    // 防止额外写入数据
        end
        if (iW && iCnt == 4) begin // todo 这边条件可能可以不用 iW
            iCnt <= 0;
            iW <= 0;
            oIC_En <= 1;
            if (dW || iDC_En) switch <= 1;
        end

        // * Update Task
        if (iIC_En) begin
            if (!dW) switch <= 0;
            iW <= 1; iCnt <= 0;
            iAdd <= iIC_Pc;
        end

        if (iDC_En) begin
            if (!iW) switch <= 1;
            dW <= 1; dCnt <= 0;

            dRw <= iDC_Rw;
            dLen <= iDC_Len - {2'b0, iDC_Rw};
            dAdd <= iDC_Add;
            dat <= iDC_Dat;

            oRAM_Dat <= iDC_Dat[7: 0];
            // if (iDC_Rw) $display("mem[%0h] %0h", iDC_Add, iDC_Dat);
        end
    end
end

endmodule
