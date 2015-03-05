library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_mips is
    generic(
        PGM_FILE : string   := "gcd.txt";   -- Assembly test code file (path)
        IA_LEN   : natural  :=  4;
        DA_LEN   : natural  := 16;
        SYS_32   : positive := 32);
end entity tb_mips;

architecture tb_arch of tb_mips is

    -------------
    -- testset --
    -------------
    component testset is
    generic(
        PGM_FILE : string    := "no.file";
        SYS_32   : positive  := 32;
        IA_LEN   : natural   :=  9;
        DA_LEN   : natural   :=  6);
    port(
        clk      : out std_logic;
        rst      : out std_logic;
        rstn     : out std_logic);
    end component testset;
    
    -----------------
    -- MIPS system --
    -----------------
    component mips32sys is 
	generic (
        PGM_FILE    : string   := "no.file";
        SYS_32      : positive := 32;
        IA_LEN      : natural  :=  9;
		DA_LEN      : natural  :=  6;
		GPIO_LEN    : natural  :=  8);
	port(
        clk         : in  std_logic;
        resetn      : in  std_logic);
    end component mips32sys;
    
    ----------------
    -- Comparator --
    ----------------
    
    --for dut : mips32core use entity work.mips32core(structural);
    
    ---------------------------------------
    --------------- Signals ---------------
    ---------------------------------------
    
    signal tb_clk       : std_logic; 
    signal tb_reset     : std_logic; -- high active reset
    signal tb_resetn    : std_logic; -- low active reset
    signal tb_redline   : std_logic; -- DEBUG: draws a red line in the simulator
    
begin

    ----------------
    -- Components --
    ----------------

    tst : testset
        generic map(
            PGM_FILE    => PGM_FILE,
            SYS_32      => SYS_32,
            IA_LEN      => IA_LEN,
            DA_LEN      => DA_LEN)
        port map(
            clk         => tb_clk,
            rst         => tb_reset,
            rstn        => tb_resetn); 
     
    -- Connect MIPS system (gut)
    gut : entity work.mips32sys(gut_struct)
        generic map(
            PGM_FILE    => PGM_FILE,
            SYS_32      => SYS_32,
            IA_LEN      => IA_LEN,
            DA_LEN      => DA_LEN,
            GPIO_LEN    => 8)
        port map(
            clk         => tb_clk,
            resetn      => tb_resetn);

    -- Connect MIPS system (dut)
    dut : entity work.mips32sys(dut_struct)
        generic map(
            PGM_FILE    => PGM_FILE,
            SYS_32      => SYS_32,
            IA_LEN      => IA_LEN,
            DA_LEN      => DA_LEN,
            GPIO_LEN    => 8)
        port map(
            clk         => tb_clk,
            resetn      => tb_resetn);
    
    -- Connect Comparator

end architecture tb_arch;