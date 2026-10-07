`timescale 1ns/1ps
module tb_top;
reg clk=0;always #10 clk=~clk;
reg rst_n=0,ready=1,estop=0,protective_stop=0,start=0,cfg_write=0,cfg_lock=0,map_begin=0,map_write=0,map_commit=0;
reg [31:0] cfg_data=32'h00143d0f,map_sequence=1;
reg [14:0] map_address=0;
reg [7:0] map_byte=0;
wire motor_enable,busy,done;
wire [4:0] v_command;
wire signed [6:0] omega_command;
wire [7:0] fault_code,last_fault;
wire [8:0] selected_index;
wire [31:0] latency_cycles,selected_score,selected_cost,selected_goal,selected_velocity,event_count;
igor_top #(.DEADLINE_CYCLES(10000),.FRESH_CYCLES(250000)) core(clk,rst_n,ready,estop,protective_stop,start,cfg_write,cfg_lock,cfg_data,map_begin,map_write,map_commit,map_sequence,map_address,map_byte,motor_enable,v_command,omega_command,fault_code,busy,done,latency_cycles,selected_index,selected_score,selected_cost,selected_goal,selected_velocity,event_count,last_fault);
// Executable HDL assertions. These are simulation assertions, not formal proof.
always @(negedge clk) if(rst_n) begin
 if(!motor_enable && (v_command!==0 || omega_command!==0)) $fatal(1,"FAIL zero-command invariant");
 if(motor_enable && (!ready || estop || protective_stop || !core.map_ok || !core.cfg_ok || !core.best_valid || core.state!=2 || start || core.tile_done!=4'b1111 || core.tile_fault!=0 || core.timed_out || core.lease_expired || core.control_fault)) $fatal(1,"FAIL gate prerequisites");
end
endmodule
