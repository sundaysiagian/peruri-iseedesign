// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_config_registers(input wire clk,rst_n,wr,lock_request,busy,
 input wire [31:0] data, output reg locked,valid,fault,
 output reg [4:0] max_v,max_dv, output reg [6:0] max_w,max_dw);
always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin locked<=0; valid<=0; fault<=0; max_v<=0;max_w<=0;max_dv<=0;max_dw<=0;end
 else if (wr) begin
  if (locked || busy || lock_request || data[31:28]!=0 || data[27:20]!=8'd1 || data[9:4]>6'd16 || data[19:14]>6'd32)
   begin fault<=1; valid<=0; end
  else begin max_v<={1'b0,data[3:0]}; max_w<={1'b0,data[9:4]}; max_dv<={1'b0,data[13:10]};max_dw<={1'b0,data[19:14]};valid<=1;end
 end else if (lock_request) begin if(valid && !busy && !fault) locked<=1;else begin fault<=1;valid<=0;end end
end
endmodule
`default_nettype wire
