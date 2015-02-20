library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clock_gen is
    generic(
        period  : time := 10 ns);
    port(
        reset   : in  std_logic;
        clk     : out std_logic);
end entity clock_gen;

architecture behav of clock_gen is
    signal clk_internal : std_logic;
begin

    clk_gen: process
    begin
        -- Wait for reset to start the clock
        if reset /= '0' then
            clk_internal <= '0';
            WAIT UNTIL reset = '0';
        elsif reset = '0' then
            clk_internal <= not clk_internal;
            WAIT UNTIL reset = '1' FOR period;
        end if;
    end process clk_gen;
    
    clk <= clk_internal;

end architecture behav;



