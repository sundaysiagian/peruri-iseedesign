`timescale 1ns/1ps
module tb_neural;
reg clk=0; always #10 clk=~clk;
reg rst_n=0,load_input=0,start=0;
reg [4:0] input_index=0;
reg signed [15:0] input_value=0;
reg [1:0] output_index=0;
wire signed [15:0] output_value;
wire busy,done,fault;
wire [31:0] latency_cycles;
igor_neural_core core(clk,rst_n,load_input,start,input_index,input_value,output_index,output_value,busy,done,fault,latency_cycles);
endmodule
