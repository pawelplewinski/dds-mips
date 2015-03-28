library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_mdu is
    port(
	mdu_l_i : in std_logic_vector(31 downto 0);
	mdu_r_i : in std_logic_vector(31 downto 0);
	
	mdu_hi_o : out std_logic_vector(31 downto 0);
	mdu_lo_o : out std_logic_vector(31 downto 0);
	
	mode_i : in std_logic;
	rdy_o : out std_logic;
	start_i : in std_logic;
	
	clk : in std_logic;
	resetn : in std_logic);
end entity mips32_mdu;

architecture behavior of mips32_mdu is
    signal hireg : unsigned(31 downto 0);
    signal hireg_nxt : unsigned(31 downto 0);
    signal loreg : unsigned(31 downto 0);
    --signal cmode : std_logic;
    signal ctr : integer range 31 downto 0 := 0;
    signal rdy : std_logic := '0';
	begin
	-- PSL default clock is rising_edge(clk);
	
	--PSL mdu_cycles_cnt: assert always (start_i -> next[32] (rdy)) abort not resetn;
    calc : process(clk, resetn) 
    begin
	if resetn = '0' then
	    hireg <= (others => '0');
	    loreg <= (others => '0');
	    ctr <= 0;
	    rdy <= '0';
	elsif rising_edge(clk) then
	    if ctr > 0 then
		if ctr = 1 then
		    rdy <= '1';
		else
		    rdy <= '0';
		end if;
		-- R >= D
		if hireg_nxt >= unsigned(mdu_r_i) then
		    hireg <= hireg_nxt - unsigned(mdu_r_i);
		    loreg(ctr) <= '1';
		else
		    hireg <= hireg_nxt;
		    loreg(ctr) <= '0';
		end if;
		ctr <= ctr - 1;
	    elsif rdy = '1' then
		rdy <= '0';
		-- R >= D
		if hireg_nxt >= unsigned(mdu_r_i) then
		    hireg <= hireg_nxt - unsigned(mdu_r_i);
		    loreg(ctr) <= '1';
		else
		    hireg <= hireg_nxt;
		    loreg(ctr) <= '0';
		end if;
		ctr <= 0;
	    else
		if start_i = '1' then
		    if mdu_r_i /= (31 downto 0 => '0') then
			rdy <= '0';
			ctr <= 31;
		    else
			rdy <= '1';
			ctr <= 0;
		    end if;
		    hireg <= (others => '0');
		    loreg <= (others => '0');
		else
		    ctr <= 0;
		    rdy <= '0';
		    hireg <= hireg;
		    loreg <= loreg;
		end if;
	    end if;
	end if;
    end process calc;
    
    hireg_nxt <= hireg(30 downto 0) & mdu_l_i(ctr);
    rdy_o <= rdy;
    mdu_hi_o <= std_logic_vector(hireg);
    mdu_lo_o <= std_logic_vector(loreg);
end architecture behavior;