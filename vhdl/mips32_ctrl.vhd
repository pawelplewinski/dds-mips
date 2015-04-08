library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_ctrl is
port(
	dbus_we_o	: out std_logic;
	
	-- Register control signals
	den		: out std_logic;
	ten		: out std_logic;
	tsrc		: out std_logic_vector(1 downto 0);
	dsrc		: out std_logic_vector(1 downto 0);
	
	-- program flow
	pgcen		: out std_logic;
	insten		: out std_logic;
	inst_i		: in std_logic_vector(31 downto 0);
	
	-- data flow
	daddren		: out std_logic;
	
	-- ALU control
	alu_func_sel_o	: out std_logic_vector(2 downto 0);
	alu_l_sel_o	: out std_logic;
	alu_r_sel_o	: out std_logic;
	
	-- MDU control/status
	mdu_mode_o	: out std_logic;
	mdu_rdy_i	: in std_logic;
	mdu_start_o	: out std_logic;
	
	-- comparator control
	cmp_r_sel_o	: out std_logic;
	
	-- Status signals
	cmp_eq_i	: in std_logic;
	cmp_gt_i	: in std_logic;
	
	-- Controller data in
	ctrl_data_o	: out std_logic_vector(31 downto 0);
	
	int0		: out std_logic;
	clk		: in std_logic;
	resetn		: in std_logic
	);
end entity mips32_ctrl;

architecture behavior of mips32_ctrl is
	type Inst_state is (init,fetch,decode,execute,writeback);
	signal state : Inst_state := init;
	signal mdu_start : std_logic := '0';
	
	alias optc : std_logic_vector(5 downto 0) is inst_i(31 downto 26);
	alias func : std_logic_vector(5 downto 0) is inst_i(5 downto 0);    
	alias imval : std_logic_vector(25 downto 0) is inst_i(25 downto 0);
begin
	mdu_start_o <= mdu_start;
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
			daddren <= '0';
			alu_func_sel_o <= (others => '-');
			alu_l_sel_o <= '-';
			alu_r_sel_o <= '-';
			mdu_start <= '0';
			mdu_mode_o <= '-';
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
				daddren <= '0';
				alu_func_sel_o <= (others => '-');
				alu_l_sel_o <= '-';
				alu_r_sel_o <= '-';
				mdu_start <= '0';
				mdu_mode_o <= '-';
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
				daddren <= '0';
				mdu_start <= '0';
				mdu_mode_o <= '-';
				cmp_r_sel_o <= '-';
				alu_func_sel_o <= (others => '-');
				alu_l_sel_o <= '-';
				alu_r_sel_o <= '-';
				ctrl_data_o <= (others => '-');
			 when decode =>
				state <= execute;
				int0 <= '0';
				insten <= '0';
				dbus_we_o <= '0';
				case optc is
				-- special instructions
				when "000000" =>
					daddren <= '0';
					case func is
					-- add, sub, and, or, xor
					when "100000"|"100010"|"100100"|"100101"|"100110" =>
						mdu_start <= '0';
						mdu_mode_o <= '-';
						den <= '1';
						dsrc <= "00";
					-- mult
					when "011000" =>
						mdu_start <= '1';
						mdu_mode_o <= '1';
						den <= '0';
						dsrc <= (others => '-');
					-- divu
					when "011011"  =>
						mdu_start <= '1';
						mdu_mode_o <= '0';
						den <= '0';
						dsrc <= (others => '-');
					-- mfhi
					when "010000" =>
						mdu_start <= '0';
						mdu_mode_o <= '-';
						den <= '1';
						dsrc <= "01";
					-- mflo
					when "010010" =>
						mdu_start <= '0';
						mdu_mode_o <= '-';
						den <= '1';
						dsrc <= "10";
					-- other special instructions are not implemented
					when others => null;  
						mdu_start <= '0';
						mdu_mode_o <= '-';
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
					daddren <= '0';
					den <= '0';
					ten <= '0';
					tsrc <= (others => '-');
					dsrc <= (others => '-');
					pgcen <= '1';
					mdu_start <= '0';
					mdu_mode_o <= '-';
					cmp_r_sel_o <= '-';
					-- nPGC := PGC & 0xFC000000
					alu_func_sel_o <= "100";
					alu_l_sel_o <= '1';
					alu_r_sel_o <= '1';
					ctrl_data_o <= (31 downto 26 => '1') & (25 downto 0 => '0');
				-- BEQ
				when "000100" =>
					daddren <= '0';
					den <= '0';
					ten <= '0';
					tsrc <= (others => '-');
					dsrc <= (others => '-');
					pgcen <= '1';
					mdu_start <= '0';
					mdu_mode_o <= '-';
					-- t reg
					cmp_r_sel_o <= '1';
					-- nPGC := PGC + 1
					alu_func_sel_o <= "000";
					alu_l_sel_o <= '1';
					alu_r_sel_o <= '1';
					ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
				-- BGTZ
				when "000111" =>
					daddren <= '0';
					den <= '0';
					ten <= '0';
					tsrc <= (others => '-');
					dsrc <= (others => '-');
					pgcen <= '1';
					mdu_start <= '0';
					mdu_mode_o <= '-';
					-- zero
					cmp_r_sel_o <= '0';
					-- nPGC := PGC + 1
					alu_func_sel_o <= "000";
					alu_l_sel_o <= '1';
					alu_r_sel_o <= '1';
					ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
				-- I instructions
				when "001000" | "001100" | "001101" | "001111" =>
					daddren <= '0';
					den <= '0';
					dsrc <= (others => '-');
					ten <= '1';
					if optc(2 downto 0) = "111" then
						tsrc <= "01";
					else
						tsrc <= "00";
					end if;
					pgcen <= '0';
					mdu_start <= '0';
					mdu_mode_o <= '-';
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
				-- LW/SW
				when "100011"|"101011" =>
					daddren <= '1';
					den <= '0';
					dsrc <= (others => '-');
					ten <= '0';
					tsrc <= (others => '-');
					pgcen <= '0';
					mdu_start <= '0';
					mdu_mode_o <= '-';
					cmp_r_sel_o <= '-';
					alu_func_sel_o <= "000";
					-- eaddr := $s + offset
					alu_l_sel_o <= '0';
					alu_r_sel_o <= '1';
					ctrl_data_o <= (31 downto 16 => imval(15)) & imval(15 downto 0);
				-- Other stuff not implemented
				when others =>
					daddren <= '0';
					den <= '0';
					dsrc <= (others => '-');
					ten <= '0';
					tsrc <= (others => '-');
					pgcen <= '0';
					mdu_start <= '0';
					mdu_mode_o <= '-';
					cmp_r_sel_o <= '-';
					alu_func_sel_o <= (others => '-');
					alu_l_sel_o <= '-';
					alu_r_sel_o <= '-';
					ctrl_data_o <= (others => '-');
				end case;
			when execute =>
				-- Now the instruction is actually executed
				daddren <= '0';
				den <= '0';
				dsrc <= (others => '-');
				insten <= '0';
				mdu_start <= '0';
				mdu_mode_o <= '-';
				cmp_r_sel_o <= '-';
				case optc is
				-- Special
				when "000000" =>
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '0';
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
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '0';
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
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '0';
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
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '0';
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
				-- LW instruction
				when "100011" =>
					ten <= '1';
					tsrc <= "10";
					dbus_we_o <= '0';
					state <= writeback;
					int0 <= '0';
					pgcen <= '1';
					-- nPGC := PGC + 1
					alu_func_sel_o <= "000";
					alu_l_sel_o <= '1';
					alu_r_sel_o <= '1';
					ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
				-- SW instruction
				when "101011" =>
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '1';
					state <= writeback;
					int0 <= '0';
					pgcen <= '1';
					-- nPGC := PGC + 1
					alu_func_sel_o <= "000";
					alu_l_sel_o <= '1';
					alu_r_sel_o <= '1';
					ctrl_data_o <= std_logic_vector(to_unsigned(1,32));
				when others => 
					ten <= '0';
					tsrc <= (others => '-');
					dbus_we_o <= '0';
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
				daddren <= '0';
				alu_func_sel_o <= (others => '-');
				alu_l_sel_o <= '-';
				alu_r_sel_o <= '-';
				mdu_start <= '0';
				cmp_r_sel_o <= '-';
				ctrl_data_o <= (others => '-');
			end case;
		end if;
	end process ctrl;
end architecture behavior;