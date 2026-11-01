# Primary timing constraints must be available DURING synthesis for XPM Tcl.
create_clock -name reference50 -period 20 [get_ports ref_in]
create_clock -name monitor50 -period 20 [get_ports monitor_in]
create_clock -name rx50 -period 20 [get_ports rx_clock]
create_clock -name control25 -period 40 [get_ports control_clock]
