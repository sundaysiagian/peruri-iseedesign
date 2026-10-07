// Fixed SDK-equivalent packets. UART 8N1, 50 clocks/bit at 50 MHz.
module stm_packet_tx #(parameter CLKS_PER_BIT=50)(
 input wire clk, input wire reset, input wire start, input wire [1:0] command,
 output reg tx, output reg busy, output reg done);
 reg [1:0] selected;
 reg [4:0] index;
 reg [3:0] bit_index;
 reg [15:0] timer;
 reg [9:0] shift;
 wire [4:0] last_index = selected == 1 ? 12 : 26;
 function [7:0] rom_byte;
 input [6:0] address;
 begin
  case(address)
      7'd0: rom_byte = 8'haa;
      7'd1: rom_byte = 8'h55;
      7'd2: rom_byte = 8'h03;
      7'd3: rom_byte = 8'h16;
      7'd4: rom_byte = 8'h01;
      7'd5: rom_byte = 8'h04;
      7'd6: rom_byte = 8'h00;
      7'd7: rom_byte = 8'h00;
      7'd8: rom_byte = 8'h00;
      7'd9: rom_byte = 8'h00;
      7'd10: rom_byte = 8'h00;
      7'd11: rom_byte = 8'h01;
      7'd12: rom_byte = 8'h00;
      7'd13: rom_byte = 8'h00;
      7'd14: rom_byte = 8'h00;
      7'd15: rom_byte = 8'h00;
      7'd16: rom_byte = 8'h02;
      7'd17: rom_byte = 8'h00;
      7'd18: rom_byte = 8'h00;
      7'd19: rom_byte = 8'h00;
      7'd20: rom_byte = 8'h00;
      7'd21: rom_byte = 8'h03;
      7'd22: rom_byte = 8'h00;
      7'd23: rom_byte = 8'h00;
      7'd24: rom_byte = 8'h00;
      7'd25: rom_byte = 8'h00;
      7'd26: rom_byte = 8'h07;
      7'd32: rom_byte = 8'haa;
      7'd33: rom_byte = 8'h55;
      7'd34: rom_byte = 8'h02;
      7'd35: rom_byte = 8'h08;
      7'd36: rom_byte = 8'h6c;
      7'd37: rom_byte = 8'h07;
      7'd38: rom_byte = 8'h64;
      7'd39: rom_byte = 8'h00;
      7'd40: rom_byte = 8'h84;
      7'd41: rom_byte = 8'h03;
      7'd42: rom_byte = 8'h01;
      7'd43: rom_byte = 8'h00;
      7'd44: rom_byte = 8'h5d;
      7'd64: rom_byte = 8'haa;
      7'd65: rom_byte = 8'h55;
      7'd66: rom_byte = 8'h03;
      7'd67: rom_byte = 8'h16;
      7'd68: rom_byte = 8'h01;
      7'd69: rom_byte = 8'h04;
      7'd70: rom_byte = 8'h00;
      7'd71: rom_byte = 8'h00;
      7'd72: rom_byte = 8'h00;
      7'd73: rom_byte = 8'h80;
      7'd74: rom_byte = 8'h3f;
      7'd75: rom_byte = 8'h01;
      7'd76: rom_byte = 8'h00;
      7'd77: rom_byte = 8'h00;
      7'd78: rom_byte = 8'h80;
      7'd79: rom_byte = 8'h3f;
      7'd80: rom_byte = 8'h02;
      7'd81: rom_byte = 8'h00;
      7'd82: rom_byte = 8'h00;
      7'd83: rom_byte = 8'h80;
      7'd84: rom_byte = 8'hbf;
      7'd85: rom_byte = 8'h03;
      7'd86: rom_byte = 8'h00;
      7'd87: rom_byte = 8'h00;
      7'd88: rom_byte = 8'h80;
      7'd89: rom_byte = 8'hbf;
      7'd90: rom_byte = 8'h0d;
      7'd96: rom_byte = 8'haa;
      7'd97: rom_byte = 8'h55;
      7'd98: rom_byte = 8'h03;
      7'd99: rom_byte = 8'h16;
      7'd100: rom_byte = 8'h01;
      7'd101: rom_byte = 8'h04;
      7'd102: rom_byte = 8'h00;
      7'd103: rom_byte = 8'h00;
      7'd104: rom_byte = 8'h00;
      7'd105: rom_byte = 8'h80;
      7'd106: rom_byte = 8'hbf;
      7'd107: rom_byte = 8'h01;
      7'd108: rom_byte = 8'h00;
      7'd109: rom_byte = 8'h00;
      7'd110: rom_byte = 8'h80;
      7'd111: rom_byte = 8'hbf;
      7'd112: rom_byte = 8'h02;
      7'd113: rom_byte = 8'h00;
      7'd114: rom_byte = 8'h00;
      7'd115: rom_byte = 8'h80;
      7'd116: rom_byte = 8'h3f;
      7'd117: rom_byte = 8'h03;
      7'd118: rom_byte = 8'h00;
      7'd119: rom_byte = 8'h00;
      7'd120: rom_byte = 8'h80;
      7'd121: rom_byte = 8'h3f;
      7'd122: rom_byte = 8'h4c;
   default: rom_byte=0;
  endcase
 end
 endfunction
 always @(posedge clk) begin
  if(reset) begin tx<=1; busy<=0; done<=0; selected<=0; index<=0; bit_index<=0; timer<=0; shift<=10'h3ff; end
  else begin
   done<=0;
   if(!busy) begin
    tx<=1;
    if(start) begin
     selected<=command; index<=0; bit_index<=0; timer<=CLKS_PER_BIT-1;
     shift<={1'b1,rom_byte({command,5'd0}),1'b0}; tx<=0; busy<=1;
    end
   end else if(timer != 0) timer<=timer-1'b1;
   else begin
    timer<=CLKS_PER_BIT-1;
    if(bit_index != 9) begin shift<={1'b1,shift[9:1]}; tx<=shift[1]; bit_index<=bit_index+1'b1; end
    else if(index==last_index) begin busy<=0; done<=1; tx<=1; end
    else begin
     index<=index+1'b1; bit_index<=0;
     shift<={1'b1,rom_byte({selected,index+5'd1}),1'b0}; tx<=0;
    end
   end
  end
 end
endmodule
