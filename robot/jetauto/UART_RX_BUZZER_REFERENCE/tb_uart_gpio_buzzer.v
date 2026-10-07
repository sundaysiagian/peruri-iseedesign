`timescale 1ns/1ps
module tb_uart_gpio_buzzer;
    reg clk=0;
    always #10 clk=~clk;
    reg rst=1,rx=1;
    wire buzzer,activity,ok,err;
    wire [7:0] gpio;
    wire [31:0] packets,errors;
    wire passive_pin,filtered_pin;
    integer starts=0,tone_edges=0;
    integer previous_beep=0;
    reg previous_tone=0;
    reg [7:0] capture[0:3711];
    integer i,old_starts,old_errors;
    uart_gpio_buzzer_demo #(.BEEP_MS(1),.COOLDOWN_MS(3),.PASSIVE_BUZZER(0)) dut(
        .clk(clk),.rst(rst),.uart_rx(rx),.buzzer_pin(buzzer),.led_activity(activity),
        .gpio_bits(gpio),.packet_ok(ok),.packet_error(err),.packet_count(packets),.error_count(errors));
    uart_gpio_buzzer_demo #(.BEEP_MS(1),.COOLDOWN_MS(3),.PASSIVE_BUZZER(1)) passive(
        .clk(clk),.rst(rst),.uart_rx(rx),.buzzer_pin(passive_pin));
    uart_gpio_buzzer_demo #(.BEEP_MS(1),.COOLDOWN_MS(3),.PASSIVE_BUZZER(0),.FILTER_TYPE(1)) filtered(
        .clk(clk),.rst(rst),.uart_rx(rx),.buzzer_pin(filtered_pin));
    always @(negedge clk) begin
        if(!rst) begin
            if(dut.beep_left>0 && previous_beep==0) starts=starts+1;
            if(passive_pin!=previous_tone) tone_edges=tone_edges+1;
        end
        previous_beep=dut.beep_left;
        previous_tone=passive_pin;
    end
    task send_byte;
        input [7:0] value;
        input integer bit_ns;
        input integer bad_stop;
        integer j;
        begin
            rx=0; #(bit_ns);
            for(j=0;j<8;j=j+1) begin rx=value[j]; #(bit_ns); end
            rx=bad_stop?0:1; #(bit_ns); rx=1;
        end
    endtask
    task gpio_frame;
        input integer crc_bad;
        input integer bit_ns;
        begin
            send_byte(8'haa,bit_ns,0); send_byte(8'h55,bit_ns,0);
            send_byte(8'h10,bit_ns,0); send_byte(1,bit_ns,0);
            send_byte(8'ha5,bit_ns,0); send_byte(crc_bad?8'h1f:8'h1e,bit_ns,0);
            #200;
        end
    endtask
    initial begin
        $readmemh("com9_capture.hex",capture);
        repeat(5) @(negedge clk); rst=0; #73; // asynchronous byte phase
        gpio_frame(0,1000);
        if(packets!=1 || gpio!=8'ha5 || !buzzer || !activity)
            $fatal(1,"Valid frame did not update GPIO/beep");
        if(filtered_pin || filtered.beep_left!=0) $fatal(1,"TYPE filter failed");
        #1100000;
        if(buzzer) $fatal(1,"Beep did not end after 1ms");
        if(tone_edges<3) $fatal(1,"Passive tone missing");
        gpio_frame(0,980); // 2% faster sender, cooldown suppresses second beep
        if(packets!=2 || starts!=1) $fatal(1,"Cooldown or fast baud failed");
        #3000000;
        old_starts=starts;
        gpio_frame(1,1000);
        if(packets!=2 || errors!=1 || gpio!=8'ha5 || starts!=old_starts || buzzer)
            $fatal(1,"Bad CRC triggered an output");
        gpio_frame(0,1040); // 4% slower sender
        if(packets!=3 || starts!=old_starts+1) $fatal(1,"Slow baud or retrigger failed");
        // CRC-valid packet containing AA 55 inside payload, not a GPIO write.
        send_byte(8'haa,1000,0); send_byte(8'h55,1000,0);
        send_byte(8'h11,1000,0); send_byte(2,1000,0);
        send_byte(8'haa,1000,0); send_byte(8'h55,1000,0);
        send_byte(8'h15,1000,0); #200;
        if(packets!=4 || gpio!=8'ha5) $fatal(1,"Embedded sync payload failed");
        // Empty payload.
        send_byte(8'haa,1000,0); send_byte(8'h55,1000,0);
        send_byte(9,1000,0); send_byte(0,1000,0); send_byte(8'hb2,1000,0); #200;
        if(packets!=5) $fatal(1,"Empty payload failed");
        // Over-limit length and partial-packet timeout.
        old_errors=errors;
        send_byte(8'haa,1000,0); send_byte(8'h55,1000,0);
        send_byte(0,1000,0); send_byte(33,1000,0); #200;
        if(errors!=old_errors+1) $fatal(1,"Oversize frame accepted");
        send_byte(8'haa,1000,0); send_byte(8'h55,1000,0); #2200000;
        if(errors!=old_errors+2) $fatal(1,"Partial frame timeout missing");
        send_byte(8'haa,1000,1); #2000;
        if(errors<=old_errors+2) $fatal(1,"Bad stop bit was not rejected");
        // Replay every captured byte across the physical UART RX waveform.
        for(i=0;i<3712;i=i+1) send_byte(capture[i],1000,0);
        #200;
        if(packets!=319) $fatal(1,"Captured replay: got %0d frames instead of 319",packets);
        if(gpio!=8'ha5) $fatal(1,"Telemetry unexpectedly changed GPIO");
        if(filtered.packet_count!=319 || filtered.error_count!=errors)
            $fatal(1,"Filtered receiver diverged");
        $display("PASS: 314 capture frames + 5 generated frames; GPIO atomic CRC commit; bad CRC/stop/length/timeout rejected; active/passive beep and cooldown; baud tolerance");
        $finish;
    end
    initial begin #60000000; $fatal(1,"Timeout"); end
endmodule
