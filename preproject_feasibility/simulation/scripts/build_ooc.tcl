set root [file normalize [file join [file dirname [info script]] ../..]]
cd $root
set_param general.maxThreads 4
foreach part {xc7z010clg400-1 xc7z020clg400-2} {
 set out "$root/evidence/timing_reports/$part"
 file mkdir $out
 create_project -in_memory -part $part
 read_verilog -sv [glob simulation/rtl/*.sv]
 synth_design -top eval_node_top -part $part -mode out_of_context
 create_clock -name ref50 -period 20.0 [get_ports ref_clk]
 create_clock -name monitor100 -period 10.0 [get_ports mon_clk]
 # Physical clocks synthesized by actual primitive and propagated by Vivado.
 create_generated_clock -name work50 -source [get_ports ref_clk] -multiply_by 1 [get_pins c/b0/O]
 create_generated_clock -name work100 -source [get_ports ref_clk] -multiply_by 2 [get_pins c/b1/O]
 create_generated_clock -name work150 -source [get_ports ref_clk] -multiply_by 3 [get_pins c/b2/O]
 set_input_delay 2.0 -clock work50 [get_ports {enable sync_in arm epoch[*] event_time[*]}]
 set_input_delay 2.0 -clock work100 [get_ports {din[*] vin}]
 set_input_delay 2.0 -clock work150 [get_ports rout]
 set_output_delay 2.0 -clock work150 [get_ports {dout[*] vout}]
 set_output_delay 2.0 -clock work100 [get_ports rin]
 set_output_delay 2.0 -clock work50 [get_ports {ticks[*] errors[*] event_out active}]
 # Deliberately no broad clock groups / false paths. Expose unresolved CDC and reset timing.
 set_input_delay 2.0 -clock work50 [get_ports reset_n]
 report_utilization -file "$root/evidence/resource_reports/${part}_synth.rpt"
 report_clock_interaction -file "$out/clock_interaction_synth.rpt"
 report_cdc -details -file "$out/cdc_synth.rpt"
 opt_design
 place_design
 phys_opt_design
 route_design
 report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file "$out/timing_summary_routed.rpt"
 report_utilization -file "$root/evidence/resource_reports/${part}_routed.rpt"
 report_clock_interaction -file "$out/clock_interaction_routed.rpt"
 report_cdc -details -file "$out/cdc_routed.rpt"
 report_drc -file "$out/drc_routed.rpt"
 report_route_status -file "$out/route_status.rpt"
 report_clocks -file "$out/clocks.rpt"
 check_timing -verbose -file "$out/check_timing.rpt"
 write_checkpoint -force "$out/eval_node_routed.dcp"
 close_project
}
exit
