# Source: DE10-Nano manual PDF pages24,27; tables3-5/6/7/8 and figure3-19.
set_location_assignment PIN_V11 -to {FPGA_CLK1_50}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {FPGA_CLK1_50}
set_location_assignment PIN_AH17 -to {KEY[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {KEY[0]}
set_location_assignment PIN_AH16 -to {KEY[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {KEY[1]}
set_location_assignment PIN_Y24 -to {SW[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[0]}
set_location_assignment PIN_W24 -to {SW[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[1]}
set_location_assignment PIN_W21 -to {SW[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[2]}
set_location_assignment PIN_W20 -to {SW[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {SW[3]}
set_location_assignment PIN_W15 -to {LED[0]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[0]}
set_location_assignment PIN_AA24 -to {LED[1]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[1]}
set_location_assignment PIN_V16 -to {LED[2]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[2]}
set_location_assignment PIN_V15 -to {LED[3]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[3]}
set_location_assignment PIN_AF26 -to {LED[4]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[4]}
set_location_assignment PIN_AE26 -to {LED[5]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[5]}
set_location_assignment PIN_Y16 -to {LED[6]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[6]}
set_location_assignment PIN_AA23 -to {LED[7]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {LED[7]}
# GPIO0 JP1 pins1 and2, manual Figure3-20/Table3-9.
set_location_assignment PIN_V12 -to UART_RX
set_location_assignment PIN_E8 -to UART_TX
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_RX
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX
