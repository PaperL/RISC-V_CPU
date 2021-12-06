// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "header.vh"

module cpu(
           input wire clk,          // System Clock signal
           input wire rst,          // Reset signal
           input wire en,          // Enabled signal, pause cpu when low

           input wire [7: 0] mem_din,             // data input bus
           output wire [ 7: 0] mem_dout,         // data output bus
           output wire [31: 0] mem_a,          // address bus (only 17:0 is used)
           output wire mem_wr,          // write/read signal (1 for write)

           input wire io_buffer_full,         // 1 if uart buffer is full

           output wire [31: 0] dbgreg_dout  // cpu register output (debugging demo)
       );

// implementation goes here

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
wire MC_IC_En;
// wire MC_IC_Per;
wire[`MEM_DAT_W - 1 : 0] MC_IC_Dat;
wire MC_DC_En;
// wire MC_DC_Per;
wire[`MEM_DAT_W - 1 : 0] MC_DC_Dat;
wire MC_RAM_Rw;
wire[16: 0] MC_RAM_Add;
wire [`MEM_DAT_W - 1: 0] MC_RAM_Dat;
// IC
wire IC_MC_En;
wire[`MEM_ADD_W - 1: 0] IC_MC_Add;
wire IC_BP_En;
wire[`INS_DAT_W - 1: 0] IC_BP_Ins;
wire IC_IF_En;
wire[`INS_DAT_W - 1: 0] IC_IF_Ins;
// BP
wire BP_IF_En;
wire[`REG_DAT_W - 1: 0] BP_IF_Pcn;
// IF
wire IF_IC_En;
wire[`REG_DAT_W - 1: 0] IF_IC_Pc;
wire[`REG_DAT_W - 1: 0]IF_BP_Pc;
wire IF_IS_En;
wire[`INS_DAT_W - 1: 0] IF_IS_Ins;
// DC
wire DC_MC_En;
wire DC_MC_Rw;
wire[`MEM_ADD_W - 1 : 0] DC_MC_Add;
wire[`MEM_DAT_W - 1 : 0] DC_MC_Dat;

ram RAM(
        clk,
        en,
        MC_RAM_Rw,
        MC_RAM_Add,
        MC_RAM_Dat,
        RAM_MC_Dat
    );

mc MC(
       clk,
       rst,
       en,

       IC_MC_En,
       IC_MC_Add,
       MC_IC_En,
       MC_IC_Dat,

       DC_MC_En,
       DC_MC_Rw,
       DC_MC_Add,
       DC_MC_Dat,
       MC_DC_En,
       MC_DC_Dat,

       MC_RAM_Rw,
       MC_RAM_Add,
       MC_RAM_Dat,
       RAM_MC_Dat
   );


ic IC(
       clk,
       rst,
       en,

       IF_IC_En,
       IF_IC_Pc,
       IC_IF_En,
       IC_IF_Ins,

       IC_MC_En,
       IC_MC_Add,
       MC_IC_En,
       MC_IC_Dat,

       IC_BP_En,
       IC_BP_Ins
   );

bp BP(
       clk,
       rst,
       en,
       IC_BP_En,
       IC_BP_Ins,
       IF_BP_Pc,
       BP_IF_En,
       BP_IF_Pcn
   );

ifet IF(
         clk,
         rst,
         en,

         IF_IC_En,
         IF_IC_Pc,
         IC_IF_En,
         IC_IF_Ins,

         IF_BP_Pc,
         BP_IF_En,
         BP_IF_Pcn,
         
         IF_IS_En,
         IF_IS_Ins
     );




always @(posedge clk) begin
    if (rst) begin

    end
    else if (!en) begin

    end
    else begin

    end
end

endmodule
