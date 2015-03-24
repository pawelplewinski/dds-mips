library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture behavior of mips32core is
  subtype u32 is unsigned(31 downto 0);
	type reg_file is array (natural range <>) of u32;
	-- GPREG bank
	signal reg : reg_file(1 to 31);
	signal sreg : u32;
	signal treg : u32;
	signal hireg : u32;
	signal loreg : u32;
	type Inst_state is (init,fetch,decode,execute,writeback);
	signal state : Inst_state := init;
	signal pgc : unsigned(IA_LEN-1 downto 0);
	signal inst : std_logic_vector(31 downto 0);
	
	signal d_sel : integer range 0 to 31;
	signal s_sel : integer range 0 to 31;
	signal t_sel : integer range 0 to 31;
	signal imval : unsigned(25 downto 0);
	signal pgc_next : unsigned(IA_LEN-1 downto 0);
	signal eaddr : u32;
	signal mductr : integer range 0 to 33 := 32;
	alias optc : std_logic_vector(5 downto 0) is inst(31 downto 26);
	alias saddr : std_logic_vector(4 downto 0) is inst(25 downto 21);
	alias taddr : std_logic_vector(4 downto 0) is inst(20 downto 16);
	alias daddr : std_logic_vector(4 downto 0) is inst(15 downto 11);
	alias func : std_logic_vector(5 downto 0) is inst(5 downto 0);
begin
    sreg <= (others => '0') when s_sel = 0 else
	reg(s_sel);
    treg <= (others => '0') when t_sel = 0 else
	reg(t_sel);
    dbus_a_o <= std_logic_vector(eaddr(DA_LEN-1 downto 0));
    exec : process(clk, resetn)
      variable addres : unsigned(32 downto 0);
      variable mres : unsigned(63 downto 0);
      variable state_next : Inst_state := init;
    begin
	if(resetn = '0') then
	    for i in 1 to 31 loop
		reg(i) <= (others => '0');
	    end loop;
	    state <= init;
	    pgc <= (others => '0');
	    imval <= (others => '0');
	    hireg <= (others => '0');
	    loreg <= (others => '0');
	    dbus_a_o <= (others => '0');
	    dbus_d_o <= (others => '0');
	    ibus_a_o <= (others => '0');
	    dbus_we_o <= '0';
	    mductr <= 32;
	elsif(rising_edge(clk)) then
	    -- Instruction state machine
		case state is
		when init => 
		    state <= fetch;
		when fetch => 
		    state <= decode;
		    inst <= ibus_d_i;
		when decode => state <= execute;
		    -- The decoding stage extracts important information from instruction code
		    -- Normally, during this step all of the control signals in the DP are configured
		    case optc is
		    -- R instruction (mult,add,and,or,xor,sub,mfhi,mflo,divu)
		    when "000000" =>
			d_sel <= to_integer(unsigned(daddr));
			t_sel <= to_integer(unsigned(taddr));
			s_sel <= to_integer(unsigned(saddr));
		    -- J instruction
		    when "000010" =>
			imval(25 downto 0) <= unsigned(inst(25 downto 0));
		    -- BEQ 
		    when "000100" =>
			imval(15 downto 0) <= unsigned(inst(15 downto 0));
			t_sel <= to_integer(unsigned(taddr));
			s_sel <= to_integer(unsigned(saddr));
		    -- BGTZ
		    when "000111" =>
			imval(15 downto 0) <= unsigned(inst(15 downto 0));
			s_sel <= to_integer(unsigned(saddr));
		    -- I instructions (addi, andi, ori, lui)
		    when "001000" | "001100" | "001101" | "001111" =>
			imval(15 downto 0) <= unsigned(inst(15 downto 0));
			t_sel <= to_integer(unsigned(taddr));
			s_sel <= to_integer(unsigned(saddr));
		    -- load instructions (lw)
		    when "100011" | "101011" =>
			imval(15 downto 0) <= unsigned(inst(15 downto 0));
			t_sel <= to_integer(unsigned(taddr));
			s_sel <= to_integer(unsigned(saddr));
		    -- Other instructions not implemented, count as NOP
		    when others => 
			optc <= "000000";
			func <= "000000";
			d_sel <= 0;
			t_sel <= 0;
			s_sel <= 0;
		    end case;
		when execute => 
		    -- Now the instruction is actually executed
		    state_next := writeback;
		    case optc is
		    -- Special
		    when "000000" =>
			if func = "001100" then
			-- syscall;
			    int0 <= '1';
			elsif func = "011000" then
			-- mult
			    mres := sreg * treg;
			    hireg <= mres(63 downto 32);
			    loreg <= mres(31 downto 0);
			    -- Execute iterative algorithm
			-- divu
			elsif func = "011011" then
			    if treg /= 0 then
				hireg <= sreg mod treg;
				loreg <= sreg / treg;
			    end if;
			    if mductr > 0 then
				state_next := execute;
				if treg /= 0 then
				    mductr <= mductr - 1;
				else
				    mductr <= 0;
				end if;
			    else
				state_next := writeback;
				mductr <= 32;
			    end if;
			    -- Execute iterative algorithm
			-- Don't do anything if d_sel is 0 (can't write to this reg)
			elsif d_sel /= 0 then
			case func is
			-- add
			when "100000" =>
			      addres := ('0'&sreg) + ('0'&treg);
			      reg(d_sel) <= addres(31 downto 0);
			-- sub
			when "100010" =>
			      addres := ('0'&sreg) - ('0'&treg);
			      reg(d_sel) <= addres(31 downto 0);
			-- bitwise and
			when "100100" =>
			      reg(d_sel) <= sreg and treg;
			-- bitwise or
			when "100101" =>
			      reg(d_sel) <= sreg or treg;
			-- bitwise xor
			when "100110" =>
			      reg(d_sel) <= sreg xor treg;
			-- mfhi
			when "010000" =>
			    reg(d_sel) <= hireg;
			-- mflo
			when "010010" =>
			    reg(d_sel) <= loreg;
			-- other r instructions are not implemented
			when others => null;    
			end case;
			end if;
			pgc_next <= pgc + 1;
		    -- J instruction
		    when "000010" =>
			pgc_next <= imval(IA_LEN-1 downto 0);
		    -- BEQ instruction
		    when "000100" =>
			-- sign extended add
			addres := ((32 downto IA_LEN => '0') & pgc) + ((32 downto 16 => imval(15)) & imval(15 downto 0)) + 1;
			if(sreg = treg) then
			    pgc_next <= addres(IA_LEN-1 downto 0);
			else
			    pgc_next <= pgc + 1;
			end if;
		    -- BGTZ instruction
		    when "000111" =>
			-- sign extended add
			addres := ((32 downto IA_LEN => '0') & pgc) + ((32 downto 16 => imval(15)) & imval(15 downto 0)) + 1;
			-- signed 
			if(sreg(31) = '0' and (sreg(30 downto 0) > 0)) then
			    pgc_next <= addres(IA_LEN-1 downto 0);
			else
			    pgc_next <= pgc + 1;
			end if;
		    -- I instructions (addi, andi, ori, lui)
		    when "001000" | "001100" | "001101" | "001111" =>
			if t_sel /= 0 then
			case optc(2 downto 0) is
			when "000" =>
			    -- addi (sign extended)
			    reg(t_sel) <= sreg + ((31 downto 16 => imval(15)) & imval(15 downto 0));
			when "100" =>
			    -- andi
			    reg(t_sel) <= sreg and ((31 downto 16 => '0') & imval(15 downto 0));
			when "101" =>
			    -- ori
			    reg(t_sel) <= sreg or ((31 downto 16 => '0') & imval(15 downto 0));
			when "111" =>
			    -- lui
			    reg(t_sel) <= imval(15 downto 0) & (15 downto 0 => '0');
			when others => null;
			end case;
			end if;
			pgc_next <= pgc + 1;
		    -- LW
		    when "100011" =>
			eaddr <= sreg + ((31 downto 16 => imval(15)) & imval(15 downto 0));
			pgc_next <= pgc + 1;
		    -- SW
		    when "101011" =>
			dbus_we_o <= '1';
			eaddr <= sreg + ((31 downto 16 => imval(15)) & imval(15 downto 0));
			dbus_d_o <= std_logic_vector(treg);
			pgc_next <= pgc + 1;
		    -- Other instructions not implemented, count as NOP
		    when others => null;
		    end case;
		    state <= state_next;
		when writeback =>
		    state <= fetch;
		    case optc is
		    -- syscall
		    when  "000000" =>
			if(func = "001100") then
			    int0 <= '0';
			end if;
		    -- LW
		    when  "100011" =>
		    if t_sel /= 0 then
			reg(t_sel) <= unsigned(dbus_d_i);
		    end if;
		    -- SW
		    when  "101011" =>
			dbus_we_o <= '0';
		    when others => null;
		    end case;
		    
		    pgc <= pgc_next;
		    ibus_a_o <= std_logic_vector(pgc_next);
		end case;
	end if;
    end process exec;
end architecture behavior;
