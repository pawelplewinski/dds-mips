library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_dp is
generic(
	WORD_LEN  	: natural := 32);
port(
	-- Data bus
	dbus_a_o  	: out std_logic_vector(WORD_LEN-1 downto 0);
	dbus_d_o  	: out std_logic_vector(WORD_LEN-1 downto 0);
	dbus_d_i  	: in  std_logic_vector(WORD_LEN-1 downto 0);
        
	-- Instruction bus
	ibus_a_o  	: out std_logic_vector(WORD_LEN-1 downto 0);
	ibus_d_i  	: in  std_logic_vector(WORD_LEN-1 downto 0);
    
	-- Register control signals
	den 		: in std_logic;
	ten 		: in std_logic;
	tsrc 		: in std_logic_vector(1 downto 0);
	dsrc 		: in std_logic_vector(1 downto 0);
	
	-- program flow
	pgcen 		: in std_logic;
	insten 		: in std_logic;
	inst_o 		: out std_logic_vector(31 downto 0);
	
	-- data flow
	daddren 	: in std_logic;
	
	-- ALU control
	alu_func_sel_i 	: in std_logic_vector(2 downto 0);
	alu_l_sel_i 	: in std_logic;
	alu_r_sel_i 	: in std_logic;
	
	-- MDU control
	mdu_mode_i 	: in std_logic;
	mdu_rdy_o 	: out std_logic;
	mdu_start_i 	: in std_logic;
	
	-- comparator control
	cmp_r_sel_i 	: in std_logic;
	
	-- Status signals
	cmp_eq_o 	: out std_logic;
	cmp_gt_o 	: out std_logic;
	
	-- Controller data in
	ctrl_data_in 	: in std_logic_vector(31 downto 0);
	
	-- System
	clk 		: in std_logic;
	resetn 		: in std_logic);
end entity mips32_dp;

architecture behavior of mips32_dp is
	subtype u32 is unsigned(31 downto 0);
	component mips32_alu is
	generic(
		WORD_LEN 	: natural := 32);
	port(
		alu_l_in 	: in std_logic_vector(WORD_LEN-1 downto 0);
		alu_r_in 	: in std_logic_vector(WORD_LEN-1 downto 0);
		alu_res_out 	: out std_logic_vector(WORD_LEN-1 downto 0);
		alu_cout   	: out std_logic;
		func_sel 	: in std_logic_vector(2 downto 0));
	end component mips32_alu;
	component mips32_cmp is
	generic(
		WORD_LEN 	: natural := 32);
	port(
		cmp_l_in 	: in std_logic_vector(WORD_LEN-1 downto 0);
		cmp_r_in 	: in std_logic_vector(WORD_LEN-1 downto 0);
		
		cmp_eq_o 	: out std_logic;
		cmp_gt_o 	: out std_logic);
	end component mips32_cmp;
	component mips32_mdu is
	port(
		mdu_l_i 	: in std_logic_vector(31 downto 0);
		mdu_r_i 	: in std_logic_vector(31 downto 0);
		
		mdu_hi_o 	: out std_logic_vector(31 downto 0);
		mdu_lo_o 	: out std_logic_vector(31 downto 0);
		
		mode_i 		: in std_logic;
		rdy_o 		: out std_logic;
		start_i 	: in std_logic;
		
		clk 		: in std_logic;
		resetn 		: in std_logic);
	end component mips32_mdu;
	
	signal cmp_l 	: std_logic_vector(WORD_LEN-1 downto 0);
	signal cmp_r 	: std_logic_vector(WORD_LEN-1 downto 0);
	
	signal alu_l	: std_logic_vector(WORD_LEN-1 downto 0);
	signal alu_r 	: std_logic_vector(WORD_LEN-1 downto 0);
	signal alu_res 	: std_logic_vector(WORD_LEN-1 downto 0);
	signal alu_cout : std_logic;
	signal alu_sel 	: std_logic_vector(2 downto 0);
	
	-- GPREG bank
	signal reg1	: u32 := (others => '0');
	signal reg2	: u32 := (others => '0');
	signal reg3	: u32 := (others => '0');
	signal reg4	: u32 := (others => '0');
	signal reg5	: u32 := (others => '0');
	signal reg6	: u32 := (others => '0');
	signal reg7	: u32 := (others => '0');
	signal reg8	: u32 := (others => '0');
	signal reg9	: u32 := (others => '0');
	signal reg10	: u32 := (others => '0');
	signal reg11	: u32 := (others => '0');
	signal reg12	: u32 := (others => '0');
	signal reg13	: u32 := (others => '0');
	signal reg14	: u32 := (others => '0');
	signal reg15	: u32 := (others => '0');
	signal reg16	: u32 := (others => '0');
	signal reg17	: u32 := (others => '0');
	signal reg18	: u32 := (others => '0');
	signal reg19	: u32 := (others => '0');
	signal reg20	: u32 := (others => '0');
	signal reg21	: u32 := (others => '0');
	signal reg22	: u32 := (others => '0');
	signal reg23	: u32 := (others => '0');
	signal reg24	: u32 := (others => '0');
	signal reg25	: u32 := (others => '0');
	signal reg26	: u32 := (others => '0');
	signal reg27	: u32 := (others => '0');
	signal reg28	: u32 := (others => '0');
	signal reg29	: u32 := (others => '0');
	signal reg30	: u32 := (others => '0');
	signal reg31	: u32 := (others => '0');
	
	signal treg_en	: std_logic_vector(31 downto 0);
	signal dreg_en	: std_logic_vector(31 downto 0);
	signal reg_en	: std_logic_vector(31 downto 0);
	
	signal sreg 	: u32;
	signal treg 	: u32;
	signal dnext 	: u32;
	signal tnext 	: u32;
	signal regnxt	: u32;
	signal hireg 	: std_logic_vector(31 downto 0);
	signal loreg 	: std_logic_vector(31 downto 0);
	
	signal inst 	: std_logic_vector(WORD_LEN-1 downto 0);
	signal pgc 	: u32 		:= (others => '0');
	signal pgcnext 	: u32 	:= (others => '0');
	signal daddr 	: u32		:= (others => '0');
	
	alias ssel : std_logic_vector(4 downto 0) is inst(25 downto 21);    
	alias tsel : std_logic_vector(4 downto 0) is inst(20 downto 16);  
	alias dsel : std_logic_vector(4 downto 0) is inst(15 downto 11);  
	
begin
	-- The address of the ibus is always connected to program counter
	ibus_a_o <= std_logic_vector(pgc);
	inst_o <= std_logic_vector(inst);
	
	dbus_a_o <= std_logic_vector(daddr);
	dbus_d_o <= std_logic_vector(treg);
	
	
	-- Declare ALU
	alu : mips32_alu
	generic map(
	    WORD_LEN => WORD_LEN)
	port map(
		alu_l_in 	=> alu_l,
		alu_r_in 	=> alu_r,
		alu_res_out 	=> alu_res,
		alu_cout 	=> alu_cout,
		func_sel 	=> alu_func_sel_i);
	
	-- Connect ALU
	with alu_l_sel_i select alu_l <=
		std_logic_vector(sreg) when '0',
		std_logic_vector(pgc) when '1',
		(others => '-') when others;
	with alu_r_sel_i select alu_r <=
		std_logic_vector(treg) when '0',
		ctrl_data_in when '1',
		(others => '-') when others;
	    
	-- Declare comparator
	cmp : mips32_cmp
	generic map(
		WORD_LEN 	=> WORD_LEN)
	port map(
		cmp_l_in 	=> std_logic_vector(sreg),
		cmp_r_in 	=> cmp_r,
		cmp_eq_o 	=> cmp_eq_o,
		cmp_gt_o 	=> cmp_gt_o);

	
	with cmp_r_sel_i select cmp_r <=
		std_logic_vector(treg) when '1',
		(others => '0') when '0',
		(others => '-') when others;
      
	mdu : mips32_mdu
	port map(
		mdu_l_i 	=> std_logic_vector(sreg),
		mdu_r_i 	=> std_logic_vector(treg),
		mdu_hi_o 	=> hireg,
		mdu_lo_o 	=> loreg,
		mode_i 		=> mdu_mode_i,
		rdy_o 		=> mdu_rdy_o,
		start_i 	=> mdu_start_i,
		clk 		=> clk,
		resetn 		=> resetn);
	    
	-- Connect registers
	with ssel select sreg <=
		 reg1 when "00001",
		 reg2 when "00010",
		 reg3 when "00011",
		 reg4 when "00100",
		 reg5 when "00101",
		 reg6 when "00110",
		 reg7 when "00111",
		 reg8 when "01000",
		 reg9 when "01001",
		 reg10 when "01010",
		 reg11 when "01011",
		 reg12 when "01100",
		 reg13 when "01101",
		 reg14 when "01110",
		 reg15 when "01111",
		 reg16 when "10000",
		 reg17 when "10001",
		 reg18 when "10010",
		 reg19 when "10011",
		 reg20 when "10100",
		 reg21 when "10101",
		 reg22 when "10110",
		 reg23 when "10111",
		 reg24 when "11000",
		 reg25 when "11001",
		 reg26 when "11010",
		 reg27 when "11011",
		 reg28 when "11100",
		 reg29 when "11101",
		 reg30 when "11110",
		 reg31 when "11111",
		 (others => '0') when others;
	
	with tsel select treg <=
		 reg1 when "00001",
		 reg2 when "00010",
		 reg3 when "00011",
		 reg4 when "00100",
		 reg5 when "00101",
		 reg6 when "00110",
		 reg7 when "00111",
		 reg8 when "01000",
		 reg9 when "01001",
		 reg10 when "01010",
		 reg11 when "01011",
		 reg12 when "01100",
		 reg13 when "01101",
		 reg14 when "01110",
		 reg15 when "01111",
		 reg16 when "10000",
		 reg17 when "10001",
		 reg18 when "10010",
		 reg19 when "10011",
		 reg20 when "10100",
		 reg21 when "10101",
		 reg22 when "10110",
		 reg23 when "10111",
		 reg24 when "11000",
		 reg25 when "11001",
		 reg26 when "11010",
		 reg27 when "11011",
		 reg28 when "11100",
		 reg29 when "11101",
		 reg30 when "11110",
		 reg31 when "11111",
		 (others => '0') when others;
	--sreg <= (others => '0') when ssel = 0 
	--	else reg(ssel);
	--treg <= (others => '0') when tsel = 0 
	--	else reg(tsel);
	    
	with tsrc select tnext <=
		-- ALU out
		unsigned(alu_res) when "00",
		-- Data
		unsigned(ctrl_data_in) when "01",
		-- Memory
		unsigned(dbus_d_i) when "10",
		(others => '-') when others;

	with dsrc select dnext <=
		-- ALU out
		unsigned(alu_res) when "00",
		-- HI reg
		unsigned(hireg) when "01",
		-- LO reg
		unsigned(loreg) when "10",
		(others => '-') when others;
	    
	regnxt <= dnext when den = '1'
		  else tnext;
	pgcnext <= unsigned(alu_res);
	    
	decoder0 : process(tsel)
	begin
		treg_en <= (others => '0');
		treg_en(to_integer(unsigned(tsel))) <= '1';
	end process decoder0;
	decoder1 : process(dsel)
	begin
		dreg_en <= (others => '0');
		dreg_en(to_integer(unsigned(dsel))) <= '1';
	end process decoder1;
	reg_en <= (treg_en and (31 downto 0 => ten)) or (dreg_en and (31 downto 0 => den));
	
	--Check if the corresponding signals in the datapath (namely 
	--registers, program counter and current instruction) have correct 
	--form (are zeroed) after reset
	--PSL dp_reset_pgc: assert forall i IN {0 to 31}: always (resetn='0' -> (pgc(i) = '0'));
	--PSL dp_reset_inst: assert forall i IN {0 to 31}: always (resetn='0' -> (inst(i) = '0'));
	--PSL dp_reset_daddr: assert forall i IN {0 to 31}: always (resetn='0' -> (daddr(i) = '0'));

	--Checks if when program counter enable signal is high the pgcnext is 
	--correctly assigned to program counter
	--PSL dp_pgc_next: assert always ((pgcen='1') -> next! (pgc = pgcnext));
	
	regproc : process(clk,resetn)
	begin
		if resetn = '0' then
			reg1 <= (others => '0');
			reg2 <= (others => '0');
			reg3 <= (others => '0');
			reg4 <= (others => '0');
			reg5 <= (others => '0');
			reg6 <= (others => '0');
			reg7 <= (others => '0');
			reg8 <= (others => '0');
			reg9 <= (others => '0');
			reg10 <= (others => '0');
			reg11 <= (others => '0');
			reg12 <= (others => '0');
			reg13 <= (others => '0');
			reg14 <= (others => '0');
			reg15 <= (others => '0');
			reg16 <= (others => '0');
			reg17 <= (others => '0');
			reg18 <= (others => '0');
			reg19 <= (others => '0');
			reg20 <= (others => '0');
			reg21 <= (others => '0');
			reg22 <= (others => '0');
			reg23 <= (others => '0');
			reg24 <= (others => '0');
			reg25 <= (others => '0');
			reg26 <= (others => '0');
			reg27 <= (others => '0');
			reg28 <= (others => '0');
			reg29 <= (others => '0');
			reg30 <= (others => '0');
			reg31 <= (others => '0');
			pgc <= (others => '0');
			inst <= (others => '0');
			daddr <= (others => '0');
		elsif rising_edge(clk) then
			if reg_en(1) = '1' then
				reg1 <= regnxt;
			end if;
			if reg_en(2) = '1' then
				reg2 <= regnxt;
			end if;
			if reg_en(3) = '1' then
				reg3 <= regnxt;
			end if;
			if reg_en(4) = '1' then
				reg4 <= regnxt;
			end if;
			if reg_en(5) = '1' then
				reg5 <= regnxt;
			end if;
			if reg_en(6) = '1' then
				reg6 <= regnxt;
			end if;
			if reg_en(7) = '1' then
				reg7 <= regnxt;
			end if;
			if reg_en(8) = '1' then
				reg8 <= regnxt;
			end if;
			if reg_en(9) = '1' then
				reg9 <= regnxt;
			end if;
			if reg_en(10) = '1' then
				reg10 <= regnxt;
			end if;
			if reg_en(11) = '1' then
				reg11 <= regnxt;
			end if;
			if reg_en(12) = '1' then
				reg12 <= regnxt;
			end if;
			if reg_en(13) = '1' then
				reg13 <= regnxt;
			end if;
			if reg_en(14) = '1' then
				reg14 <= regnxt;
			end if;
			if reg_en(15) = '1' then
				reg15 <= regnxt;
			end if;
			if reg_en(16) = '1' then
				reg16 <= regnxt;
			end if;
			if reg_en(17) = '1' then
				reg17 <= regnxt;
			end if;
			if reg_en(18) = '1' then
				reg18 <= regnxt;
			end if;
			if reg_en(19) = '1' then
				reg19 <= regnxt;
			end if;
			if reg_en(20) = '1' then
				reg20 <= regnxt;
			end if;
			if reg_en(21) = '1' then
				reg21 <= regnxt;
			end if;
			if reg_en(22) = '1' then
				reg22 <= regnxt;
			end if;
			if reg_en(23) = '1' then
				reg23 <= regnxt;
			end if;
			if reg_en(24) = '1' then
				reg24 <= regnxt;
			end if;
			if reg_en(25) = '1' then
				reg25 <= regnxt;
			end if;
			if reg_en(26) = '1' then
				reg26 <= regnxt;
			end if;
			if reg_en(27) = '1' then
				reg27 <= regnxt;
			end if;
			if reg_en(28) = '1' then
				reg28 <= regnxt;
			end if;
			if reg_en(29) = '1' then
				reg29 <= regnxt;
			end if;
			if reg_en(30) = '1' then
				reg30 <= regnxt;
			end if;
			if reg_en(31) = '1' then
				reg31 <= regnxt;
			end if;
			
			if pgcen = '1' then
				pgc <= pgcnext;
			end if;
			
			if insten = '1' then
				inst <= ibus_d_i;
			end if;
			
			if daddren = '1' then
				daddr <= unsigned(alu_res);
			end if;
		end if;
	end process regproc;
end architecture behavior;
