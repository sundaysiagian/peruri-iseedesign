// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_neural_core(input wire clk,rst_n,load_input,start,
 input wire [4:0] input_index,input wire signed [15:0] input_value,
 input wire [1:0] output_index,output wire signed [15:0] output_value,
 output reg busy,done,fault,output reg [31:0] latency_cycles);
reg signed [15:0] inputs[0:23];reg signed [15:0] h1[0:63],h2[0:63],outputs[0:3];
reg [23:0] loaded;reg [3:0] state;reg [1:0] layer;reg [6:0] neuron,k;
reg signed [39:0] accumulator;reg signed [15:0] operand;
reg [12:0] address;wire signed [15:0] weight;
igor_neural_rom weights(clk,address,weight);
wire signed [31:0] product=operand*weight;
wire signed [39:0] sum=accumulator+{{8{product[31]}},product};
// Arithmetic floor to Q8.8, then output hard clipping. Matches all supplied vectors.
wire signed [31:0] scaled=accumulator[39:8];
wire signed [15:0] nonlinear=scaled>32'sd256 ? 16'sd256 :
 (scaled < -32'sd256 ? -16'sd256 : scaled[15:0]);
assign output_value=done && !fault ? outputs[output_index] : 16'sd0;
wire [6:0] input_count=layer==0 ? 7'd24:7'd64;
wire [6:0] output_count=layer==2 ? 7'd4:7'd64;
wire [12:0] base=layer==0 ? 13'd0:(layer==1 ? 13'd1600:13'd5760);
wire [12:0] bias_base=layer==0 ? 13'd1536:(layer==1 ? 13'd5696:13'd6016);
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin loaded<=0;state<=0;layer<=0;neuron<=0;k<=0;accumulator<=0;operand<=0;address<=0;busy<=0;done<=0;fault<=0;latency_cycles<=0;end
 else begin
 if(load_input)begin
  if(busy || input_index>=24)fault<=1;
  else begin inputs[input_index]<=input_value;loaded[input_index]<=1;done<=0;end
 end
 if(busy)latency_cycles<=latency_cycles+1'b1;
 case(state)
 0:if(start)begin if(loaded==24'hffffff && !fault && !load_input)begin busy<=1;done<=0;latency_cycles<=0;layer<=0;neuron<=0;state<=1;end else fault<=1;end
 1:begin address<=bias_base+neuron;state<=2;end
 2:state<=3;
 3:begin accumulator<={{16{weight[15]}},weight,8'd0};k<=0;state<=4;end
 4:begin address<=base+neuron*input_count+k;operand<=layer==0 ? inputs[k]:(layer==1 ? h1[k]:h2[k]);state<=5;end
 5:state<=6;
 6:begin accumulator<=sum;if(k==input_count-1'b1)state<=7;else begin k<=k+1'b1;state<=4;end end
 7:begin
  if(layer==2)outputs[neuron[1:0]]<=nonlinear;
  else if(layer==0)h1[neuron]<=scaled<0 ? 16'sd0:(scaled>32767 ? 16'sd32767:scaled[15:0]);
  else h2[neuron]<=scaled<0 ? 16'sd0:(scaled>32767 ? 16'sd32767:scaled[15:0]);
  if(layer!=2 && scaled>32767)fault<=1;
  if(neuron==output_count-1'b1)begin
   if(layer==2)begin busy<=0;done<=1;state<=0;loaded<=0;end
   else begin layer<=layer+1'b1;neuron<=0;state<=1;end
  end else begin neuron<=neuron+1'b1;state<=1;end
 end
 default:begin busy<=0;done<=0;fault<=1;state<=0;end
 endcase
 if(start && busy)fault<=1;
 end
end
endmodule
`default_nettype wire
