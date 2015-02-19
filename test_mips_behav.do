echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim

echo "DO: Starting compilation."
# -- Compile memory [entity::mem32] [architecture::behav]
vcom mem.vhd

# -- Compile MIPS core [entity::mips32core]
vcom mips32core.vhd

# -- Compile MIPS core [architecture::behavior] (behavioural)
vcom mips32core_arch_behav.vhd

# -- Compile MIPS system [architecture::struct] (structural)
vcom mips32sys.vhd

# -- Compile testbench (top entity)
vcom tb_mips.vhd

echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.tb_mips(tb_arch)

#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic   {sim:/tb_mips/clk                } \
-logic   {sim:/tb_mips/resetn             } \
-logic   {sim:/tb_mips/imem_we            } \
-logic   {sim:/tb_mips/ia_sel             } \
-literal -hex   {sim:/tb_mips/iaddr       } \
-literal -hex   {sim:/tb_mips/ibus_a_o    } \
-literal -hex   {sim:/tb_mips/imem_a_i    } \
-literal -dec   {sim:/tb_mips/imem_d_i    } \
-literal -dec   {sim:/tb_mips/imem_d_o    } \
-literal -dec   {sim:/tb_mips/inst        } \


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
run {1700 ns}