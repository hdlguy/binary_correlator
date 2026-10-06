# top.xdc -- Arty A7-100T pins and timing for top.sv

# 100 MHz oscillator; the MMCM output clock (300 MHz) is derived automatically
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports clk100]
create_clock -name clk100 -period 10.000 [get_ports clk100]

# red RESET button (active low) and switch SW0
set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports ck_rst_n]
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {sw[0]}]

# green LEDs LD4..LD7
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

# button, switch and LEDs are asynchronous to every clock
set_false_path -from [get_ports {ck_rst_n sw[0]}]
set_false_path -to   [get_ports {led[*]}]

# configuration
set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# debug hub (inserted for the ILA) runs on the 150 MHz ILA clock; let it divide that down
# internally so its JTAG logic meets timing (UG908, ILA Core and Timing Considerations)
set_property C_CLK_INPUT_FREQ_HZ 150000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER true     [get_debug_cores dbg_hub]
