`include "header.vh" 
// Execution Module
module ex (
           input wire clk,
           input wire rst,
           input wire en
       );

always @(posedge clk) begin
    if (rst) begin
        // todo
    end
    else if (en) begin
        // todo
    end
end

endmodule
