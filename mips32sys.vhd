library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity mips32sys is 
    generic (
        SYS_32      : positive := 32;
        IA_LEN      : natural  :=  9;
        DA_LEN      : natural  :=  5;
        GPIO_LEN    : natural  :=  8
    );
    port(
        clk         : in  std_logic;
        resetn      : in  std_logic
    );
end entity mips32sys;
    
architecture struct of mips32sys is

    ---------------
    -- MIPS core --
    ---------------
    component mips32core is
    generic(
        SYS_32    : positive := 32;
        IA_LEN    : natural  :=  9;
        DA_LEN    : natural  :=  6
    );
    port(
        ibus_data_inp   : in  std_logic_vector(SYS_32-1 downto 0);
        ibus_addr_out   : out std_logic_vector(IA_LEN-1 downto 0);
        
        dbus_addr_out   : out std_logic_vector(DA_LEN-1 downto 0);
        dbus_data_inp   : in  std_logic_vector(SYS_32-1 downto 0);
        dbus_data_out   : out std_logic_vector(SYS_32-1 downto 0);
        dbus_wren_out   : out std_logic;
        
        clk             : in std_logic;
        resetn          : in std_logic
    );
    end component mips32core;

    ------------
    -- memory --
    ------------
    component mem32 is
    generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9
    );
    port(
        -- COM bus interface
        bus_addr_inp    : in  std_logic_vector(ADDR_LENGTH-1 downto 0);
        bus_data_inp    : in  std_logic_vector(SYS_32-1 downto 0);
        bus_data_out    : out std_logic_vector(SYS_32-1 downto 0);
        bus_wren_inp    : in  std_logic;                                        -- '1' -> enable write ; '0' -> disable write
          
        clk             : in std_logic;
        resetn          : in std_logic
    );
    end component mem32;
    
    -- Use the different flavours of the memory component
    for imem : mem32 use entity work.mem32(ibehav);
    for dmem : mem32 use entity work.mem32(dbehav);
  
    ---------------------------------------
    --------------- Signals ---------------
    ---------------------------------------
    
    -- bus signals for COM with RAM components from the master PoV (core -> I/O) 
    -- imem(iram):
    --signal iram_d_i   : std_logic_vector(SYS_32-1 downto 0);        -- [obsolete] holds new instr data for imem
    signal iram_data_inp    : std_logic_vector(SYS_32-1 downto 0);        -- holds new instr from imem
    signal iram_addr_out    : std_logic_vector(IA_LEN-1 downto 0);        -- holds new instr addr for imem
    --signal iram_we_o  : std_logic;                                  -- [obsolete] holds the write enable signal from core->imem
    -- dmem(dram):
    signal dram_data_inp    : std_logic_vector(SYS_32-1 downto 0);
    signal dram_addr_out    : std_logic_vector(DA_LEN-1 downto 0);
    signal dram_data_out    : std_logic_vector(SYS_32-1 downto 0);
    signal dram_wren_out    : std_logic;
    
begin

    -- Connect MIPS core
    cpu : mips32core
        generic map(
            IA_LEN          => IA_LEN,
            DA_LEN          => DA_LEN
        )
        port map(
            ibus_data_inp   => iram_data_inp,
            ibus_addr_out   => iram_addr_out,

            dbus_data_inp   => dram_data_inp,
            dbus_addr_out   => dram_addr_out,
            dbus_data_out   => dram_data_out,
            dbus_wren_out   => dram_wren_out,

            clk             => clk,
            resetn          => resetn
        );

    -- Connect instruction memory
    imem : mem32
        generic map(
            SYS_32          => SYS_32,
            ADDR_LENGTH     => IA_LEN
        )
        port map(
            bus_wren_inp    => 'Z',
            bus_addr_inp    => iram_addr_out,
            bus_data_inp    => (others => 'Z'),
            bus_data_out    => iram_data_inp,
           
            clk             => clk,
            resetn          => resetn
        );

    -- Connect data memory            
    dmem : mem32
        generic map(
            SYS_32          => SYS_32,
            ADDR_LENGTH     => DA_LEN
        )
        port map(
            bus_wren_inp    => dram_wren_out,
            bus_addr_inp    => dram_addr_out,
            bus_data_inp    => dram_data_out,
            bus_data_out    => dram_data_inp,

            clk             => clk,
            resetn          => resetn
        );

end architecture struct;