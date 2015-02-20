library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_mips is
    generic(
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
        SYS_32  : positive  := 32;
        IA_LEN  : natural   :=  9;
        DA_LEN  : natural   :=  6);
    port(
        clk     : out std_logic;
        rst     : out std_logic;
        rstn    : out std_logic);
    end component testset;
    
    -----------------
    -- MIPS system --
    -----------------
    component mips32sys is 
	generic (
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
            SYS_32      => SYS_32,
            IA_LEN      => IA_LEN,
            DA_LEN      => DA_LEN)
        port map(
            clk         => tb_clk,
            rst         => tb_reset,
            rstn        => tb_resetn); 
     
    -- Connect MIPS system (gut)
    gut : mips32sys
    generic map(
        SYS_32      => SYS_32,
        IA_LEN      => IA_LEN,
		DA_LEN      => DA_LEN,
		GPIO_LEN    => 8)
    port map(
	    clk         => tb_clk,
	    resetn      => tb_resetn);

    -- Connect MIPS system (dut)
    
    -- Connect Comparator

end architecture tb_arch;