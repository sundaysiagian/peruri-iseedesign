`timescale 1ns/1ps
module tb_uart;
reg clk=0;always #10 clk=~clk;
reg rst_n=0,rx=1;
wire tx,command_valid,protocol_fault;
wire [7:0] opcode;
wire [31:0] payload;
reg [31:0] response_data=32'h12345678;
igor_uart_protocol #(.CLKS_PER_BIT(8)) core(clk,rst_n,rx,tx,command_valid,opcode,payload,response_data,protocol_fault);
reg [31:0] accepted=0;
always @(posedge clk) if(!rst_n) accepted<=0;else if(command_valid)accepted<=accepted+1;
endmodule
