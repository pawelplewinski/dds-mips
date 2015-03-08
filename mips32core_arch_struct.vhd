library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture structural of mips32core is

    component mips32_dp is
    generic(
        IA_LEN    : natural :=  9);
    port(
        -- Data bus
        dbus_addr_out  : out std_logic_vector(31 downto 0);
        dbus_data_out  : out std_logic_vector(31 downto 0);
        dbus_data_inp  : in  std_logic_vector(31 downto 0);
        
        -- Instruction bus
        ibus_addr_out  : out std_logic_vector(IA_LEN-1 downto 0);
        ibus_data_inp  : in  std_logic_vector(31 downto 0);
    
        -- Register control signals
        den  : in std_logic;
        ten  : in std_logic;
        tsrc : in std_logic_vector(1 downto 0);
        dsrc : in std_logic_vector(1 downto 0);
        
        -- program flow
        pgcen    : in  std_logic;
        insten   : in  std_logic;
        inst_out : out std_logic_vector(31 downto 0);
        
        -- ALU control
        alu_func_sel_inp : in std_logic_vector(2 downto 0);
        alu_l_sel_inp    : in std_logic;
        alu_r_sel_inp    : in std_logic;
        
        -- MDU control
        mdu_start_inp    : in  std_logic;
        mdu_func_sel_inp : in  std_logic;
        mdu_rdy_out      : out std_logic;
    
        -- comparator control
        cmp_r_sel_inp : in std_logic;
        
        -- Status signals
        cmp_eq_out : out std_logic;
        cmp_gt_out : out std_logic;
        
        -- Controller data in
        ctrl_data_inp : in std_logic_vector(31 downto 0);
        
        -- System
        clk    : in std_logic;
        resetn : in std_logic);
    end component mips32_dp;

    component mips32_ctrl is
    port(
        dbus_wren_out : out std_logic;
        
        -- Register control signals
        den  : out std_logic;
        ten  : out std_logic;
        tsrc : out std_logic_vector(1 downto 0);
        dsrc : out std_logic_vector(1 downto 0);
        
        -- program flow
        pgcen    : out std_logic;
        insten   : out std_logic;
        inst_inp : in  std_logic_vector(31 downto 0);
        
        -- ALU control
        alu_func_sel_out : out std_logic_vector(2 downto 0);
        alu_l_sel_out    : out std_logic;
        alu_r_sel_out    : out std_logic;
        
        -- MDU control
        mdu_rdy_inp      : in  std_logic;
        mdu_start_out    : out std_logic;
        mdu_func_sel_out : out std_logic;
        
        -- comparator control
        cmp_r_sel_out : out std_logic;
        
        -- Status signals
        cmp_eq_inp : in std_logic;
        cmp_gt_inp : in std_logic;
        
        -- Controller data
        ctrl_data_out : out std_logic_vector(31 downto 0);
        
        --int0 : out std_logic;
        clk    : in std_logic;
        resetn : in std_logic);
    end component mips32_ctrl;
    
    signal den  : std_logic;
    signal ten  : std_logic;
    signal tsrc : std_logic_vector(1 downto 0);
    signal dsrc : std_logic_vector(1 downto 0);
    
    signal pgcen  : std_logic;
    signal insten : std_logic;
    signal inst   : std_logic_vector(31 downto 0);

    signal alu_func_sel : std_logic_vector(2 downto 0);
    signal alu_l_sel    : std_logic;
    signal alu_r_sel    : std_logic;
    
    signal mdu_rdy      : std_logic;
    signal mdu_start    : std_logic;
    signal mdu_func_sel : std_logic;
    
    signal cmp_r_sel : std_logic;

    signal cmp_eq : std_logic;
    signal cmp_gt : std_logic;

    signal ctrl_data : std_logic_vector(31 downto 0);
begin
    datapath : mips32_dp
    generic map(
        IA_LEN           => IA_LEN)
    port map(
        dbus_addr_out    => dbus_addr_out,
        dbus_data_out    => dbus_data_out,
        dbus_data_inp    => dbus_data_inp,
        ibus_addr_out    => ibus_addr_out,
        ibus_data_inp    => ibus_data_inp,
        den              => den,
        ten              => ten,
        tsrc             => tsrc,
        dsrc             => dsrc,
        pgcen            => pgcen,
        insten           => insten,
        inst_out         => inst,
        alu_func_sel_inp => alu_func_sel,
        alu_l_sel_inp    => alu_l_sel,
        alu_r_sel_inp    => alu_r_sel,
        mdu_start_inp    => mdu_start,
        mdu_rdy_out      => mdu_rdy,
        mdu_func_sel_inp => mdu_func_sel,
        cmp_r_sel_inp    => cmp_r_sel,
        cmp_eq_out       => cmp_eq,
        cmp_gt_out       => cmp_gt,
        ctrl_data_inp    => ctrl_data,
        clk              => clk,
        resetn           => resetn);

    controller : mips32_ctrl
    port map(
        dbus_wren_out    => dbus_wren_out,
        den              => den,
        ten              => ten,
        tsrc             => tsrc,
        dsrc             => dsrc,
        pgcen            => pgcen,
        insten           => insten,
        inst_inp         => inst,
        alu_func_sel_out => alu_func_sel,
        alu_l_sel_out    => alu_l_sel,
        alu_r_sel_out    => alu_r_sel,
        mdu_start_out    => mdu_start,
        mdu_rdy_inp      => mdu_rdy,
        mdu_func_sel_out => mdu_func_sel,
        cmp_r_sel_out    => cmp_r_sel,
        cmp_eq_inp       => cmp_eq,
        cmp_gt_inp       => cmp_gt,
        ctrl_data_out    => ctrl_data,
        --int0 => int0,
        clk              => clk,
        resetn           => resetn);
    
end architecture structural;