`include "header.vh" 
// Register File Module
module regfile(input wire clk,
               input wire rst,
               input wire en,

               input wire iIS_En,
               input wire[`REG_ADD_W - 1: 0] iIS_Rs1,
               input wire[`REG_ADD_W - 1: 0] iIS_Rs2,
               input wire[`REG_ADD_W - 1: 0] iIS_Rd,
               input wire[`INS_OP_W - 1 : 0] iIS_Op,
               input wire[`REG_DAT_W - 1: 0] iIS_Imm,
               input wire[`REG_DAT_W - 1: 0] iIS_Pc,
               input wire iIS_Ils,

               input wire[`ROB_ADD_W - 1: 0] iROB_Qn,
               input wire iROB_En,
               input wire[`REG_ADD_W - 1: 0] iROB_Rd,
               input wire[`FIFO_ADD_W - 1: 0] iROB_Qd,
               input wire[`REG_DAT_W - 1: 0] iROB_Vd,
               output reg oROB_En,
               output reg[`ROB_ADD_W - 1: 0] oROB_Qs1,
               output reg[`ROB_ADD_W - 1: 0] oROB_Qs2,
               output reg[`REG_DAT_W - 1: 0] oROB_Vs1,
               output reg[`REG_DAT_W - 1: 0] oROB_Vs2,
               output reg[`ROB_ADD_W - 1: 0] oROB_Qd,
               // Passing by
               output reg[`INS_OP_W - 1 : 0] oROB_Op,
               output reg[`REG_DAT_W - 1: 0] oROB_Pc,
               output reg[`REG_DAT_W - 1: 0] oROB_Imm,
               output reg oROB_Ils,

               // Misprediction
               input wire iROB_Mp
              );
reg[`REG_DAT_W - 1: 0] v[`REG_S - 1: 0];
reg[`ROB_ADD_W - 1: 0] q[`REG_S - 1: 0];

// todo Debug
wire[`REG_DAT_W - 1: 0] regA0; assign regA0 = v[10];

// wire[`FIFO_ADD_W-1:0] qS0 = q[8];

integer i;
always@(posedge clk) begin
    if (rst || iROB_Mp) begin
        for (i = 0; i < `REG_S; i = i + 1) begin
            if (rst) v[i] <= 0;
            q[i] <= 0;
        end
        oROB_En <= 0;
        oROB_Qs1 <= 0; oROB_Qs2 <= 0;
        oROB_Vs1 <= 0; oROB_Vs2 <= 0;
        oROB_Qd <= 0;

        oROB_Op <= 0; oROB_Pc <= 0; oROB_Imm <= 0; oROB_Ils <= 0;
    end
    else if (en) begin
        oROB_En <= 0;
        oROB_Op <= 0; oROB_Pc <= 0; oROB_Imm <= 0; oROB_Ils <= 0;

        if (iIS_En) begin
            oROB_Op <= iIS_Op;
            oROB_Pc <= iIS_Pc;
            oROB_Imm <= iIS_Imm;
            oROB_Ils <= iIS_Ils;

            oROB_Vs1 <= v[iIS_Rs1]; oROB_Vs2 <= v[iIS_Rs2];

            oROB_En <= 1;
            // If rs == rd
            // send old q[rs] and set q[rd] qn
            oROB_Qs1 <= q[iIS_Rs1]; oROB_Qs2 <= q[iIS_Rs2];
            oROB_Qd <= iROB_Qn;
            q[iIS_Rd] <= iROB_Qn;
        end

        if (iROB_En) begin
            v[iROB_Rd] <= iROB_Vd;
            if(q[iROB_Rd] == iROB_Qd) q[iROB_Rd] <= 0;
            // oROB_Vs is logic circuit,
            // so when commit_rd == new_ins_rs, output_vs = input_vd
        end
    end

    q[0] <= 0;
    v[0] <= 0;
end

endmodule
