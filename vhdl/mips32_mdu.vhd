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
    subtype u32 is unsigned(31 downto 0);
    
    -- Registers
    -- MDU operands
    signal mdu_r : u32 := (others => '0');
    signal mdu_l : u32 := (others => '0');
    -- Result registers
    signal hireg : u32 := (others => '0');
    signal loreg : u32 := (others => '0');
    -- Mode selection (1 = mult; 0 = divu)
    signal cmode : std_logic := '0';
    -- Status
    signal busy : std_logic := '0';
    signal ctr : integer range 31 downto 0 := 0;
    -- Multiplier specific
    signal lsb : std_logic := '0';
    
    -- Combinatorial wires
    -- Sign inversion (2's complement)
    signal nmdu_l : u32;
    signal nmdu_r : u32;
    -- Shifts
    signal hireg_nxt : u32;
    signal loreg_nxt : u32;
    -- Adder
    signal add_l : u32;
    signal add_r : u32;
    signal add_o : u32;
    signal add_l_sel : std_logic;
    signal add_r_sel : std_logic_vector(2 downto 0);
    -- Tiny comparator (used by divu)
    signal cmp : std_logic;
begin
    -- Negate the inputs
    nmdu_l <= (not mdu_l) + 1;
    nmdu_r <= (not mdu_r) + 1;

    -- Left adder input multiplexer
    add_l <= hireg when add_l_sel = '1' else
	     hireg_nxt;
    -- Right adder input multiplexer
    with add_r_sel select add_r <=
	mdu_l when "001"|"101",
	nmdu_l when "010"|"110",
	nmdu_r when "100",
	(others => '0') when others;
    add_o <= add_l + add_r;
    
    -- Adder input multiplexers control signals
    add_r_sel <= '0'&loreg(0)&lsb when cmode = '1'  -- Select LSB's of the product as control signals if in 'multiply' mode
	         else cmp&"00";		    -- Select comparator output as control if in 'divide' mode
    -- The left adder input
    add_l_sel <= cmode;
    
    -- In 'divide' mode, check if shifted version is greater than divider value
    cmp <= '1' when hireg_nxt >= mdu_r else '0';
    
    -- shifts
    hireg_nxt <= hireg(30 downto 0) & mdu_l(ctr) when cmode = '0' else
		 add_o(31) & add_o(31 downto 1);
    loreg_nxt <= add_o(0) & loreg(31 downto 1);
    
    -- output
    rdy_o <= '1' when ctr = 0 and busy = '1' else '0';
    mdu_hi_o <= std_logic_vector(hireg);
    mdu_lo_o <= std_logic_vector(loreg);
    
    seq : process(clk, resetn)
    begin
	if resetn = '0' then
	    lsb <= '0';
	    mdu_r <= (others => '0');
	    mdu_l <= (others => '0');
	    hireg <= (others => '0');
	    loreg <= (others => '0');
	    cmode <= '0'; --divu by default
	    ctr <= 0;
	    busy <= '0';
	elsif rising_edge(clk) then
	    if busy = '1' then
		if cmode = '0' then
		    hireg <= add_o;
		    loreg(ctr) <= cmp;
		else
		    hireg <= hireg_nxt;
		    loreg <= loreg_nxt;
		    lsb <= loreg(0);
		end if;
		if ctr = 0 then
		    busy <= '0';
		else
		    ctr <= ctr - 1;
		end if;
	    elsif start_i = '1' then
		cmode <= mode_i;
		-- If the multiplier or divider right side is 0, don't do anything
		if mdu_r_i /= (31 downto 0 => '0') then
		    mdu_r <= unsigned(mdu_r_i);
		    mdu_l <= unsigned(mdu_l_i);
		    ctr <= 31;
		    busy <= '1';
		else
		    mdu_r <= (others => '0');
		    mdu_l <= (others => '0');
		    ctr <= 0;
		    busy <= '1';
		end if;
		
		if mode_i = '1' then
		    loreg <= unsigned(mdu_r_i);
		else
		    loreg <= (others => '0');
		end if;
		lsb <= '0';
		hireg <= (others => '0');
	    end if;
	end if;
    end process seq;
end architecture behavior;