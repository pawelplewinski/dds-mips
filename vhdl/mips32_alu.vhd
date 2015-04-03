library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_alu is
    generic(
      WORD_LEN : natural := 32);
    port(
	alu_l_in : in std_logic_vector(WORD_LEN-1 downto 0);
	alu_r_in : in std_logic_vector(WORD_LEN-1 downto 0);
	alu_res_out : out std_logic_vector(WORD_LEN-1 downto 0);
	alu_cout   : out std_logic;
	func_sel : in std_logic_vector(2 downto 0));
end entity mips32_alu;
	
architecture behavior of mips32_alu is
    signal alu_res : unsigned (WORD_LEN downto 0);
begin
    with func_sel select alu_res <=
	unsigned(alu_l_in(WORD_LEN-1)&alu_l_in) + unsigned(alu_r_in(WORD_LEN-1)&alu_r_in) when "000",
	unsigned(alu_l_in(WORD_LEN-1)&alu_l_in) - unsigned(alu_r_in(WORD_LEN-1)&alu_r_in) when "010",
	unsigned('0'&alu_l_in and '0'&alu_r_in) when "100",
	unsigned('0'&alu_l_in or '0'&alu_r_in) when "101",
	unsigned('0'&alu_l_in xor '0'&alu_r_in) when "110",
	(others => '-') when others;
    alu_res_out <= std_logic_vector(alu_res(WORD_LEN-1 downto 0));
    alu_cout <= alu_res(WORD_LEN);
end architecture behavior;
