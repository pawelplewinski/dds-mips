add wave -position insertpoint  \
sim:/tb_mips/dut/clk \
sim:/tb_mips/dut/resetn \
sim:/tb_mips/dut/end_sim
add wave -position insertpoint  \
sim:/tb_mips/dut/cpu/datapath/reg \
sim:/tb_mips/dut/cpu/datapath/hireg \
sim:/tb_mips/dut/cpu/datapath/loreg
add wave -position insertpoint  \
sim:/tb_mips/dut/cpu/controller/optc
add wave -position insertpoint  \
sim:/tb_mips/dut/cpu/controller/state
add wave -position insertpoint  \
sim:/tb_mips/dut/cpu/controller/op_state
add wave -position insertpoint  \
sim:/tb_mips/dut/cpu/datapath/mdu/start_i \
sim:/tb_mips/dut/cpu/datapath/mdu/mdu_r \
sim:/tb_mips/dut/cpu/datapath/mdu/mdu_l \
sim:/tb_mips/dut/cpu/datapath/mdu/busy \
sim:/tb_mips/dut/cpu/datapath/mdu/ctr \
sim:/tb_mips/dut/cpu/datapath/mdu/rdy_o