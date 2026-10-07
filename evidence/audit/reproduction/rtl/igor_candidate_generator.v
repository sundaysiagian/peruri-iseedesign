// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_candidate_generator(input wire [8:0] candidate_index,
 input wire [4:0] previous_v,max_v,max_dv,
 input wire signed [6:0] previous_w, input wire [6:0] max_w,max_dw,
 output wire [3:0] velocity, output wire signed [5:0] omega,output wire legal);
assign velocity=candidate_index[8:5];
assign omega=$signed({1'b0,candidate_index[4:0]})-6'sd16;
wire [5:0] aw=omega[5] ? -omega : omega;
wire [4:0] dv={1'b0,velocity}>=previous_v ? {1'b0,velocity}-previous_v : previous_v-{1'b0,velocity};
wire signed [7:0] dw={{2{omega[5]}},omega}-{previous_w[6],previous_w};
wire [7:0] adw=dw[7] ? -dw : dw;
assign legal=({1'b0,velocity}<=max_v) && ({1'b0,aw}<=max_w) && dv<=max_dv && adw<={1'b0,max_dw};
endmodule
`default_nettype wire
