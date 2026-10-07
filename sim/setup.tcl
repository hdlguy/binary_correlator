# This script sets up a Vivado project with all ip references resolved.
close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs
#
create_project -force proj 
set_property part xc7a100ticsg324-1L [current_project]
set_property target_language verilog [current_project]
set_property default_lib work [current_project]

#reset_target all [get_files *.xci]
#upgrade_ip -quiet  [get_ips *]
#generate_target {all} [get_ips *]

read_verilog -sv ../source/correlator/template_pkg.sv
read_verilog -sv ../source/correlator/correlator.sv
read_verilog -sv ../source/correlator/correlator_tb.sv

add_files -fileset sim_1 -norecurse ./correlator_tb_behav.wcfg

close_project


