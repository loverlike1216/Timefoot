set root [file normalize [file join [file dirname [info script]] ../..]]
set tag [lindex $argv 0]
set lanes [lindex $argv 1]
if {$lanes eq ""} {set lanes 4}
set out "$root/v1/verification/evidence/$tag"
file mkdir $out
file mkdir "$root/v1/work/$tag"
cd "$root/v1/work/$tag"
set_param general.maxThreads 4
foreach part {xc7z010clg400-1 xc7z020clg400-2} {
 set od "$out/$part";file mkdir $od
 create_project -in_memory -part $part
 set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
 read_verilog -sv [glob $root/v1/rtl/*/*.sv]
 read_xdc "$root/v1/constraints/adapter_clocks.xdc"
 synth_design -top tf_physical_node_top -generic LANES=$lanes -part $part
 read_xdc "$root/v1/constraints/adapter_interfaces.xdc"
 if {$part eq "xc7z010clg400-1"} {set refpin H16;set monpin N18;set rxpin J18;set ctlpin K17} else {set refpin U14;set monpin U18;set rxpin H16;set ctlpin J18}
 foreach {port ball} [list ref_in $refpin monitor_in $monpin rx_clock $rxpin control_clock $ctlpin] {set_property PACKAGE_PIN $ball [get_ports $port]}
 # Connector-feasible conditional map: EBAZ community DATA1/2/3 schematic
 # cross-checked against its XDC, plus AX7020 original J10/J11 tables.
 foreach {port ball} {tx_clock H17 tx_valid A20 tx_sof B19 tx_ready B20 rx_valid H20 rx_sof J20 rx_ready K18 control_cs_n M18 control_mosi M17 control_miso D20 control_ready D19 sync_marker H18 marker_qualified E19 arst C20 event_out K19 fault_out J19} {
  set_property PACKAGE_PIN $ball [get_ports $port]
 }
 set txpins {F20 F19 G20 G19 L17 L16 N17 P18}
 if {$part eq "xc7z010clg400-1"} {set rxpins {L20 L19 M20 M19 N20 P20 R18 R19}} else {set rxpins {L20 L19 M20 M19 W19 W18 R14 P14}}
 for {set i 0} {$i<$lanes} {incr i} {
  set_property PACKAGE_PIN [lindex $txpins $i] [get_ports [format {tx_data[%d]} $i]]
  set_property PACKAGE_PIN [lindex $rxpins $i] [get_ports [format {rx_data[%d]} $i]]
 }
 # CANDIDATE_PIN_MAPPING only. Community revision vs actual boards UNVERIFIED.
 set_property IOSTANDARD LVCMOS33 [get_ports *]
 set ioc [get_cells -hier -quiet -filter {NAME =~ *management/ready_reg || NAME =~ *fault_out_reg || NAME =~ *core/scheduler/event_execute_reg}]
 if {[llength $ioc]>0} {set_property IOB TRUE $ioc}
 report_cdc -details -file "$od/cdc_synth.rpt"
 write_xdc -force "$od/effective_synth.xdc"
 report_exceptions -file "$od/exceptions_synth.rpt"
 opt_design
 place_design
 phys_opt_design
 route_design
 report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file "$od/timing.rpt"
 report_timing -delay_type max -max_paths 20 -file "$od/setup_paths.rpt"
 report_timing -delay_type min -max_paths 20 -file "$od/hold_paths.rpt"
 report_timing -from [all_registers] -to [all_registers] -delay_type max -max_paths 10 -file "$od/internal_setup.rpt"
 report_timing -from [all_registers] -to [all_registers] -delay_type min -max_paths 10 -file "$od/internal_hold.rpt"
 report_bus_skew -file "$od/bus_skew.rpt"
 report_clock_interaction -file "$od/clock_interaction.rpt"
 report_cdc -details -file "$od/cdc.rpt"
 report_drc -file "$od/drc.rpt"
 report_methodology -file "$od/methodology.rpt"
 report_utilization -file "$od/utilization.rpt"
 report_route_status -file "$od/route.rpt"
 report_clocks -file "$od/clocks.rpt"
 report_io -file "$od/io.rpt"
 report_datasheet -file "$od/datasheet.rpt"
 report_exceptions -file "$od/exceptions.rpt"
 report_exceptions -coverage -file "$od/exceptions_coverage.rpt"
 report_exceptions -ignored -file "$od/ignored_exceptions.rpt"
 check_timing -verbose -file "$od/constraint_coverage.rpt"
 write_xdc -force "$od/effective.xdc"
 write_checkpoint -force "$od/routed.dcp"
 close_project
}
exit
