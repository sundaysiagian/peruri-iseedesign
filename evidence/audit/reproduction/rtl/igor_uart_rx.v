// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_uart_rx #(parameter [15:0] CLKS_PER_BIT=16'd434)(input wire clk,rst_n,rx,output reg valid,error,output reg [7:0] data);
reg meta,sync;reg [1:0] state;reg [15:0] count;reg [2:0] bit_index;reg [7:0] shift;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n)begin meta<=1;sync<=1;end else begin meta<=rx;sync<=meta;end
end
always @(posedge clk or negedge rst_n) begin
 if(!rst_n)begin state<=0;count<=0;bit_index<=0;shift<=0;data<=0;valid<=0;error<=0;end
 else begin valid<=0;error<=0;
 case(state)
 0:if(!sync)begin state<=1;count<=CLKS_PER_BIT/16'd2-16'd1;end
 1:if(count!=0)count<=count-1'b1;else if(!sync)begin count<=CLKS_PER_BIT-1'b1;bit_index<=0;state<=2;end else state<=0;
 2:if(count!=0)count<=count-1'b1;else begin shift[bit_index]<=sync;count<=CLKS_PER_BIT-1'b1;if(bit_index==7)state<=3;else bit_index<=bit_index+1'b1;end
 3:if(count!=0)count<=count-1'b1;else begin state<=0;if(sync)begin valid<=1;data<=shift;end else error<=1;end
 default:state<=0;
 endcase end
end
endmodule
`default_nettype wire
