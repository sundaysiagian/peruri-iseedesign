// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_de10_lite_top #(parameter [15:0] CLKS_PER_BIT=16'd434)(
 input wire MAX10_CLK1_50,input wire [1:0] KEY,input wire [3:0] SW,
 input wire UART_RX,output wire UART_TX,output wire [9:0] LEDR);
// Common accelerator remains identical at 50 MHz; only board and RAM family differ.
igor_uart_top #(.CLKS_PER_BIT(CLKS_PER_BIT)) system(
 MAX10_CLK1_50,KEY,SW,UART_RX,UART_TX,LEDR[7:0]);
reg [25:0] heartbeat;
reg rx_meta,rx_sync,rx_previous;
reg [22:0] activity;
always @(posedge MAX10_CLK1_50 or negedge KEY[0])begin
 if(!KEY[0])begin heartbeat<=0;rx_meta<=1;rx_sync<=1;rx_previous<=1;activity<=0;end
 else begin
  heartbeat<=heartbeat+1'b1;
  rx_meta<=UART_RX;rx_sync<=rx_meta;rx_previous<=rx_sync;
  if(rx_sync!=rx_previous)activity<=23'd5000000;
  else if(activity!=0)activity<=activity-1'b1;
 end
end
assign LEDR[8]=heartbeat[25];
assign LEDR[9]=activity!=0;
endmodule
`default_nettype wire
