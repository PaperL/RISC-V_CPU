`include "header.vh" 
// Load Store Buffer Module
module lsb (
           input wire clk,
           input wire rst,
           input wire en,

           // Get Instruction
           input wire iROB_En,
           input wire[`INS_OP_W - 1: 0] iROB_Op,
           input wire[`REG_DAT_W - 1: 0] iROB_Imm,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qs1,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qs2,
           input wire[`REG_DAT_W - 1: 0] iROB_Vs1,
           input wire[`REG_DAT_W - 1: 0] iROB_Vs2,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qd,

           // Visit Memory
           output reg oDC_En,
           output wire oDC_Rw,                                // 0:R, 1:W
           output reg[2: 0] oDC_Len,                          // 1:B; 2:H; 4:W
           output reg[`MEM_ADD_W - 1: 0] oDC_Add,
           output reg[`REG_DAT_W - 1: 0] oDC_Dat,
           input wire iDC_En,
           input wire[`REG_DAT_W - 1: 0] iDC_Dat,

           // Output LOAD Result
           output reg oRS_En,
           output wire[`ROB_ADD_W - 1: 0] oRS_Qd,
           output wire[`REG_DAT_W - 1: 0] oRS_Vd,

           output reg oROB_En,
           output wire[`ROB_ADD_W - 1: 0] oROB_Qd,
           output wire[`REG_DAT_W - 1: 0] oROB_Vd,

           // Update Calculation Result
           input wire iEX_En,
           input wire[`ROB_ADD_W - 1: 0] iEX_Qd,
           input wire[`REG_DAT_W - 1: 0] iEX_Vd,

           // Commit STORE
           input wire iROB_Cs,

           // ! Misprediction
           input wire iROB_Mp,

           input wire iIOB_Full,       // Stall when IO Buffer is Full
           output wire oIF_Full     // Stall IF when Full
       );

// Main Data
reg[`ROB_ADD_W - 1: 0] qs1[`FIFO_S - 1: 0], qs2[`FIFO_S - 1: 0];
reg[`REG_DAT_W - 1: 0] vs1[`FIFO_S - 1: 0], vs2[`FIFO_S - 1: 0];
reg[`ROB_ADD_W - 1: 0] qd[`FIFO_S - 1: 0];
reg[`INS_OP_W - 1: 0] op[`FIFO_S - 1: 0];
reg[`REG_DAT_W - 1: 0] imm[`FIFO_S - 1: 0];
wire ls[`FIFO_S - 1: 0];   // 0: LOAD; 1: STORE
wire exe[`FIFO_S - 1: 0];

// Queue
reg full; wire empty;
reg[`FIFO_ADD_W - 1: 0] head, tail;
wire [`FIFO_ADD_W - 1: 0] nxtHead, nxtTail, fullPtr1, fullPtr2;

assign empty = (!full) && (head == tail);
assign nxtHead = head + 5'b1;assign nxtTail = tail + 5'b1;
assign fullPtr1 = tail + 5'b11;
assign fullPtr2 = tail + 5'b10;
genvar j;
generate
    for (j = 0; j < `FIFO_S; j = j + 1) begin
        assign exe[j] = (qs1[j] == 5'b0) && (qs2[j] == 5'b0);
        assign ls[j] = ((op[j] == 5'b0110) ||
                        (op[j] == 5'b0111) ||
                        (op[j] == 5'b1000)) ? 1 : 0;
    end
    endgenerate

        // Output
        reg[`REG_DAT_W - 1: 0] oVd;
reg[`ROB_ADD_W - 1: 0] oQ;

// Local Information
reg wDC;
reg[`FIFO_ADD_W - 1: 0] ncs;    // Number of Committed STORE Instruction
// BUG 理论上或许 ncs 能够达到 32, 需要 6-bit 长

wire[`INS_OP_W - 1: 0] headOp;
wire headLs;
wire[`REG_DAT_W - 1: 0] headVs1, headVs2, headImm;
wire[`ROB_ADD_W - 1: 0] headQd;

assign headOp = op[head];
assign headLs = ls[head];
assign headVs1 = vs1[head]; assign headVs2 = vs2[head];
assign headImm = imm[head];
assign headQd = qd[head];

wire[`REG_DAT_W - 1: 0] vd;
assign vd = (headOp == 5'b0001) ?
       {{25{iDC_Dat[7]}}, iDC_Dat[6 : 0]}
       : ( (headOp == 5'b0010) ?
           {{17{iDC_Dat[5]}}, iDC_Dat[14 : 0]}
           : iDC_Dat
         );
// case (headOp)
//   5'b0001:                            // LB
//     oVd <= {{25{iDC_Dat[7]}}, iDC_Dat[6: 0]};
//   5'b0010:                            // LH
//     oVd <= {{17{iDC_Dat[5]}}, iDC_Dat[14: 0]};
//   5'b0011, 5'b0100, 5'b0101:          // LW, LBU, LHU
//     oVd <= iDC_Dat;
//   default: begin                      // STORE
//     oRS_En <= 0;
//     oROB_En <= 0;
//   end
// endcase
wire pushCond; assign pushCond = iROB_En;
wire popCond; assign popCond = wDC && iDC_En;


// IO Assign
assign oDC_Rw = headLs;

assign oRS_Qd = oQ;
assign oRS_Vd = oVd;
assign oROB_Qd = oQ;
assign oROB_Vd = oVd;

assign oIF_Full = full;

//===================== ALWAYS =====================

integer i;
always @(posedge clk) begin
    // if (iROB_Mp && head != tail) begin
    //     $display("ROB_LSB_Mp happen. Head:%0h,\tTail:%0h,\tncs:%d", head, tail, ncs);
    //     for (i = head; i != tail; i = i + 1) begin
    //         $display("[%d]\tls:%d,\texe:%d", i, ls[i], exe[i]);
    //     end
    // end
    if (iROB_Mp || rst) begin
        if (rst) begin
            for (i = 0; i < `FIFO_S; i = i + 1) begin
                qs1[i] <= 0; qs2[i] <= 0;
                vs1[i] <= 0; vs2[i] <= 0;
                qd[i] <= 0;
                op[i] <= 0; imm[i] <= 0;
            end
            head <= 0; tail <= 0;
            ncs <= 0;
            wDC <= 0;
        end
        else begin
            if (wDC == 0 || empty || headLs == 0) begin
                wDC <= 0;
                tail <= head + ncs;
            end
            else begin
                tail <= head + ncs + 1;
                if (popCond) begin
                    wDC <= 0;
                    head <= nxtHead;        // * Pop front
                end
            end
        end

        full <= 0;  // BUG 理论上可能出现清除后仍 full 的情况

        oVd <= 0; oQ <= 0;

        oDC_En <= 0;
        oDC_Len <= 0; oDC_Add <= 0; oDC_Dat <= 0;

        oRS_En <= 0;
        oROB_En <= 0;
    end
    else if (en) begin
        // Pop after Push. Because when only 1 empty space left,
        // pushing first leads to wrong "full/empty" flag.
        oDC_En <= 0;
        oDC_Len <= 0; oDC_Add <= 0; oDC_Dat <= 0;

        oRS_En <= 0;
        oROB_En <= 0;

        oVd <= 0; oQ <= 0;

        ncs <= ncs + {4'b0, iROB_Cs};

        if (iEX_En) begin   // Update
            for (i = 0; i < `FIFO_S; i = i + 1) begin
                if (iEX_Qd == qs1[i]) begin
                    vs1[i] <= iEX_Vd; qs1[i] <= 0;
                end
                if (iEX_Qd == qs2[i]) begin
                    vs2[i] <= iEX_Vd; qs2[i] <= 0;
                end
            end
        end

        if (pushCond) begin  // Push new LS Ins from ROB
            qs1[tail] <= iROB_Qs1; qs2[tail] <= iROB_Qs2;
            vs1[tail] <= iROB_Vs1; vs2[tail] <= iROB_Vs2;
            qd[tail] <= iROB_Qd;
            op[tail] <= iROB_Op;
            imm[tail] <= iROB_Imm;

            tail <= nxtTail;    // * Push tail
            // full <= (nxtTail == head) ? 1 : 0;
            full <= (nxtTail == head ||
                     fullPtr1 == head ||
                     fullPtr2 == head) ? 1 : 0;
        end

        if (popCond) begin   // LS finished, pop front and output load result
            wDC <= 0;
            if (headLs == 0) begin  // Load
                for (i = 0; i < `FIFO_S; i = i + 1) begin
                    if (headQd == qs1[i]) begin
                        vs1[i] <= vd; qs1[i] <= 0;
                    end
                    if (headQd == qs2[i]) begin
                        vs2[i] <= vd; qs2[i] <= 0;
                    end
                end

                oQ <= headQd;
                oRS_En <= 1;
                oROB_En <= 1;

                oVd <= vd;
            end                     // Store has no output

            head <= nxtHead;        // * Pop front
            if (!pushCond && !(nxtTail == head || fullPtr1 == head)) full <= 0;
        end

        // * Handle front LS;
        // oDC_Rw is assigned as headLs;
        oDC_Add <= headVs1 + headImm;
        oDC_Dat <= headVs2;
        if ((!empty) && (wDC == 0) && exe[head]) begin
            if (headLs == 0) begin   // LOAD
                wDC <= 1;
                oDC_En <= 1;
                case (headOp)
                    5'b0001, 5'b0100, 5'b0110:                                     // LB, LBU, SB
                        oDC_Len <= 1;
                    5'b0010, 5'b0101, 5'b0111:                                     // LH, LHU, SH
                        oDC_Len <= 2;
                    5'b0011, 5'b1000:                                              // LW, SW
                        oDC_Len <= 4;
                    default: ;                  // Unexpected OP
                endcase
            end
            else if ((!iIOB_Full) && ((ncs != 0) || iROB_Cs)) begin  // STORE
                ncs <= iROB_Cs ? ncs : (ncs - 1);
                wDC <= 1;
                oDC_En <= 1;
                case (headOp)
                    5'b0110: oDC_Len <= 1;  // SB
                    5'b0111: oDC_Len <= 2;  // SH
                    5'b1000: oDC_Len <= 4;  // SW
                    default: ;              // Unexpected OP
                endcase
            end
        end
    end
end

endmodule

    /*
     * 任意 SL 操作都需要等 DC 返回结果
     * Load 需要根据 mp 信号清除 wDC 标记（应该不会出现下一个指令的 wDC 标记导致获得上一条指令结果）
     * 不能清除 Store 的 wDC 标记
     * ncs 代表还有几个要提交
     */
