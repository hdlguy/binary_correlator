#!/bin/bash
# Run the correlator testbench in xsim.
#   ./sim.sh            # 127-tap and 1023-tap configurations
#   ./sim.sh 1023       # one configuration
# Requires Vivado settings64.sh to be sourced.
set -e
cd "$(dirname "$0")"

SRC=../source/correlator
TAPS=${@:-127 1023}

xvlog -sv $SRC/template_pkg.sv $SRC/correlator.sv $SRC/correlator_tb.sv > xvlog.out || { cat xvlog.out; exit 1; }

status=0
for n in $TAPS; do
    xelab -debug typical -generic_top "N_TAPS=$n" -s tb_$n correlator_tb > xelab_$n.out || { cat xelab_$n.out; exit 1; }
    xsim tb_$n -R | tee xsim_$n.out | grep -E "correlator_tb|ok$|done$|Error|FAILED|PASSED"
    grep -q "TEST PASSED" xsim_$n.out || status=1
done
exit $status
