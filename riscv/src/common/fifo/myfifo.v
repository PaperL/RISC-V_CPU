`include "header.vh" 
// Just a Example
// Used in ROB and LSB

module myfifo
       (
           input wire clk,
           input wire rst,
           input wire en,
           input wire i_en,
           input wire i_rw,     // 1: Read; 0: Write
           input wire [32 - 1: 0] i_WrDat,
           output wire [32 - 1: 0] o_RdDat,
           output wire o_full
       );

reg[32 - 1: 0] dat[`FIFO_S - 1: 0];
reg[`FIFO_ADD_W - 1: 0] head, tail; // 左闭右开
reg full, empty;
reg[32 - 1: 0] out;

assign o_RdDat = out;
assign o_full = full;

wire[`FIFO_ADD_W - 1: 0] head_nxt, tail_nxt;



integer i;
always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `FIFO_S; i = i + 1) dat[i] <= 0;
        head <= 1; tail <= 1;
        full <= 0; empty <= 1;
    end
    else if (en) begin
        if (i_en) begin
            if (i_rw) begin
                out <= dat[head];
                head <= head_nxt;
                empty <= (head_nxt == tail) ? 1 : 0;
            end
            else begin
                dat[tail] <= out;
                tail <= tail_nxt;
                full <= (tail_nxt == head) ? 1 : 0;
            end
        end
    end
end

endmodule