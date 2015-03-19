echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim
echo "DO: Starting compilation."
# -- Compile 
vcom mult32x32.vhd
echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.mult32x32(behav)
#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic {sim:/mult32x32/clk                    } \
-logic {sim:/mult32x32/reset                  } \
-logic {sim:/mult32x32/start                  } \
-logic {sim:/mult32x32/rdy                    } \
-literal -unsigned {sim:/mult32x32/a_in       } \
-literal -unsigned {sim:/mult32x32/b_in       } \
-literal -unsigned {sim:/mult32x32/res        } \
-literal -unsigned {sim:/mult32x32/state_cnt  } \
-literal -unsigned {sim:/mult32x32/state      }

force -freeze sim:/mult32x32/reset 1 0, 0 {50 ns}
force -freeze sim:/mult32x32/clk 1 0, 0 {50000 ps} -r {100 ns}
force -freeze sim:/mult32x32/start 0 0, 1 {150 ns}
force -freeze sim:/mult32x32/a_in 00000000000000000000000000000011 0
force -freeze sim:/mult32x32/b_in 00000000000000000000000000000101 0
run {3700 ns}