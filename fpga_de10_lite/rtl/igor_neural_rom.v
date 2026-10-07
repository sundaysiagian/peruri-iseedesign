// William Anthony
// 13223048
// ISeeDesignITB
`timescale 1ns/1ps
`default_nettype none
module igor_neural_rom #(parameter FILE="../assets/neural_24_64_64_4/bram_unified_weights_padded.mem")(
 input wire clk,input wire [12:0] address,output reg signed [15:0] data);
(* ramstyle="M9K" *) reg [15:0] memory [0:8191];
// Supported FPGA ROM initialization; not a run-time initial state machine.
initial $readmemh(FILE,memory);
always @(posedge clk) if(address<13'd6020)data<=memory[address];else data<=16'd0;
endmodule
`default_nettype wire
