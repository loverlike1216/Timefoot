set root [file normalize [file join [file dirname [info script]] ../..]]
set tag [lindex $argv 0]
if {$tag eq ""} {set tag "impl01"}
set mode [lindex $argv 1]
if {$mode eq ""} {set mode "node"}
set out "$root/v1/verification/evidence/$tag"
file mkdir $out
set work "$root/v1/work/$tag"
file mkdir $work
cd $work
set_param general.maxThreads 4
set files [glob -nocomplain $root/v1/rtl/*/*.sv]
foreach {part pin} {xc7z010clg400-1 H16 xc7z020clg400-2 U14} {
 set od "$out/$part"
 file mkdir $od
 create_project -in_memory -part $part
 set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
 read_verilog -sv $files
 if {$mode eq "pin"} {
  if {$pin eq "H16"} {read_xdc "$root/v1/constraints/pin_z010_candidate.xdc"} else {read_xdc "$root/v1/constraints/pin_z020_candidate.xdc"}
  synth_design -top tf_pin_timing_top -part $part
 } else {
  read_xdc "$root/v1/constraints/common_clocks.xdc"
  synth_design -top tf_node_top -part $part -mode out_of_context
  read_xdc "$root/v1/constraints/logical_interfaces.xdc"
  read_xdc "$root/v1/constraints/cdc_policy.xdc"
  # Only vendor-scoped XPM constraints are used for asynchronous crossings.
  # No blanket set_clock_groups/set_false_path is added here.
 }
 report_utilization -file "$od/utilization_synth.rpt"
 report_cdc -details -file "$od/cdc_synth.rpt"
 opt_design
 place_design
 phys_opt_design
 route_design
 report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file "$od/timing.rpt"
 report_timing -max_paths 10 -delay_type max -file "$od/critical_paths.rpt"
 report_timing -from [all_registers] -to [all_registers] -max_paths 10 -delay_type max -file "$od/internal_setup.rpt"
 report_timing -from [all_registers] -to [all_registers] -max_paths 10 -delay_type min -file "$od/internal_hold.rpt"
 report_cdc -details -file "$od/cdc.rpt"
 report_drc -file "$od/drc.rpt"
 report_clock_interaction -file "$od/clock_interaction.rpt"
 report_bus_skew -file "$od/bus_skew.rpt"
 report_methodology -file "$od/methodology.rpt"
 report_utilization -file "$od/utilization.rpt"
 report_route_status -file "$od/route.rpt"
 report_clocks -file "$od/clocks.rpt"
 check_timing -verbose -file "$od/constraint_coverage.rpt"
 write_xdc -force "$od/effective.xdc"
 write_checkpoint -force "$od/routed.dcp"
 set f [open "$od/reset_inventory.tsv" w]
 puts $f "REGISTER\tCLOCK\tASYNC_CONTROL_NET"
 foreach c [get_cells -hier -filter {IS_SEQUENTIAL==1}] {
  set cp [get_pins -quiet -of_objects $c -filter {REF_PIN_NAME==C}]
  set ap [get_pins -quiet -of_objects $c -filter {REF_PIN_NAME==CLR || REF_PIN_NAME==PRE}]
  puts $f "$c\t[get_clocks -quiet -of_objects $cp]\t[get_nets -quiet -of_objects $ap]"
 }
 close $f
 close_project
}
exit
