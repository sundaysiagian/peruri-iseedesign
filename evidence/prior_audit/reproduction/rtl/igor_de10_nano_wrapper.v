// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_de10_nano_wrapper(input wire FPGA_CLK1_50,input wire [1:0] KEY,
 input wire [3:0] SW,output wire [7:0] LED);
reg [1:0] reset_sync;reg [3:0] sw_meta,sw_sync;
always @(posedge FPGA_CLK1_50 or negedge KEY[0]) begin
 if(!KEY[0]) reset_sync<=0;else reset_sync<={reset_sync[0],1'b1};
end
wire rst_n=reset_sync[1];
always @(posedge FPGA_CLK1_50 or negedge rst_n) begin
 if(!rst_n) begin sw_meta<=0;sw_sync<=0;end else begin sw_meta<=SW;sw_sync<=sw_meta;end
end
reg [3:0] demo_state;reg [14:0] address;reg [31:0] sequence_number;
reg [19:0] delay_count;reg [1:0] scenario;
wire cfg_write=demo_state==4'd0,cfg_lock=demo_state==4'd1;
wire map_begin=demo_state==4'd2,map_write=demo_state==4'd3,map_commit=demo_state==4'd4,start=demo_state==4'd5;
wire [7:0] data_byte=scenario==2'd1 ? 8'd254 : (scenario==2'd2 ? 8'd255 : {1'b0,address[6:0]});
wire enable,busy,done;wire [4:0] vcmd;wire signed [6:0] wcmd;wire [7:0] fault,last_fault;
wire [8:0] index;wire [31:0] latency,score,cost,goal,velocity,events;
igor_top core(FPGA_CLK1_50,rst_n,!sw_sync[2],!KEY[1],sw_sync[3],start,cfg_write,cfg_lock,32'h00143d0f,
 map_begin,map_write,map_commit,sequence_number,address,data_byte,enable,vcmd,wcmd,fault,busy,done,latency,index,score,cost,goal,velocity,events,last_fault);
always @(posedge FPGA_CLK1_50 or negedge rst_n) begin
 if(!rst_n) begin demo_state<=8;address<=0;sequence_number<=1;delay_count<=0;scenario<=0;end
 else case(demo_state)
  0:demo_state<=1;
  1:begin demo_state<=2;scenario<=sw_sync[1:0];end
  2:begin demo_state<=3;address<=0;end
  3:if(address==15'd16383 || (scenario==2'd3 && address==15'd100))demo_state<=4;else address<=address+15'd1;
  4:demo_state<=5;
  5:begin demo_state<=6;delay_count<=0;end
  6:if(delay_count==20'd900000) begin sequence_number<=sequence_number+32'd1;scenario<=sw_sync[1:0];demo_state<=2;end else delay_count<=delay_count+20'd1;
  8:demo_state<=9;
  9:demo_state<=0;
  default:demo_state<=7;
 endcase
end
assign LED={fault[3:0],done,busy,rst_n,enable};
endmodule
`default_nettype wire
