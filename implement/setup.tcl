# This script sets up a Vivado project with all ip references resolved.
# vivado -mode batch -source setup.tcl
# vivado -mode batch -source compile.tcl
close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs

create_project -force proj 
set_property part xc7a100tcsg324-1 [current_project]
set_property target_language verilog [current_project]
set_property default_lib work [current_project]
load_features ipintegrator
tclapp::install ultrafast -quiet


#read_ip ../source/iir_filter_core/iir_filter_core.xci
#upgrade_ip -quiet  [get_ips *]
#generate_target {all} [get_ips *]

read_verilog -sv ../source/correlator/template_pkg.sv
read_verilog -sv ../source/correlator/correlator.sv

add_files -fileset sim_1 ../source/correlator/correlator_tb.sv
set_property top correlator_tb [get_filesets sim_1]

read_xdc ../source/top.xdc

close_project


