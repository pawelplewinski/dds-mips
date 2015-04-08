library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity tb_mips is
generic(
	  IMEM_LEN		: natural  := 64;
	  DMEM_LEN		: natural  := 64;
	  PGM_FILE		: string := "../asm/mult_test.txt");
end entity tb_mips;

architecture tb_arch of tb_mips is
	signal clk		: std_logic := '0';
	signal resetn		: std_logic;
	
	component mips32sys_gut is 
	generic (
		PGM_FILE : string := "pgm_mem.txt";
		SYS_32   : positive := 32;
		DMEM_LEN   : natural  :=  64;  --In bytes
		IMEM_LEN   : natural  :=  64  --In 32-bit words
	);
	port(
		clk      : in  std_logic;
		resetn   : in  std_logic;
		
		end_sim	 : out std_logic
		);
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
		
		end_sim	 : out std_logic
		);
	end component mips32sys_dut;
	
	signal gut_end_sim	: std_logic; 
	signal dut_end_sim	: std_logic; 
	signal gut_end_sim0	: std_logic := '0';
	signal dut_end_sim0	: std_logic := '0';
begin
	     
	-- Connect MIPS systems
	gut : mips32sys_gut
	generic map(
		    PGM_FILE	=> PGM_FILE,
		    IMEM_LEN	=> IMEM_LEN,
		    DMEM_LEN	=> DMEM_LEN)
	port map(
		end_sim 	=> gut_end_sim,
		clk		=> clk,
		resetn		=> resetn);

	-- Connect MIPS systems
	dut : mips32sys_dut
	generic map(
		PGM_FILE	=> PGM_FILE,
		IMEM_LEN	=> IMEM_LEN,
		DMEM_LEN	=> DMEM_LEN)
	port map(
		end_sim 	=> dut_end_sim,
		clk		=> clk,
		resetn		=> resetn);

	-- clock generation
	clk <= not clk after 50 ns;
	
	-- reset generation
	rst : process
	begin
		resetn <= '0';
		wait for 100 ns;
		resetn <= '1';
		wait;
	end process;
	

	
	sim_monitor : process(clk, resetn)
	begin
		if resetn = '0' then
			gut_end_sim0 <= '0';
			dut_end_sim0 <= '0';
		elsif rising_edge(clk) then
			if gut_end_sim = '1' then
				gut_end_sim0 <= '1';
			end if;
			if dut_end_sim = '1' then
				dut_end_sim0 <= '1';
			end if;
			
			if gut_end_sim0 = '1' and dut_end_sim0 = '1' then
				assert false report "End of simulation" severity failure;
				gut_end_sim0 <= '0';
				dut_end_sim0 <= '0';
			end if;
		end if;
	end process sim_monitor;
end architecture tb_arch;