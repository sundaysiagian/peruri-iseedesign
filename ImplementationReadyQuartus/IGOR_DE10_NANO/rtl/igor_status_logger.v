// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_status_logger(input wire clk,rst_n,input wire [7:0] fault_code,
 output reg [31:0] event_count,output reg [7:0] last_fault);
reg [7:0] previous_fault;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin event_count<=0;last_fault<=0;previous_fault<=0;end
 else begin
  previous_fault<=fault_code;
  if(fault_code!=0 && fault_code!=previous_fault) begin last_fault<=fault_code;if(event_count!=32'hffffffff)event_count<=event_count+32'd1;end
 end
end
endmodule
`default_nettype wire
