// RISCV32I CPU top module
`include "header.vh"
module cpu(
           input wire clk,                                                                 // System Clock signal
           input wire rst,                                                                 // Reset signal
           input wire en,                                                                  // Enabled signal, pause cpu when low

           input wire[7 : 0] mem_din,                                                      // data input bus
           output wire[7 : 0] mem_dout,                                                   // data output bus
           output wire[31 : 0] mem_a,                                                      // address bus (only 17:0 is used)
           output wire mem_wr,                                                             // write/read signal (1 for write)

           input wire io_buffer_full,                                                      // 1 if uart buffer is full

           output wire[31 : 0] dbgreg_dout  // cpu register output (debugging demo)
       );

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when en is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// RAM
wire [`MEM_DAT_W - 1: 0] RAM_MC_Dat;
// MC
wire MC_IC_En; wire[`MEM_DAT_W - 1 : 0] MC_IC_Dat;
wire MC_DC_En; wire[`MEM_DAT_W - 1 : 0] MC_DC_Dat;
wire MC_RAM_Rw;
wire[16: 0]MC_RAM_Add; wire [`MEM_DAT_W - 1: 0] MC_RAM_Dat;
// IC
wire IC_IF_En; wire[`INS_DAT_W - 1: 0] IC_IF_Ins;
wire IC_MC_En; wire[`MEM_ADD_W - 1: 0] IC_MC_Add;
wire IC_BP_En; wire[`INS_DAT_W - 1: 0] IC_BP_Ins;
// DC
wire DC_LSB_En; wire[`REG_DAT_W - 1: 0] DC_LSB_Dat;
wire DC_MC_En; wire DC_MC_Rw;
wire[`MEM_ADD_W - 1: 0] DC_MC_Add; wire[`MEM_DAT_W - 1: 0] DC_MC_Dat;
// BP
wire BP_IF_En;
wire[`REG_DAT_W - 1: 0] BP_IF_Pjt;
// IF
wire IF_IC_En; wire[`REG_DAT_W - 1: 0] IF_IC_Pc;
wire[`REG_DAT_W - 1: 0] IF_BP_Pc;
wire IF_IS_En; wire[`INS_DAT_W - 1: 0] IF_IS_Ins;
wire IF_IS_Bj; wire[`REG_DAT_W - 1: 0] IF_IS_Pc, IF_IS_Pjt;
// IS
wire IS_REG_En;
wire[`REG_ADD_W - 1: 0] IS_REG_Rs1, IS_REG_Rs2, IS_REG_Rd;
wire[`INS_OP_W - 1: 0] IS_REG_Op;
wire[`REG_DAT_W - 1: 0] IS_REG_Imm, IS_REG_Pc;
wire IS_ROB_En, IS_ROB_Is;
wire[`REG_ADD_W - 1: 0] IS_ROB_Rd;
wire IS_ROB_Bj;
wire[`REG_DAT_W - 1: 0] IS_ROB_Pc, IS_ROB_Pjt;
// REG
wire REG_ROB_En;
wire[`ROB_ADD_W - 1: 0] REG_ROB_Qs1, REG_ROB_Qs2;
wire[`REG_DAT_W - 1: 0] REG_ROB_Vs1, REG_ROB_Vs2;
wire[`ROB_ADD_W - 1: 0] REG_ROB_Qd;
wire[`INS_OP_W - 1: 0] REG_ROB_Op;
wire[`REG_DAT_W - 1: 0] REG_ROB_Pc, REG_ROB_Imm;
// RS
wire RS_EX_En;
wire[`INS_OP_W - 1: 0] RS_EX_Op;
wire[`REG_DAT_W - 1: 0] RS_EX_Pc, RS_EX_Imm, RS_EX_Vs1, RS_EX_Vs2;
wire[`ROB_ADD_W - 1: 0] RS_EX_Qd;
// EX
wire EX_RS_En;
wire[`ROB_ADD_W - 1: 0] EX_RS_Qd; wire[`REG_DAT_W - 1: 0] EX_RS_Vd;
wire EX_LSB_En;
wire[`ROB_ADD_W - 1: 0] EX_LSB_Qd; wire[`REG_DAT_W - 1: 0] EX_LSB_Vd;
wire EX_ROB_En;
wire[`ROB_ADD_W - 1: 0] EX_ROB_Qd;
wire[`REG_DAT_W - 1: 0] EX_ROB_Vd, EX_ROB_Jt;
// LSB
wire LSB_DC_En, LSB_DC_Rw;
wire[2: 0] LSB_DC_Len;
wire[`MEM_ADD_W - 1: 0] LSB_DC_Add; wire[`REG_DAT_W - 1: 0] LSB_DC_Dat;
wire LSB_RS_En;
wire[`ROB_ADD_W - 1: 0] LSB_RS_Qd; wire[`REG_DAT_W - 1: 0] LSB_RS_Vd;
wire LSB_ROB_En;
wire[`ROB_ADD_W - 1: 0] LSB_ROB_Qd; wire[`REG_DAT_W - 1: 0] LSB_ROB_Vd;
wire LSB_IF_Full;   // todo
// ROB
wire ROB_RS_En;
wire[`INS_OP_W - 1: 0] ROB_RS_Op;
wire[`REG_DAT_W - 1: 0] ROB_RS_Pc, ROB_RS_Imm;
wire[`ROB_ADD_W - 1: 0] ROB_RS_Qs1, ROB_RS_Qs2;
wire[`REG_DAT_W - 1: 0] ROB_RS_Vs1, ROB_RS_Vs2;
wire[`ROB_ADD_W - 1: 0] ROB_RS_Qd;
wire ROB_LSB_En;
wire[`INS_OP_W - 1: 0] ROB_LSB_Op;
wire[`REG_DAT_W - 1: 0] ROB_LSB_Imm;
wire[`ROB_ADD_W - 1: 0] ROB_LSB_Qs1, ROB_LSB_Qs2;
wire[`REG_DAT_W - 1: 0] ROB_LSB_Vs1, ROB_LSB_Vs2;
wire[`ROB_ADD_W - 1: 0] ROB_LSB_Qd;
wire ROB_LSB_Cs;
wire[`ROB_ADD_W - 1: 0] ROB_REG_Qn;
wire ROB_REG_En;
wire[`REG_ADD_W - 1: 0] ROB_REG_Rd;
wire[`REG_DAT_W - 1: 0] ROB_REG_Vd;
wire ROB_Mp;        // tod
wire[`REG_DAT_W - 1: 0] ROB_IF_Rpc;
wire ROB_IF_Full;

ram RAM( clk, en,
         MC_RAM_Rw, MC_RAM_Add, MC_RAM_Dat,
         RAM_MC_Dat
       );

mc MC( clk, rst, en,

       IC_MC_En, IC_MC_Add,
       MC_IC_En, MC_IC_Dat,

       DC_MC_En, DC_MC_Rw,
       DC_MC_Add, DC_MC_Dat,
       MC_DC_En, MC_DC_Dat,

       MC_RAM_Rw, MC_RAM_Add, MC_RAM_Dat,
       RAM_MC_Dat
     );


ic IC( clk, rst, en,

       IF_IC_En, IF_IC_Pc,
       IC_IF_En, IC_IF_Ins,

       IC_MC_En, IC_MC_Add,
       MC_IC_En, MC_IC_Dat,

       IC_BP_En, IC_BP_Ins
     );

dc DC( clk, rst, en,

       LSB_DC_En, LSB_DC_Rw,
       LSB_DC_Len, LSB_DC_Add, LSB_DC_Dat,
       DC_LSB_En, DC_LSB_Dat,

       DC_MC_En, DC_MC_Rw,
       DC_MC_Add, DC_MC_Dat,
       MC_DC_En, MC_DC_Dat
     );

bp BP( clk, rst, en,

       IC_BP_En, IC_BP_Ins,
       IF_BP_Pc,
       BP_IF_En, BP_IF_Pjt
     );

ifet IF( clk,
         rst,
         en & (!ROB_IF_Full) & (!LSB_IF_Full),

         IF_IC_En, IF_IC_Pc,
         IC_IF_En, IC_IF_Ins,

         IF_BP_Pc,
         BP_IF_En, BP_IF_Pjt,

         IF_IS_En, IF_IS_Ins,
         IF_IS_Bj, IF_IS_Pc, IF_IS_Pjt,

         ROB_Mp,
         ROB_IF_Rpc
       );

is IS( clk, rst | ROB_Mp, en,

       IF_IS_En, IF_IS_Ins,
       IF_IS_Bj, IF_IS_Pc, IF_IS_Pjt,

       IS_REG_En,
       IS_REG_Rs1, IS_REG_Rs2, IS_REG_Rd,
       IS_REG_Op, IS_REG_Imm, IS_REG_Pc,

       IS_ROB_En, IS_ROB_Is,
       IS_ROB_Rd,
       IS_ROB_Bj, IS_ROB_Pc, IS_ROB_Pjt
     );

regfile REG( clk, rst, en,

             IS_REG_En,
             IS_REG_Rs1, IS_REG_Rs1, IS_REG_Rd,
             IS_REG_Op, IS_REG_Imm, IS_REG_Pc,

             ROB_REG_Qn,
             ROB_REG_En, ROB_REG_Rd, ROB_REG_Vd,
             REG_ROB_En,
             REG_ROB_Qs1, REG_ROB_Qs2, REG_ROB_Vs1, REG_ROB_Vs2, REG_ROB_Qd,
             REG_ROB_Op, REG_ROB_Pc, REG_ROB_Imm,

             ROB_Mp
           );

rs RS(clk, rst | ROB_Mp, en,

      ROB_RS_En,
      ROB_RS_Op, ROB_RS_Pc, ROB_RS_Imm,
      ROB_RS_Qs1, ROB_RS_Qs2, ROB_RS_Vs1, ROB_RS_Vs2, ROB_RS_Qd,

      RS_EX_En,
      RS_EX_Op, RS_EX_Pc, RS_EX_Imm,
      RS_EX_Vs1, RS_EX_Vs2,
      RS_EX_Qd,

      EX_RS_En, EX_RS_Qd, EX_RS_Vd,

      LSB_RS_En, LSB_RS_Qd, LSB_RS_Vd
     );

ex EX(clk, rst | ROB_Mp, en,

      RS_EX_En,
      RS_EX_Op, RS_EX_Pc, RS_EX_Imm,
      RS_EX_Vs1, RS_EX_Vs2,
      RS_EX_Qd,

      EX_RS_En, EX_RS_Qd, EX_RS_Vd,

      EX_LSB_En, EX_LSB_Qd, EX_LSB_Vd,

      EX_ROB_En, EX_ROB_Qd, EX_ROB_Vd, EX_ROB_Jt
     );

lsb LSB(clk, rst, en,

        ROB_LSB_En,
        ROB_LSB_Op, ROB_LSB_Imm,
        ROB_LSB_Qs1, ROB_LSB_Qs2, ROB_LSB_Vs1, ROB_LSB_Vs2, ROB_LSB_Qd,

        LSB_DC_En, LSB_DC_Rw,
        LSB_DC_Len, LSB_DC_Add, LSB_DC_Dat,
        DC_LSB_En, DC_LSB_Dat,

        LSB_RS_En, LSB_RS_Qd, LSB_RS_Vd,

        LSB_ROB_En, LSB_ROB_Qd, LSB_ROB_Vd,

        EX_LSB_En, EX_LSB_Qd, EX_LSB_Vd,

        ROB_LSB_Cs,

        ROB_Mp,

        LSB_IF_Full
       );

rob ROB(clk, rst, en,

        IS_ROB_En,
        IS_ROB_Is, IS_ROB_Rd,
        IS_ROB_Bj, IS_ROB_Pc, IS_ROB_Pjt,

        REG_ROB_En,
        REG_ROB_Qs1, REG_ROB_Qs2, REG_ROB_Vs2, REG_ROB_Vs2, REG_ROB_Qd,
        REG_ROB_Op, REG_ROB_Pc, REG_ROB_Imm,

        ROB_RS_En,
        ROB_RS_Op, ROB_RS_Pc, ROB_RS_Imm,
        ROB_RS_Qs1, ROB_RS_Qs2, ROB_RS_Vs1, ROB_RS_Vs2, ROB_RS_Qd,

        ROB_LSB_En,
        ROB_LSB_Op, ROB_LSB_Imm,
        ROB_LSB_Qs1, ROB_LSB_Qs2, ROB_LSB_Vs1, ROB_LSB_Vs2, ROB_LSB_Qd,

        EX_ROB_En,
        EX_ROB_Qd, EX_ROB_Vd, EX_ROB_Jt,

        ROB_LSB_Cs,
        LSB_ROB_En, LSB_ROB_Qd, LSB_ROB_Vd,

        ROB_REG_Qn,
        ROB_REG_En, ROB_REG_Rd, ROB_REG_Vd,

        ROB_Mp,
        ROB_IF_Rpc,

        ROB_IF_Full
       );

// always @(posedge clk) begin
//     if (rst) begin

//     end
//     else if (!en) begin

//     end
//     else begin

//     end
// end

endmodule
