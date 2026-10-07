create_clock -name clk50 -period 20.000 [get_ports FPGA_CLK1_50]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*] UART_RX}]
set_false_path -to [get_ports {UART_TX LED[*]}]
