echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim

echo "DO: Starting compilation."
# -- Compile memory [entity::mem32] [architecture::behav]
vcom mem.vhd
# -- Compile MIPS core sub-components
vcom mips32_cmp.vhd
vcom mips32_mdu.vhd
vcom mips32_alu.vhd
vcom mips32_ctrl.vhd
vcom mips32_dp.vhd
# -- Compile MIPS core [architecture::behavior] (behavioural)
vcom mips32core_arch_behav.vhd
vcom mips32core_arch_struct.vhd
# -- Compile MIPS core [entity::mips32core]
vcom mips32core.vhd
# -- Compile MIPS system [architecture::struct] (structural)
vcom mips32sys.vhd

# -- Compile clock generator
vcom clock_gen.vhd
# -- Compile testset
vcom testset.vhd

# -- Compile testbench (top entity)
vcom tb_mips.vhd

echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.tb_mips(tb_arch)

#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic   {sim:/tb_mips/tb_clk                                       } \
-logic   {sim:/tb_mips/tb_resetn                                    } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -hex   {sim:/tb_mips/gut/iram_addr_out                     } \
-literal -hex   {sim:/tb_mips/gut/imem/memory                       } \
-literal -hex   {sim:/tb_mips/gut/iram_data_inp                     } \
-literal -sym   {sim:/tb_mips/gut/cpu/state                         } \
-literal -sym   {sim:/tb_mips/dut/cpu/controller/state              } \
-literal -sym   {sim:/tb_mips/gut/cpu/exec/state_next               } \
-literal -sym   {sim:/tb_mips/gut/cpu/op_state                      } \
-literal -dec   {sim:/tb_mips/dut/cpu/controller/op_state           } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -dec   {sim:/tb_mips/gut/cpu/reg                           } \
-literal -dec   {sim:/tb_mips/dut/cpu/datapath/reg                  } \
-literal -dec   {sim:/tb_mips/dut/cpu/datapath/tnext                } \
-literal -dec   {sim:/tb_mips/dut/cpu/datapath/dnext                } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -dec   {sim:/tb_mips/gut/cpu/sreg                          } \
-literal -dec   {sim:/tb_mips/gut/cpu/treg                          } \
-literal -dec   {sim:/tb_mips/dut/cpu/datapath/treg                 } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -hex   {sim:/tb_mips/gut/dram_addr_out                     } \
-literal -hex   {sim:/tb_mips/dut/dram_addr_out                     } \
-literal -hex   {sim:/tb_mips/gut/dram_wren_out                     } \
-literal -dec   {sim:/tb_mips/dut/cpu/controller/dbus_wren_out      } \
-literal -dec   {sim:/tb_mips/gut/dram_data_out                     } \
-literal -dec   {sim:/tb_mips/dut/dram_data_out                     } \
-literal -hex   {sim:/tb_mips/gut/dram_data_inp                     } \
-literal -hex   {sim:/tb_mips/dut/dram_data_inp                     } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -hex   {sim:/tb_mips/dut/cpu/datapath/tsel                 } \
-literal -hex   {sim:/tb_mips/dut/cpu/datapath/treg                 } \
-logic   {sim:/tb_mips/tb_redline                                   } \
-literal -dec   {sim:/tb_mips/gut/dmem/memory(0)                    } \
-literal -dec   {sim:/tb_mips/dut/dmem/memory(0)                    }
 

# vsim -gui -voptargs=+acc work.mips32sys(struct)

# #restart -nolist -nowave
# # -- Add waves to simulation plot
# add wave \
   # {sim:/mips32sys/clk                } \
   # {sim:/mips32sys/resetn             }   
   
# vsim -gui -voptargs=+acc work.mem32(behav)

# #restart -nolist -nowave
# # -- Add waves to simulation plot
# add wave \
# -logic        {sim:/mem32/wbs_addr_i         } \
# -logic        {sim:/mem32/clk                } \
# -literal -dec {sim:/mem32/resetn             }
    
# force -freeze sim:/mem32/wbs_addr_i      00000000000000000000000000000001 0

# should run at least 1000 x period
run {2880 ns}
#run {2839 ns}