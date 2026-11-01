# CANDIDATE_DIGITAL_PROFILE:4/8-bit SDR50, centre-aligned forwarded clock.
create_generated_clock -name tx50 -source [get_pins transmitter/clkout/forward_oddr/C] -divide_by 1 -invert [get_ports tx_clock]
# External sender changes data at forwarded falling; receiver captures rising.
# Sender data-vs-clock launch offset -1..2ns plus allowed relative path skew +/-1ns.
set_input_delay -clock rx50 -clock_fall -max 3.0 [get_ports {rx_data[*] rx_valid rx_sof}]
set_input_delay -clock rx50 -clock_fall -min -2.0 [get_ports {rx_data[*] rx_valid rx_sof}]
# RX ready is held FRAME CREDIT through an XPM synchronizer at the peer. The
# source reserves a whole frame and waits for a low->high acknowledgement.
# Driver settles within one RX cycle (2ns external reserve), not a half-cycle
# combinational beat-ready deadline. Old half-cycle profile remains adapter01/02.
set_output_delay -clock rx50 -max 2.0 [get_ports rx_ready]
set_output_delay -clock rx50 -min -1.5 [get_ports rx_ready]
set_output_delay -clock tx50 -max 2.0 [get_ports {tx_data[*] tx_valid tx_sof}]
set_output_delay -clock tx50 -min -1.5 [get_ports {tx_data[*] tx_valid tx_sof}]
# Return FRAME CREDIT enters only the scoped XPM first-stage synchronizer;
# subsequent stages are timed.1..5ns is an illustrative transport offset, not
# a per-beat deadline and does not constrain/claim physical cable flight.
set_input_delay -clock tx50 -max 5.0 [get_ports tx_ready]
set_input_delay -clock tx50 -min 1.0 [get_ports tx_ready]
# Management source launches falling, local capture rising, host MISO capture falling.
set_input_delay -clock control25 -clock_fall -max 3.0 [get_ports {control_cs_n control_mosi}]
set_input_delay -clock control25 -clock_fall -min 0.5 [get_ports {control_cs_n control_mosi}]
set_output_delay -clock control25 -clock_fall -max 2.0 [get_ports {control_miso control_ready}]
set_output_delay -clock control25 -clock_fall -min -1.5 [get_ports {control_miso control_ready}]
set_input_delay -clock reference50 -clock_fall -max 3.0 [get_ports {sync_marker marker_qualified arst}]
set_input_delay -clock reference50 -clock_fall -min 0.5 [get_ports {sync_marker marker_qualified arst}]
set_output_delay -clock reference50 -max 2.0 [get_ports {event_out fault_out}]
set_output_delay -clock reference50 -min -1.5 [get_ports {event_out fault_out}]
