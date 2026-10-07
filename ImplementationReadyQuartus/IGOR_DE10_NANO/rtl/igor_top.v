// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_top #(parameter [31:0] DEADLINE_CYCLES=32'd1000000,FRESH_CYCLES=32'd1000000)(
 input wire clk,rst_n,ready,estop,protective_stop,start,
 input wire cfg_write,cfg_lock,input wire [31:0] cfg_data,
 input wire map_begin,map_write,map_commit,input wire [31:0] map_sequence,
 input wire [14:0] map_address,input wire [7:0] map_byte,
 output wire motor_enable,output wire [4:0] v_command,output wire signed [6:0] omega_command,
 output wire [7:0] fault_code,output wire busy,done,
 output reg [31:0] latency_cycles,output wire [8:0] selected_index,
 output wire [31:0] selected_score,selected_cost,selected_goal,selected_velocity,
 output wire [31:0] event_count,output wire [7:0] last_fault);
wire locked,cfg_valid,cfg_fault;wire [4:0] max_v,max_dv;wire [6:0] max_w,max_dw;
igor_config_registers cfg(clk,rst_n,cfg_write,cfg_lock,busy,cfg_data,locked,cfg_valid,cfg_fault,max_v,max_dv,max_w,max_dw);
wire bank,map_valid,map_fault,map_fresh,ram_wr;wire [14:0] ram_addr;wire [7:0] ram_data;wire [31:0] seq,age;
igor_costmap_manager #(.FRESH_CYCLES(FRESH_CYCLES)) maps(clk,rst_n,map_begin,map_write,map_commit,busy,map_sequence,map_address,map_byte,bank,map_valid,map_fault,map_fresh,ram_wr,ram_addr,ram_data,seq,age);
localparam [2:0] IDLE=3'd0,RUN=3'd1,RESULT=3'd2,FAULT=3'd3;
reg [2:0] state; reg tile_start;reg [31:0] elapsed;reg timed_out,control_fault;
reg [4:0] previous_v,run_previous_v;reg signed [6:0] previous_w,run_previous_w;
wire [3:0] tile_done,tile_valid,tile_fault;
wire [35:0] indices;wire [127:0] scores,costs,goals,velocities;
wire abort_run=state==FAULT || !ready || estop || protective_stop;
genvar t;
generate for(t=0;t<4;t=t+1) begin:tiles
 wire [13:0] address;wire [7:0] cell_data;
 igor_costmap_bank memory(clk,ram_wr,ram_addr,ram_data,{bank,address},cell_data);
 igor_rollout_tile #(.TILE_ID(t)) tile(clk,rst_n,tile_start,abort_run,run_previous_v,max_v,max_dv,run_previous_w,max_w,max_dw,address,cell_data,tile_done[t],tile_valid[t],tile_fault[t],indices[t*9 +:9],scores[t*32 +:32],costs[t*32 +:32],goals[t*32 +:32],velocities[t*32 +:32]);
end endgenerate
wire best_valid;
igor_best_candidate_selector selector(tile_valid,indices,scores,costs,goals,velocities,best_valid,selected_index,selected_score,selected_cost,selected_goal,selected_velocity);
wire [4:0] cv={1'b0,selected_index[8:5]};
wire signed [6:0] cw=$signed({2'b0,selected_index[4:0]})-7'sd16;
assign busy=state==RUN;assign done=state==RESULT;
wire map_ok=map_valid && map_fresh && !map_fault;
wire cfg_ok=cfg_valid && locked && !cfg_fault;
wire lease_expired=elapsed>=DEADLINE_CYCLES;
igor_safety_security_gate gate(rst_n,ready && !control_fault,estop,protective_stop,map_ok,cfg_ok,
 best_valid && state==RESULT && !start, &tile_done,|tile_fault,timed_out || lease_expired,
 cv,run_previous_v,max_v,max_dv,cw,run_previous_w,max_w,max_dw,motor_enable,v_command,omega_command,fault_code);
igor_status_logger logger(clk,rst_n,fault_code,event_count,last_fault);
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin state<=IDLE;tile_start<=0;elapsed<=0;latency_cycles<=0;timed_out<=0;control_fault<=0;previous_v<=0;previous_w<=0;run_previous_v<=0;run_previous_w<=0;end
 else begin
  tile_start<=0;
  if(state==RUN || state==RESULT) if(elapsed!=32'hffffffff) elapsed<=elapsed+32'd1;
  if(motor_enable) begin previous_v<=v_command;previous_w<=omega_command;end
  else if(state!=RUN) begin previous_v<=0;previous_w<=0;end
  case(state)
   IDLE,RESULT: if(estop || protective_stop || !ready || (state==RESULT && (!map_ok || !cfg_ok))) begin state<=FAULT;control_fault<=1;end
   else if(start) begin
    if(map_ok && cfg_ok && ready && !estop && !protective_stop && !control_fault) begin
     state<=RUN;tile_start<=1;elapsed<=0;timed_out<=0;run_previous_v<=previous_v;run_previous_w<=previous_w;
    end else begin state<=FAULT;control_fault<=1;end
   end
   RUN: begin
    if(!map_ok || !cfg_ok || !ready || estop || protective_stop || (|tile_fault)) begin state<=FAULT;control_fault<=1;end
    else if(elapsed>=DEADLINE_CYCLES-32'd1) begin state<=FAULT;timed_out<=1;end
    else if((&tile_done) && !tile_start && elapsed>=32'd2) begin state<=RESULT;latency_cycles<=elapsed+32'd1;end
   end
   FAULT: state<=FAULT;
   default: begin state<=FAULT;control_fault<=1;end
  endcase
 end
end
endmodule
`default_nettype wire
