library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mem32 is
  generic(ADDR_LENGTH : natural := 9);
  port(addr : in std_logic_vector(ADDR_LENGTH-1 downto 0);
       data : inout std_logic_vector(31 downto 0);
       
       we : in std_logic;	-- '1' -> enable write ; '0' -> disalbe write
       wr : in std_logic;	-- '0' -> write ; '1' -> read
       
       
       clk : in std_logic;
       resetn : in std_logic);
end entity mem32;

architecture behav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(31 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
    signal data_in : std_logic_vector(31 downto 0);
    signal data_out : std_logic_vector(31 downto 0);
begin
    mem_access : process(clk, resetn)
    begin
	if(resetn = '0') then
	    for i in 0 to ((2**ADDR_LENGTH) - 1) loop
		    memory(i) <= (others => '0');
	    end loop;
	elsif(rising_edge(clk)) then
	    if(wr = '0') then
		if(we = '1') then
		    memory(to_integer(unsigned(addr))) <= data_in;
		end if;
	    end if;
	end if;
    end process mem_access;
    
    data_out <= memory(to_integer(unsigned(addr)));
    
    data <= data_out when wr = '1' else
	    ( others => 'Z' );
	    
    data_in <= data;
end architecture behav;