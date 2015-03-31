library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_dp is
    generic(
	WORD_LEN  : natural := 32;
	IA_LEN    : natural  :=  9;
	DA_LEN    : natural  :=  6);
    port(
	-- Data bus
	dbus_a_o  : out std_logic_vector(DA_LEN-1 downto 0);
        dbus_d_o  : out std_logic_vector(WORD_LEN-1 downto 0);
        dbus_d_i  : in  std_logic_vector(WORD_LEN-1 downto 0);
        
        -- Instruction bus
        ibus_a_o  : out std_logic_vector(IA_LEN-1 downto 0);
        ibus_d_i  : in  std_logic_vector(WORD_LEN-1 downto 0);
    
	-- Register control signals
	den : in std_logic;
	ten : in std_logic;
	tsrc : in std_logic_vector(1 downto 0);
	dsrc : in std_logic_vector(1 downto 0);
	
	-- program flow
	pgcen : in std_logic;
	insten : in std_logic;
	inst_o : out std_logic_vector(31 downto 0);
	
	-- ALU control
	alu_func_sel_i : in std_logic_vector(2 downto 0);
	alu_l_sel_i : in std_logic;
	alu_r_sel_i : in std_logic;
	
	-- MDU control
	mdu_mode_i : in std_logic;
	mdu_rdy_o : out std_logic;
	mdu_start_i : in std_logic;
	
	-- comparator control
	cmp_r_sel_i : in std_logic;
	
	-- Status signals
	cmp_eq_o : out std_logic;
	cmp_gt_o : out std_logic;
	
	-- Controller data in
	ctrl_data_in : in std_logic_vector(31 downto 0);
	
	-- System
	clk : in std_logic;
	resetn : in std_logic);
end entity mips32_dp;

architecture behavior of mips32_dp is
  subtype u32 is unsigned(31 downto 0);
    component mips32_alu is
    generic(
	WORD_LEN : natural := 32);
    port(
	alu_l_in : in std_logic_vector(WORD_LEN-1 downto 0);
	alu_r_in : in std_logic_vector(WORD_LEN-1 downto 0);
	alu_res_out : out std_logic_vector(WORD_LEN-1 downto 0);
	alu_cout   : out std_logic;
	func_sel : in std_logic_vector(2 downto 0));
    end component mips32_alu;
    component mips32_cmp is
    generic(
      WORD_LEN : natural := 32);
    port(
	cmp_l_in : in std_logic_vector(WORD_LEN-1 downto 0);
	cmp_r_in : in std_logic_vector(WORD_LEN-1 downto 0);
	
	cmp_eq_o : out std_logic;
	cmp_gt_o : out std_logic);
    end component mips32_cmp;
    component mips32_mdu is
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
    end component mips32_mdu;
    
    signal cmp_l : std_logic_vector(WORD_LEN-1 downto 0);
    signal cmp_r : std_logic_vector(WORD_LEN-1 downto 0);
    
    signal alu_l : std_logic_vector(WORD_LEN-1 downto 0);
    signal alu_r : std_logic_vector(WORD_LEN-1 downto 0);
    signal alu_res : std_logic_vector(WORD_LEN-1 downto 0);
    signal alu_cout : std_logic;
    signal alu_sel : std_logic_vector(2 downto 0);
    
    type reg_file is array (natural range <>) of u32;
    -- GPREG bank
    signal reg : reg_file(1 to 31);
    signal sreg : u32;
    signal treg : u32;
    signal dnext : u32;
    signal tnext : u32;
    signal hireg : std_logic_vector(31 downto 0);
    signal loreg : std_logic_vector(31 downto 0);
    
    signal inst : std_logic_vector(WORD_LEN-1 downto 0);
    signal pgc : u32 		:= (others => '0');
    signal pgcnext : u32 	:= (others => '0');
    
    signal ssel : integer range 0 to 31;
    signal tsel : integer range 0 to 31;
    signal dsel : integer range 0 to 31;
begin
    -- The address of the ibus is always connected to program counter
    ibus_a_o <= std_logic_vector(pgc(IA_LEN-1 downto 0));
    inst_o <= std_logic_vector(inst);
    
    dbus_a_o <= alu_res(DA_LEN-1 downto 0);
    dbus_d_o <= std_logic_vector(treg);
    
    ssel <= to_integer(unsigned(inst(25 downto 21)));
    tsel <= to_integer(unsigned(inst(20 downto 16)));
    dsel <= to_integer(unsigned(inst(15 downto 11)));
    
    -- Declare ALU
    alu : mips32_alu
    generic map(
	WORD_LEN => WORD_LEN)
    port map(
	alu_l_in => alu_l,
	alu_r_in => alu_r,
	alu_res_out => alu_res,
	alu_cout => alu_cout,
	func_sel => alu_func_sel_i);
     
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
	WORD_LEN => WORD_LEN)
    port map(
	cmp_l_in => std_logic_vector(sreg),
	cmp_r_in => cmp_r,
	cmp_eq_o => cmp_eq_o,
	cmp_gt_o => cmp_gt_o);

    
    with cmp_r_sel_i select cmp_r <=
	std_logic_vector(treg) when '1',
	(others => '0') when '0',
	(others => '-') when others;
   
    mdu : mips32_mdu
    port map(
	mdu_l_i => std_logic_vector(sreg),
	mdu_r_i => std_logic_vector(treg),
	mdu_hi_o => hireg,
	mdu_lo_o => loreg,
	mode_i => mdu_mode_i,
	rdy_o => mdu_rdy_o,
	start_i => mdu_start_i,
	clk => clk,
	resetn => resetn);
	
    -- Connect registers
    sreg <= (others => '0') when ssel = 0 
	else reg(ssel);
    treg <= (others => '0') when tsel = 0 
	else reg(tsel);
	
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
	
    pgcnext <= unsigned(alu_res);
	
    regproc : process(clk,resetn)
    begin
	if resetn = '0' then
	    for i in 1 to 31 loop
		reg(i) <= (others => '0');
	    end loop;
	    pgc <= (others => '0');
	    inst <= (others => '0');
	elsif rising_edge(clk) then
	    if ten = '1' and tsel /= 0 then
		reg(tsel) <= tnext;
	    end if;
	    
	    if den = '1' and dsel /= 0 then
		reg(dsel) <= dnext;
	    end if;
	    
	    if pgcen = '1' then
		pgc <= pgcnext;
	    end if;
	    
	    if insten = '1' then
		inst <= ibus_d_i;
	    end if;
	end if;
    end process regproc;
	
	
end architecture behavior;
