library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture dmem of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(7 downto 0);
    signal memory : mem_type(0 to MEM_LEN-1);

	-- PSL default clock is rising_edge(clk);
	--Checks if the data from correct address are
	--sent by the instruction memory
	-- PSL mem_i_data: assert always (wbs_addr_i -> next (wbs_dat_o = memory(to_integer(unsigned(wbs_addr_i))+3) & 		      memory(to_integer(unsigned(wbs_addr_i))+2) & memory(to_integer(unsigned(wbs_addr_i))+1) & memory(to_integer(unsigned(wbs_addr_i))))) abort not resetn;

begin
    mem_access : process(clk, resetn)
    begin
        if(resetn = '0') then
            for i in 0 to MEM_LEN-1 loop
                memory(i) <= (others => '0');
            end loop;
        elsif(rising_edge(clk)) then
            if(wbs_we_i = '1' and to_integer(unsigned(wbs_addr_i)) < MEM_LEN-3) then
                memory(to_integer(unsigned(wbs_addr_i))) <= wbs_dat_i(7 downto 0);
                memory(to_integer(unsigned(wbs_addr_i))+1) <= wbs_dat_i(15 downto 8);
                memory(to_integer(unsigned(wbs_addr_i))+2) <= wbs_dat_i(23 downto 16);
                memory(to_integer(unsigned(wbs_addr_i))+3) <= wbs_dat_i(31 downto 24);
            end if;
        end if;
    end process mem_access;
    
    wbs_dat_o <= (others => '0') when to_integer(unsigned(wbs_addr_i)) >= (MEM_LEN-3)
		 else memory(to_integer(unsigned(wbs_addr_i))+3) &
		      memory(to_integer(unsigned(wbs_addr_i))+2) &
		      memory(to_integer(unsigned(wbs_addr_i))+1) &
		      memory(to_integer(unsigned(wbs_addr_i)));  
end architecture dmem;