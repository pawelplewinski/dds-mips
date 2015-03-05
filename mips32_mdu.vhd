library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Multiplication and Division Unit

entity mips32_mdu is
    port(
    mdu_l_inp  : in  std_logic_vector(31 downto 0);
    mdu_r_inp  : in  std_logic_vector(31 downto 0);
    
    mdu_hi_out : out std_logic_vector(31 downto 0);
    mdu_lo_out : out std_logic_vector(31 downto 0);
    
    mode_inp   : in  std_logic;
    rdy_out    : out std_logic;
    start_inp  : in  std_logic;
    
    clk        : in  std_logic;
    resetn     : in  std_logic);
end entity mips32_mdu;

architecture behavior of mips32_mdu is
    signal hireg     : unsigned(31 downto 0);
    signal hireg_nxt : unsigned(31 downto 0);
    signal loreg     : unsigned(31 downto 0);
    signal ctr       : integer range 31 downto 0 := 0;
    signal rdy       : std_logic := '0';
    --signal cmode     : std_logic;
begin
    calc : process(clk, resetn) 
    begin
        if resetn = '0' then
            hireg <= (others => '0');
            loreg <= (others => '0');
            ctr   <= 0;
            rdy   <= '0';
        elsif rising_edge(clk) then
            if ctr > 0 then
                if ctr = 1 then
                    rdy <= '1';
                else
                    rdy <= '0';
                end if;
                -- R >= D
                if hireg_nxt >= unsigned(mdu_r_inp) then
                    hireg      <= hireg_nxt - unsigned(mdu_r_inp);
                    loreg(ctr) <= '1';
                else
                    hireg      <= hireg_nxt;
                    loreg(ctr) <= '0';
                end if;
                ctr <= ctr - 1;
            elsif rdy = '1' then
                rdy <= '0';
                -- R >= D
                if hireg_nxt >= unsigned(mdu_r_inp) then
                    hireg      <= hireg_nxt - unsigned(mdu_r_inp);
                    loreg(ctr) <= '1';
                else
                    hireg      <= hireg_nxt;
                    loreg(ctr) <= '0';
                end if;
                ctr <= 0;
            else
                rdy <= '0';
                if start_inp = '1' then
                    if mdu_r_inp /= (31 downto 0 => '0') then
                        ctr <= 31;
                    else
                        ctr <= 0;
                    end if;
                    hireg <= (others => '0');
                    loreg <= (others => '0');
                else
                    ctr   <= 0;
                    hireg <= hireg;
                    loreg <= loreg;
                end if;
            end if;
        end if;
    end process calc;
    
    hireg_nxt  <= hireg(30 downto 0) & mdu_l_inp(ctr);
    rdy_out    <= rdy;
    mdu_hi_out <= std_logic_vector(hireg);
    mdu_lo_out <= std_logic_vector(loreg);
end architecture behavior;