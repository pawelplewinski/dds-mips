library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- architecture by Sameera Somisetty

entity boothmult is 
    port( 
        a_in  : in  std_logic_vector(31 downto 0);
        b_in  : in  std_logic_vector(31 downto 0);
        res   : out std_logic_vector(63 downto 0) ;
        start : in  std_logic;
		clk   : in  std_logic;
		done  : out std_logic);
end entity;

architecture booth_arch of boothmult is
begin
    -- PSL l1: assert always TRUE;
    process(start, a_in, b_in, clk)
		variable cnt : integer RANGE 0 TO 33;
		variable br,nbr : std_logic_vector(31 downto 0);
		variable acqr : std_logic_vector(63 downto 0);
		variable qn1 : std_logic ;
    begin
	  if (rising_edge(clk)) then
		if (start = '1') then
            acqr(63 downto 32) := (others=>'0');
            acqr(31 downto  0) := a_in;
            br  := b_in;
            nbr := (not b_in) + '1';
            qn1 := '0';
			res <= (others => '0');
			cnt := 0;
			done <= '0';
		else
    if (cnt < 31) then
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
     cnt := cnt+1;
     done <= '0';
    end if; 
	if (cnt = 31) then
		done <= '1';
	end if;
		res <= acqr;
	end if;
  end if;
    end process ;
end booth_arch;

