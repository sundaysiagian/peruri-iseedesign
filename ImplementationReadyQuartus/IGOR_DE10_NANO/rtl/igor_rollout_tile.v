// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_rollout_tile #(parameter [8:0] TILE_ID=9'd0, parameter [5:0] HORIZON=6'd20)(
 input wire clk,rst_n,start,abort_run, input wire [4:0] previous_v,max_v,max_dv,
 input wire signed [6:0] previous_w, input wire [6:0] max_w,max_dw,
 output wire [13:0] map_addr,input wire [7:0] map_data,
 output reg done,best_valid,arithmetic_fault,output reg [8:0] best_index,
 output reg [31:0] best_score,best_cost,best_goal,best_velocity);
localparam [2:0] IDLE=3'd0,INIT=3'd1,STEP=3'd2,WAIT_RAM=3'd3,SCORE=3'd4,FINISH=3'd5;
reg [2:0] state; reg [8:0] candidate_index; reg [5:0] pose;
reg signed [23:0] x,y;reg [7:0] heading;reg legal;
reg [31:0] cost_sum;wire [3:0] velocity; wire signed [5:0] omega;wire window_legal;
wire signed [23:0] nx,ny;wire [7:0] nh;wire ov,outside;
igor_candidate_generator gen(candidate_index,previous_v,max_v,max_dv,previous_w,max_w,max_dw,velocity,omega,window_legal);
igor_kinematic_step stepper(x,y,heading,velocity,omega,nx,ny,nh,ov,outside);
assign map_addr={y[14:8],x[14:8]};
wire [31:0] updated_cost;wire cost_overflow;
igor_score_accumulator acc(cost_sum,{24'd0,map_data},updated_cost,cost_overflow);
wire signed [24:0] gx={x[23],x}-25'sd24576,gy={y[23],y}-25'sd16384;
wire [24:0] ax=gx[24] ? -gx:gx,ay=gy[24] ? -gy:gy;
wire [31:0] goal={7'd0,ax}+{7'd0,ay};
wire [31:0] vp={20'd0,(4'd15-velocity),8'd0};
wire [32:0] weighted={1'b0,cost_sum}<<4;
wire [32:0] final_score=weighted+{1'b0,goal}+{1'b0,vp};
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin state<=IDLE;candidate_index<=0;pose<=0;x<=0;y<=0;heading<=0;legal<=0;cost_sum<=0;done<=0;best_valid<=0;arithmetic_fault<=0;best_index<=0;best_score<=0;best_cost<=0;best_goal<=0;best_velocity<=0;end
 else if(abort_run) begin state<=IDLE;done<=0;best_valid<=0;end
 else case(state)
 IDLE: if(start) begin candidate_index<=TILE_ID;best_valid<=0;arithmetic_fault<=0;done<=0;state<=INIT;end
 INIT: begin x<=24'sd16384;y<=24'sd16384;heading<=0;pose<=0;cost_sum<=0;legal<=window_legal;state<=STEP;end
 STEP: begin x<=nx;y<=ny;heading<=nh;legal<=legal && !outside && !ov;arithmetic_fault<=arithmetic_fault || ov;state<=WAIT_RAM;end
 WAIT_RAM: state<=SCORE;
 SCORE: begin
  cost_sum<=updated_cost;legal<=legal && map_data<8'd254 && !cost_overflow;
  arithmetic_fault<=arithmetic_fault || cost_overflow;
  if(pose==HORIZON-6'd1) state<=FINISH;else begin pose<=pose+6'd1;state<=STEP;end
 end
 FINISH: begin
  if(final_score[32] || (|cost_sum[31:28])) arithmetic_fault<=1;
  if(legal && !(|cost_sum[31:28]) && !final_score[32] && (!best_valid || final_score[31:0]<best_score || (final_score[31:0]==best_score && candidate_index<best_index))) begin
   best_valid<=1;best_index<=candidate_index;best_score<=final_score[31:0];best_cost<=cost_sum;best_goal<=goal;best_velocity<=vp;
  end
  if(candidate_index>=9'd508) begin done<=1;state<=IDLE;end
  else begin candidate_index<=candidate_index+9'd4;state<=INIT;end
 end
 default: begin state<=IDLE;done<=0;best_valid<=0;arithmetic_fault<=1;end
 endcase
end
endmodule
`default_nettype wire
