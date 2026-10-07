// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_costmap_bank(input wire clk,wr_en, input wire [14:0] wr_addr,
 input wire [7:0] wr_data, input wire [14:0] rd_addr, output reg [7:0] rd_data);
(* ramstyle = "M10K" *) reg [7:0] memory [0:32767];
always @(posedge clk) begin
 if(wr_en) memory[wr_addr]<=wr_data;
 rd_data<=memory[rd_addr];
end
endmodule
`default_nettype wire
