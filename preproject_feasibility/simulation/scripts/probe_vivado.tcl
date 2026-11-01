set root [file normalize [file join [file dirname [info script]] ../..]]
cd $root
set fp [open evidence/environment/vivado_probe.txt w]
puts $fp [version]
puts $fp "LICENSE_PROOF: synthesis is checked in build stage, not inferred from installation."
foreach part {xc7z010clg400-1 xc7z020clg400-2} {
  create_project -in_memory -part $part
  read_verilog simulation/rtl/probe_top.v
  synth_design -top probe_top -part $part
  puts $fp "PART $part: [get_parts $part]"
  set f [open evidence/environment/pins_${part}.tsv w]
  puts $f "PIN\tFUNCTION\tBANK\tCLOCK_CAPABLE"
  foreach p [get_package_pins] {
    set name [get_property NAME $p]
    set fun [get_property PIN_FUNC $p]
    if {[regexp {MRCC|SRCC} $fun] || $name in {N18 U18 H16 J18 K18 U19 E7 E19 K17 H17 L16 U14}} {
      puts $f "$name\t$fun\t[get_property BANK $p]\t[get_property IS_CLK_CAPABLE $p]"
    }
  }
  close $f
  close_project
}
close $fp
exit
