// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_score_accumulator(input wire [31:0] prior,increment,
 output wire [31:0] total, output wire overflow);
wire [32:0] wide={1'b0,prior}+{1'b0,increment};
assign total=wide[31:0]; assign overflow=wide[32];
endmodule
`default_nettype wire
