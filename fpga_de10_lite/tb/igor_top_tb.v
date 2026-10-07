// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_top_tb;
reg clk=0;always #10 clk=~clk;
reg rst_n,ready,estop,protective,start,cfg_write,cfg_lock,map_begin,map_write,map_commit;
reg [31:0] cfg_data,map_seq;reg [14:0] map_addr;reg [7:0] map_data;
wire enable,busy,done;wire [4:0] vcmd;wire signed [6:0] wcmd;wire [7:0] fault,last_fault;
wire [8:0] index;wire [31:0] latency,score,cost,goal,velocity,events;
igor_top #(.DEADLINE_CYCLES(32'd10000),.FRESH_CYCLES(32'd250000)) dut(clk,rst_n,ready,estop,protective,start,cfg_write,cfg_lock,cfg_data,map_begin,map_write,map_commit,map_seq,map_addr,map_data,enable,vcmd,wcmd,fault,busy,done,latency,index,score,cost,goal,velocity,events,last_fault);
reg [31:0] error_count=0,checks=0,cycles=0,i,s,log_fd,trace_fd;
reg [7:0] map_mem[0:16383];reg [128:0] oracle[0:511];
reg compare_active;reg [31:0] candidate_checks;
reg [255:0] test_name;
always @(posedge clk) cycles<=cycles+32'd1;
task check;input [255:0] name;input condition;input [63:0] expected_value,actual_value;
begin checks=checks+1;if(condition!==1'b1)begin error_count=error_count+1;$display("FAIL time=%0t case=%0s expected=%0d actual=%0d",$time,name,expected_value,actual_value);end
 $fdisplay(log_fd,"%0s,%0t,%0d,%0d,%0s",name,$time,expected_value,actual_value,condition===1'b1 ? "PASS":"FAIL");end endtask
task tick;begin @(posedge clk);#1;end endtask
task reset_all;begin
 @(negedge clk);rst_n=0;ready=1;estop=0;protective=0;start=0;cfg_write=0;cfg_lock=0;cfg_data=32'h00143d0f;
 map_begin=0;map_write=0;map_commit=0;map_seq=1;map_addr=0;map_data=0;compare_active=0;
 tick;tick;check("SAFE-01 reset",enable===0,0,enable);@(negedge clk);rst_n=1;tick;
end endtask
task configure;begin @(negedge clk);cfg_write=1;tick;@(negedge clk);cfg_write=0;cfg_lock=1;tick;@(negedge clk);cfg_lock=0;tick;end endtask
task begin_map;begin @(negedge clk);map_begin=1;tick;@(negedge clk);map_begin=0;end endtask
task commit_map;begin @(negedge clk);map_commit=1;tick;@(negedge clk);map_commit=0;tick;end endtask
task load_map;begin
 begin_map;
 for(i=0;i<16384;i=i+1)begin map_write=1;map_addr=i[14:0];map_data=map_mem[i];tick;@(negedge clk);end
 map_write=0;commit_map;
end endtask
task launch;begin @(negedge clk);start=1;tick;@(negedge clk);start=0;end endtask
task await_result;begin while(busy)tick;tick;end endtask
task normal;input [31:0] scene;input [8:0] expected_index;input [31:0] expected_score,expected_cost,expected_goal,expected_velocity;input expected_valid;
begin
 reset_all;configure;
 case(scene)
 0:begin $readmemh("../tb/test_vectors/map_0.hex",map_mem);$readmemh("../tb/test_vectors/expected_0.hex",oracle);end
 1:begin $readmemh("../tb/test_vectors/map_1.hex",map_mem);$readmemh("../tb/test_vectors/expected_1.hex",oracle);end
 2:begin $readmemh("../tb/test_vectors/map_2.hex",map_mem);$readmemh("../tb/test_vectors/expected_2.hex",oracle);end
 3:begin $readmemh("../tb/test_vectors/map_3.hex",map_mem);$readmemh("../tb/test_vectors/expected_3.hex",oracle);end
 4:begin $readmemh("../tb/test_vectors/map_4.hex",map_mem);$readmemh("../tb/test_vectors/expected_4.hex",oracle);end
 5:begin $readmemh("../tb/test_vectors/map_5.hex",map_mem);$readmemh("../tb/test_vectors/expected_5.hex",oracle);end
 endcase
 load_map;check("MAP-01 valid commit",dut.map_ok,1,dut.map_ok);
 candidate_checks=0;compare_active=1;launch;await_result;compare_active=0;
 check("BITEXACT candidate count",candidate_checks==512,512,candidate_checks);
 check("BITEXACT selected index",index==expected_index,expected_index,index);
 check("BITEXACT score",score==expected_score,expected_score,score);
 check("BITEXACT cost",cost==expected_cost,expected_cost,cost);
 check("BITEXACT goal",goal==expected_goal,expected_goal,goal);
 check("BITEXACT velocity",velocity==expected_velocity,expected_velocity,velocity);
 check("BITEXACT gate",enable==expected_valid,expected_valid,enable);
 check("TIME-01 latency",latency==7938,7938,latency);
 $display("SCENE %0d index=%0d score=%0d enable=%0d latency=%0d candidate_checks=%0d",scene,index,score,enable,latency,candidate_checks);
end endtask
always @(negedge clk) if(compare_active && dut.tiles[0].tile.state==3'd5) begin
 candidate_checks=candidate_checks+1;
 check("candidate tile0 valid",dut.tiles[0].tile.legal===oracle[dut.tiles[0].tile.candidate_index][128],oracle[dut.tiles[0].tile.candidate_index][128],dut.tiles[0].tile.legal);
 check("candidate tile0 score",dut.tiles[0].tile.final_score[31:0]===oracle[dut.tiles[0].tile.candidate_index][127:96],oracle[dut.tiles[0].tile.candidate_index][127:96],dut.tiles[0].tile.final_score[31:0]);
 check("candidate tile0 cost",dut.tiles[0].tile.cost_sum===oracle[dut.tiles[0].tile.candidate_index][95:64],oracle[dut.tiles[0].tile.candidate_index][95:64],dut.tiles[0].tile.cost_sum);
 check("candidate tile0 goal",dut.tiles[0].tile.goal===oracle[dut.tiles[0].tile.candidate_index][63:32],oracle[dut.tiles[0].tile.candidate_index][63:32],dut.tiles[0].tile.goal);
 $fdisplay(trace_fd,"%0d,%0d,%0d,%0d,%0d",s,dut.tiles[0].tile.candidate_index,dut.tiles[0].tile.legal,dut.tiles[0].tile.cost_sum,dut.tiles[0].tile.final_score[31:0]);
end
always @(negedge clk) if(compare_active && dut.tiles[1].tile.state==3'd5) begin
 candidate_checks=candidate_checks+1;
 check("candidate tile1 valid",dut.tiles[1].tile.legal===oracle[dut.tiles[1].tile.candidate_index][128],oracle[dut.tiles[1].tile.candidate_index][128],dut.tiles[1].tile.legal);
 check("candidate tile1 score",dut.tiles[1].tile.final_score[31:0]===oracle[dut.tiles[1].tile.candidate_index][127:96],oracle[dut.tiles[1].tile.candidate_index][127:96],dut.tiles[1].tile.final_score[31:0]);
 check("candidate tile1 cost",dut.tiles[1].tile.cost_sum===oracle[dut.tiles[1].tile.candidate_index][95:64],oracle[dut.tiles[1].tile.candidate_index][95:64],dut.tiles[1].tile.cost_sum);
 check("candidate tile1 goal",dut.tiles[1].tile.goal===oracle[dut.tiles[1].tile.candidate_index][63:32],oracle[dut.tiles[1].tile.candidate_index][63:32],dut.tiles[1].tile.goal);
 $fdisplay(trace_fd,"%0d,%0d,%0d,%0d,%0d",s,dut.tiles[1].tile.candidate_index,dut.tiles[1].tile.legal,dut.tiles[1].tile.cost_sum,dut.tiles[1].tile.final_score[31:0]);
end
always @(negedge clk) if(compare_active && dut.tiles[2].tile.state==3'd5) begin
 candidate_checks=candidate_checks+1;
 check("candidate tile2 valid",dut.tiles[2].tile.legal===oracle[dut.tiles[2].tile.candidate_index][128],oracle[dut.tiles[2].tile.candidate_index][128],dut.tiles[2].tile.legal);
 check("candidate tile2 score",dut.tiles[2].tile.final_score[31:0]===oracle[dut.tiles[2].tile.candidate_index][127:96],oracle[dut.tiles[2].tile.candidate_index][127:96],dut.tiles[2].tile.final_score[31:0]);
 check("candidate tile2 cost",dut.tiles[2].tile.cost_sum===oracle[dut.tiles[2].tile.candidate_index][95:64],oracle[dut.tiles[2].tile.candidate_index][95:64],dut.tiles[2].tile.cost_sum);
 check("candidate tile2 goal",dut.tiles[2].tile.goal===oracle[dut.tiles[2].tile.candidate_index][63:32],oracle[dut.tiles[2].tile.candidate_index][63:32],dut.tiles[2].tile.goal);
 $fdisplay(trace_fd,"%0d,%0d,%0d,%0d,%0d",s,dut.tiles[2].tile.candidate_index,dut.tiles[2].tile.legal,dut.tiles[2].tile.cost_sum,dut.tiles[2].tile.final_score[31:0]);
end
always @(negedge clk) if(compare_active && dut.tiles[3].tile.state==3'd5) begin
 candidate_checks=candidate_checks+1;
 check("candidate tile3 valid",dut.tiles[3].tile.legal===oracle[dut.tiles[3].tile.candidate_index][128],oracle[dut.tiles[3].tile.candidate_index][128],dut.tiles[3].tile.legal);
 check("candidate tile3 score",dut.tiles[3].tile.final_score[31:0]===oracle[dut.tiles[3].tile.candidate_index][127:96],oracle[dut.tiles[3].tile.candidate_index][127:96],dut.tiles[3].tile.final_score[31:0]);
 check("candidate tile3 cost",dut.tiles[3].tile.cost_sum===oracle[dut.tiles[3].tile.candidate_index][95:64],oracle[dut.tiles[3].tile.candidate_index][95:64],dut.tiles[3].tile.cost_sum);
 check("candidate tile3 goal",dut.tiles[3].tile.goal===oracle[dut.tiles[3].tile.candidate_index][63:32],oracle[dut.tiles[3].tile.candidate_index][63:32],dut.tiles[3].tile.goal);
 $fdisplay(trace_fd,"%0d,%0d,%0d,%0d,%0d",s,dut.tiles[3].tile.candidate_index,dut.tiles[3].tile.legal,dut.tiles[3].tile.cost_sum,dut.tiles[3].tile.final_score[31:0]);
end
initial begin
 log_fd=$fopen("../evidence/test_summary.csv","w");trace_fd=$fopen("../evidence/candidate_trace.csv","w");
 $fdisplay(log_fd,"case,time_ns,expected,actual,status");$fdisplay(trace_fd,"scene,index,valid,cost,score");
 $dumpfile("waveform/igor_top.vcd");$dumpvars(1,igor_top_tb);$dumpvars(1,dut.gate);$dumpvars(1,dut.maps);
s=0;normal(0,9'd496,32'd3392,32'd0,32'd3392,32'd0,1'b1);
s=1;normal(1,9'd0,32'd0,32'd0,32'd0,32'd0,1'b0);
s=2;normal(2,9'd0,32'd0,32'd0,32'd0,32'd0,1'b0);
s=3;normal(3,9'd450,32'd13591,32'd341,32'd7879,32'd256,1'b1);
s=4;normal(4,9'd496,32'd3392,32'd0,32'd3392,32'd0,1'b1);
s=5;normal(5,9'd436,32'd9436,32'd0,32'd8924,32'd512,1'b1);

 // Atomic inactive writes do not alter current run data.
 reset_all;configure;$readmemh("../tb/test_vectors/map_0.hex",map_mem);load_map;launch;tick;
 map_seq=2;begin_map;map_write=1;map_addr=0;map_data=254;tick;@(negedge clk);map_write=0;
 check("MAP-08 bank held during update",dut.bank==1,1,dut.bank);await_result;
 check("MAP-08 selected unaffected",enable && index==496,496,index);
 commit_map;check("MAP-07 partial rejects",!enable && dut.map_fault,1,dut.map_fault);
 reset_all;configure;begin_map;commit_map;check("MAP-03 missing frame",dut.map_fault,1,dut.map_fault);
 reset_all;configure;begin_map;map_write=1;map_addr=1;tick;@(negedge clk);map_write=0;
 check("MAP-04 missing byte",dut.map_fault,1,dut.map_fault);
 reset_all;configure;begin_map;map_write=1;map_addr=15'd16384;tick;@(negedge clk);map_write=0;
 check("MAP-06 bad address",dut.map_fault,1,dut.map_fault);
 reset_all;configure;load_map;begin_map;check("MAP-02 replay",dut.map_fault && !enable,1,dut.map_fault);
 reset_all;configure;begin_map;
 for(i=0;i<16384;i=i+1)begin map_write=1;map_addr=i[14:0];map_data=0;tick;@(negedge clk);end
 map_addr=15'd16384;tick;@(negedge clk);map_write=0;commit_map;check("MAP-05 oversized",dut.map_fault,1,dut.map_fault);
 reset_all;configure;load_map;map_seq=2;load_map;check("MAP-09 bank toggles",dut.bank==0 && dut.seq==2,2,dut.seq);
 launch;await_result;force dut.maps.age=32'd250000;#1;check("STALE stops",!enable,0,enable);release dut.maps.age;
 reset_all;configure;cfg_write=1;tick;@(negedge clk);cfg_write=0;check("CFG-02 locked write",dut.cfg_fault && !dut.cfg_ok,1,dut.cfg_fault);
 reset_all;cfg_data=32'h00043d0f;cfg_write=1;tick;@(negedge clk);cfg_write=0;check("CFG-04 version rollback",dut.cfg_fault,1,dut.cfg_fault);
 reset_all;cfg_data=32'h00143fff;cfg_write=1;tick;@(negedge clk);cfg_write=0;check("CFG-03 range",dut.cfg_fault,1,dut.cfg_fault);
 reset_all;configure;load_map;launch;cfg_write=1;tick;@(negedge clk);cfg_write=0;tick;check("CFG-05 busy write",!enable && dut.cfg_fault,1,dut.cfg_fault);
 reset_all;configure;load_map;launch;force dut.tiles[0].tile.done=1'b0;repeat(10004)tick;
 check("TIME-04 missing tile timeout",!enable && dut.timed_out,1,dut.timed_out);release dut.tiles[0].tile.done;
 reset_all;configure;load_map;launch;force dut.elapsed=32'd9999;tick;release dut.elapsed;check("TIME-02 deadline boundary stop",!enable && dut.timed_out,1,dut.timed_out);
 reset_all;configure;load_map;launch;repeat(50)tick;rst_n=0;#1;check("SAFE-02 reset during run",!enable,0,enable);tick;
 reset_all;configure;load_map;launch;estop=1;#1;check("SAFE-04 estop during run",!enable && fault==2,2,fault);tick;
 reset_all;configure;load_map;launch;while(!( &dut.tile_done))tick;estop=1;#1;check("SAFE-05 estop before commit",!enable && fault==2,2,fault);tick;
 reset_all;configure;load_map;launch;await_result;protective=1;#1;check("SAFE-06 protective",!enable && fault==3,3,fault);protective=0;ready=0;#1;check("SAFE-10 not ready",!enable && fault==4,4,fault);
 reset_all;configure;load_map;launch;await_result;force dut.state=3'd7;#1;check("SAFE-09 illegal FSM",!enable,0,enable);tick;release dut.state;tick;check("SAFE-09 recovery",dut.control_fault,1,dut.control_fault);

 reset_all;configure;load_map;launch;await_result;
 launch;await_result;check("back to back",enable && index==496,496,index);
 force dut.best_valid=1'b0;#1;check("PLAN-05 missing valid",!enable,0,enable);release dut.best_valid;
 force dut.cv=5'd31;#1;check("PLAN-08 extreme result",!enable && fault==10,10,fault);release dut.cv;
 force dut.tile_fault=4'b0001;#1;check("ARITH stop integrated",!enable && fault==7,7,fault);release dut.tile_fault;
 force dut.elapsed=32'd10000;#1;check("TIME-03 command lease expires",!enable,0,enable);release dut.elapsed;
 reset_all;configure;load_map;launch;
 map_seq=2;begin_map;
 for(i=0;i<16384;i=i+1)begin map_write=1;map_addr=i[14:0];map_data=0;tick;@(negedge clk);end
 map_write=0;launch;tick;commit_map;check("MAP-09 busy commit rejects",dut.map_fault && dut.bank==1,1,dut.bank);
 reset_all;configure;load_map;launch;force dut.tiles[0].tile.done=1'b0;repeat(10004)tick;
 release dut.tiles[0].tile.done;force dut.tile_done=4'b1111;repeat(3)tick;check("PLAN-07 late tile remains stop",!enable,0,enable);release dut.tile_done;
 $display("CHECKS=%0d ERRORS=%0d",checks,error_count);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED errors=%0d",error_count);
 $fclose(log_fd);$fclose(trace_fd);$finish;
end
initial begin #50000000;$display("TEST FAILED WATCHDOG");$finish;end
endmodule
`default_nettype wire
