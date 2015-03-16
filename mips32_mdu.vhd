library IEEE;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- Multiplication and Division Unit

entity mips32_mdu is
    port(
    mdu_l_inp  : in  std_logic_vector(31 downto 0);
    mdu_r_inp  : in  std_logic_vector(31 downto 0);
    
    mdu_hi_out : out std_logic_vector(31 downto 0);
    mdu_lo_out : out std_logic_vector(31 downto 0);
    
    mode_inp   : in  std_logic;                         -- selects mult(0) or divu(0)
    start_inp  : in  std_logic;
    rdy_out    : out std_logic;
    
    clk        : in  std_logic;
    resetn     : in  std_logic);
end entity mips32_mdu;

architecture behavior of mips32_mdu is
    signal hireg         : std_logic_vector(31 downto 0);   -- used for divu
    signal hireg_nxt     : unsigned(31 downto 0);
    signal loreg         : std_logic_vector(31 downto 0);
    signal ctr           : integer range 31 downto 0;
    signal rdy           : std_logic;
    signal start_inp_tmp : std_logic;
    --signal cmode     : std_logic;
begin
    calc : process(clk, resetn)
        variable mres : signed(63 downto 0);
        variable strt : std_logic;
		variable br,nbr : std_logic_vector(31 downto 0);
		variable qn1 : std_logic ;	
		variable acqr : std_logic_vector(63 downto 0);		
    begin
        if resetn = '0' then
            hireg         <= (others => '0');
            loreg         <= (others => '0');
            ctr           <= 0;
            rdy           <= '0';
            start_inp_tmp <= '0';
        elsif rising_edge(clk) then
            if start_inp = '1' then 
                strt := '1'; 
            else
                strt := start_inp_tmp;
            end if;
            if mode_inp = '1' and strt = '1' then -- divu
                if ctr > 0 then
                    if ctr = 1 then
                        rdy <= '1';
                    else
                        rdy <= '0';
                    end if;
                    -- R >= D
                    if hireg_nxt >= unsigned(mdu_r_inp) then
                        hireg      <= std_logic_vector(hireg_nxt - unsigned(mdu_r_inp));
                        loreg(ctr) <= '1';
                    else
                        hireg      <= std_logic_vector(hireg_nxt);
                        loreg(ctr) <= '0';
                    end if;
                    ctr <= ctr - 1;
                elsif rdy = '1' then
                    rdy  <= '0';
                    strt := '0';
                    -- R >= D
                    if hireg_nxt >= unsigned(mdu_r_inp) then
                        hireg      <= std_logic_vector(hireg_nxt - unsigned(mdu_r_inp));
                        loreg(ctr) <= '1';
                    else
                        hireg      <= std_logic_vector(hireg_nxt);
                        loreg(ctr) <= '0';
                    end if;
                    ctr <= 0;
                else -- ctr = 0
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
            elsif strt = '1' then -- mult
				if (ctr = 0) then
					acqr(63 downto 32) := (others=>'0');
					acqr(31 downto  0) := mdu_l_inp;
					br  := (mdu_r_inp);
					nbr := (not mdu_r_inp) + '1';
					qn1 := '0';
					rdy <= '1';
				end if;
				if (ctr < 31) then
					if( acqr(0) = '0' and qn1 = '0') then
						qn1 := acqr(0);
						acqr(62 downto 0) := acqr(63 downto 1);
					elsif ( acqr(0) = '0' and qn1 = '1') then
						acqr(63 downto 32) := acqr(63 downto 32) + br;
						qn1 := acqr(0);
						acqr(62 downto 0) := acqr(63 downto 1);
					elsif ( acqr(0) = '1' and qn1 = '0') then
						acqr(63 downto 32) := acqr(63 downto 32) + nbr;
						qn1 := acqr(0);
						acqr(62 downto 0) := acqr(63 downto 1);
					elsif ( acqr(0) = '1' and qn1 = '1') then
							qn1 := acqr(0);
							acqr(62 downto 0) := acqr(63 downto 1);
					end if ;
					ctr <= ctr + 1;
					rdy <= '1';
				end if; 
				if (ctr = 31) then
					rdy <= '0';
					ctr <= 0;
				end if;
					hireg <= acqr(63 downto 32);
					loreg <= acqr(31 downto 0);

                -- ctr <= ctr + 1;
                -- if ctr = 31 then 
                    -- ctr <= 0;
                    -- rdy <= '1';
                -- else
                    -- rdy  <= '0';
                    -- strt := '0';
                -- end if;
                -- mres  := signed(mdu_l_inp) * signed(mdu_r_inp);
                -- hireg <= std_logic_vector(mres(63 downto 32));
                -- loreg <= std_logic_vector(mres(31 downto  0));
                -- assert false report "DEBUG: MULTMULTMULTMULTMULTMULTMULTMULTMULTMULTMULT" severity warning;
            end if;
            start_inp_tmp <= strt;
        end if;
    end process calc;

    -- read inputs into local regs    
    rdy_out    <= rdy;
    mdu_hi_out <= std_logic_vector(hireg);
    mdu_lo_out <= std_logic_vector(loreg);
    -- for divu
    hireg_nxt  <= unsigned(hireg(30 downto 0) & mdu_l_inp(ctr));
    
end architecture behavior;