// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_uart_protocol #(parameter [15:0] CLKS_PER_BIT=16'd434)(
 input wire clk,rst_n,rx, output wire tx,output reg command_valid,
 output reg [7:0] opcode,output reg [31:0] payload,input wire [31:0] response_data,
 output reg protocol_fault);
wire rx_valid,rx_error;wire [7:0] rx_data;reg tx_send;reg [7:0] tx_data;wire tx_busy;
igor_uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) receiver(clk,rst_n,rx,rx_valid,rx_error,rx_data);
igor_uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter(clk,rst_n,tx_send,tx_data,tx,tx_busy);
function [7:0] crc8;input [7:0] prior,value;reg [7:0] c;reg [3:0] j;begin c=prior^value;for(j=0;j<8;j=j+1'b1)c=c[7] ? (c<<1)^8'h07 : c<<1;crc8=c;end endfunction
reg [3:0] pos;reg [7:0] crc,received_crc;reg [31:0] timer;reg [3:0] respond_delay;
reg [31:0] response_sample;
reg sending;reg [3:0] out_pos;reg [63:0] out_frame;reg [7:0] response_crc;
always @(*) begin
 response_crc=crc8(8'd0,8'h5a);response_crc=crc8(response_crc,opcode);
 response_crc=crc8(response_crc,response_sample[7:0]);response_crc=crc8(response_crc,response_sample[15:8]);
 response_crc=crc8(response_crc,response_sample[23:16]);response_crc=crc8(response_crc,response_sample[31:24]);
end
always @(posedge clk or negedge rst_n) begin
 if(!rst_n)begin response_sample<=0;command_valid<=0;opcode<=0;payload<=0;protocol_fault<=0;pos<=0;crc<=0;received_crc<=0;timer<=0;respond_delay<=0;sending<=0;out_pos<=0;out_frame<=0;tx_send<=0;tx_data<=0;end
 else begin
 command_valid<=0;tx_send<=0;
 if(pos!=0)begin if(timer>=32'd5000000)begin pos<=0;protocol_fault<=1;end else timer<=timer+1'b1;end
 if(rx_error)begin protocol_fault<=1;pos<=0;end
 if(rx_valid)begin
  timer<=0;
  if(sending || respond_delay!=0)begin protocol_fault<=1;pos<=0;end
  else case(pos)
  0:if(rx_data==8'ha5)begin crc<=crc8(0,rx_data);pos<=1;end
  1:begin opcode<=rx_data;crc<=crc8(crc,rx_data);pos<=2;end
  2,3,4,5:begin payload[(pos-2)*8 +:8]<=rx_data;crc<=crc8(crc,rx_data);pos<=pos+1'b1;end
  6:begin received_crc<=rx_data;pos<=7;end
  7:begin pos<=0;if(rx_data==8'h5a && received_crc==crc && !protocol_fault)begin command_valid<=1;respond_delay<=4;end else protocol_fault<=1;end
  default:begin pos<=0;protocol_fault<=1;end
  endcase
 end
 if(respond_delay!=0)begin
  respond_delay<=respond_delay-1'b1;
  // Snapshot before CRC to separate core selection from serial framing timing.
  if(respond_delay==2)response_sample<=response_data;
  if(respond_delay==1)begin out_frame<={8'ha5,response_crc,response_sample,opcode,8'h5a};out_pos<=0;sending<=1;end
 end
 if(sending && !tx_busy && !tx_send)begin tx_data<=out_frame[out_pos*8 +:8];tx_send<=1;if(out_pos==7)sending<=0;else out_pos<=out_pos+1'b1;end
 end
end
endmodule
`default_nettype wire
