// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_costmap_manager #(parameter [31:0] FRESH_CYCLES=32'd1000000)(
 input wire clk,rst_n,begin_frame,write_byte,commit_frame,busy,
 input wire [31:0] frame_sequence, input wire [14:0] frame_addr,
 input wire [7:0] frame_data,
 output reg active_bank, valid, fault, output wire fresh,
 output wire ram_wr, output wire [14:0] ram_addr, output wire [7:0] ram_data,
 output reg [31:0] committed_sequence,age);
reg loading; reg [14:0] count; reg [31:0] pending_sequence;
wire conflict=(begin_frame && (write_byte || commit_frame)) || (write_byte && commit_frame);
assign ram_wr=write_byte && loading && !fault && !conflict && count<15'd16384 && frame_addr==count;
assign ram_addr={~active_bank,frame_addr[13:0]}; assign ram_data=frame_data;
assign fresh=valid && age<FRESH_CYCLES;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin active_bank<=0;valid<=0;fault<=0;loading<=0;count<=0;pending_sequence<=0;committed_sequence<=0;age<=32'hffffffff;end
 else begin
  if(age!=32'hffffffff) age<=age+32'd1;
  if(conflict) begin fault<=1;loading<=0;end
  else if(begin_frame) begin
   if(loading || frame_sequence<=committed_sequence || fault) begin fault<=1;loading<=0;end
   else begin loading<=1;count<=0;pending_sequence<=frame_sequence;end
  end else if(write_byte) begin
   if(!ram_wr) begin fault<=1;loading<=0;end else count<=count+15'd1;
  end else if(commit_frame) begin
   if(!loading || count!=15'd16384 || busy || fault) begin fault<=1;loading<=0;end
   else begin active_bank<=~active_bank;valid<=1;loading<=0;committed_sequence<=pending_sequence;age<=0;end
  end
 end
end
endmodule
`default_nettype wire
