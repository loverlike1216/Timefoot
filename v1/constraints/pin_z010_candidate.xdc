# CANDIDATE_PIN_MAPPING: regression only; not board-safe wiring approval.
# H16 requires checking board peripheral ownership/VCCO before hardware use.
set_property PACKAGE_PIN H16 [get_ports ref_in]
foreach {port ball} {q[0] W13 q[1] V12 q[2] L19} {set_property PACKAGE_PIN $ball [get_ports $port]}
set_property IOSTANDARD LVCMOS33 [get_ports *]
create_clock -name reference50 -period 20.0 [get_ports ref_in]
set_output_delay 2.0 -clock reference50 [get_ports q*]
