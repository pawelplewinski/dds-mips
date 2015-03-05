library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture behavior of mips32core is

    -- Type declarations
    subtype u32_stype       is unsigned(31 downto 0);    
    type reg_file_type      is array (natural range <>) of u32_stype;
    type op_type            is (no_op, add_op, addi_op, and_op, andi_op, beq_op, bgtz_op, divu_op, j_op, lui_op, lw_op, mfhi_op, mflo_op, mult_op, or_op, ori_op, sub_op, sw_op, syscall, xor_op, r_nop);
    type inst_state_type    is (init,fetch,decode,execute,writeback);

    function getOp (op_code_tmp : std_logic_vector(5 downto 0); func_tmp : std_logic_vector(5 downto 0)) return op_type is
        VARIABLE return_val : op_type;
    begin
        case op_code_tmp is
            -- R instruction (mult,add,and,or,xor,sub,mfhi,mflo,divu)
            when "000000" =>
                case func_tmp is
                    when "001100" =>    return_val := syscall;   -- syscall
                    when "100000" =>    return_val :=  add_op;   -- add
                    when "100010" =>    return_val :=  sub_op;   -- sub
                    when "100100" =>    return_val :=  and_op;   -- and (bitwise)
                    when "100101" =>    return_val :=   or_op;   -- or (bitwise)
                    when "100110" =>    return_val :=  xor_op;   -- xor (bitwise)
                    when "011000" =>    return_val := mult_op;   -- mult
                    when "011011" =>    return_val :=  xor_op;   -- divu
                    when "010000" =>    return_val := mfhi_op;   -- mfhi
                    when "010010" =>    return_val := mflo_op;   -- mflo
                    -- other r instructions are not implemented
                    when others   =>    return_val :=    no_op;   --
                end case;
            -- J instruction
            when "000010" =>            return_val :=    j_op;   -- j
            -- BEQ 
            when "000100" =>            return_val :=  beq_op;   -- beq
            -- BGTZ
            when "000111" =>            return_val := bgtz_op;   -- bgtz
            -- I instructions (addi, andi, ori, lui)
            when "001000" =>            return_val := addi_op;   -- addi
            when "001100" =>            return_val := andi_op;   -- andi
            when "001101" =>            return_val :=  ori_op;   -- ori
            when "001111" =>            return_val :=  lui_op;   -- lui
            -- load instructions (sw, lw)
            when "100011" =>            return_val :=   lw_op;   -- lw
            when "101011" =>            return_val :=   sw_op;   -- sw
            -- Other instructions not implemented, count as NOP
            when others =>              return_val := no_op;     --
        end case;
        return return_val;
    end getOp;
    
    -- GPREG bank
    signal   reg    : reg_file_type(1 to 31);           -- Note: $0 gives always 0 (see also below)
    signal  sreg    : u32_stype;
    signal  treg    : u32_stype;
    signal hireg    : u32_stype;
    signal loreg    : u32_stype;
    
    
    signal pgc      : unsigned(IA_LEN-1 downto 0);      -- program counter
    signal pgc_next : unsigned(IA_LEN-1 downto 0);
    
    signal inst     : std_logic_vector(31 downto 0);
        alias optc  : std_logic_vector(5 downto 0) is inst(31 downto 26);
        alias saddr : std_logic_vector(4 downto 0) is inst(25 downto 21);
        alias taddr : std_logic_vector(4 downto 0) is inst(20 downto 16);
        alias daddr : std_logic_vector(4 downto 0) is inst(15 downto 11);
        alias func  : std_logic_vector(5 downto 0) is inst(5 downto 0);
    
    signal eaddr    : u32_stype;
    signal d_sel    : integer range 0 to 31;      -- int reg file addr of the respective operand fields
    signal s_sel    : integer range 0 to 31;      -- int reg file addr of the respective operand fields
    signal t_sel    : integer range 0 to 31;      -- int reg file addr of the respective operand fields

    signal imval    : unsigned(25 downto 0);      -- stores the immediate value
	signal mductr   : integer range 0 to 33 := 0; -- counter to simulate multi-cycle R operations
    
    -- DEBUG signals and variables
    signal state    : inst_state_type := init;
    signal state_nxt: inst_state_type := init;    
    signal op_state : op_type := no_op;
    signal intrp    : boolean := false;
    

    
begin

    -- if operand field points to 0 (i.e. $0) then return always the value 0
    sreg <= (others => '0') when s_sel = 0      else reg(s_sel);
    treg <= (others => '0') when t_sel = 0      else reg(t_sel);
    
    dbus_addr_out <= std_logic_vector(eaddr(DA_LEN-1 downto 0));

    exec : process(clk, resetn)
        variable addres     : unsigned(32 downto 0);    -- add result
        variable mres       : unsigned(63 downto 0);    -- mult result
        variable state_var  : inst_state_type := init;  --
        variable state_next : inst_state_type := init;  -- 
    begin
        if(resetn = '0') then
            state           <= init;
            reg             <= (others => (others => '0'));
            pgc             <= (others => '0');
            imval           <= (others => '0');
            hireg           <= (others => '0');
            loreg           <= (others => '0');
            eaddr           <= (others => '0'); -- dbus_addr_out   <= (others => '0');
            dbus_data_out   <= (others => '0');
            ibus_addr_out   <= (others => '0');
            dbus_wren_out   <= '0';
            mductr <= 0;
        elsif(rising_edge(clk)) then
            -- Instruction state machine
            state       <= state_nxt;
            state_var   := state_nxt;
            case state_var is
                when init =>
                    state_nxt       <= fetch;           -- Update state
                when fetch => 
                    inst        <= ibus_data_inp;
                    state_nxt       <= decode;          -- Update state
                when decode =>
                    op_state    <= getOp(optc,func);    -- Update op state
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
                    state_nxt       <= execute;             -- Update state
                when execute => 
                    -- Now the instruction is actually executed
                    state_next := writeback; -- Update state
                    case optc is
                        -- Special
                        when "000000" =>
                            -- syscall;
                            if      func = "001100" then
                                --int0 <= '1';
                                intrp <= false;
                            -- mult
                            elsif   func = "011000" then
                                mres := sreg * treg;
                                hireg <= mres(63 downto 32);
                                loreg <= mres(31 downto 0);
                                -- Execute iterative algorithm
                            -- divu
                            elsif   func = "011011" then
                                hireg <= sreg mod treg;
                                loreg <= sreg / treg;
                                -- overwrite state_next to simulate multi-cycle R operation
                                if mductr < 32 then
                                    mductr <= mductr + 1;
                                    state_next := execute;          -- still processing
                                else
                                    mductr <= 0;
                                    state_next := writeback;        -- operation finished   
                                end if;
                                op_state    <= getOp(optc,func);    -- Update op state
                                -- Execute iterative algorithm
                            -- remaining functions
                            elsif d_sel /= 0 then
                            -- Don't do anything if d_sel is pointing to $0 (can't write to this reg)
                                case func is
                                    -- add
                                    when "100000" =>
                                          addres := ('0'&sreg) + ('0'&treg);
                                          reg(d_sel) <= addres(31 downto 0);
                                    -- sub
                                    when "100010" =>
                                          addres := ('0'&sreg) - ('0'&treg);
                                          reg(d_sel) <= addres(31 downto 0);
                                    -- and (bitwise)
                                    when "100100" =>
                                          reg(d_sel) <= sreg and treg;
                                    -- or (bitwise)
                                    when "100101" =>
                                          reg(d_sel) <= sreg or treg;
                                    -- xor (bitwise)
                                    when "100110" =>
                                          reg(d_sel) <= sreg xor treg;
                                    -- mfhi
                                    when "010000" =>
                                        reg(d_sel) <= hireg;
                                    -- mflo
                                    when "010010" =>
                                        reg(d_sel) <= loreg;
                                    -- other r instructions are not implemented
                                    when others   => null;    
                                end case;
                            elsif inst /= "00000000000000000000000000000000" then
                                -- If this is not a NOOP then there's an error
                                -- DEBUG: sys error interrupt
                                assert false report "DEBUG: Detected write attempt for $0 (R instr)." severity error;    
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
                            -- only write as long as destination reg addr is not $0
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
                            else
                                -- DEBUG: sys error interrupt
                                assert false report "DEBUG: Detected write attempt for $0 (I instr)." severity error;
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
                    state_nxt <= state_next;    -- Update next state
                when writeback =>
                    case optc is
                        -- syscall
                        when  "000000" =>
                            if(func = "001100") then
                                intrp <= true;        --int0 <= '0';
                            end if;
                        -- LW
                        when  "100011" =>
                            -- only write as long as destination reg addr is not $0
                            if t_sel /= 0 then
                                reg(t_sel) <= unsigned(dbus_data_inp);
                            else
                                -- DEBUG: sys error interrupt
                                assert false report "DEBUG: Detected write attempt for $0 (lw)." severity error;
                            end if;
                        -- SW
                        when  "101011" =>
                            dbus_wren_out <= '0';       -- 
                        when others => null;
                    end case;
                    pgc <= pgc_next;                                -- Update program counter
                    ibus_addr_out <= std_logic_vector(pgc_next);    -- Assign program counter to output
                    state_nxt <= fetch;                             -- Update state (i.e. start all over again)
            end case;
        end if;
    end process exec;
end architecture behavior;
