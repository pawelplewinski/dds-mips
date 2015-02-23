library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture behavior of mips32core is
    subtype u32_stype is unsigned(SYS_32-1 downto 0);
    
    type reg_file_type is array (natural range <>) of u32_stype;
    -- GPREG bank
    signal reg      : reg_file_type(1 to 31);
    signal sreg     : u32_stype;
    signal treg     : u32_stype;
    signal hireg    : u32_stype;
    signal loreg    : u32_stype;
    
    type inst_state_type is (init,fetch,decode,execute,writeback);
    signal state    : inst_state_type := init;
    
    signal pgc      : unsigned(IA_LEN-1 downto 0);      -- program counter
    signal pgc_next : unsigned(IA_LEN-1 downto 0);
    
    signal inst     : std_logic_vector(SYS_32-1 downto 0);
    alias optc      : std_logic_vector(5 downto 0) is inst(31 downto 26);
    alias saddr     : std_logic_vector(4 downto 0) is inst(25 downto 21);
    alias taddr     : std_logic_vector(4 downto 0) is inst(20 downto 16);
    alias daddr     : std_logic_vector(4 downto 0) is inst(15 downto 11);
    alias func      : std_logic_vector(5 downto 0) is inst(5 downto 0);
    
    signal eaddr : u32_stype;
    signal d_sel    : integer range 0 to SYS_32-1;
    signal s_sel    : integer range 0 to SYS_32-1;
    signal t_sel    : integer range 0 to SYS_32-1;
    signal imval    : unsigned(25 downto 0);            -- stores the immediate value

    -- DEBUG signals and variables
    signal done     : boolean := false;
begin
    sreg <= (others => '0') when s_sel = 0      else reg(s_sel);
    treg <= (others => '0') when t_sel = 0      else reg(t_sel);
    
    dbus_addr_out <= std_logic_vector(eaddr(DA_LEN-1 downto 0));

    exec : process(clk, resetn)
        variable addres : unsigned(32 downto 0);    -- 
        variable mres   : unsigned(63 downto 0);    -- mult result
    begin
        if(resetn = '0') then
            state           <= init;
            for i in 1 to SYS_32-1 loop
                reg(i)      <= (others => '0');
            end loop;
            pgc             <= (others => '0');
            imval           <= (others => '0');
            hireg           <= (others => '0');
            loreg           <= (others => '0');
            dbus_addr_out   <= (others => '0');
            dbus_data_out   <= (others => '0');
            ibus_addr_out   <= (others => '0');
            dbus_wren_out   <= '0';
        elsif(rising_edge(clk)) then
            -- Instruction state machine
            case state is
                when init =>
                    state <= fetch;     -- Update state
                when fetch => 
                    state <= decode;    -- Update state
                    inst <= ibus_data_inp;
                when decode =>
                    state <= execute;   -- Update state
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
                    state <= writeback; -- Update state
                    case optc is
                        -- Special
                        when "000000" =>
                            -- syscall;
                            if func = "001100" then
                                --int0 <= '1';
                                done <= false;
                            elsif d_sel /= 0 then
                            -- Don't do anything if d_sel is 0 (can't write to this reg)
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
                                    -- mult
                                    when "011000" =>
                                        mres := sreg * treg;
                                        hireg <= mres(63 downto 32);
                                        loreg <= mres(31 downto 0);
                                        -- Execute iterative algorithm
                                    -- divu
                                    when "011011" =>
                                        hireg <= ((31 downto 0 => '0') & sreg) mod treg;
                                        loreg <= ((31 downto 0 => '0') & sreg) / treg;
                                        -- Execute iterative algorithm
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
                            dbus_wren_out <= '1';
                            eaddr <= sreg + ((31 downto 16 => imval(15)) & imval(15 downto 0));
                            dbus_data_out <= std_logic_vector(treg);
                            pgc_next <= pgc + 1;
                        -- Other instructions not implemented, count as NOP
                        when others => null;
                    end case;
                when writeback =>
                    state <= fetch;     -- Update state
                    case optc is
                        -- syscall
                        when  "000000" =>
                            if(func = "001100") then
                                --int0 <= '0';
                                done <= true;
                            end if;
                        -- LW
                        when  "100011" =>
                            if t_sel /= 0 then
                                reg(t_sel) <= unsigned(dbus_data_inp);
                            end if;
                        -- SW
                        when  "101011" =>
                            dbus_wren_out <= '0';
                        when others => null;
                    end case;
                    pgc <= pgc_next;
                    ibus_addr_out <= std_logic_vector(pgc_next);
            end case;
        end if;
    end process exec;
end architecture behavior;
