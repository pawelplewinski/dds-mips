library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

architecture imem of mem32 is
	type mem_type is array (integer range <>) of std_logic_vector(SYS_32-1 downto 0);
	signal memory : mem_type(0 to MEM_LEN-1);
	file mips_pgm : text open read_mode is PGM_FILE;
	signal addrst : integer range 0 to MEM_LEN-1 := 0;
begin
	mem_access : process(clk, resetn)
		variable addr_ctr : integer range 0 to MEM_LEN-1 := 0;
		variable hexdata : std_logic_vector(SYS_32-1 downto 0);
		variable rdline : line;
		variable once : boolean := false;
	begin
		if(resetn = '0') then
			-- Load program memory
			addr_ctr := addrst;
			while not endfile(mips_pgm) loop
				readline(mips_pgm,rdline);
				hread(rdline,hexdata);
				memory(addr_ctr) <= hexdata;
				addr_ctr := addr_ctr + 1;
			end loop;
			addrst <= addr_ctr;
			while addr_ctr < MEM_LEN-1 loop
				memory(addr_ctr) <= (others => '0');
				addr_ctr := addr_ctr + 1;
			end loop;
			memory(addr_ctr) <= (others => '0');
		elsif(rising_edge(clk)) then
			if(wbs_we_i = '1' and to_integer(unsigned(wbs_addr_i)) < MEM_LEN-1) then
				memory(to_integer(unsigned(wbs_addr_i))) <= wbs_dat_i;
			end if;
		end if;
	end process mem_access;
	
	wbs_dat_o <= (others => '0') when to_integer(unsigned(wbs_addr_i)) >= MEM_LEN-1
		     else memory(to_integer(unsigned(wbs_addr_i)));  
end architecture imem;