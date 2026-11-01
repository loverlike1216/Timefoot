set root [file normalize [file join [file dirname [info script]] ../..]]
cd $root
set_param general.maxThreads 4
foreach {part pin} {xc7z010clg400-1 H16 xc7z020clg400-2 U14} {
 set out "$root/evidence/timing_reports/${part}_pin_probe"
 file mkdir $out
 create_project -in_memory -part $part
 read_verilog -sv {simulation/rtl/clock_tree.sv simulation/rtl/pin_clock_top.sv}
 synth_design -top pin_clock_top -part $part
 set_property PACKAGE_PIN $pin [get_ports ref_in]
 set_property PACKAGE_PIN W13 [get_ports {q[0]}]
 set_property PACKAGE_PIN V12 [get_ports {q[1]}]
 set_property PACKAGE_PIN L19 [get_ports {q[2]}]
 set_property IOSTANDARD LVCMOS33 [get_ports *]
 create_clock -name external_ref50 -period 20.0 [get_ports ref_in]
 set_output_delay 2.0 -clock external_ref50 [get_ports q*]
 opt_design
 place_design
 route_design
 report_timing_summary -delay_type min_max -report_unconstrained -file "$out/timing.rpt"
 report_drc -file "$out/drc.rpt"
 report_route_status -file "$out/route.rpt"
 report_clock_utilization -file "$out/clock_utilization.rpt"
 write_checkpoint -force "$out/pin_route.dcp"
 close_project
}
exit
