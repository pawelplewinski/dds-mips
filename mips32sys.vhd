library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity mips32sys is 
    generic (
        SYS_32   : positive := 32;
        IA_LEN   : natural  :=  9;
        DA_LEN   : natural  :=  5;
        GPIO_LEN : natural  :=  8);
    port(
        -- control signal for imem addr input
        ia_select   : in  std_logic;                                    -- ('1' -> MIPS; '0' -> testset)

        ibus_d_i    : in  std_logic_vector(SYS_32-1 downto 0);
        ibus_a_o    : out std_logic_vector(IA_LEN-1 downto 0);
      
        clk         : in  std_logic;
        resetn      : in  std_logic);
end entity mips32sys;
    
architecture struct of mips32sys is

    ---------------
    -- MIPS core --
    ---------------
    component mips32core is
    generic(
        SYS_32    : positive := 32;
        IA_LEN    : natural  :=  9;
        DA_LEN    : natural  :=  6);
    port(
        ibus_d_i  : in  std_logic_vector(SYS_32-1 downto 0);
        ibus_a_o  : out std_logic_vector(IA_LEN-1 downto 0);
        
        dbus_a_o  : out std_logic_vector(DA_LEN-1 downto 0);
        dbus_d_i  : in  std_logic_vector(SYS_32-1 downto 0);
        dbus_d_o  : out std_logic_vector(SYS_32-1 downto 0);
        dbus_we_o : out std_logic;
        
        clk       : in std_logic;
        resetn    : in std_logic);
    end component mips32core;

    ------------
    -- memory --
    ------------
    component mem32 is
	generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9);
	port(
		-- wishbone interface
		wbs_addr_i  : in  std_logic_vector(ADDR_LENGTH-1 downto 0);
		wbs_dat_i   : in  std_logic_vector(SYS_32-1 downto 0);
		wbs_dat_o   : out std_logic_vector(SYS_32-1 downto 0);
        wbs_sel_i   : in  std_logic;        
		wbs_we_i    : in std_logic;	                                    -- '1' -> enable write ; '0' -> disable write
          
		clk         : in std_logic;
		resetn      : in std_logic);
    end component mem32;
    
    -- Use the different flavours of the memory component
    for imem : mem32 use entitiy work.mem32(ibehav);
    for dmem : mem32 use entitiy work.mem32(dbehav);
    
--     component gpio is
--     generic( GPIO_LEN : natural := 8 );
--     port(
--                -- wishbone interface
--         wbs_addr_i : in std_logic_vector(1 downto 0);
--         wbs_dat_o : out std_logic_vector(31 downto 0);
--         wbs_dat_i : in std_logic_vector(31 downto 0);
--         
--         wbs_we_i : in std_logic;    -- '1' -> enable write ; '0' -> disable write
--        
--         io : inout std_logic_vector(GPIO_LEN-1 downto 0);
--         
--         
--         clk : in std_logic;
--         resetn : in std_logic
--     );
--     end component gpio;
    
    ---------------------------------------
    --------------- Signals ---------------
    ---------------------------------------
    
    -- bus signals for COM with imem(iram) and dmem(dram)
    signal ibus_a_o     : std_logic_vector(IA_LEN-1 downto 0);      -- holds new instr addr for imem
    
    signal dbus_a_o     : std_logic_vector(DA_LEN-1 downto 0);
    signal dbus_d_i     : std_logic_vector(SYS_32-1 downto 0);
    signal dbus_d_o     : std_logic_vector(SYS_32-1 downto 0);
    signal dbus_we      : std_logic;
    
    -- Internal RAM related signals
    signal iram_d_o     : std_logic_vector(SYS_32-1 downto 0);      -- holds read instruction from imem
    
    signal dram_d_o     : std_logic_vector(SYS_32-1 downto 0);
    signal dram_a_i     : std_logic_vector(DA_LEN-1 downto 0);
    signal dram_we_i    : std_logic;
    
    signal dperiph_d_o  : std_logic_vector(SYS_32-1 downto 0);
    signal dperiph_d_i  : std_logic_vector(SYS_32-1 downto 0);

begin

    -- Connect MIPS core
    cpu : mips32core
    generic map(
        IA_LEN      => IA_LEN,
        DA_LEN      => DA_LEN)
    port map(
        ibus_a_o    => ibus_a_o,
        dbus_a_o    => dbus_a_o,
        dbus_d_o    => dbus_d_o,
        
        ibus_d_i    => iram_i_o,
         
        dbus_d_i    => dbus_d_i,
        dbus_we_o   => dbus_we,

        dbus_sel1   => wbs_sel_i,
        dbus_sel2   => wbs_sel_i,
        
        clk         => clk,
        resetn      => resetn);

    -- Connect instruction memory
    imem : mem32
        generic map(
            SYS_32      => SYS_32,
            ADDR_LENGTH => IA_LEN)
        port map(
            wbs_addr_i  => imem_a_i,
            wbs_dat_i   => imem_d_i,
            wbs_dat_o   => iram_d_o,
            wbs_sel_i   => dbus_sel1,
            wbs_we_i    => imem_we,
           
            clk         => clk,
            resetn      => resetn);

    -- Connect data memory            
    dmem : mem32
        generic map(
            SYS_32      => SYS_32,
            ADDR_LENGTH => DA_LEN)
        port map(
            wbs_addr_i  => dram_a_i,
            wbs_dat_o   => dram_d_o,
            wbs_dat_i   => dbus_d_o,
            wbs_sel_i   => dbus_sel2,            
            wbs_we_i    => dram_we_i,
            
            clk         => clk,
            resetn      => resetn);
    
    -- NO in and output from peripherals for now
    dperiph_d_o <= (others => '-');
    dperiph_d_i <= (others => '-');
    
    -- Map memory on addresses 256-512
    --dram_a_i    <= dbus_a_o(DA_LEN-1 downto 0);
    dram_a_i    <= dbus_a_o;
    dram_we_i   <= dbus_we and dbus_a_o(DA_LEN-1);
    
    -- Map ports to signals
    ia_sel <= ia_select;

    -- Switch between RAM and peripherals
    with dbus_a(DA_LEN-1) select dbus_d_i <=
        dram_d_o        when '1',
        dperiph_d_o     when '0',
        (others => '-') when others;
        
    -- switch between CPU and program loader
	imem_a_i <=  ibus_a_o when ia_sel = '0' else
	             iaddr;
        
end architecture struct;