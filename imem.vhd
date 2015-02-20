library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity imem32 is
    generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9);
    port(
        -- wishbone interface
        wbs_addr_i : in  std_logic_vector(ADDR_LENGTH-1 downto 0);
        wbs_dat_i  : in  std_logic_vector(SYS_32-1 downto 0);
        wbs_dat_o  : out std_logic_vector(SYS_32-1 downto 0);
        
        wbs_we_i   : in  std_logic;	-- '1' -> enable write ; '0' -> disable write
          
        clk        : in  std_logic;
        resetn     : in  std_logic);
end entity imem32;

architecture behav of imem32 is
    type mem_type is array (natural range <>) of std_logic_vector(SYS_32-1 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
	
begin
    mem_access : process(clk, resetn)
		variable addr_ctr : unsigned(ADDR_LENGTH-1 downto 0) := (others => '0');
		file mips_pgm : text open read_mode is "gcd.txt";
		variable rdline : line;
	    variable hexdata : std_logic_vector(SYS_32-1 downto 0);
		
    begin
        if(resetn = '0') then
	        while not endfile(mips_pgm) loop
				readline(mips_pgm,rdline);
				hread(rdline,hexdata);
				memory(to_integer(addr_ctr)) <= hexdata;
				addr_ctr := addr_ctr + 1;
				--wait until clk='0'
			end loop;
            for i in to_integer(addr_ctr) to ((2**ADDR_LENGTH)-1) loop
                memory(i) <= (others => '0');
            end loop;

        elsif(rising_edge(clk)) then
            if(wbs_we_i = '1') then
                memory(to_integer(unsigned(wbs_addr_i))) <= wbs_dat_i;
            end if;
        end if;
    end process mem_access;
    
    wbs_dat_o <= memory(to_integer(unsigned(wbs_addr_i)));  
end architecture behav;