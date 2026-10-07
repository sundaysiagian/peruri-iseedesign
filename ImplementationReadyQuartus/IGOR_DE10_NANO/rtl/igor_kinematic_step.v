// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_kinematic_step(input wire signed [23:0] x,y,
 input wire [7:0] heading, input wire [3:0] velocity,
 input wire signed [5:0] omega,
 output wire signed [23:0] next_x,next_y, output wire [7:0] next_heading,
 output wire overflow,outside);
wire signed [15:0] sn,cs; wire [7:0] cos_phase=heading+8'd64;
igor_trig_lut s(heading,sn); igor_trig_lut c(cos_phase,cs);
wire signed [15:0] displacement={8'd0,velocity,4'd0};
wire signed [31:0] px=displacement*cs, py=displacement*sn;
wire signed [31:0] dx=px>>>14, dy=py>>>14;
wire signed [24:0] nx={x[23],x}+{dx[23],dx[23:0]};
wire signed [24:0] ny={y[23],y}+{dy[23],dy[23:0]};
assign overflow=(nx[24]!=nx[23]) || (ny[24]!=ny[23]);
assign next_x=nx[23:0];assign next_y=ny[23:0];
assign outside=nx<25'sd0 || ny<25'sd0 || nx>=25'sd32768 || ny>=25'sd32768;
assign next_heading=heading+{{2{omega[5]}},omega};
endmodule
`default_nettype wire
