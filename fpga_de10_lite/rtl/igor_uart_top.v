// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_uart_top #(parameter [15:0] CLKS_PER_BIT=16'd434)(
 input wire FPGA_CLK1_50,input wire [1:0] KEY,input wire [3:0] SW,
 input wire UART_RX,output wire UART_TX,output wire [7:0] LED);
reg [1:0] reset_sync;reg [3:0] sw_meta,sw_sync;
always @(posedge FPGA_CLK1_50 or negedge KEY[0])begin if(!KEY[0])reset_sync<=0;else reset_sync<={reset_sync[0],1'b1};end
wire rst_n=reset_sync[1];
always @(posedge FPGA_CLK1_50 or negedge rst_n)begin if(!rst_n)begin sw_meta<=0;sw_sync<=0;end else begin sw_meta<=SW;sw_sync<=sw_meta;end end
wire command,protocol_fault;wire [7:0] op;wire [31:0] data;reg [31:0] response;reg invalid_command;
igor_uart_protocol #(.CLKS_PER_BIT(CLKS_PER_BIT)) serial(FPGA_CLK1_50,rst_n,UART_RX,UART_TX,command,op,data,response,protocol_fault);
wire enable,busy,done;wire [4:0] vc;wire signed [6:0] wc;wire [7:0] fault,last;
wire [8:0] index;wire [31:0] latency,score,cost,goal,velocity,events;
wire cfg_wr=command && op==4,cfg_lock=command && op==5,run=command && op==6;
wire mb=command && op==1,mw=command && op==2,mc=command && op==3;
// Begin command payload is visible during its command pulse. No stale sequence register.
igor_top core(FPGA_CLK1_50,rst_n,!protocol_fault && !invalid_command && !sw_sync[2],!KEY[1],sw_sync[3],run,cfg_wr,cfg_lock,data,
 mb,mw,mc,data,data[14:0],data[23:16],enable,vc,wc,fault,busy,done,latency,index,score,cost,goal,velocity,events,last);
wire signed [15:0] rom_data,nn_value;wire nn_busy,nn_done,nn_fault;wire [31:0] nn_cycles;
igor_neural_rom inspection_rom(FPGA_CLK1_50,data[12:0],rom_data);
igor_neural_core neural(FPGA_CLK1_50,rst_n,command && op==10,command && op==11,data[4:0],data[23:8],data[1:0],nn_value,nn_busy,nn_done,nn_fault,nn_cycles);
always @(posedge FPGA_CLK1_50 or negedge rst_n)begin
 if(!rst_n)begin invalid_command<=0;end
 else if(command)begin
  if(op<1 || op>14 || (op==8 && data>=6020) || (op==10 && (data[7:5]!=0 || data[31:24]!=0 || data[4:0]>=24)))invalid_command<=1;
 end
end
always @(*)begin
 response={7'd0,index,fault,3'd0,invalid_command,protocol_fault,done,busy,enable};
 case(op)
 8:response={16'd0,rom_data};
 9:response=latency;
 12:response={13'd0,nn_fault,nn_busy,nn_done,nn_value};
 13:response=nn_cycles;
 14:response={20'd0,wc,vc};
 default:response={7'd0,index,fault,3'd0,invalid_command,protocol_fault,done,busy,enable};
 endcase
end
assign LED={fault[3:0],done,busy,rst_n,enable};
endmodule
`default_nettype wire
