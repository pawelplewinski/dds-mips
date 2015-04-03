library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity tb_mips is
    generic(
        IMEM_LEN   : natural  := 64;
        DMEM_LEN   : natural  := 64;
        PGM_FILE : string := "gcd.txt");
end entity tb_mips;

architecture tb_arch of tb_mips is
    signal clk      : std_logic := '0';
    signal resetn   : std_logic;
    
    component mips32sys_gut is 
    generic (
	PGM_FILE : string := "pgm_mem.txt";
        SYS_32   : positive := 32;
        DMEM_LEN   : natural  :=  64;  --In bytes
        IMEM_LEN   : natural  :=  64  --In 32-bit words;
        );
    port(
        clk      : in  std_logic;
        resetn   : in  std_logic;
        
        end_sim	 : out std_logic);
    end component mips32sys_gut;
    
    component mips32sys_dut is 
    generic (
	PGM_FILE : string := "pgm_mem.txt";
        SYS_32   : positive := 32;
        DMEM_LEN   : natural  :=  64;  --In bytes
        IMEM_LEN   : natural  :=  64  --In 32-bit words
	);
    port(
        clk      : in  std_logic;
        resetn   : in  std_logic;
        
        end_sim	 : out std_logic);
    end component mips32sys_dut;
    
    signal gut_end_sim : std_logic; 
    signal dut_end_sim : std_logic; 
begin
	     
    -- Connect MIPS systems
    gut : mips32sys_gut
    generic map(
		PGM_FILE	    => PGM_FILE,
		IMEM_LEN     => IMEM_LEN,
		DMEM_LEN     => DMEM_LEN)
    port map(
	    end_sim 	=> gut_end_sim,
	    clk         => clk,
	    resetn      => resetn);

    -- clock generation
    clk <= not clk after 50 ns;
    -- Connect MIPS systems
    dut : mips32sys_dut
    generic map(
		PGM_FILE	    => PGM_FILE,
		IMEM_LEN     => IMEM_LEN,
		DMEM_LEN     => DMEM_LEN)
    port map(
	    end_sim 	=> dut_end_sim,
	    clk         => clk,
	    resetn      => resetn);

    -- clock generation
    clk <= not clk after 50 ns;
    
    -- reset generation
    rst : process
        begin
            resetn      <= '0';
            wait for 50 ns;
            resetn      <= '1';
            wait;
        end process;
    
    sim_monitor : process
    begin
        -- wait til the system is reset
        wait until gut_end_sim = '1';
        wait until dut_end_sim = '1';
        wait until gut_end_sim = '0';
        wait until dut_end_sim = '0';
        assert false report "End of simulation" severity failure;
        wait;
    end process;
	
end architecture tb_arch;