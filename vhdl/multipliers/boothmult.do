echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim
echo "DO: Starting compilation."
# -- Compile 
vcom boothmult.vhd
vcom boothtest.vhd
echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.boothtest(test_arch)
#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic {sim:/boothtest/inst/start                  } \
-literal -dec {sim:/boothtest/a_in       } \
-literal -dec {sim:/boothtest/b_in       } \
-literal -dec {sim:/boothtest/res        }

run {100 ns}