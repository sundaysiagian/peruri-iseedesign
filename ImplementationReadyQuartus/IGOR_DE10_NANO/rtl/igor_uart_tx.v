// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_uart_tx #(parameter [15:0] CLKS_PER_BIT=16'd434)(input wire clk,rst_n,send,input wire [7:0] data,output wire tx,output reg busy);
reg [9:0] shift;reg [15:0] count;reg [3:0] bit_index;
assign tx=busy ? shift[0] : 1'b1;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n)begin shift<=10'h3ff;count<=0;bit_index<=0;busy<=0;end
 else if(!busy)begin if(send)begin shift<={1'b1,data,1'b0};busy<=1;count<=CLKS_PER_BIT-1'b1;bit_index<=0;end end
 else if(count!=0)count<=count-1'b1;
 else begin count<=CLKS_PER_BIT-1'b1;shift<={1'b1,shift[9:1]};if(bit_index==9)busy<=0;else bit_index<=bit_index+1'b1;end
end
endmodule
`default_nettype wire
