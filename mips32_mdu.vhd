library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Multiplication and Division Unit

entity mips32_mdu is
    port(
    mdu_l_inp  : in  std_logic_vector(31 downto 0);
    mdu_r_inp  : in  std_logic_vector(31 downto 0);
    
    mdu_hi_out : out std_logic_vector(31 downto 0);
    mdu_lo_out : out std_logic_vector(31 downto 0);
    
    mode_inp   : in  std_logic;                         -- selects mult(0) or divu(1)
    start_inp  : in  std_logic;
    rdy_out    : out std_logic;
    
    clk        : in  std_logic;
    resetn     : in  std_logic);
end entity mips32_mdu;

architecture behavior of mips32_mdu is
    signal loreg         : std_logic_vector(31 downto 0);
    signal hireg         : std_logic_vector(31 downto 0);   -- used for divu
    signal hireg_nxt     : unsigned(31 downto 0);
    signal ctr           : integer range 31 downto 0;
    signal rdy           : std_logic;
    signal start_inp_tmp : std_logic;
begin
	-- PSL default clock is rising_edge(clk);

	--PSL mdu_cycles_cnt: assert always (start_inp -> next[32] (rdy));
    calc : process(clk, resetn)
        -- mult and divu vars
        variable runp : std_logic;
        -- mult vars
        variable br,nbr : std_logic_vector(31 downto 0);
        variable acqr   : std_logic_vector(63 downto 0);
        variable qn1    : std_logic ;
    begin
        if resetn = '0' then
            hireg         <= (others => '0');
            loreg         <= (others => '0');
            ctr           <= 0;
            rdy           <= '0';
            start_inp_tmp <= '0';
        elsif rising_edge(clk) then
            -- save start impulse 
            -- (i.e. to keep the iterative process running while starts get inactive again)
            if start_inp = '1' then 
                runp := '1';            -- set to 1 when receiving start
            else
                runp := start_inp_tmp;  -- keep old value
            end if;
            
            -- DIVU
            if mode_inp = '1' and runp = '1' then -- divu
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
                    runp := '0';
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
                    if start_inp = '1' then -- first cycle
                        -- Check if divider is 0 -> finish divu if true
                        if mdu_r_inp /= (31 downto 0 => '0') then
                            rdy  <= '0';
                            ctr  <= 31;
                            runp := '1';
                        else
                            rdy  <= '1';
                            ctr  <= 0;
                            runp := '1';
                        end if;
                        hireg <= (others => '0');
                        loreg <= (others => '0');
                    else -- (last cycle) reset
                        rdy   <= '0';
                        ctr   <= 0;
                        runp  := '1';
                        hireg <= hireg;
                        loreg <= loreg;
                    end if;
                end if;
                -- end DIVU process
            -- MULT
            elsif runp = '1'then -- ..and mode_inp = '0'
                --assert false report "DEBUG: MULT" severity warning;
                if (ctr > 0 and runp = '1') then
                    ctr  <= ctr - 1;
                    rdy  <= '0';
                    
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
                elsif ctr = 0 then -- last cycle
                    if start_inp = '1' then -- first cycle
                        acqr(63 downto 32) := (others=>'0');
                        acqr(31 downto  0) := mdu_l_inp;
                        br  := mdu_r_inp;
                        nbr := (not mdu_r_inp) + '1';
                        qn1 := '0';
                        ctr  <= 30;

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
                    else -- (last cycle) reset 
                        rdy  <= '1';
                        runp := '0';
                        
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
                    end if;
                end if;
                hireg <= acqr(63 downto 32);
                loreg <= acqr(31 downto  0);
            else -- reset all if no operation (MULT or DIVU) is selected
                ctr           <= 0;
                rdy           <= '0';
                start_inp_tmp <= '0';
            end if; -- end MULT (and DIVU)

            start_inp_tmp <= runp; -- update start reg
        end if;
    end process calc;

    -- read inputs into local regs    
    rdy_out    <= rdy;
    mdu_hi_out <= hireg;
    mdu_lo_out <= loreg;
    -- for divu
    hireg_nxt  <= unsigned(hireg(30 downto 0) & mdu_l_inp(ctr));
    
end architecture behavior;