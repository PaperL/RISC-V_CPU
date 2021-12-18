`include "header.vh" 
// Reservation Station Module

/* "findEmpty" and "findExe" will cause a WRONG warning with linter "Verilator":
 * "Signal unoptimizable: Feedback to clock or circular logic: 'rs.findEmpty'"
 * See "https://github.com/verilator/verilator/issues/63"
 *
 * Bug Example:
 * module transmit(output out, input in);
 *   wire [1:0] jumper;
 *   assign jumper[1] = in;
 *   assign jumper[0] = jumper[1];
 *   assign out = jumper[0];
 * endmodule
 */
module rs (
           input wire clk,
           input wire rst,
           input wire en,

           input wire iROB_En,
           input wire[`INS_OP_W - 1: 0] iROB_Op,
           input wire[`REG_DAT_W - 1: 0] iROB_Pc,
           input wire[`REG_DAT_W - 1: 0] iROB_Imm,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qs1,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qs2,
           input wire[`REG_DAT_W - 1: 0] iROB_Vs1,
           input wire[`REG_DAT_W - 1: 0] iROB_Vs2,
           input wire[`ROB_ADD_W - 1: 0] iROB_Qd,

           output reg oEX_En,
           output wire[`INS_OP_W - 1: 0] oEX_Op,
           output wire[`REG_DAT_W - 1: 0] oEX_Pc,
           output wire[`REG_DAT_W - 1: 0] oEX_Imm,
           output wire[`REG_DAT_W - 1: 0] oEX_Vs1,
           output wire[`REG_DAT_W - 1: 0] oEX_Vs2,
           output wire[`ROB_ADD_W - 1: 0] oEX_Qd,

           input wire iEX_En,
           input wire[`ROB_ADD_W - 1: 0] iEX_Qd,
           input wire[`REG_DAT_W - 1: 0] iEX_Vd,

           input wire iLSB_En,
           input wire[`ROB_ADD_W - 1: 0] iLSB_Qd,
           input wire[`REG_DAT_W - 1: 0] iLSB_Vd
       );

// * Inner Data
reg[`REG_DAT_W - 1: 0] vs1[`RS_S - 1: 0], vs2[`RS_S - 1: 0];
reg[`ROB_ADD_W - 1: 0] qs1[`RS_S - 1: 0], qs2[`RS_S - 1: 0];
reg[`ROB_ADD_W - 1: 0] qd[`RS_S - 1: 0];
reg[`INS_OP_W - 1: 0] op[`RS_S - 1: 0];
reg[`REG_DAT_W - 1: 0] pc[`RS_S - 1: 0];
reg[`REG_DAT_W - 1: 0] imm[`RS_S - 1: 0];
wire exe[`RS_S - 1: 0];  // Executable
reg empty[`RS_S - 1: 0];  // Enabled

// * Fine first empty/executable entry
wire[`RS_ADD_W - 1: 0] findEmpty[`RS_S: 0];
wire[`RS_ADD_W - 1: 0] emptyAdd;
assign findEmpty[`RS_S] = 0;
assign emptyAdd = findEmpty[0];
wire[`RS_ADD_W - 1: 0] findExe[`RS_S: 0];
wire[`RS_ADD_W - 1: 0] exeAdd;
assign findExe[`RS_S] = 0;
assign exeAdd = findExe[0];
wire exe0; assign exe0 = exe[0];

genvar j;
generate
    for (j = 0; j < `RS_S; j = j + 1) begin
        assign exe[j] = (!empty[j]) && (qs1[j] == 5'b0) && (qs2[j] == 5'b0);
    end
    for (j = 0; j < `RS_S; j = j + 1) begin
        assign findEmpty[j] = empty[j] ? j : findEmpty[j + 1];  // RS 大小与 ROB 相同，故不可能出现 ROB 未满而 RS 满
        assign findExe[j] = exe[j] ? j : findExe[j + 1];
    end
    endgenerate

        // * Output to Module EX
        assign oEX_Op = op[exeAdd];
assign oEX_Pc = pc[exeAdd];
assign oEX_Imm = imm[exeAdd];
assign oEX_Vs1 = vs1[exeAdd]; assign oEX_Vs2 = vs2[exeAdd];
assign oEX_Qd = qd[exeAdd];

integer i, k;
always @(posedge clk) begin
    if (rst) begin
        oEX_En <= 0;
        for (i = 0; i < `RS_S; i = i + 1) begin
            vs1[i] <= 0; vs2[i] <= 0;
            qs1[i] <= 0; qs2[i] <= 0; qd[i] <= 0;
            op[i] <= 0; pc[i] <= 0; imm[i] <= 0;
            empty[i] <= 1;
        end
    end
    else if (en) begin
        oEX_En <= 0;

        if (iROB_En) begin
            empty[emptyAdd] <= 0;
            vs1[emptyAdd] <= iROB_Vs1; vs2[emptyAdd] <= iROB_Vs2;
            qs1[emptyAdd] <= iROB_Qs1; qs2[emptyAdd] <= iROB_Qs2;
            qd[emptyAdd] <= iROB_Qd;
            op[emptyAdd] <= iROB_Op;
            pc[emptyAdd] <= iROB_Pc;
            imm[emptyAdd] <= iROB_Imm;
        end

        if ((exeAdd != 0) || (exe0 == 1)) begin
            // * 存储数据下标为 0..31, 但当无可执行条目时 exeAdd == 0
            // * 所以 exe[0] 需要特判
            oEX_En <= 1;
            empty[exeAdd] <= 1;
        end

        if (iEX_En) begin
            for (k = 0; k < `RS_S; k = k + 1) begin
                if (iEX_Qd == qs1[k]) begin
                    vs1[k] <= iEX_Vd; qs1[k] <= 0;
                end
                if (iEX_Qd == qs2[k]) begin
                    vs2[k] <= iEX_Vd; qs2[k] <= 0;
                end
            end
        end

        if (iLSB_En) begin
            for (k = 0; k < `RS_S; k = k + 1) begin
                if (iLSB_Qd == qs1[k]) begin
                    vs1[k] <= iLSB_Vd; qs1[k] <= 0;
                end
                if (iLSB_Qd == qs2[k]) begin
                    vs2[k] <= iLSB_Vd; qs2[k] <= 0;
                end
            end
        end
    end
end

endmodule
