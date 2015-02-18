library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mem32 is
  generic(ADDR_LENGTH : natural := 9);
  port(
       -- wishbone interface
       wbs_addr_i : in std_logic_vector(ADDR_LENGTH-1 downto 0);
       wbs_dat_o : out std_logic_vector(31 downto 0);
       wbs_dat_i : in std_logic_vector(31 downto 0);
       
       wbs_we_i : in std_logic;	-- '1' -> enable write ; '0' -> disable write
          
       clk : in std_logic;
       resetn : in std_logic);
end entity mem32;

architecture behav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(31 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
begin
    mem_access : process(clk, resetn)
    begin
	if(resetn = '0') then
	    for i in 0 to ((2**ADDR_LENGTH) - 1) loop
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