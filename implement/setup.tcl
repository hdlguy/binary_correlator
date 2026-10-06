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

# ILA for the hardware test, clocked at 150 MHz with two 300 MHz cycles per sample
# (see source/top.sv). probe0/probe1 = correlator {tlast, tvalid, tdata[15:0]} lanes 0/1,
# probe2 = datagen {tlast, tvalid, tdata} x 2 lanes. A BASIC license allows at most
# 5 probes, so the signals are packed. Storage qualification lets a capture keep only
# valid samples.
create_ip -name ila -vendor xilinx.com -library ip -module_name top_ila
set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES      3 \
    CONFIG.C_PROBE0_WIDTH       18 \
    CONFIG.C_PROBE1_WIDTH       18 \
    CONFIG.C_PROBE2_WIDTH       6 \
    CONFIG.C_DATA_DEPTH         8192 \
    CONFIG.C_EN_STRG_QUAL       1 \
    CONFIG.C_INPUT_PIPE_STAGES  1 \
] [get_ips top_ila]
generate_target {all} [get_ips top_ila]

read_verilog -sv ../source/correlator/template_pkg.sv
read_verilog -sv ../source/correlator/correlator.sv
read_verilog -sv ../source/datagen/datagen.sv
read_verilog -sv ../source/top.sv
add_files ../source/datagen/lidar_record.mem
set_property top top [current_fileset]

add_files -fileset sim_1 ../source/correlator/correlator_tb.sv
set_property top correlator_tb [get_filesets sim_1]

read_xdc ../source/top.xdc

close_project


