# Disable NumericStd and NumericBit warnigns (see also modelsim.ini)
set NumericStdNoWarnings 1

echo "DO: Quitting simulation if runnning."
# -- value [@time:{100ns} or percentaged: 50]
quit -sim
vdel -all
vlib work
echo "DO: Starting compilation."
# -- Compile memory [entity::mem32] [architecture::behav]
vcom mem.vhd
# -- Compile MIPS core sub-components
vcom -check_synthesis mips32_cmp.vhd
vcom -check_synthesis mips32_mdu.vhd
vcom -check_synthesis mips32_alu.vhd
vcom -check_synthesis mips32_ctrl.vhd
vcom -check_synthesis mips32_dp.vhd
# Compile MIPS core [entity::mips32core]
vcom -check_synthesis mips32core.vhd
# Compile MIPS core [architecture::behavior] (behavioural)
vcom mips32core_arch_behav.vhd
vcom -check_synthesis mips32core_arch_struct.vhd
# Compile MIPS system [architecture::struct] (structural)
vcom mips32sys.vhd

# Compile clock generator
vcom clock_gen.vhd
# Compile testset
vcom testset.vhd
# Compile verifier
#vcom verifier.vhd
vcom -2008 -explicit verifier.vhd

# Compile testbench (top entity)
vcom tb_mips.vhd

echo "DO: Starting simulation."
vsim -gui -voptargs=+acc work.tb_mips(tb_arch)

#restart -nolist -nowave
# -- Add waves to simulation plot
add wave \
-logic -label clock {sim:/tb_mips/tb_clk                                                   } \
-logic -label reset {sim:/tb_mips/tb_resetn                                                } \
-literal -dec -label GUT_pc            {sim:/tb_mips/gut/cpu/pgc                           } \
-literal -dec -label DUT_pc            {sim:/tb_mips/dut/cpu/datapath/pgc                  } \
-literal -dec -label DUT_cmp_r_inp     {sim:/tb_mips/dut/cpu/datapath/cmp/cmp_r_inp        } \
-literal -dec -label DUT_cmp_l_inp     {sim:/tb_mips/dut/cpu/datapath/cmp/cmp_l_inp        } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -hex -label GUT_iram_addr_out {sim:/tb_mips/gut/iram_addr_out                     } \
-literal -hex -label GUT_iram_addr_out {sim:/tb_mips/dut/iram_addr_out                     } \
-literal -hex -label GUT_imem          {sim:/tb_mips/gut/imem/memory                       } \
-literal -hex -label GUT_iram_data_inp {sim:/tb_mips/gut/iram_data_inp                     } \
-literal -sym -label GUT_state         {sim:/tb_mips/gut/cpu/state                         } \
-literal -sym -label DUT_state         {sim:/tb_mips/dut/cpu/controller/state              } \
-literal -sym -label GUT_state_next    {sim:/tb_mips/gut/cpu/exec/state_next               } \
-literal -sym -label DUT_state_next    {sim:/tb_mips/dut/cpu/controller/state_nxt          } \
-literal -sym -label GUT_op_state      {sim:/tb_mips/gut/cpu/op_state                      } \
-literal -dec -label DUT_op_state      {sim:/tb_mips/dut/cpu/controller/op_state           } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -dec -label GUT_reg           {sim:/tb_mips/gut/cpu/reg                           } \
-literal -dec -label DUT_reg           {sim:/tb_mips/dut/cpu/datapath/reg                  } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -dec -label DUT_tnext         {sim:/tb_mips/dut/cpu/datapath/tnext                } \
-literal -dec -label DUT_dnext         {sim:/tb_mips/dut/cpu/datapath/dnext                } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -dec -label GUT_sreg          {sim:/tb_mips/gut/cpu/sreg                          } \
-literal -dec -label DUT_sreg          {sim:/tb_mips/dut/cpu/datapath/sreg                 } \
-literal -dec -label GUT_treg          {sim:/tb_mips/gut/cpu/treg                          } \
-literal -dec -label DUT_treg          {sim:/tb_mips/dut/cpu/datapath/treg                 } \
-literal -dec -label GUT_multres       {sim:/tb_mips/gut/cpu/exec/mres                     } \
-literal -dec -label GUT_mdures        {sim:/tb_mips/gut/cpu/mdures                        } \
-literal -dec -label DUT_mdures        {sim:/tb_mips/dut/cpu/datapath/mdures               } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -dec -label DUT_ctrl_data     {sim:/tb_mips/dut/cpu/ctrl_data                     } \
-literal -dec -label DUT_ctrl_func_1   {sim:/tb_mips/dut/cpu/controller/func(1)            } \
-literal -dec -label DUT_mdu_start_inp {sim:/tb_mips/dut/cpu/datapath/mdu/start_inp        } \
-literal -dec -label DUT_mdu_mode_inp  {sim:/tb_mips/dut/cpu/datapath/mdu/mode_inp         } \
-literal -sym -label GUT_mdu_rdy_out   {sim:/tb_mips/gut/cpu/exec/mdu_rdy                  } \
-literal -sym -label DUT_mdu_rdy_out   {sim:/tb_mips/dut/cpu/datapath/mdu/rdy              } \
-literal -dec -label DUT_mdu_ctr       {sim:/tb_mips/dut/cpu/datapath/mdu/ctr              } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -hex -label GUT_dram_addr_out {sim:/tb_mips/gut/dram_addr_out                     } \
-literal -hex -label DUT_dram_addr_out {sim:/tb_mips/dut/dram_addr_out                     } \
-literal -hex -label GUT_dram_wren_out {sim:/tb_mips/gut/cpu/dbus_wren_out                 } \
-literal -dec -label DUT_dram_wren_out {sim:/tb_mips/dut/cpu/controller/dbus_wren_out      } \
-literal -hex -label GUT_dram_data_inp {sim:/tb_mips/gut/dram_data_inp                     } \
-literal -hex -label DUT_dram_data_inp {sim:/tb_mips/dut/dram_data_inp                     } \
-literal -dec -label GUT_dram_data_out {sim:/tb_mips/gut/dram_data_out                     } \
-literal -dec -label DUT_dram_data_out {sim:/tb_mips/dut/dram_data_out                     } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -hex -label DUT_tsel          {sim:/tb_mips/dut/cpu/datapath/tsel                 } \
-literal -dec -label DUT_treg          {sim:/tb_mips/dut/cpu/datapath/treg                 } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } \
-literal -dec -label GUT_dmem          {sim:/tb_mips/gut/dmem/memory                       } \
-literal -dec -label DUT_dmem          {sim:/tb_mips/dut/dmem/memory                       } \
-logic -label _____ {sim:/tb_mips/tb_redline                                               } 

# psl test
add wave /tb_mips/dut/cpu/controller/ctrl_states_init \
	/tb_mips/dut/cpu/controller/ctrl_states_fetch \
	/tb_mips/dut/cpu/controller/ctrl_states_decode \
	/tb_mips/dut/cpu/controller/ctrl_states_exec \
	/tb_mips/dut/cpu/controller/ctrl_states_writeback


# should run at least 1000 x period
run {1600 ns}
#run {2839 ns}