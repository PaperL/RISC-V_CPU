`include "header.vh"
// Register File Module
module regfile(input wire clk,
               input wire rst,
               input wire en,

               input wire iIS_En,
               input wire[`REG_ADD_W - 1: 0] iIS_Rs1,
               input wire[`REG_ADD_W - 1: 0] iIS_Rs2,
               input wire iIS_EnRd,
               input wire[`REG_ADD_W - 1: 0] iIS_Rd,

               input wire[`REG_ADD_W - 1: 0] iROB_Qn,
               input wire iROB_En,
               input wire[`REG_ADD_W - 1: 0] iROB_Rd,
               input wire[`REG_DAT_W - 1: 0] iROB_Vd,
               output reg oROB_En,
               output reg[`REG_ADD_W - 1: 0] oROB_Qs1,
               output reg[`REG_ADD_W - 1: 0] oROB_Qs2,
               output wire[`REG_DAT_W - 1: 0] oROB_Vs1,
               output wire[`REG_DAT_W - 1: 0] oROB_Vs2
              );
reg[`REG_DAT_W - 1: 0] v[`REG_S - 1: 0];
reg[`REG_ADD_W - 1: 0] q[`REG_S - 1: 0];

assign oROB_Vs1 = v[iIS_Rs1];
assign oROB_Vs2 = v[iIS_Rs2];

integer i;
always@(posedge clk) begin
    if (rst) begin
        for (i = 0;i < `REG_S;i = i + 1) begin
            v[i] <= 0;
            q[i] <= 0;
        end
    end
    else if (en) begin
        oROB_En <= 0;

        if (iIS_En) begin
            oROB_En <= 1;
            // If rs == rd
            // send old q[rs] and set q[rd] qn
            oROB_Qs1 <= q[iIS_Rs1];
            oROB_Qs2 <= q[iIS_Rs2];
            if (iIS_EnRd) q[iIS_Rd] <= iROB_Qn;
        end

        if (iROB_En) begin
            v[iROB_Rd] = iROB_Vd;
            // oROB_Vs is logic circuit,
            // so when commit_rd == new_ins_rs, output_vs = input_vd
        end
    end
end

endmodule
