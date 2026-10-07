// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_wrapper_tb;
reg clk=0;always #10 clk=~clk;
reg [1:0] key;reg [3:0] sw;wire [7:0] led;
reg [31:0] error_count=0,checks=0,i;
igor_de10_nano_wrapper dut(clk,key,sw,led);
task check;input [255:0] n;input c;
begin checks=checks+1;if(c!==1'b1)begin error_count=error_count+1;$display("FAIL time=%0t case=%0s expected=1 actual=%b",$time,n,c);end end endtask
task reset;begin key=2'b10;repeat(5)@(negedge clk);key=2'b11;repeat(26000)@(negedge clk);end endtask
initial begin
 $dumpfile("waveform/igor_wrapper.vcd");$dumpvars(1,igor_wrapper_tb);
 sw=0;reset;check("wrapper normal",led[0] && led[3]);
 key[1]=0;#1;check("wrapper immediate key stop",!led[0]);repeat(5)@(negedge clk);key[1]=1;repeat(5)@(negedge clk);
 check("wrapper no resume after estop",!led[0]);
 sw=1;reset;check("wrapper blocked map",!led[0] && led[3]);
 sw=2;reset;check("wrapper unknown map",!led[0] && led[3]);
 sw=3;reset;check("wrapper partial map",!led[0] && dut.core.map_fault);
 sw=4;reset;check("wrapper not ready",!led[0]);
 sw=8;reset;check("wrapper protective",!led[0]);
 $display("WRAPPER CHECKS=%0d ERRORS=%0d",checks,error_count);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED");$finish;
end
initial begin #20000000;$display("TEST FAILED watchdog");$finish;end
endmodule
`default_nettype wire
