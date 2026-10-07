`timescale 1ns/1ps
module tb_multispeed_control;
reg clk=0;always #10 clk=~clk;
reg [1:0] key=3;reg [3:0] sw=0;
wire tx;wire [7:0] led;
stm_uart_multispeed_top #(.HOLD_CYCLES(200000),.REFRESH_CYCLES(20000),.DEBOUNCE_CYCLES(5)) dut(clk,key,sw,1'b1,tx,led);
integer stops=0,buzzers=0,motors=0,expected_bank=-1;
integer level,before_stop,before_motor;
always @(posedge clk)if(dut.sender.done)begin
 if(dut.sender.selected==0)stops=stops+1;
 else if(dut.sender.selected==1)buzzers=buzzers+1;
 else begin
  motors=motors+1;
  if(dut.sender.selected!=expected_bank)$fatal(1,"Wrong speed/direction bank");
 end
end
task press;
begin @(negedge clk);key[1]=0;repeat(20)@(negedge clk);key[1]=1;end
endtask
initial begin
 wait(stops==1);wait(dut.state==2);
 sw=0;repeat(5)@(negedge clk);press;
 wait(buzzers==1);wait(dut.state==2);
 if(motors!=0)$fatal(1,"Disarmed motor output");
 for(level=0;level<4;level=level+1)begin
  expected_bank=2+2*level;before_stop=stops;before_motor=motors;
  sw=8+level;repeat(5)@(negedge clk);press;
  wait(dut.state==4);
  // Changing switches must not change a running session's latched speed/direction.
  @(negedge clk);sw=12+((level+1)%4);
  wait(stops>before_stop);wait(dut.state==2);
  if(motors-before_motor<3)$fatal(1,"Missing refresh packets");
 end
 expected_bank=9;before_stop=stops;sw=15;repeat(5)@(negedge clk);press;
 wait(dut.state==7);@(negedge clk);sw[3]=0;
 wait(stops>before_stop);wait(dut.state==2);
 $display("PASS: four speed selections, latched direction/speed, refresh, lease STOP and arm-clear STOP");
 $finish;
end
initial begin #50000000;$fatal(1,"Controller timeout");end
endmodule
