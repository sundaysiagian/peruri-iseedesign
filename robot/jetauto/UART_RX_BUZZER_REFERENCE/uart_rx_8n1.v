// UART RX, 8N1, LSB first; two-register synchronization of the async input.
// valid and framing_error pulse for one clk cycle; data updates only on valid.
module uart_rx_8n1 #(
    parameter integer CLK_HZ=50000000,
    parameter integer BAUD=1000000
)(
    input wire clk, input wire rst, input wire rx,
    output reg [7:0] data, output reg valid, output reg framing_error
);
    localparam integer TICKS=(CLK_HZ+BAUD/2)/BAUD;
    localparam IDLE=0, START=1, DATA=2, STOP=3;
    (* ASYNC_REG="TRUE" *) reg rx_meta,rx_sync;
    reg [1:0] state;
    reg [2:0] bit_index;
    reg [7:0] shift;
    integer count;
    always @(posedge clk) begin
        if(rst) begin rx_meta<=1; rx_sync<=1; end
        else begin rx_meta<=rx; rx_sync<=rx_meta; end
    end
    always @(posedge clk) begin
        if(rst) begin
            state<=IDLE; count<=0; shift<=0; bit_index<=0;
            data<=0; valid<=0; framing_error<=0;
        end else begin
            valid<=0; framing_error<=0;
            case(state)
                IDLE: if(!rx_sync) begin count<=TICKS/2-1; state<=START; end
                START: if(count!=0) count<=count-1;
                    else if(rx_sync) state<=IDLE;
                    else begin count<=TICKS-1; bit_index<=0; state<=DATA; end
                DATA: if(count!=0) count<=count-1;
                    else begin
                        shift[bit_index]<=rx_sync; count<=TICKS-1;
                        if(bit_index==7) state<=STOP;
                        else bit_index<=bit_index+1'b1;
                    end
                STOP: if(count!=0) count<=count-1;
                    else begin
                        if(rx_sync) begin data<=shift; valid<=1; end
                        else framing_error<=1;
                        state<=IDLE;
                    end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
