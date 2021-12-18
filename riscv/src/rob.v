`include "header.vh" 
// ReOrdered Buffer Module
module rob (
           input wire clk,
           input wire rst,
           input wire en,

           // New Instruction
           input wire iIS_En,
           input wire iIS_Is,
           input wire[`REG_ADD_W - 1: 0]iIS_Rd,
           input wire iIS_Bj,
           input wire[`REG_DAT_W - 1: 0] iIS_Pc,
           input wire[`REG_DAT_W - 1: 0] iIS_Pjt,

           input wire iREG_En,
           input wire[`ROB_ADD_W - 1: 0] iREG_Qs1,
           input wire[`ROB_ADD_W - 1: 0] iREG_Qs2,
           input wire[`REG_DAT_W - 1: 0] iREG_Vs1,
           input wire[`REG_DAT_W - 1: 0] iREG_Vs2,
           input wire[`ROB_ADD_W - 1: 0] iREG_Qd,
           input wire[`INS_OP_W - 1: 0] iREG_Op,
           input wire[`REG_DAT_W - 1: 0] iREG_Pc,
           input wire[`REG_DAT_W - 1: 0] iREG_Imm,
           input wire iREG_Ils,


           output reg oRS_En,
           output wire[`INS_OP_W - 1: 0] oRS_Op,
           output wire[`REG_DAT_W - 1: 0] oRS_Pc,
           output wire[`REG_DAT_W - 1: 0] oRS_Imm,
           output wire[`ROB_ADD_W - 1: 0] oRS_Qs1,
           output wire[`ROB_ADD_W - 1: 0] oRS_Qs2,
           output wire[`REG_DAT_W - 1: 0] oRS_Vs1,
           output wire[`REG_DAT_W - 1: 0] oRS_Vs2,
           output wire[`ROB_ADD_W - 1: 0] oRS_Qd,

           output reg oLSB_En,
           output wire[`INS_OP_W - 1: 0] oLSB_Op,
           output wire[`REG_DAT_W - 1: 0] oLSB_Imm,
           output wire[`ROB_ADD_W - 1: 0] oLSB_Qs1,
           output wire[`ROB_ADD_W - 1: 0] oLSB_Qs2,
           output wire[`REG_DAT_W - 1: 0] oLSB_Vs1,
           output wire[`REG_DAT_W - 1: 0] oLSB_Vs2,
           output wire[`ROB_ADD_W - 1: 0] oLSB_Qd,

           // LOAD / Calculation Result
           input wire iEX_En,
           input wire[`ROB_ADD_W - 1: 0] iEX_Qd,
           input wire[`REG_DAT_W - 1: 0] iEX_Vd,
           input wire[`REG_DAT_W - 1: 0] iEX_Jt,

           // Commit
           output reg oLSB_Cs,                                   // Commit Store
           input wire iLSB_En,
           input wire[`ROB_ADD_W - 1: 0] iLSB_Qd,
           input wire[`REG_DAT_W - 1: 0] iLSB_Vd,

           output wire[`ROB_ADD_W - 1: 0] oREG_Qn,
           output reg oREG_En,
           output reg[`REG_ADD_W - 1: 0] oREG_Rd,
           output reg[`FIFO_ADD_W - 1: 0] oREG_Qd,
           output reg[`REG_DAT_W - 1: 0] oREG_Vd,

           // Branch / JUMP
           output wire oMp,                                                    // Misprediction
           output reg[`REG_DAT_W - 1: 0] oIF_Rpc,

           // Full
           output wire oIF_Full
       );

// Main Data
reg [`REG_DAT_W - 1: 0] vd[`FIFO_S - 1: 0];
reg is[`FIFO_S - 1: 0];
reg bj[`FIFO_S - 1: 0];
reg [`REG_DAT_W - 1: 0] jt[`FIFO_S - 1: 0];
reg [`REG_ADD_W - 1: 0] rd[`FIFO_S - 1: 0];
reg [`REG_DAT_W - 1: 0] pc[`FIFO_S - 1: 0];
reg [`REG_DAT_W - 1: 0] pjt[`FIFO_S - 1: 0];
reg rdy[`FIFO_S - 1: 0];

// Queue
reg full; wire empty;
reg[`FIFO_ADD_W - 1: 0] head, tail;
wire [`FIFO_ADD_W - 1: 0] nxtHead, nxtTail;

assign empty = (!full) && (head == tail);
assign nxtHead = ((head + 5'b1 != 5'b0) ? (head + 5'b1) : 5'b1);
assign nxtTail = ((tail + 5'b1 != 5'b0) ? (tail + 5'b1) : 5'b1);

// Local Information
reg mp; // Misprediction
wire[`REG_DAT_W - 1: 0] headJt;
assign headJt = jt[head];

// IO
assign oREG_Qn = tail;

reg[`ROB_ADD_W - 1: 0] oQs1, oQs2;
reg[`REG_DAT_W - 1: 0] oVs1, oVs2;
reg[`ROB_ADD_W - 1: 0] oQd;
reg[`INS_OP_W - 1: 0] oOp;
reg[`REG_DAT_W - 1: 0] oPc;
reg[`REG_DAT_W - 1: 0] oImm;

assign oRS_Op = oOp; assign oLSB_Op = oOp;
assign oRS_Pc = oPc;
assign oRS_Imm = oImm; assign oLSB_Imm = oImm;
assign oRS_Qs1 = oQs1; assign oLSB_Qs1 = oQs1;
assign oRS_Qs2 = oQs2; assign oLSB_Qs2 = oQs2;
assign oRS_Vs1 = oVs1; assign oLSB_Vs1 = oVs1;
assign oRS_Vs2 = oVs2; assign oLSB_Vs2 = oVs2;
assign oRS_Qd = oQd; assign oLSB_Qd = oQd;

assign oMp = mp;

assign oIF_Full = full;

//===================== ALWAYS =====================

integer i;
always @(posedge clk) begin
    if (rst || mp) begin    // ! Clear Self when Misprediction
        for (i = 0; i < `FIFO_S; i = i + 1) begin
            vd[i] <= 0; is[i] <= 0; bj[i] <= 0;
            jt[i] <= 0; rd[i] <= 0; pc[i] <= 0;
            pjt[i] <= 0; rdy[i] <= 0;
        end

        full <= 0;
        head <= 1; tail <= 1;

        mp <= 0;

        oQs1 <= 0; oQs2 <= 0;
        oVs1 <= 0; oVs2 <= 0;
        oQd <= 0; oOp <= 0; oPc <= 0; oImm <= 0;

        oRS_En <= 0;
        oLSB_En <= 0; oLSB_Cs <= 0;
        oREG_En <= 0;
        oREG_Rd <= 0; oREG_Qd <= 0; oREG_Vd <= 0;

        oIF_Rpc <= 0;
    end
    else if (en) begin
        mp <= 0;
        oRS_En <= 0;
        oLSB_En <= 0;
        oLSB_Cs <= 0;
        oREG_En <= 0;

        // Update LOAD or Arith Result
        if (iLSB_En) begin
            rdy[iLSB_Qd] <= 1;
            vd[iLSB_Qd] <= iLSB_Vd;
        end
        if (iEX_En) begin
            rdy[iEX_Qd] <= 1;
            vd[iEX_Qd] <= iEX_Vd;
            jt[iEX_Qd] <= iEX_Jt;
        end

        // New Instruction used current available Q
        if (iIS_En) begin
            vd[tail] <= 0;
            jt[tail] <= 0;
            rdy[tail] <= 0;

            rd[tail] <= iIS_Rd;
            is[tail] <= iIS_Is;
            bj[tail] <= iIS_Bj;
            pc[tail] <= iIS_Pc;
            pjt[tail] <= iIS_Pjt;

            tail <= nxtTail;    // * Push tail
            full <= (nxtTail == head) ? 1 : 0;
        end

        // Ready to commit first instruction
        if (!empty) begin
            if (is[head]) begin // Commit STORE
                // $display("%0h", pc[head]);
                // Nothing is needed for STORE to commit, so STORE needn't "rdy" signal
                oLSB_Cs <= 1;
                head <= nxtHead;    // * Pop front
                if (!iIS_En) full <= 0;
            end
            else if (rdy[head]) begin
                // $display("%0h", pc[head]);
                if (bj[head]) begin  // Commit BRANCH or JUMP
                    if (headJt != pjt[head]) begin  // ! Misprediction
                        mp <= 1;
                        oIF_Rpc <= headJt;
                    end
                end
                else begin  // Commit Arith Instruction
                    oREG_En <= 1;
                    oREG_Rd <= rd[head]; oREG_Qd <= head; oREG_Vd <= vd[head];
                    // $display("reg[%0h] %0h", rd[head], vd[head]);
                end

                head <= nxtHead;    // * Pop front
                if (!iIS_En) full <= 0;
            end
        end

        // Update instruction information from REG
        if (iREG_En) begin
            oRS_En <= ~iREG_Ils;
            oLSB_En <= iREG_Ils;

            oOp <= iREG_Op;
            oPc <= iREG_Pc;
            oImm <= iREG_Imm;

            oQs1 <= iREG_Qs1; oVs1 <= iREG_Vs1;
            oQs2 <= iREG_Qs2; oVs2 <= iREG_Vs2;

            if (iREG_Qs1 != 0) begin
                if (iEX_En && iEX_Qd == iREG_Qs1) begin
                    oQs1 <= 0;
                    oVs1 <= iEX_Vd;
                end
                else if (iLSB_En && iLSB_Qd == iREG_Qs1) begin
                    oQs1 <= 0;
                    oVs1 <= iLSB_Vd;
                end
                else if (rdy[iREG_Qs1]) begin
                    oQs1 <= 0;
                    oVs1 <= vd[iREG_Qs1];
                end
            end
            if (iREG_Qs2 != 0) begin
                if (iEX_En && iEX_Qd == iREG_Qs2) begin
                    oQs2 <= 0;
                    oVs2 <= iEX_Vd;
                end
                else if (iLSB_En && iLSB_Qd == iREG_Qs2) begin
                    oQs2 <= 0;
                    oVs2 <= iLSB_Vd;
                end
                else if (rdy[iREG_Qs2]) begin
                    oQs2 <= 0;
                    oVs2 <= vd[iREG_Qs2];
                end
            end

            oQd <= iREG_Qd;
        end
    end

    vd[0] <= 0;
    bj[0] <= 0; jt[0] <= 0;
    rd[0] <= 0; pc[0] <= 0; pjt[0] <= 0;
    rdy[0] <= 0;
end

endmodule
