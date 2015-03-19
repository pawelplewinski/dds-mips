library IEEE;

use IEEE.std_logic_1164.all;


entity verifier is
    generic(
        PGM_FILE : string    := "no.file";
        IA_LEN   : natural   :=  9;
        DA_LEN   : natural   :=  6);
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        rstn     : in std_logic);
end entity verifier;

architecture behav of verifier is
    alias clock is
        << signal ^.gut.clk : std_logic >>;
    alias reset is
        << signal ^.gut.clk : std_logic >>;
begin
    cmp : process (rst,clk)
    begin
        if rst = '1' then
        elsif rising_edge(clk) then
            if clock = reset then
                assert false report "REPORTREPORTREPORTREPORTREPORTREPORTREPORTREPORTREPORT" severity error;
            else 
                assert false report "TORTETORTETORTETORTETORTETORTETORTETORTETORTETORTETORTE" severity error;
            end if;
            
            assert false report "TORTETORTETORTETORTETORTETORTETORTETORTETORTETORTETORTE" severity error;

        end if;
    end process cmp;
end architecture behav;