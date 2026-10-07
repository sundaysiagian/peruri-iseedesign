// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_neural_tb;
reg clk=0;always #10 clk=~clk;
reg rst_n,load,start;reg [4:0] idx;reg signed [15:0] value;reg [1:0] oi;
wire signed [15:0] output_value;wire busy,done,fault;wire [31:0] cycles;
igor_neural_core dut(clk,rst_n,load,start,idx,value,oi,output_value,busy,done,fault,cycles);
reg [15:0] input_mem[0:2399],expected[0:399];reg [31:0] test_id,k,error_count=0,checks=0;
task check;input [255:0] n;input c;begin checks=checks+1;if(c!==1'b1)begin error_count=error_count+1;$display("FAIL t=%0t case=%0s vector=%0d output=%0d expected=%0d actual=%0d",$time,n,test_id,oi,$signed(expected[test_id*4+oi]),output_value);end end endtask
initial begin
 $readmemh("../assets/neural_24_64_64_4/test_inputs.mem",input_mem);$readmemh("../tb/test_vectors/neural_expected.hex",expected);
 $dumpfile("waveform/igor_neural.vcd");$dumpvars(1,igor_neural_tb);
 rst_n=0;load=0;start=0;idx=0;value=0;oi=0;repeat(3)@(negedge clk);rst_n=1;
 for(test_id=0;test_id<100;test_id=test_id+1)begin
  for(k=0;k<24;k=k+1)begin @(negedge clk);load=1;idx=k[4:0];value=input_mem[test_id*24+k];end
  @(negedge clk);load=0;start=1;@(negedge clk);start=0;
  while(busy)@(negedge clk);
  check("NN completed without saturation",done && !fault);
  for(k=0;k<4;k=k+1)begin oi=k[1:0];#1;check("NN integer oracle",output_value===expected[test_id*4+k]);end
 end
 $display("NN latency=%0d CHECKS=%0d ERRORS=%0d",cycles,checks,error_count);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED");$finish;
end
initial begin #100000000;$display("TEST FAILED watchdog");$finish;end
endmodule
`default_nettype wire
