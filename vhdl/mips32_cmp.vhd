library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_cmp is
    generic(
      WORD_LEN : natural := 32);
    port(
	cmp_l_in : in std_logic_vector(WORD_LEN-1 downto 0);
	cmp_r_in : in std_logic_vector(WORD_LEN-1 downto 0);
	
	cmp_eq_o : out std_logic;
	cmp_gt_o : out std_logic);
end entity mips32_cmp;
	
architecture behavior of mips32_cmp is
begin
    cmp: process(cmp_l_in,cmp_r_in)
    begin
	if(unsigned(cmp_l_in) = unsigned(cmp_r_in)) then
	    cmp_eq_o <= '1';
	    cmp_gt_o <= '0';
	elsif(unsigned(cmp_l_in) > unsigned(cmp_r_in)) then
	    cmp_eq_o <= '0';
	    cmp_gt_o <= '1';
	else
	    cmp_eq_o <= '0';
	    cmp_gt_o <= '0';
	end if;
    end process cmp;
end architecture behavior;