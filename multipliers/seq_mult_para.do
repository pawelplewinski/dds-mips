echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim
echo "DO: Starting compilation."
# -- Compile 
vcom seq_mult_para.vhd
echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.seq_mult_para(shift_add_better_arch)
#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-literal -unsigned {sim:/seq_mult_para/WIDTH      } \
-literal -unsigned {sim:/seq_mult_para/C_WIDTH    } \
-literal -unsigned {sim:/seq_mult_para/C_INIT     } \
-logic {sim:/seq_mult_para/clk                    } \
-logic {sim:/seq_mult_para/reset                  } \
-logic {sim:/seq_mult_para/start                  } \
-logic {sim:/seq_mult_para/rdy                    } \
-literal -unsigned {sim:/seq_mult_para/a_in       } \
-literal -unsigned {sim:/seq_mult_para/b_in       } \
-literal -unsigned {sim:/seq_mult_para/res        } \
-literal -unsigned {sim:/seq_mult_para/state_reg  } \
-literal -unsigned {sim:/seq_mult_para/state_next } \
-literal -unsigned {sim:/seq_mult_para/a_reg      } \
-literal -unsigned {sim:/seq_mult_para/a_next     } \
-literal -unsigned {sim:/seq_mult_para/n_reg      } \
-literal -unsigned {sim:/seq_mult_para/n_next     } \
-literal -unsigned {sim:/seq_mult_para/p_reg      } \
-literal -unsigned {sim:/seq_mult_para/p_next     } \
-literal -unsigned {sim:/seq_mult_para/pl_reg     } \
-literal -unsigned {sim:/seq_mult_para/pu_reg     } \
-literal -unsigned {sim:/seq_mult_para/pu_next    }

force -freeze sim:/seq_mult_para/reset 1 0, 0 {50 ns}
force -freeze sim:/seq_mult_para/clk 1 0, 0 {50000 ps} -r {100 ns}
force -freeze sim:/seq_mult_para/start 0 0, 1 {150 ns}
force -freeze sim:/seq_mult_para/a_in 00000000000000000000000000000011 0
force -freeze sim:/seq_mult_para/b_in 00000000000000000000000000000101 0
run {3500 ns}