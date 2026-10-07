create_clock -name clk50 -period 20.000 [get_ports {FPGA_CLK1_50}]
derive_clock_uncertainty
# Async RX to the first synchronization register only.
set_false_path -from [get_ports {UART_RX}] -to [get_registers {*|rx_meta}]
set_false_path -from [get_ports {KEY0_N}]
# Outputs control LEDs/static GPIO/buzzer; no externally clocked receiver specified.
