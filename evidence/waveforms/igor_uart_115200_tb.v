`timescale 1ns/1ps
module igor_uart_115200_tb;
reg clk=0; always #10 clk=~clk;
reg [1:0] key=2'b10; reg [3:0] sw=0; reg rx=1;
wire tx; wire [7:0] led,rb;wire rv,re;
igor_uart_top dut(clk,key,sw,rx,tx,led);
igor_uart_rx #(.CLKS_PER_BIT(16'd434)) monitor(clk,key[0],tx,rv,re,rb);
reg [7:0] response[0:7];integer received=0,checks=0,error_count=0,k;
reg [7:0] crc;
always @(posedge clk) if(rv && received<8)begin response[received]=rb;received=received+1;end
function [7:0] crc8;input [7:0] a,b;reg [7:0] c;integer n;begin c=a^b;for(n=0;n<8;n=n+1)c=c[7]?(c<<1)^8'h07:c<<1;crc8=c;end endfunction
task sendbyte;input [7:0] b;integer i;begin
 @(negedge clk);rx=0;repeat(434)@(negedge clk);
 for(i=0;i<8;i=i+1)begin rx=b[i];repeat(434)@(negedge clk);end
 rx=1;repeat(434)@(negedge clk);
end endtask
task check;input good;begin checks=checks+1;if(good!==1'b1)error_count=error_count+1;end endtask
initial begin
 $dumpfile("igor_uart_115200.vcd");
 $dumpvars(0,rx,tx,rv,re,rb,received,checks,error_count,key);
 repeat(8)@(negedge clk);key=3;repeat(8)@(negedge clk);
 crc=crc8(0,8'ha5);crc=crc8(crc,8'd7);
 for(k=0;k<4;k=k+1)crc=crc8(crc,0);
 sendbyte(8'ha5);sendbyte(7);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(crc);sendbyte(8'h5a);
 wait(received==8);repeat(4)@(negedge clk);
 check(response[0]==8'h5a);check(response[1]==7);check(response[7]==8'ha5);check(re==0);
 crc=0;for(k=0;k<6;k=k+1)crc=crc8(crc,response[k]);check(response[6]==crc);
 $display("UART RELEASE BAUD CLKS_PER_BIT=434 CHECKS=%0d ERRORS=%0d RECEIVED=%0d",checks,error_count,received);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED");
 $finish;
end
initial begin #5000000;$display("TEST FAILED watchdog");$finish;end
endmodule
