// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_uart_full_map_tb;
reg clk=0;always #10 clk=~clk;
reg [1:0] key;reg [3:0] sw;reg rx;wire tx;wire [7:0] led;
igor_uart_top #(.CLKS_PER_BIT(16'd8)) dut(clk,key,sw,rx,tx,led);
wire rv,re;wire [7:0] rb;
igor_uart_rx #(.CLKS_PER_BIT(16'd8)) monitor(clk,key[0],tx,rv,re,rb);
reg [7:0] response[0:7];reg [3:0] received;reg [31:0] error_count=0,checks=0,i,j;
reg [7:0] crc;reg [31:0] reply;reg [15:0] input_mem[0:2399],expected[0:399];
always @(posedge clk)if(!key[0])received<=0;else if(rv)begin response[received]<=rb;received<=received+1'b1;end
function [7:0] crc8;input [7:0] prior,b;reg [7:0] c;reg [3:0] k;begin c=prior^b;for(k=0;k<8;k=k+1'b1)c=c[7] ? (c<<1)^8'h07:c<<1;crc8=c;end endfunction
task check;input [255:0] n;input c;begin checks=checks+1;if(c!==1'b1)begin error_count=error_count+1;$display("FAIL time=%0t case=%0s expected=1 actual=%b",$time,n,c);end end endtask
task sendbyte;input [7:0] b;reg [3:0] k;begin
 @(negedge clk);rx=0;repeat(8)@(negedge clk);
 for(k=0;k<8;k=k+1'b1)begin rx=b[k];repeat(8)@(negedge clk);end
 rx=1;repeat(8)@(negedge clk);
end endtask
task packet;input [7:0] op;input [31:0] data;begin
 received=0;crc=crc8(0,8'ha5);crc=crc8(crc,op);crc=crc8(crc,data[7:0]);crc=crc8(crc,data[15:8]);crc=crc8(crc,data[23:16]);crc=crc8(crc,data[31:24]);
 sendbyte(8'ha5);sendbyte(op);sendbyte(data[7:0]);sendbyte(data[15:8]);sendbyte(data[23:16]);sendbyte(data[31:24]);sendbyte(crc);sendbyte(8'h5a);
 while(received!=8)@(negedge clk);
 repeat(10)@(negedge clk);
 reply={response[5],response[4],response[3],response[2]};
 crc=0;for(j=0;j<6;j=j+1)crc=crc8(crc,response[j]);
 check("UART response CRC",response[0]==8'h5a && response[1]==op && response[6]==crc && response[7]==8'ha5 && !re);
end endtask
initial begin
 $readmemh("../assets/neural_24_64_64_4/test_inputs.mem",input_mem);$readmemh("../tb/test_vectors/neural_expected.hex",expected);

 key=2'b10;sw=0;rx=1;repeat(8)@(negedge clk);key=3;repeat(8)@(negedge clk);
 // End-to-end serial map upload, commit, DWA and gated command readout.
 packet(4,32'h00183d0f);packet(5,0);packet(1,1);
 for(i=0;i<16384;i=i+1)packet(2,i);
 packet(3,0);check("UART full map committed",dut.core.map_valid && !dut.core.map_fault);
 packet(6,0);repeat(9000)@(negedge clk);packet(7,0);
 check("UART DWA done and enabled",reply[2] && reply[0] && reply[15:8]==0);
 packet(9,0);check("UART DWA cycle count",reply==7938);
 packet(14,0);check("UART DWA nonzero velocity",reply[4:0]!=0);
 check("AUDIT CRC permission before fault",dut.enable);
received=0;sendbyte(8'ha5);sendbyte(7);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(8'hff);sendbyte(8'h5a);repeat(30)@(negedge clk);
check("AUDIT CRC revokes enabled command",dut.protocol_fault && !dut.enable && dut.vc==0 && dut.wc==0);
key=2;repeat(8)@(negedge clk);key=3;repeat(8)@(negedge clk);
 packet(4,32'h00143d0f);packet(5,0);packet(1,1);packet(2,0);packet(3,0);
 check("UART partial map rejected",dut.core.map_fault && !led[0]);
 // malformed CRC never issues a new command and inhibits permission.
 received=0;sendbyte(8'ha5);sendbyte(7);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(0);sendbyte(8'hff);sendbyte(8'h5a);repeat(30)@(negedge clk);
 check("UART bad CRC fail closed",dut.protocol_fault && !led[0]);
 $display("UART FULL MAP CHECKS=%0d ERRORS=%0d",checks,error_count);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED");$finish;
end
initial begin #1000000000;$display("TEST FAILED UART watchdog");$finish;end
endmodule
`default_nettype wire
