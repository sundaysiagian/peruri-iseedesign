// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_best_candidate_selector(input wire [3:0] valid,
 input wire [35:0] indices,input wire [127:0] scores,costs,goals,velocities,
 output reg best_valid,output reg [8:0] best_index,
 output reg [31:0] best_score,best_cost,best_goal,best_velocity);
// Balanced two-level tournament, deterministic lowest-index tie break.
wire take1=valid[1] && (!valid[0] || scores[63:32]<scores[31:0] ||
 (scores[63:32]==scores[31:0] && indices[17:9]<indices[8:0]));
wire take3=valid[3] && (!valid[2] || scores[127:96]<scores[95:64] ||
 (scores[127:96]==scores[95:64] && indices[35:27]<indices[26:18]));
wire va=valid[0] || valid[1],vb=valid[2] || valid[3];
wire [31:0] sa=take1 ? scores[63:32]:scores[31:0];
wire [31:0] sb=take3 ? scores[127:96]:scores[95:64];
wire [8:0] ia=take1 ? indices[17:9]:indices[8:0];
wire [8:0] ib=take3 ? indices[35:27]:indices[26:18];
wire takeb=vb && (!va || sb<sa || (sb==sa && ib<ia));
wire [1:0] winner=takeb ? {1'b1,take3}:{1'b0,take1};
always @(*) begin
 best_valid=va || vb;
 best_index=0;best_score=0;best_cost=0;best_goal=0;best_velocity=0;
 if(best_valid)begin
  best_index=indices[winner*9 +:9];best_score=scores[winner*32 +:32];
  best_cost=costs[winner*32 +:32];best_goal=goals[winner*32 +:32];best_velocity=velocities[winner*32 +:32];
 end
end
endmodule
`default_nettype wire
