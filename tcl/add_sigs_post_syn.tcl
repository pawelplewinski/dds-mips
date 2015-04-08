# ***************************************************************************
add wave -noupdate -divider -height 32 "Common signals"
add wave -hex  \
sim:/tb_mips/clk \
sim:/tb_mips/resetn \
sim:/tb_mips/gut_end_sim \
sim:/tb_mips/dut_end_sim
# ***************************************************************************
add wave -noupdate -divider -height 32 "States"
add wave -hex  \
sim:/tb_mips/gut/cpu/state_o \
sim:/tb_mips/dut/cpu/\\controller|state\\
# ***************************************************************************
add wave -noupdate -divider -height 32 "Register banks"
add wave -hex  \
sim:/tb_mips/gut/cpu/reg
add wave -hex -group reg sim:/tb_mips/dut/cpu/\\datapath|reg1\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg2\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg3\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg4\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg5\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg6\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg7\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg8\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg9\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg10\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg11\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg12\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg13\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg14\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg15\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg16\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg17\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg18\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg19\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg20\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg21\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg22\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg23\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg24\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg25\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg26\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg27\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg28\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg29\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg30\\ \
		    sim:/tb_mips/dut/cpu/\\datapath|reg31\\
# ***************************************************************************
add wave -noupdate -divider -height 32 "HI-LO registers"
add wave -hex  \
sim:/tb_mips/gut/cpu/hireg \
sim:/tb_mips/gut/cpu/loreg \
sim:/tb_mips/dut/cpu/\\datapath|mdu|hireg\\ \
sim:/tb_mips/dut/cpu/\\datapath|mdu|loreg\\
# ***************************************************************************
add wave -noupdate -divider -height 32 "PGC register"
add wave -hex  \
sim:/tb_mips/gut/cpu/pgc \
sim:/tb_mips/dut/cpu/\\datapath|pgc\\
# ***************************************************************************
add wave -noupdate -divider -height 32 "Data memory"
add wave -hex  \
sim:/tb_mips/gut/d_mem/memory \
sim:/tb_mips/dut/d_mem/memory
# ***************************************************************************
add wave -noupdate -divider -height 32 "Data bus"
add wave -hex  \
sim:/tb_mips/gut/dbus_a \
sim:/tb_mips/gut/dbus_d_i \
sim:/tb_mips/gut/dbus_d_o \
sim:/tb_mips/gut/dbus_we \
sim:/tb_mips/dut/dbus_a \
sim:/tb_mips/dut/dbus_d_i \
sim:/tb_mips/dut/dbus_d_o \
sim:/tb_mips/dut/dbus_we
# ***************************************************************************
add wave -noupdate -divider -height 32 "Instruction bus"
add wave -hex   \
sim:/tb_mips/gut/ibus_d_i \
sim:/tb_mips/gut/ibus_a_o \
sim:/tb_mips/dut/ibus_d_i \
sim:/tb_mips/dut/ibus_a_o

