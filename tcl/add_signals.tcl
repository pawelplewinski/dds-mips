add wave -noupdate -divider -height 32 "Common signals"
add wave -position insertpoint  \
sim:/tb_mips/clk \
sim:/tb_mips/resetn \
sim:/tb_mips/gut_end_sim \
sim:/tb_mips/dut_end_sim
add wave -noupdate -divider -height 32 "States"
add wave -position insertpoint  \
sim:/tb_mips/gut/cpu/state \
sim:/tb_mips/dut/cpu/controller/state
add wave -noupdate -divider -height 32 "Register banks"
add wave -position insertpoint  \
sim:/tb_mips/gut/cpu/reg \
sim:/tb_mips/dut/cpu/datapath/reg
add wave -noupdate -divider -height 32 "HI-LO registers"
add wave -position insertpoint  \
sim:/tb_mips/gut/cpu/hireg \
sim:/tb_mips/gut/cpu/loreg \
sim:/tb_mips/dut/cpu/datapath/hireg \
sim:/tb_mips/dut/cpu/datapath/loreg
add wave -noupdate -divider -height 32 "T/S registers"
add wave -position insertpoint  \
sim:/tb_mips/gut/cpu/sreg \
sim:/tb_mips/gut/cpu/treg \
sim:/tb_mips/dut/cpu/datapath/sreg \
sim:/tb_mips/dut/cpu/datapath/treg
add wave -noupdate -divider -height 32 "PGC register"
add wave -position insertpoint  \
sim:/tb_mips/gut/cpu/pgc \
sim:/tb_mips/dut/cpu/datapath/pgc
add wave -noupdate -divider -height 32 "Data memory"
add wave -position insertpoint  \
sim:/tb_mips/gut/d_mem/memory \
sim:/tb_mips/dut/d_mem/memory
add wave -noupdate -divider -height 32 "Data bus"
add wave -position insertpoint  \
sim:/tb_mips/gut/dbus_a \
sim:/tb_mips/gut/dbus_d_i \
sim:/tb_mips/gut/dbus_d_o \
sim:/tb_mips/gut/dbus_we \
sim:/tb_mips/dut/dbus_a \
sim:/tb_mips/dut/dbus_d_i \
sim:/tb_mips/dut/dbus_d_o \
sim:/tb_mips/dut/dbus_we
add wave -noupdate -divider -height 32 "Instruction bus"
add wave -position insertpoint  \
sim:/tb_mips/gut/ibus_d_i \
sim:/tb_mips/gut/ibus_a_o \
sim:/tb_mips/dut/ibus_d_i \
sim:/tb_mips/dut/ibus_a_o
add wave -noupdate -divider -height 32 "PSL tests"
add wave /tb_mips/dut/cpu/controller/ctrl_states_init \
	/tb_mips/dut/cpu/controller/ctrl_states_fetch \
	/tb_mips/dut/cpu/controller/ctrl_states_decode \
	/tb_mips/dut/cpu/controller/ctrl_states_exec_normal \
	/tb_mips/dut/cpu/controller/ctrl_states_exec_mult \
	/tb_mips/dut/cpu/controller/ctrl_states_writeback \
	/tb_mips/dut/cpu/datapath/mdu/mdu_cycles_cnt  \
	/tb_mips/dut/cpu/datapath/dp_ibus_addr \
	/tb_mips/dut/cpu/datapath/dp_reset_pgc \
	/tb_mips/dut/cpu/datapath/dp_reset_reg \
	/tb_mips/dut/cpu/datapath/dp_reset_inst \
	/tb_mips/dut/cpu/datapath/dp_pgc_next \
	/tb_mips/dut/dmem/mem_o_data \
	/tb_mips/dut/imem/mem_i_data