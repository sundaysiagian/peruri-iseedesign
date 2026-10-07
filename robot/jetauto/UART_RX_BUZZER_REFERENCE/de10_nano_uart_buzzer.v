// DE10-Nano standalone demo. KEY0_N is the FPGA KEY[0] button, active low.
module de10_nano_uart_buzzer #(
    parameter integer PASSIVE_BUZZER=1
)(
    input wire FPGA_CLK1_50, input wire KEY0_N, input wire UART_RX,
    output wire BUZZER_CTRL, output wire [7:0] GPIO_MASK_OUT,
    output wire [5:0] LED
);
    (* ASYNC_REG="TRUE" *) reg [1:0] reset_pipe=2'b11;
    always @(posedge FPGA_CLK1_50 or negedge KEY0_N) begin
        if(!KEY0_N) reset_pipe<=2'b11;
        else reset_pipe<={reset_pipe[0],1'b0};
    end
    wire rst=reset_pipe[1];
    wire packet_ok,packet_error,activity;
    wire [31:0] packet_count,error_count;
    reg error_seen;
    always @(posedge FPGA_CLK1_50) begin
        if(rst) error_seen<=0;
        else if(packet_error) error_seen<=1;
    end
    uart_gpio_buzzer_demo #(.PASSIVE_BUZZER(PASSIVE_BUZZER)) demo(
        .clk(FPGA_CLK1_50),.rst(rst),.uart_rx(UART_RX),
        .buzzer_pin(BUZZER_CTRL),.led_activity(activity),.gpio_bits(GPIO_MASK_OUT),
        .packet_ok(packet_ok),.packet_error(packet_error),
        .packet_count(packet_count),.error_count(error_count));
    assign LED={GPIO_MASK_OUT[3:0],error_seen,activity};
endmodule
