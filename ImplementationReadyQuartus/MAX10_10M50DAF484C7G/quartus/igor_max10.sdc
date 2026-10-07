create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty
# Human-operated asynchronous inputs: no synchronous input timing contract.
# SW crosses two registers; constrain all subsequent internal paths normally.
set_false_path -from [get_ports {SW[*]}] -to [get_registers {*sw_meta*}]
# KEY0 async reset assertion; synchronous release through reset_sync.
set_false_path -from [get_ports {KEY[0]}]
# KEY1 is demo emergency inhibit, not a certified physical safety path.
set_false_path -from [get_ports {KEY[1]}]
# LEDs have no synchronous receiving device. Internal sources remain timed.
set_false_path -to [get_ports {LEDR[*]}]
# UART asynchronous receiver, synchronize RX before sampling.
set_false_path -from [get_ports UART_RX] -to [get_registers {*receiver*meta}]
# UART TX is a baud-timed serial output, no external synchronous capture clock.
set_false_path -to [get_ports UART_TX]

set_false_path -from [get_ports UART_RX] -to [get_registers {*rx_meta}]
