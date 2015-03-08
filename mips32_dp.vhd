library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_dp is
    generic(
        IA_LEN    : natural  :=  9
    );
    port(
        -- Data bus
        dbus_addr_out  : out std_logic_vector(31 downto 0);
        dbus_data_out  : out std_logic_vector(31 downto 0);
        dbus_data_inp  : in  std_logic_vector(31 downto 0);
        
        -- Instruction bus
        ibus_addr_out  : out std_logic_vector(31 downto 0);
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
end entity mips32_dp;

architecture behav of mips32_dp is

    subtype u32 is unsigned(31 downto 0);
    type reg_file is array (natural range <>) of u32;
  
    component mips32_alu is
    port(
        func_sel    : in  std_logic_vector(2 downto 0);
        alu_l_inp   : in  std_logic_vector(31 downto 0);
        alu_r_inp   : in  std_logic_vector(31 downto 0);
        alu_res_out : out std_logic_vector(31 downto 0);
        alu_cout    : out std_logic);
    end component mips32_alu;
    
    component mips32_cmp is
    port(
        cmp_l_inp  : in  std_logic_vector(31 downto 0);
        cmp_r_inp  : in  std_logic_vector(31 downto 0);
        
        cmp_eq_out : out std_logic;
        cmp_gt_out : out std_logic);
    end component mips32_cmp;
    
    component mips32_mdu is
    port(
        mdu_l_inp  : in  std_logic_vector(31 downto 0);
        mdu_r_inp  : in  std_logic_vector(31 downto 0);
        
        mdu_hi_out : out std_logic_vector(31 downto 0);
        mdu_lo_out : out std_logic_vector(31 downto 0);
        
        mode_inp   : in  std_logic;
        start_inp  : in  std_logic;
        rdy_out    : out std_logic;
        
        clk        : in std_logic;
        resetn     : in std_logic);
    end component mips32_mdu;
    
    -- Comparator inputs
    signal cmp_l    : std_logic_vector(31 downto 0);
    signal cmp_r    : std_logic_vector(31 downto 0);
    
    -- ALU interface
    signal alu_l    : std_logic_vector(31 downto 0);
    signal alu_r    : std_logic_vector(31 downto 0);
    signal alu_res  : std_logic_vector(31 downto 0);
    signal alu_cout : std_logic;
    signal alu_sel  : std_logic_vector(2 downto 0);
    
    -- GPREG bank
    signal reg      : reg_file(1 to 31);
    signal sreg     : u32;
    signal treg     : u32;
    signal dnext    : u32;
    signal tnext    : u32;
    signal hireg    : std_logic_vector(31 downto 0);
    signal loreg    : std_logic_vector(31 downto 0);
    signal mdures   : std_logic_vector(63 downto 0);
    
    signal inst     : std_logic_vector(31 downto 0);
    signal pgc      : u32 := (others => '0');
    signal pgcnext  : u32 := (others => '0');
    
    signal ssel     : integer range 0 to 31;
    signal tsel     : integer range 0 to 31;
    signal dsel     : integer range 0 to 31;
begin

    -- The address of the ibus is always connected to program counter
    ibus_addr_out <= std_logic_vector(pgc);
    inst_out      <= std_logic_vector(inst);
    
    dbus_addr_out <= alu_res(31 downto 0);
    dbus_data_out <= std_logic_vector(treg);
    
    ssel <= to_integer(unsigned(inst(25 downto 21)));
    tsel <= to_integer(unsigned(inst(20 downto 16)));
    dsel <= to_integer(unsigned(inst(15 downto 11)));
    
    -- DEBUG: concatenate sub-results of the mdu
    mdures <= hireg & loreg;
    
    -- Declare ALU
    alu : mips32_alu
    port map(
        alu_l_inp   => alu_l,
        alu_r_inp   => alu_r,
        alu_res_out => alu_res,
        alu_cout    => alu_cout,
        func_sel    => alu_func_sel_inp);
     
    -- Connect ALU
    with alu_l_sel_inp select alu_l <=
        std_logic_vector(sreg) when '0',
        std_logic_vector(pgc)  when '1',
        (others => '-')        when others;
        
    with alu_r_sel_inp select alu_r <=
        std_logic_vector(treg) when '0',
        ctrl_data_inp          when '1',
        (others => '-')        when others;
    
    -- Declare comparator
    cmp : mips32_cmp
    port map(
        cmp_l_inp  => std_logic_vector(sreg),
        cmp_r_inp  => cmp_r,
        cmp_eq_out => cmp_eq_out,
        cmp_gt_out => cmp_gt_out);
    
    -- Connect comparator
    with cmp_r_sel_inp select cmp_r <=
        std_logic_vector(treg) when '1',
        (others => '0')        when '0',
        (others => '-')        when others;
   
    -- Connect MDU
    mdu : mips32_mdu
    port map(
        mdu_l_inp  => std_logic_vector(sreg),
        mdu_r_inp  => std_logic_vector(treg),
        mdu_hi_out => hireg,
        mdu_lo_out => loreg,
        mode_inp   => mdu_func_sel_inp,
        rdy_out    => mdu_rdy_out,
        start_inp  => mdu_start_inp,
        clk        => clk,
        resetn     => resetn);
    
    -- Connect register file output registers
    -- (will give value 0 when reg file addr $0 is addressed)
    sreg <= (others => '0') when ssel = 0 else reg(ssel);
    treg <= (others => '0') when tsel = 0 else reg(tsel);
    
    with tsrc select tnext <=
        unsigned(alu_res)       when "00",   -- ALU out
        unsigned(ctrl_data_inp) when "01",   -- Data
        unsigned(dbus_data_inp) when "10",   -- Memory
        (others => '-')         when others;

    with dsrc select dnext <=
        unsigned(alu_res)       when "00",   -- ALU out
        unsigned(hireg)         when "01",   -- HI reg
        unsigned(loreg)         when "10",   -- LO reg
        (others => '-')         when others;
    
    -- Synchronize the updates of
    --      incoming new instruction
    --      register file output
    --      program counter
    sync_proc : process(clk,resetn)
    begin
        if resetn = '0' then
            reg  <= (others => (others => '0'));
            pgc  <= (others => '0');
            inst <= (others => '0');
        elsif rising_edge(clk) then
            -- Update reg file output (dependent on the requested addr)
            if ten = '1' and tsel /= 0 then
                reg(tsel) <= tnext;
            end if;
            if den = '1' and dsel /= 0 then
                reg(dsel) <= dnext;
            end if;
            -- Update pcg
            if pgcen = '1' then
                pgc <= pgcnext;
            end if;
            -- Get new instruction
            if insten = '1' then
                inst <= ibus_data_inp;
            end if;
        end if;
    end process sync_proc;
    
    -- Get next pgc from alue
    pgcnext <= unsigned(alu_res);
    
end architecture behav;
