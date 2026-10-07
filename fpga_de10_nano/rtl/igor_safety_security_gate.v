// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_safety_security_gate(
 input wire rst_n, ready, estop, protective_stop, map_ok, cfg_ok,
 input wire result_valid, all_done, arithmetic_fault, timeout,
 input wire [4:0] candidate_v, previous_v, max_v, max_dv,
 input wire signed [6:0] candidate_w, previous_w,
 input wire [6:0] max_w, max_dw,
 output reg motor_enable, output reg [4:0] v_command,
 output reg signed [6:0] omega_command, output reg [7:0] fault_code);
wire signed [7:0] dw = {candidate_w[6],candidate_w}-{previous_w[6],previous_w};
wire [7:0] abs_dw = dw[7] ? -dw : dw;
wire [6:0] abs_w = candidate_w[6] ? -candidate_w : candidate_w;
wire [4:0] abs_dv = candidate_v>=previous_v ? candidate_v-previous_v : previous_v-candidate_v;
always @(*) begin
 motor_enable=1'b0; v_command=5'd0; omega_command=7'sd0; fault_code=8'd0;
 if (!rst_n) fault_code=8'd1;
 else if (estop) fault_code=8'd2;
 else if (protective_stop) fault_code=8'd3;
 else if (!ready) fault_code=8'd4;
 else if (!map_ok) fault_code=8'd5;
 else if (!cfg_ok) fault_code=8'd6;
 else if (arithmetic_fault) fault_code=8'd7;
 else if (timeout) fault_code=8'd8;
 else if (!all_done || !result_valid) fault_code=8'd9;
 else if (candidate_v>max_v || abs_w>max_w) fault_code=8'd10;
 else if (abs_dv>max_dv || abs_dw>{1'b0,max_dw}) fault_code=8'd11;
 else begin motor_enable=1'b1; v_command=candidate_v; omega_command=candidate_w; end
end
endmodule
`default_nettype wire
