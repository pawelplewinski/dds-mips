library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity verifier is
    generic(
        PGM_FILE : string    := "no.file";
        IA_LEN   : natural   :=  9;
        DA_LEN   : natural   :=  6);
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        rstn     : in std_logic);
end entity verifier;

architecture behav of verifier is

    -- Type declarations
    type inst_state is (init,fetch,decode,execute,writeback);
    subtype u32_stype       is unsigned(31 downto 0);
    subtype u32             is unsigned(31 downto 0);
    
    -- 
    alias gut_clock is  << signal ^.gut.clk : std_logic >>;
    alias gut_reset is  << signal ^.gut.resetn : std_logic >>;

    alias gut_pgc is  << signal ^.gut.cpu.pgc           : unsigned(IA_LEN-1 downto 0) >>;
    alias dut_pgc is  << signal ^.dut.cpu.datapath.pgc  : u32 >>;
    
    alias dut_state is  << signal ^.dut.cpu.controller.state : inst_state >>;
    
    -- ALU
    alias gut_sreg is  << signal ^.gut.cpu.sreg          : u32_stype >>;
    alias dut_sreg is  << signal ^.dut.cpu.datapath.sreg : u32_stype >>;
    alias gut_treg is  << signal ^.gut.cpu.treg          : u32_stype >>;
    alias dut_treg is  << signal ^.dut.cpu.datapath.treg : u32_stype >>;

begin
    
    -- Note: checks should be triggered by DUT in order to verify pre and post-simulation
    
    chk00 : process (rst,clk)
    begin
        if rst = '1' then
        elsif rising_edge(clk) then
            -- chk nothing
        end if;
    end process chk00;
    
    -- 01 CHECK: ALU outputs regs (at every DUT execute start)
    chk01: process (dut_state)
    begin
        if dut_state'event and dut_state = execute then
            assert gut_sreg = dut_sreg report "VFY_CHK01: sregs differ." severity warning;
            assert gut_treg = dut_treg report "VFY_CHK01: tregs differ." severity warning;
        end if;
    end process chk01;

    -- 02 CHECK: pgc regs (at every DUT writeback start)
    chk02: process (dut_state)
    begin
        if dut_state'event and dut_state = writeback then
            assert gut_pgc /= unsigned(dut_pgc(IA_LEN-1 downto 0)) report "VFY_CHK02: Program counter differ." severity warning;
        end if; 
    end process chk02;
    
end architecture behav;