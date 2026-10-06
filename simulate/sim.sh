#!/bin/bash
# Run the testbenches in xsim.
#   ./sim.sh            # correlator_tb at 127 and 1023 taps, then datagen_tb
#   ./sim.sh 1023       # correlator_tb at one tap count only
#   ./sim.sh datagen    # datagen_tb only
# Requires Vivado settings64.sh to be sourced.
set -e
cd "$(dirname "$0")"

SRC=../source
TESTS=${@:-127 1023 datagen}

xvlog -sv $SRC/correlator/template_pkg.sv $SRC/correlator/correlator.sv $SRC/correlator/correlator_tb.sv \
          $SRC/datagen/datagen.sv $SRC/datagen/datagen_tb.sv > xvlog.out || { cat xvlog.out; exit 1; }

status=0
for t in $TESTS; do
    if [ "$t" = datagen ]; then
        xelab -debug typical -s tb_$t datagen_tb > xelab_$t.out || { cat xelab_$t.out; exit 1; }
    else
        xelab -debug typical -generic_top "N_TAPS=$t" -s tb_$t correlator_tb > xelab_$t.out || { cat xelab_$t.out; exit 1; }
    fi
    xsim tb_$t -R | tee xsim_$t.out | grep -E "_tb:|ok$|done$|full_rate=|Error|FAILED|PASSED"
    grep -q "TEST PASSED" xsim_$t.out || status=1
done
exit $status
