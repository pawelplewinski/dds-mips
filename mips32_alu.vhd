library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_alu is
    port(
    func_sel    : in  std_logic_vector(2 downto 0);
    alu_l_inp   : in  std_logic_vector(31 downto 0);
    alu_r_inp   : in  std_logic_vector(31 downto 0);
    alu_res_out : out std_logic_vector(31 downto 0);
    alu_cout    : out std_logic);
end entity mips32_alu;
    
architecture behav of mips32_alu is
    signal alu_res : unsigned (32 downto 0);  -- 33 bit (incl carry bit)
begin
    with func_sel select alu_res <=
        unsigned(alu_l_inp(31) & alu_l_inp) + unsigned(alu_r_inp(31) & alu_r_inp) when "000",   -- add
        unsigned(alu_l_inp(31) & alu_l_inp) - unsigned(alu_r_inp(31) & alu_r_inp) when "010",   -- sub
        unsigned('0' & alu_l_inp and '0' & alu_r_inp)                             when "100",   -- and
        unsigned('0' & alu_l_inp or  '0' & alu_r_inp)                             when "101",   --  or
        unsigned('0' & alu_l_inp xor '0' & alu_r_inp)                             when "110",   -- xor
        (others => '-')                                                           when others;
        
        alu_res_out <= std_logic_vector(alu_res(31 downto 0));
        
        alu_cout    <= alu_res(32);                                                             -- carry
end architecture behav;
