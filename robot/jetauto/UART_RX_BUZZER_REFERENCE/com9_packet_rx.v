// Byte parser for AA 55 TYPE LEN PAYLOAD CRC8/MAXIM.
// Outputs commit atomically only after CRC succeeds. Payload byte 0 is [7:0].
// The timeout is an INTER-BYTE timeout in clk cycles, not a whole-frame limit.
module com9_packet_rx #(
    parameter integer MAX_PAYLOAD=32,
    parameter integer TIMEOUT_CYCLES=100000
)(
    input wire clk, input wire rst,
    input wire [7:0] byte_data, input wire byte_valid, input wire framing_error,
    output reg [7:0] msg_type, output reg [7:0] length,
    output reg [MAX_PAYLOAD*8-1:0] payload,
    output reg packet_valid, output reg packet_error
);
    localparam SYNC0=0,SYNC1=1,TYPE=2,LEN=3,BODY=4,CRC=5;
    reg [2:0] state;
    reg [7:0] type_buf,len_buf,index,crc_buf;
    reg [MAX_PAYLOAD*8-1:0] body_buf;
    integer idle_count;
    function [7:0] crc_update;
        input [7:0] current,value;
        reg [7:0] c;
        integer j;
        begin
            c=current^value;
            for(j=0;j<8;j=j+1) c=c[0]?((c>>1)^8'h8c):(c>>1);
            crc_update=c;
        end
    endfunction
    always @(posedge clk) begin
        if(rst) begin
            state<=SYNC0; type_buf<=0; len_buf<=0; index<=0; crc_buf<=0;
            body_buf<=0; idle_count<=0; msg_type<=0; length<=0; payload<=0;
            packet_valid<=0; packet_error<=0;
        end else begin
            packet_valid<=0; packet_error<=0;
            if(framing_error) begin state<=SYNC0; idle_count<=0; packet_error<=1; end
            else if(byte_valid) begin
                idle_count<=0;
                case(state)
                    SYNC0: if(byte_data==8'haa) state<=SYNC1;
                    SYNC1: if(byte_data==8'h55) begin state<=TYPE; crc_buf<=0; end
                        else if(byte_data!=8'haa) state<=SYNC0;
                    TYPE: begin
                        type_buf<=byte_data; crc_buf<=crc_update(0,byte_data); state<=LEN;
                    end
                    LEN: if(byte_data>MAX_PAYLOAD) begin state<=SYNC0; packet_error<=1; end
                        else begin
                            len_buf<=byte_data; index<=0; body_buf<=0;
                            crc_buf<=crc_update(crc_buf,byte_data);
                            state<=(byte_data==0)?CRC:BODY;
                        end
                    BODY: begin
                        body_buf[index*8 +: 8]<=byte_data;
                        crc_buf<=crc_update(crc_buf,byte_data);
                        index<=index+1'b1;
                        if(index==len_buf-1'b1) state<=CRC;
                    end
                    CRC: begin
                        state<=SYNC0;
                        if(byte_data==crc_buf) begin
                            msg_type<=type_buf; length<=len_buf; payload<=body_buf;
                            packet_valid<=1;
                        end else packet_error<=1;
                    end
                    default: state<=SYNC0;
                endcase
            end else if(state!=SYNC0) begin
                if(idle_count>=TIMEOUT_CYCLES-1) begin
                    state<=SYNC0; idle_count<=0; packet_error<=1;
                end else idle_count<=idle_count+1;
            end else idle_count<=0;
        end
    end
endmodule
