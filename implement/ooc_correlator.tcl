# Out-of-context synthesis, place and route of the correlator alone, to check timing
# at 300 MHz and resource use. Non-project mode; results in ./results_ooc/.
#   vivado -mode batch -source ooc_correlator.tcl [-tclargs N_TAPS]
set n_taps [expr {[llength $argv] > 0 ? [lindex $argv 0] : 1023}]
set part   xc7a100tcsg324-1
set out    ./results_ooc
file mkdir $out

read_verilog -sv ../source/correlator/template_pkg.sv
read_verilog -sv ../source/correlator/correlator.sv
read_xdc -mode out_of_context ../source/correlator/correlator_ooc.xdc

synth_design -top correlator -part $part -mode out_of_context -generic N_TAPS=$n_taps
opt_design
place_design
phys_opt_design
route_design

report_timing_summary -file $out/timing_$n_taps.rpt
report_utilization    -file $out/utilization_$n_taps.rpt
puts "N_TAPS=$n_taps WNS=[get_property SLACK [get_timing_paths -max_paths 1 -setup]] WHS=[get_property SLACK [get_timing_paths -max_paths 1 -hold]]"
