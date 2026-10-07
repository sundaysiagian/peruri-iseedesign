`timescale 1ns/1ps
// Independent UART receiver checks wire bytes, IDs, float bits and CRC.
module tb_multispeed;
reg clk=0,reset=1,start=0;
reg [1:0] command=0,speed_level=0;
wire tx,busy,done;
always #10 clk=~clk;
stm_packet_tx_multispeed dut(clk,reset,start,command,speed_level,tx,busy,done);
reg [7:0] bytes_rx[0:26];
reg [31:0] bits_expected,bits_received;
reg [7:0] crc;
integer bank,level,direction,n,b,i,k,fd,frames=0,total=0;
function [31:0] speed_bits;
input integer level;
begin case(level)
 0:speed_bits=32'h3e800000;
 1:speed_bits=32'h3f000000;
 2:speed_bits=32'h3f800000;
 3:speed_bits=32'h3fc00000;
endcase end
endfunction
initial begin
 $dumpfile("multispeed.vcd");$dumpvars(0,tb_multispeed);
 fd=$fopen("tb/rtl_captured_packets.hex","w");
 if(!fd)$fatal(1,"Cannot open capture file");
 repeat(4)@(negedge clk);reset=0;
 for(bank=0;bank<10;bank=bank+1)begin
  if(bank<2)begin command=bank;speed_level=0;end
  else begin command=2+((bank-2)%2);speed_level=(bank-2)/2;end
  @(negedge clk);start=1;
  @(negedge clk);start=0;
  $fwrite(fd,"%0d %0d ",command,speed_level);
  for(n=0;n<(command==1?13:27);n=n+1)begin
   if(n!=0)@(negedge tx);
   #500;if(tx!==0)$fatal(1,"Bad start bit");
   for(b=0;b<8;b=b+1)begin #1000;bytes_rx[n][b]=tx;end
   #1000;if(tx!==1)$fatal(1,"Bad stop bit");
   $fwrite(fd,"%02x ",bytes_rx[n]);total=total+1;
  end
  $fwrite(fd,"\n");
  if(bytes_rx[0]!==8'haa||bytes_rx[1]!==8'h55)$fatal(1,"Bad header");
  crc=0;
  for(n=2;n<(command==1?12:26);n=n+1)begin
   crc=crc^bytes_rx[n];
   for(k=0;k<8;k=k+1)crc=crc[0]?(crc>>1)^8'h8c:crc>>1;
  end
  if(crc!==bytes_rx[command==1?12:26])$fatal(1,"CRC mismatch");
  if(command!=1)begin
   if(bytes_rx[2]!==3||bytes_rx[3]!==22||bytes_rx[4]!==1||bytes_rx[5]!==4)$fatal(1,"Motor frame fields");
   for(i=0;i<4;i=i+1)begin
    if(bytes_rx[6+i*5]!==i)$fatal(1,"Missing/wrong motor ID");
    bits_received={bytes_rx[10+i*5],bytes_rx[9+i*5],bytes_rx[8+i*5],bytes_rx[7+i*5]};
    bits_expected=command==0?0:speed_bits(speed_level);
    if(command>=2&&((i>=2)^(command==3)))bits_expected[31]=1;
    if(bits_received!==bits_expected)$fatal(1,"Wrong float speed, level %0d ID %0d",speed_level,i+1);
   end
  end
  wait(!busy);repeat(3)@(negedge clk);frames=frames+1;
 end
 $fclose(fd);
 $display("PASS: %0d UART frames, %0d bytes, four speed levels, both directions, all four IDs, floats and CRC",frames,total);
 $finish;
end
initial begin #10000000;$fatal(1,"Test timeout");end
endmodule
