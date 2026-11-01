create_clock -name MAX10_CLK_50 -period 20.000 [get_ports {MAX10_CLK_50}]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY0 SW* SIGNAL_IN}]
set_false_path -to   [get_ports {HEX* LEDR* TEST_OUT}]