// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_units_tb;
reg rst_n,ready,estop,protective,map_ok,cfg_ok,valid,all_done,arith,timeout;
reg [4:0] cv,pv,mv,mdv;reg signed [6:0] cw,pw;reg [6:0] mw,mdw;
wire en;wire [4:0] vc;wire signed [6:0] wc;wire [7:0] code;
igor_safety_security_gate gate(rst_n,ready,estop,protective,map_ok,cfg_ok,valid,all_done,arith,timeout,cv,pv,mv,mdv,cw,pw,mw,mdw,en,vc,wc,code);
reg [31:0] a,b;wire [31:0] total;wire ov;
igor_score_accumulator acc(a,b,total,ov);
reg signed [23:0] x,y;reg [7:0] h;reg [3:0] v;reg signed [5:0] w;
wire signed [23:0] nx,ny;wire [7:0] nh;wire kov,outside;
igor_kinematic_step kin(x,y,h,v,w,nx,ny,nh,kov,outside);
reg [3:0] sv;reg [35:0] si;reg [127:0] ss;wire bv;wire [8:0] bi;wire [31:0] bs,bc,bg,bp;
igor_best_candidate_selector sel(sv,si,ss,128'd0,128'd0,128'd0,bv,bi,bs,bc,bg,bp);
reg [31:0] error_count=0,checks=0,k;
task check;input [255:0] n;input c;begin checks=checks+1;if(c!==1)begin error_count=error_count+1;$display("FAIL time=%0t case=%0s expected=1 actual=%b",$time,n,c);end end endtask
task good;begin rst_n=1;ready=1;estop=0;protective=0;map_ok=1;cfg_ok=1;valid=1;all_done=1;arith=0;timeout=0;cv=5;pv=4;mv=15;mdv=2;cw=-2;pw=-1;mw=16;mdw=2;#1;end endtask
initial begin
 $dumpfile("waveform/igor_units.vcd");$dumpvars(0,igor_units_tb);
 good;check("gate valid",en && vc==5 && wc==-2);
 for(k=0;k<10;k=k+1)begin
 good;case(k)0:rst_n=0;1:ready=0;2:estop=1;3:protective=1;4:map_ok=0;5:cfg_ok=0;6:valid=0;7:all_done=0;8:arith=1;9:timeout=1;endcase
 #1;check("gate each prerequisite",!en && vc==0 && wc==0 && code!=0);
 end
 good;cv=31;#1;check("SAFE-07 velocity",!en && code==10);
 good;cw=-64;#1;check("SAFE-07 signed omega minimum",!en && code==10);
 good;cv=10;#1;check("SAFE-08 acceleration",!en && code==11);
 good;cw=2;#1;check("SAFE-08 angular acceleration",!en && code==11);
 a=32'hffffffff;b=1;#1;check("ARITH-02 accumulator overflow",ov && total==0);
 a=32'hfffffffe;b=1;#1;check("ARITH-02 maximum legal",!ov && total==32'hffffffff);
 x=24'sh7fffff;y=0;h=0;v=15;w=0;#1;check("ARITH positive position overflow",kov);
 x=24'sh800000;h=128;#1;check("ARITH negative position overflow",kov);
 x=0;y=0;h=128;#1;check("boundary outside map",outside);
 x=16384;y=16384;h=255;v=0;w=1;#1;check("heading wrap",nh==0 && nx==x && ny==y);
 sv=15;si={9'd9,9'd2,9'd3,9'd7};ss={32'd10,32'd10,32'd10,32'd10};#1;check("PLAN-03 deterministic tie",bv && bi==2 && bs==10);
 sv=0;#1;check("PLAN-05 no valid",!bv);
 $display("UNIT CHECKS=%0d ERRORS=%0d",checks,error_count);
 if(error_count==0)$display("TEST PASSED");else $display("TEST FAILED");$finish;
end
endmodule
`default_nettype wire
