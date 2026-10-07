`timescale 1ns/1ps
module tb_control;
reg clk=0;always #10 clk=~clk;
reg [1:0] key=3;reg [3:0] sw=0;
wire tx;wire [7:0] led;
stm_uart_demo_top #(.HOLD_CYCLES(200000),.DEBOUNCE_CYCLES(5),.REFRESH_CYCLES(20000)) dut(clk,key,sw,1'b1,tx,led);
integer stops=0,buzzers=0,forwards=0,backwards=0;
integer before_stop;
time hold_begin,stop_begin;
always @(posedge clk)if(dut.done)case(dut.command)
 0:stops=stops+1;
 1:buzzers=buzzers+1;
 2:forwards=forwards+1;
 3:backwards=backwards+1;
endcase
task press;
begin @(negedge clk);key[1]=0;repeat(20)@(negedge clk);key[1]=1;end
endtask
initial begin
 wait(stops==1);wait(dut.state==2);
 sw=1;repeat(5)@(negedge clk);press;
 wait(buzzers==1);wait(dut.state==2);
 before_stop=stops;sw=2;repeat(5)@(negedge clk);press;
 wait(stops>before_stop);wait(dut.state==2);
 if(forwards!=0)$fatal(1,"Disarmed request emitted motor frame");
 before_stop=stops;sw=10;repeat(5)@(negedge clk);press;
 wait(dut.state==4);hold_begin=$time;
 wait(dut.state==5);stop_begin=$time;
 if(stop_begin-hold_begin<4000000||stop_begin-hold_begin>4280000)
  $fatal(1,"Unexpected deadline %0t",stop_begin-hold_begin);
 wait(stops>before_stop);wait(dut.state==2);
 if(forwards<3)$fatal(1,"Motor refresh was not repeated");
 before_stop=stops;sw=11;repeat(5)@(negedge clk);press;
 wait(backwards>=2);@(negedge clk);sw[3]=0;
 wait(stops>before_stop);wait(dut.state==2);
 sw=10;repeat(5)@(negedge clk);
 key[1]=0;wait(dut.state==4);wait(dut.state==2);
 before_stop=stops;repeat(220000)@(negedge clk);
 if(stops!=before_stop)$fatal(1,"Held key retriggered session");
 key[1]=1;
 $display("PASS: boot STOP, buzzer, disarmed rejection, repeated motor frames, bounded deadline, arm-clear STOP, held-button suppression");
 $finish;
end
initial begin #40000000;$fatal(1,"Control timeout");end
endmodule
