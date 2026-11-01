# CANDIDATE_INTERFACE_TIMING: logical single-node OOC integration only.
create_clock -name reference50 -period 20.0 [get_ports ref_in]
create_clock -name monitor50 -period 20.0 [get_ports monitor_in]
create_clock -name rx100 -period 10.0 [get_ports rx_clock]
# Work clock is automatically derived from MMCME2_BASE, never redefined.
