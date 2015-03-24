library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_ctrl is
    port(
	dbus_we_o : out std_logic;
	
	-- Register control signals
	den : out std_logic;
	ten : out std_logic;
	tsrc : out std_logic_vector(1 downto 0);
	dsrc : out std_logic_vector(1 downto 0);
	
	-- program flow
	pgcen : out std_logic;
	insten : out std_logic;
	inst_i : in std_logic_vector(31 downto 0);
	
	-- ALU control
	alu_func_sel_o : out std_logic_vector(2 downto 0);
	alu_l_sel_o : out std_logic;
	alu_r_sel_o : out std_logic;
	
	-- MDU control
	mdu_rdy_i : in std_logic;
	mdu_start_o : out std_logic;
	
	-- comparator control
	cmp_r_sel_o : out std_logic;
	
	-- Status signals
	cmp_eq_i : in std_logic;
	cmp_gt_i : in std_logic;
	
	-- Controller data in
	ctrl_data_o : out std_logic_vector(31 downto 0);
	
	int0 : out std_logic;
	clk : in std_logic;
	resetn : in std_logic);
end entity mips32_ctrl;

architecture behavior of mips32_ctrl is
    type Inst_state is (init,fetch,decode,execute,writeback);
    signal state : Inst_state := init;

    alias optc : std_logic_vector(5 downto 0) is inst_i(31 downto 26);
    alias func : std_logic_vector(5 downto 0) is inst_i(5 downto 0);    
    alias imval : std_logic_vector(25 downto 0) is inst_i(25 downto 0);
    
    type op_type is (no_op, add_op, addi_op, and_op, andi_op, beq_op, bgtz_op, divu_op, j_op, lui_op, lw_op, mfhi_op, mflo_op, mult_op, or_op, ori_op, sub_op, sw_op, syscall, xor_op, r_nop);
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
                    when "011011" =>    return_val := divu_op;   -- divu
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
    signal op_state  : op_type := no_op;
begin
    ctrl : process(clk, resetn)
    begin
	if resetn = '0' then
	    state <= init;
	    int0 <= '0';
	    dbus_we_o <= '0';
	    den <= '0';
	    ten <= '0';
	    dsrc <= (others => '-');
	    tsrc <= (others => '-');
	    pgcen <= '0';
	    insten <= '0';
	    alu_func_sel_o <= (others => '-');
	    alu_l_sel_o <= '-';
	    alu_r_sel_o <= '-';
	    mdu_start_o <= '0';
	    cmp_r_sel_o <= '-';
	    ctrl_data_o <= (others => '-');
	elsif rising_edge(clk) then
	    case state is
		when init =>
		    state <= fetch;
		    int0 <= '0';
		    insten <= '1';
		    dbus_we_o <= '0';
		    den <= '0';
		    ten <= '0';
		    tsrc <= (others => '-');
		    dsrc <= (others => '-');
		    pgcen <= '0';
		    alu_func_sel_o <= (others => '-');
		    alu_l_sel_o <= '-';
		    alu_r_sel_o <= '-';
		    mdu_start_o <= '0';
		    cmp_r_sel_o <= '-';
		    ctrl_data_o <= (others => '-');
		when fetch =>
		    state <= decode;
		    int0 <= '0';
		    insten <= '0';
		    dbus_we_o <= '0';
		    den <= '0';
		    ten <= '0';
		    tsrc <= (others => '-');
		    dsrc <= (others => '-');
		    pgcen <= '0';
		    mdu_start_o <= '0';
		    cmp_r_sel_o <= '-';
		    alu_func_sel_o <= (others => '-');
		    alu_l_sel_o <= '-';
		    alu_r_sel_o <= '-';
		    ctrl_data_o <= (others => '-');
		when decode =>
		    state <= execute;
		    int0 <= '0';
		    insten <= '0';
		    case optc is
		    -- special instructions
		    when "000000" =>
			dbus_we_o <= '0';
			case func is
			-- add, sub, and, or, xor
			when "100000"|"100010"|"100100"|"100101"|"100110" =>
			    mdu_start_o <= '0';
			    den <= '1';
			    dsrc <= "00";
			-- mult, divu
			when "011000"|"011011"  =>
			    mdu_start_o <= '1';
			    -- Execute iterative algorithm;
			    den <= '0';
			    dsrc <= (others => '-');
			-- mfhi
			when "010000" =>
			    mdu_start_o <= '0';
			    den <= '1';
			    dsrc <= "01";
			-- mflo
			when "010010" =>
			    mdu_start_o <= '0';
			    den <= '1';
			    dsrc <= "10";
			-- other special instructions are not implemented
			when others => null;  
			    mdu_start_o <= '0';
			    den <= '0';
			    dsrc <= (others => '-');
			end case;
			ten <= '0';
			tsrc <= (others => '-');
			pgcen <= '0';
			cmp_r_sel_o <= '-';
			if func(5 downto 3) = "100" then
			    alu_func_sel_o <= func(2 downto 0);
			else
			    alu_func_sel_o <= (others => '-');
			end if;
			  
			-- s reg
			alu_l_sel_o <= '0';
			-- t reg
			alu_r_sel_o <= '0';
			ctrl_data_o <= (others => '-');
		    -- J instruction
		    when "000010" =>
			dbus_we_o <= '0';
			den <= '0';
			ten <= '0';
			tsrc <= (others => '-');
			dsrc <= (others => '-');
			pgcen <= '1';
			mdu_start_o <= '0';
			cmp_r_sel_o <= '-';
			-- nPGC := PGC & 0xFC000000
			alu_func_sel_o <= "100";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			ctrl_data_o <= (31 downto 26 => '1') & (25 downto 0 => '0');
		    -- BEQ
		    when "000100" =>
			dbus_we_o <= '0';
			den <= '0';
			ten <= '0';
			tsrc <= (others => '-');
			dsrc <= (others => '-');
			pgcen <= '1';
			mdu_start_o <= '0';
			-- t reg
			cmp_r_sel_o <= '1';
			-- nPGC := PGC + 1
			alu_func_sel_o <= "000";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
		    -- BGTZ
		    when "000111" =>
			dbus_we_o <= '0';
			den <= '0';
			ten <= '0';
			tsrc <= (others => '-');
			dsrc <= (others => '-');
			pgcen <= '1';
			mdu_start_o <= '0';
			-- zero
			cmp_r_sel_o <= '0';
			-- nPGC := PGC + 1
			alu_func_sel_o <= "000";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
		    -- I instructions
		    when "001000" | "001100" | "001101" | "001111" =>
			dbus_we_o <= '0';
			den <= '0';
			dsrc <= (others => '-');
			ten <= '1';
			if optc(2 downto 0) = "111" then
			    tsrc <= "01";
			else
			    tsrc <= "00";
			end if;
			pgcen <= '0';
			mdu_start_o <= '0';
			cmp_r_sel_o <= '-';
			alu_func_sel_o <= optc(2 downto 0);
			alu_l_sel_o <= '0';
			alu_r_sel_o <= '1';
			if optc(2 downto 0) = "000" then
			    ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
			elsif optc(2 downto 0) = "111" then
			    ctrl_data_o <= imval(15 downto 0) & (15 downto 0 => '0');
			else
			    ctrl_data_o <= (31 downto 16 => '0') & imval(15 downto 0);
			end if;
		    -- LW
		    when "100011" =>
			dbus_we_o <= '0';
			den <= '0';
			dsrc <= (others => '-');
			ten <= '1';
			tsrc <= "10";
			pgcen <= '0';
			mdu_start_o <= '0';
			cmp_r_sel_o <= '-';
			alu_func_sel_o <= "000";
			-- eaddr := $s + offset
			alu_l_sel_o <= '0';
			alu_r_sel_o <= '1';
			ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
		    -- SW
		    when "101011" =>
			dbus_we_o <= '1';
			den <= '0';
			dsrc <= (others => '-');
			ten <= '0';
			tsrc <= (others => '-');
			pgcen <= '0';
			mdu_start_o <= '0';
			cmp_r_sel_o <= '-';
			alu_func_sel_o <= "000";
			-- eaddr := $s + offset
			alu_l_sel_o <= '0';
			alu_r_sel_o <= '1';
			ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
		    -- Other stuff not implemented
		    when others =>
			dbus_we_o <= '0';
			den <= '0';
			dsrc <= (others => '-');
			ten <= '0';
			tsrc <= (others => '-');
			pgcen <= '0';
			mdu_start_o <= '0';
			cmp_r_sel_o <= '-';
			alu_func_sel_o <= (others => '-');
			alu_l_sel_o <= '-';
			alu_r_sel_o <= '-';
			ctrl_data_o <= (others => '-');
		    end case;
		when execute =>
		    -- Now the instruction is actually executed
		    dbus_we_o <= '0';
		    ten <= '0';
		    tsrc <= (others => '-');
		    den <= '0';
		    dsrc <= (others => '-');
		    insten <= '0';
		    mdu_start_o <= '0';
		    cmp_r_sel_o <= '-';
		    case optc is
		    -- Special
		    when "000000" =>
			-- syscall
			if func = "001100" then
			   int0 <= '1';
			   state <= writeback;
			   pgcen <= '1';
			   alu_func_sel_o <= "000";
			   alu_l_sel_o <= '1';
			   alu_r_sel_o <= '1';
			   ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
			elsif func = "011000" or func = "011011" then
			   int0 <= '0';
			   if mdu_rdy_i = '0' then
			      state <= execute;
			      pgcen <= '0';
			      alu_func_sel_o <= (others => '-');
			      alu_l_sel_o <= '-';
			      alu_r_sel_o <= '-';
			      ctrl_data_o <= (others => '-');
			   else
			      state <= writeback;
			      pgcen <= '1';
			      alu_func_sel_o <= "000";
			      alu_l_sel_o <= '1';
			      alu_r_sel_o <= '1';
			      ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
			   end if;
		        else
			   int0 <= '0';
			   state <= writeback;
			   pgcen <= '1';
			   -- nPGC := PGC + 1
			   alu_func_sel_o <= "000";
			   alu_l_sel_o <= '1';
			   alu_r_sel_o <= '1';
			   ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
			end if;
		    -- J instruction
		    when "000010" =>
			state <= writeback;
			int0 <= '0';
			-- nPGC := PGC | imval
			pgcen <= '1';
			alu_func_sel_o <= "101";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			ctrl_data_o <= (31 downto 26 => '0') & imval;
		    -- BEQ instruction
		    when "000100" =>
			state <= writeback;
			int0 <= '0';
			pgcen <= '1';
			alu_func_sel_o <= "000";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			if(cmp_eq_i = '1') then
			  -- nPGC := PGC + offset
			    ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
			else
			    ctrl_data_o <= (others => '0');
			end if;
		    -- BGTZ instruction
		    when "000111" =>
			state <= writeback;
			int0 <= '0';
			pgcen <= '1';
			alu_func_sel_o <= "000";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			if(cmp_gt_i = '1') then
			  -- nPGC := PGC + offset
			    ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
			else
			    ctrl_data_o <= (others => '0');
			end if;
		    when others => 
			state <= writeback;
			int0 <= '0';
			pgcen <= '1';
			-- nPGC := PGC + 1
			alu_func_sel_o <= "000";
			alu_l_sel_o <= '1';
			alu_r_sel_o <= '1';
			ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
		    end case;
		when writeback =>
		    state <= fetch;
		    int0 <= '0';
		    dbus_we_o <= '0';
		    den <= '0';
		    ten <= '0';
		    tsrc <= (others => '-');
		    dsrc <= (others => '-');
		    pgcen <= '0';
		    insten <= '1';
		    alu_func_sel_o <= (others => '-');
		    alu_l_sel_o <= '-';
		    alu_r_sel_o <= '-';
		    mdu_start_o <= '0';
		    cmp_r_sel_o <= '-';
		    ctrl_data_o <= (others => '-');
	    end case;
	end if;
    end process ctrl;
    
   op_state         <= getOp(optc,func);    -- Update op state
end architecture behavior;