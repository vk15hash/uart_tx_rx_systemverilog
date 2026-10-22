read_verilog -sv {baud_gen.sv uart_tx.sv uart_rx.sv uart_top.sv}
synth_design -top uart_top -part xc7a35tcpg236-1 -mode out_of_context
create_clock -period 10.000 -name clk [get_ports clk]
report_utilization -file util_synth.rpt
opt_design
place_design
route_design
report_utilization -hierarchical -file util_impl.rpt
report_timing_summary -file timing.rpt
check_timing -file check_timing.rpt