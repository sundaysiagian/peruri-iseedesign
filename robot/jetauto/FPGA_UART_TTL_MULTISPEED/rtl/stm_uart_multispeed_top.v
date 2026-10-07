// Four RRC speeds: 15/30/60/90 RPM, 6 second lease and 50 ms refresh.
module stm_uart_multispeed_top #(parameter HOLD_CYCLES=300000000,
 DEBOUNCE_CYCLES=1000000, REFRESH_CYCLES=2500000)(
 input wire FPGA_CLK1_50,input wire [1:0] KEY,input wire [3:0] SW,
 input wire UART_RX,output wire UART_TX,output wire [7:0] LED);
 reg [15:0] por=0;
 always @(posedge FPGA_CLK1_50) if(!(&por))por<=por+1'b1;
 reg [1:0] key_meta=3,key_sync=3;
 reg [3:0] sw_meta=0,sw_sync=0;
 always @(posedge FPGA_CLK1_50)begin
  key_meta<=KEY;key_sync<=key_meta;sw_meta<=SW;sw_sync<=sw_meta;
 end
 wire reset=!(&por)||!key_sync[0];
 reg [20:0] debounce;
 reg held,trigger;
 always @(posedge FPGA_CLK1_50)begin
  trigger<=0;
  if(reset||key_sync[1])begin debounce<=0;held<=0;end
  else if(!held)begin
   if(debounce==DEBOUNCE_CYCLES-1)begin held<=1;trigger<=1;end
   else debounce<=debounce+1'b1;
  end
 end
 reg [2:0] state;
 reg [1:0] command;
 reg [1:0] speed_level;
 reg start;
 reg [28:0] hold_count;
 reg [21:0] refresh_count;
 wire busy,done;
 stm_packet_tx_multispeed sender(FPGA_CLK1_50,reset,start,command,speed_level,UART_TX,busy,done);
 // 0 boot STOP,1 wait boot,2 idle,3 wait first frame,
 // 4 motor hold,5 issue STOP,6 wait STOP,7 wait refresh frame.
 always @(posedge FPGA_CLK1_50)begin
  start<=0;
  if(reset)begin state<=0;command<=0;hold_count<=0;refresh_count<=0;speed_level<=0;end
  else begin
   if(state==4||state==7)begin
    if(hold_count<HOLD_CYCLES)hold_count<=hold_count+1'b1;
    if(refresh_count<REFRESH_CYCLES)refresh_count<=refresh_count+1'b1;
   end
   case(state)
    0:begin command<=0;start<=1;state<=1;end
    1:if(done)state<=2;
    2:if(trigger)begin
     command<=sw_sync[3]?(sw_sync[2]?2'd3:2'd2):2'd1;
     speed_level<=sw_sync[1:0];
     start<=1;state<=3;
    end
    3:if(done)begin
     if(command>=2)begin hold_count<=0;refresh_count<=0;state<=sw_sync[3]?4:5;end
     else state<=2;
    end
    4:if(!sw_sync[3]||hold_count>=HOLD_CYCLES-1)state<=5;
      else if(refresh_count>=REFRESH_CYCLES-1)begin refresh_count<=0;start<=1;state<=7;end
    5:begin command<=0;start<=1;state<=6;end
    6:if(done)state<=2;
    7:if(done)state<=(!sw_sync[3]||hold_count>=HOLD_CYCLES-1)?5:4;
    default:state<=0;
   endcase
  end
 end
 assign LED={1'b0,UART_RX,command==3,sw_sync[3],speed_level,state!=2,busy};
endmodule
