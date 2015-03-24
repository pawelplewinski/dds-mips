library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity tb_mips is
    generic(
        IA_LEN   : natural  := 8;
        DA_LEN   : natural  := 4;
        SYS_32   : positive := 32;
        PGM_FILE : string := "memwr.txt");
end entity tb_mips;

architecture tb_arch of tb_mips is
    signal clk      : std_logic := '0';
    signal resetn   : std_logic;
    
    component mips32sys_gut is 
	generic (
	      PGM_FILE   : string := "pgm_mem.txt";
        SYS_32      : positive := 32;
        IA_LEN      : natural  :=  9;
		DA_LEN      : natural  :=  6;
		GPIO_LEN    : natural  :=  8);
	port(
	end_sim	    : out std_logic;
        
        clk         : in  std_logic;
        resetn      : in  std_logic);
    end component mips32sys_gut;
    
    component mips32sys_dut is 
	generic (
	      PGM_FILE   : string := "pgm_mem.txt";
        SYS_32      : positive := 32;
        IA_LEN      : natural  :=  9;
		DA_LEN      : natural  :=  6;
		GPIO_LEN    : natural  :=  8);
	port(
	end_sim	    : out std_logic;
        
        clk         : in  std_logic;
        resetn      : in  std_logic);
    end component mips32sys_dut;
    
    signal gut_end_sim : std_logic; 
    signal dut_end_sim : std_logic; 
begin
	     
    -- Connect MIPS systems
    gut : mips32sys_gut
    generic map(
		PGM_FILE	=> PGM_FILE,
		SYS_32      	=> SYS_32,
		IA_LEN      	=> IA_LEN,
		DA_LEN      	=> DA_LEN,
		GPIO_LEN    	=> 8)
    port map(
	    end_sim 	=> gut_end_sim,
	    clk         => clk,
	    resetn      => resetn);

    -- clock generation
    clk <= not clk after 50 ns;
    -- Connect MIPS systems
    dut : mips32sys_dut
    generic map(
		PGM_FILE	=> PGM_FILE,
		SYS_32      	=> SYS_32,
		IA_LEN      	=> IA_LEN,
		DA_LEN      	=> DA_LEN,
		GPIO_LEN    	=> 8)
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