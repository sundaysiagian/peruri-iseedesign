project_open igor
create_timing_netlist
read_sdc
update_timing_netlist
report_clocks -file reports/clocks.rpt
report_clock_fmax_summary -file reports/fmax.rpt
report_timing -setup -npaths 10 -detail full_path -file reports/setup.rpt
report_timing -hold -npaths 10 -detail full_path -file reports/hold.rpt
report_timing -recovery -npaths 10 -file reports/recovery.rpt
report_timing -removal -npaths 10 -file reports/removal.rpt
report_ucp -file reports/unconstrained.rpt
check_timing -file reports/check_timing.rpt
project_close
