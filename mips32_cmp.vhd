library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- separate compare unit for instr like bgtz
-- DEBUG: use std_match(a,b) to prevent dontcare conversion problems

entity mips32_cmp is
    port(
    cmp_l_inp : in std_logic_vector(31 downto 0);
    cmp_r_inp : in std_logic_vector(31 downto 0);
    
    cmp_eq_out : out std_logic;
    cmp_gt_out : out std_logic);
end entity mips32_cmp;
    
architecture behav of mips32_cmp is
begin
    cmp: process(cmp_l_inp,cmp_r_inp)
    begin
        -- DEBUG: if check is supposed to suppress warnings
        if cmp_l_inp = "--------------------------------" or cmp_r_inp = "--------------------------------" then
            cmp_eq_out <= '0';
            cmp_gt_out <= '0';
        else
            if(unsigned(cmp_l_inp) = unsigned(cmp_r_inp)) then
                cmp_eq_out <= '1';
                cmp_gt_out <= '0';
            elsif(unsigned(cmp_l_inp) > unsigned(cmp_r_inp)) then
                cmp_eq_out <= '0';
                cmp_gt_out <= '1';
            else
                cmp_eq_out <= '0';
                cmp_gt_out <= '0';
            end if;
        end if;
    end process cmp;
end architecture behav;