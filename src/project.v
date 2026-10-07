// Tiny Tapeout prototype of the actual IGOR safety gate, with a register front end.
`default_nettype none
module tt_um_wlmoi_igor_gate(
 input wire [7:0] ui_in, output reg [7:0] uo_out,
 input wire [7:0] uio_in,output wire [7:0] uio_out,output wire [7:0] uio_oe,
 input wire ena,clk,rst_n);
reg [7:0] flags;
reg timeout;
reg [4:0] candidate_v,previous_v,max_v,max_dv;
reg signed [6:0] candidate_w,previous_w;
reg [6:0] max_w,max_dw;
wire motor_enable;
wire [4:0] v_command;
wire signed [6:0] omega_command;
wire [7:0] fault_code;
always @(posedge clk) begin
 if(!rst_n) begin
  flags<=0;timeout<=0;candidate_v<=0;previous_v<=0;max_v<=0;max_dv<=0;
  candidate_w<=0;previous_w<=0;max_w<=0;max_dw<=0;
 end else if(ena && ui_in[0]) case(ui_in[4:1])
  0:flags<=uio_in;
  1:timeout<=uio_in[0];
  2:candidate_v<=uio_in[4:0];
  3:previous_v<=uio_in[4:0];
  4:max_v<=uio_in[4:0];
  5:max_dv<=uio_in[4:0];
  6:candidate_w<=uio_in[6:0];
  7:previous_w<=uio_in[6:0];
  8:max_w<=uio_in[6:0];
  9:max_dw<=uio_in[6:0];
  default:begin end
 endcase
end
igor_safety_security_gate gate(rst_n,flags[0] && ena,flags[1],flags[2],flags[3],flags[4],flags[5],flags[6],flags[7],timeout,candidate_v,previous_v,max_v,max_dv,candidate_w,previous_w,max_w,max_dw,motor_enable,v_command,omega_command,fault_code);
always @(*) begin
 case(ui_in[7:5])
  0:uo_out={7'd0,motor_enable};
  1:uo_out={3'd0,v_command};
  2:uo_out={omega_command[6],omega_command};
  3:uo_out=fault_code;
  4:uo_out=flags;
  default:uo_out=0;
 endcase
end
assign uio_out=0;
assign uio_oe=0;
endmodule
`default_nettype wire
