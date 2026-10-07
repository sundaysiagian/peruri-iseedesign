// Receive UART -> check frame/CRC -> GPIO latch and rate-limited audible beep.
// GPIO_TYPE 0x10 is a NEW application convention, not identified device semantics.
// Buzzer output is a LOGIC CONTROL signal; use the board's suitable driver.
module uart_gpio_buzzer_demo #(
    parameter integer CLK_HZ=50000000,
    parameter integer BAUD=1000000,
    parameter integer MAX_PAYLOAD=32,
    parameter integer BEEP_MS=80,
    parameter integer COOLDOWN_MS=1000,
    parameter integer TONE_HZ=2000,
    parameter integer PASSIVE_BUZZER=1,
    parameter integer FILTER_TYPE=0,
    parameter [7:0] BEEP_TYPE=8'h00,
    parameter [7:0] GPIO_TYPE=8'h10
)(
    input wire clk, input wire rst, input wire uart_rx,
    output wire buzzer_pin, output wire led_activity,
    output reg [7:0] gpio_bits,
    output wire packet_ok, output wire packet_error,
    output reg [31:0] packet_count, output reg [31:0] error_count
);
    localparam integer BEEP_TICKS=(CLK_HZ/1000)*BEEP_MS;
    localparam integer COOL_TICKS=(CLK_HZ/1000)*COOLDOWN_MS;
    localparam integer TONE_HALF=CLK_HZ/(2*TONE_HZ);
    wire [7:0] byte_data,msg_type,length;
    wire byte_valid,framing_error;
    wire [MAX_PAYLOAD*8-1:0] payload;
    integer beep_left,cool_left,activity_left,tone_count;
    reg tone;
    assign led_activity=(activity_left>0);
    assign buzzer_pin=(beep_left>0) && ((PASSIVE_BUZZER!=0)?tone:1'b1);
    uart_rx_8n1 #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) uart(
        .clk(clk),.rst(rst),.rx(uart_rx),.data(byte_data),
        .valid(byte_valid),.framing_error(framing_error));
    com9_packet_rx #(.MAX_PAYLOAD(MAX_PAYLOAD),.TIMEOUT_CYCLES(CLK_HZ/500)) parser(
        .clk(clk),.rst(rst),.byte_data(byte_data),.byte_valid(byte_valid),
        .framing_error(framing_error),.msg_type(msg_type),.length(length),.payload(payload),
        .packet_valid(packet_ok),.packet_error(packet_error));
    always @(posedge clk) begin
        if(rst) begin
            beep_left<=0; cool_left<=0; activity_left<=0;
            tone_count<=0; tone<=0; gpio_bits<=0; packet_count<=0; error_count<=0;
        end else begin
            if(beep_left>0) beep_left<=beep_left-1;
            if(cool_left>0) cool_left<=cool_left-1;
            if(activity_left>0) activity_left<=activity_left-1;
            if(beep_left>0) begin
                if(tone_count>=TONE_HALF-1) begin tone_count<=0; tone<=!tone; end
                else tone_count<=tone_count+1;
            end else begin tone_count<=0; tone<=0; end
            if(packet_error) error_count<=error_count+1;
            if(packet_ok) begin
                packet_count<=packet_count+1;
                activity_left<=BEEP_TICKS;
                if(msg_type==GPIO_TYPE && length==1) gpio_bits<=payload[7:0];
                if((FILTER_TYPE==0 || msg_type==BEEP_TYPE) && cool_left==0 && beep_left==0) begin
                    beep_left<=BEEP_TICKS; cool_left<=COOL_TICKS;
                    tone_count<=0; tone<=0;
                end
            end
        end
    end
endmodule
