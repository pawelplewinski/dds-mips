library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture structural of mips32core is
    component mips32_dp is
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
	    
	    -- MDU control/status
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
    end component mips32_dp;

    component mips32_ctrl is
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
	    
	    -- MDU control/status
	    mdu_mode_o : out std_logic;
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
    end component mips32_ctrl;
    
    signal den : std_logic;
    signal ten : std_logic;
    signal tsrc : std_logic_vector(1 downto 0);
    signal dsrc : std_logic_vector(1 downto 0);
    
    signal pgcen : std_logic;
    signal insten : std_logic;
    signal inst : std_logic_vector(31 downto 0);

    signal alu_func_sel : std_logic_vector(2 downto 0);
    signal alu_l_sel : std_logic;
    signal alu_r_sel : std_logic;
    
    signal mdu_mode : std_logic;
    signal mdu_rdy : std_logic;
    signal mdu_start : std_logic;

    signal cmp_r_sel : std_logic;

    signal cmp_eq : std_logic;
    signal cmp_gt : std_logic;

    signal ctrl_data : std_logic_vector(31 downto 0);
begin
    datapath : mips32_dp
    generic map(
	WORD_LEN => SYS_32,
	IA_LEN => IA_LEN,
	DA_LEN => DA_LEN)
    port map(
	dbus_a_o => dbus_a_o,
	dbus_d_o => dbus_d_o,
	dbus_d_i => dbus_d_i,
	ibus_a_o => ibus_a_o,
	ibus_d_i => ibus_d_i,
	den => den,
	ten => ten,
	tsrc => tsrc,
	dsrc => dsrc,
	pgcen => pgcen,
	insten => insten,
	inst_o => inst,
	alu_func_sel_i => alu_func_sel,
	alu_l_sel_i => alu_l_sel,
	alu_r_sel_i => alu_r_sel,
	mdu_mode_i => mdu_mode,
	mdu_start_i => mdu_start,
	mdu_rdy_o => mdu_rdy,
	cmp_r_sel_i => cmp_r_sel,
	cmp_eq_o => cmp_eq,
	cmp_gt_o => cmp_gt,
	ctrl_data_in => ctrl_data,
	clk => clk,
	resetn => resetn);

    controller : mips32_ctrl
    generic map(
	WORD_LEN => SYS_32,
	IA_LEN => IA_LEN,
	DA_LEN => DA_LEN)
    port map(
	dbus_we_o => dbus_we_o,
	den => den,
	ten => ten,
	tsrc => tsrc,
	dsrc => dsrc,
	pgcen => pgcen,
	insten => insten,
	inst_i => inst,
	alu_func_sel_o => alu_func_sel,
	alu_l_sel_o => alu_l_sel,
	alu_r_sel_o => alu_r_sel,
	mdu_mode_o => mdu_mode,
	mdu_start_o => mdu_start,
	mdu_rdy_i => mdu_rdy,
	cmp_r_sel_o => cmp_r_sel,
	cmp_eq_i => cmp_eq,
	cmp_gt_i => cmp_gt,
	ctrl_data_o => ctrl_data,
	int0 => int0,
	clk => clk,
	resetn => resetn);
	
end architecture structural;