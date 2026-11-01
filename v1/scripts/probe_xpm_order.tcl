set root [file normalize [file join [file dirname [info script]] ../..]]
set tag [lindex $argv 0]
set order [lindex $argv 1]
set od "$root/v1/verification/evidence/$tag"
file mkdir $od
file mkdir "$root/v1/work/$tag"
cd "$root/v1/work/$tag"
set_param general.maxThreads 4
create_project -in_memory -part xc7z010clg400-1
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
read_verilog -sv [glob $root/v1/rtl/*/*.sv]
if {$order eq "early"} {read_xdc "$root/v1/constraints/common_clocks.xdc"}
synth_design -top tf_node_top -part xc7z010clg400-1 -mode out_of_context
if {$order eq "late"} {read_xdc "$root/v1/constraints/common_clocks.xdc"}
read_xdc "$root/v1/constraints/logical_interfaces.xdc"
write_xdc -force "$od/effective_synth.xdc"
report_clocks -file "$od/clocks.rpt"
report_exceptions -file "$od/exceptions.rpt"
report_clock_interaction -file "$od/clock_interaction_synth.rpt"
set f [open "$od/gray_clock_objects.tsv" w]
puts $f "SOURCE\tDESTINATION\tSOURCE_CLOCK\tSOURCE_PERIOD\tDEST_CLOCK\tDEST_PERIOD"
foreach c [get_cells -hier -filter {NAME =~ *src_gray_ff_reg*}] {
 set sc [get_clocks -quiet -of_objects [get_pins -of_objects $c -filter {REF_PIN_NAME==C}]]
 set nets [all_fanout -flat -endpoints_only -from [get_pins -of_objects $c -filter {REF_PIN_NAME==Q}]]
 foreach d $nets {
  if {[string match *dest_graysync_ff_reg* $d]} {
   set dc [get_clocks -quiet -of_objects [get_pins -of_objects [get_cells -of_objects $d] -filter {REF_PIN_NAME==C}]]
   puts $f "$c\t$d\t$sc\t[get_property -quiet PERIOD $sc]\t$dc\t[get_property -quiet PERIOD $dc]"
  }
 }
}
close $f
if {$order eq "early"} {
 opt_design
 place_design
 phys_opt_design
 route_design
 report_bus_skew -file "$od/bus_skew.rpt"
 report_timing_summary -delay_type min_max -file "$od/timing.rpt"
 report_exceptions -file "$od/exceptions_routed.rpt"
 report_cdc -details -file "$od/cdc.rpt"
 write_xdc -force "$od/effective_routed.xdc"
 write_checkpoint -force "$od/routed.dcp"
}
exit
