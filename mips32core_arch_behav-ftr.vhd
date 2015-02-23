library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture behavior of mips32core is
begin
    exec : process(clk, resetn)
        subtype u32 is unsigned(31 downto 0);
        type reg_file is array (natural range <>) of u32;
        -- GPREG bank
        variable reg   : reg_file(1 to 31);
        variable sreg  : u32;
        variable treg  : u32;
        variable hireg : u32;
        variable loreg : u32;
        type inst_state is (init,fetch,decode,execute);
        variable state : inst_state := init;
        variable pgc   : unsigned(IA_LEN-1 downto 0);
        variable inst  : std_logic_vector(31 downto 0);
        variable optc  : std_logic_vector(5 downto 0);
        variable func  : std_logic_vector(5 downto 0);
        variable d_sel : integer range 0 to 31;
        variable s_sel : integer range 0 to 31;
        variable t_sel : integer range 0 to 31;
        variable addr  : unsigned(32 downto 0);
        variable imval : unsigned(25 downto 0);
    begin
        if(resetn = '0') then
            for i in 1 to 31 loop
                reg(i) := (others => '0');
            end loop;
            state := init;
            pgc := (others => '0');
            dbus_addr_out <= (others => '0');
            dbus_data_out <= (others => '0');
            ibus_addr_out <= (others => '0');
            dbus_wren_out <= '0'; 
        elsif(rising_edge(clk)) then
	    -- Instruction state machine
            case state is
                when init => 
                    state := fetch;
                when fetch => 
                    state := decode;
                    ibus_addr_out <= std_logic_vector(pgc);
                    inst := ibus_data_inp;
                    optc := inst(31 downto 26);
                when decode => state := execute;
                    -- The decoding stage extracts important information from instruction code
                    -- Normally, during this step all of the control signals in the DP are configured
                    case optc is
                        -- R instruction (mult,add,and,or,xor,sub,mfhi,mflo,divu)
                        when "000000" =>
                            func := inst(5 downto 0);
                            d_sel := to_integer(unsigned(inst(15 downto 11)));
                            t_sel := to_integer(unsigned(inst(20 downto 16)));
                            s_sel := to_integer(unsigned(inst(25 downto 21)));
                        -- J instruction
                        when "000010" =>
                            imval(25 downto 0) := unsigned(inst(25 downto 0));
                        -- BEQ 
                        when "000100" =>
                            imval(15 downto 0) := unsigned(inst(15 downto 0));
                            t_sel := to_integer(unsigned(inst(20 downto 16)));
                            s_sel := to_integer(unsigned(inst(25 downto 21)));
                        -- BGTZ
                        when "000111" =>
                            imval(15 downto 0) := unsigned(inst(15 downto 0));
                            s_sel := to_integer(unsigned(inst(25 downto 21)));
                        -- I instructions (addi, andi, ori, lui)
                        when "001---" =>
                            imval(15 downto 0) := unsigned(inst(15 downto 0));
                            t_sel := to_integer(unsigned(inst(20 downto 16)));
                            s_sel := to_integer(unsigned(inst(25 downto 21)));
                        -- Other instructions not implemented, count as NOP
                        when others => 
                            optc := "000000";
                            func := "000000";
                            d_sel := 0;
                            t_sel := 0;
                            s_sel := 0;
                    end case;
                when execute => 
                    -- Now the instruction is actually executed
                    -- There is no memory access, so WB stage is skipped
                    state := fetch;
                    if(s_sel = 0) then
                        sreg := (others => '0');
                    else
                        sreg := reg(s_sel);
                    end if;
                    if(t_sel = 0) then
                        treg := (others => '0');
                    else
                        treg := reg(t_sel);
                    end if;
                    case optc is
                        -- Special
                        when "000000" =>
                            -- Don't do anything if d_sel is 0 (can't write to this reg)
                            if d_sel /= 0 then
                                case func is
                                    -- add
                                    when "100000" =>
                                        addr := ('0'&sreg) + ('0'&treg);
                                        reg(d_sel) := addr(31 downto 0);
                                    -- sub
                                    when "100010" =>
                                        addr := ('0'&sreg) - ('0'&treg);
                                        reg(d_sel) := addr(31 downto 0);
                                    -- bitwise and
                                    when "100100" =>
                                        reg(d_sel) := sreg and treg;
                                    -- bitwise or
                                    when "100101" =>
                                        reg(d_sel) := sreg or treg;
                                    -- bitwise xor
                                    when "100110" =>
                                        reg(d_sel) := sreg xor treg;
                                    -- mult
                                    when "011000" =>
                                        --reg(d_sel) := sreg * treg;
                                        -- Execute iterative algorithm
                                    -- divu
                                    when "011011" =>
                                        --reg(d_sel) := sreg / treg;
                                        -- Execute iterative algorithm
                                    -- mfhi
                                    when "010000" =>
                                        reg(d_sel) := hireg;
                                    -- mflo
                                    when "010010" =>
                                        reg(d_sel) := loreg;
                                    -- other r instructions are not implemented
                                    when others => null;    
                                end case;
                            end if;
                            pgc := pgc + 1;
                        -- J instruction
                        when "000010" =>
                            pgc := imval(IA_LEN-1 downto 0);
                        -- BEQ instruction
                        when "000100" =>
                            -- sign extended add
                            addr := ((32 downto IA_LEN => '0') & pgc) + ((32 downto 16 => imval(15)) & imval(15 downto 0));
                            if(sreg = treg) then
                                pgc := addr(IA_LEN-1 downto 0);
                            else
                                pgc := pgc + 1;
                            end if;
                        -- BGTZ instruction
                        when "000111" =>
                            -- sign extended add
                            addr := ((32 downto IA_LEN => '0') & pgc) + ((32 downto 16 => imval(15)) & imval(15 downto 0));
                            -- signed 
                            if(sreg(31) = '0' and (sreg(30 downto 0) > 0)) then
                                pgc := addr(IA_LEN-1 downto 0);
                            else
                                pgc := pgc + 1;
                            end if;
                        -- I instructions (addi, andi, ori, lui)
                        when "001---" =>
                            case optc(2 downto 0) is
                                when "000" =>
                                    -- addi (sign extended)
                                    reg(t_sel) := sreg + ((31 downto 16 => imval(15)) & imval(15 downto 0));
                                when "100" =>
                                    -- andi
                                    reg(t_sel) := sreg and ((31 downto 16 => '0') & imval(15 downto 0));
                                when "101" =>
                                    -- ori
                                    reg(t_sel) := sreg or ((31 downto 16 => '0') & imval(15 downto 0));
                                when "111" =>
                                    -- lui
                                    reg(t_sel) := imval(15 downto 0) & (15 downto 0 => '0');
                                when others => null;
                            end case;
                        -- Other instructions not implemented, count as NOP
                        when others => null;
                    end case;
            end case;
        end if;
    end process exec;
end architecture behavior;
