library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_multiplier is
	generic (width : natural :=32);
end entity tb_multiplier;

architecture test of tb_multiplier is
	
	signal clk : std_logic := '0';
	signal op1 : unsigned (width-1 DOWNTO 0);
	signal op2 : unsigned (width-1 DOWNTO 0);
	signal result : unsigned(width-1 DOWNTO 0);
	signal done : boolean;

	component multiplier is 
	generic (width : natural :=32);
	port(
		clk : IN std_logic;
		op1 : IN unsigned (width-1 DOWNTO 0);
		op2 : IN unsigned (width-1 DOWNTO 0);
		result : OUT unsigned(width-1 DOWNTO 0);
		done : OUT boolean);
	end component multiplier;

begin
	
	mult : multiplier
	generic map(width => width)
	port map(
		clk => clk,
		op1 => op1,
		op2 => op2,
		result => result,
		done => done
	);
	
	clk <= not clk after 50 ns;
  process begin
	op1 <= to_unsigned(4, 32);
	op2 <= to_unsigned(6, 32);
	
	wait on done;
	end process;
end test;