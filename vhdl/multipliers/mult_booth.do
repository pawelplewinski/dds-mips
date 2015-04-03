echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim
echo "DO: Starting compilation."
# -- Compile 
vcom mult_booth.vhd
echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.mult_booth(booth_behav)
#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic {sim:/mult_booth/clk                    } \
-logic {sim:/mult_booth/reset                  } \
-logic {sim:/mult_booth/start                  } \
-logic {sim:/mult_booth/rdy                    } \
-literal -unsigned {sim:/mult_booth/a_in       } \
-literal -unsigned {sim:/mult_booth/b_in       } \
-literal -unsigned {sim:/mult_booth/res        }

force -freeze sim:/mult_booth/reset 1 0, 0 {50 ns}
force -freeze sim:/mult_booth/clk 1 0, 0 {50000 ps} -r {100 ns}
force -freeze sim:/mult_booth/start 0 0, 1 {150 ns}
force -freeze sim:/mult_booth/a_in 00000000000000000000000000000011 0
force -freeze sim:/mult_booth/b_in 00000000000000000000000000000101 0
run {3700 ns}