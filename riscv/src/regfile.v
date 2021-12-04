`include "header.vh"

module regfile(input wire clk,
               input wire rst,                    // reset
               input wire rdy,                    // ready
               input wire rw,                     // read/write
               input wire[`REG_ADD_W - 1: 0] id,     // visit-id
               output wire[`REG_DAT_W - 1: 0] val); // read-result
reg[`REG_DAT_W - 1: 0] register[`REG_S - 1: 0];

endmodule
