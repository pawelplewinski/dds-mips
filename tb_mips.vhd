library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_mips is
    generic(
        IA_LEN   : natural  := 20;
        DA_LEN   : natural  := 16;
        SYS_32   : positive := 32);
end entity tb_mips;

architecture tb_arch of tb_mips is

    -------------
    -- testset --
    -------------
    component testset is
    generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9);
    port(
        -- Wishbone bus interface (with imem)
        wbs_addr_o : out std_logic_vector(ADDR_LENGTH-1 downto 0);  -- imem address 
        wbs_dat_o  : out std_logic_vector(SYS_32-1 downto 0);       -- imem data
        
        clk        : out std_logic;
        rst        : out std_logic);  
    
    -----------------
    -- MIPS system --
    -----------------
    component mips32sys is 
	generic (
        SYS_32      : positive := 32;
        IA_LEN      : natural  :=  9;
		DA_LEN      : natural  :=  6;
		GPIO_LEN    : natural  :=  8);
	port(
        ibus_a_o    : out std_logic_vector(IA_LEN-1 downto 0);
        ibus_d_i    : in  std_logic_vector(SYS_32-1 downto 0);
        
        clk         : in  std_logic;
        resetn      : in  std_logic);
    end component mips32sys;
    
    ----------------
    -- Comparator --
    ----------------
    
    
    ---------------------------------------
    --------------- Signals ---------------
    ---------------------------------------
    
    signal tb_clk      : std_logic; 
    signal tb_reset    : std_logic; -- high active reset
    signal tb_resetn   : std_logic; -- low active reset
    
    signal imem_a_i : std_logic_vector(IA_LEN-1 downto 0);
    signal imem_d_o : std_logic_vector(SYS_32-1 downto 0);
    signal imem_d_i : std_logic_vector(SYS_32-1 downto 0);
    signal imem_we  : std_logic;

    signal inst     : std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    
    signal ibus_a_o : std_logic_vector(IA_LEN-1 downto 0);
    signal iaddr    : std_logic_vector(IA_LEN-1 downto 0);
    signal ia_sel   : std_logic;
begin

    ----------------
    -- Components --
    ----------------

    tst : testset
        generic(
            SYS_32      => SYS_32,
            ADDR_LENGTH => IA_LEN)
        port(
            -- Wishbone bus interface (with imem)
            wbs_addr_o : out std_logic_vector(ADDR_LENGTH-1 downto 0);  -- imem address 
            wbs_dat_o  : out std_logic_vector(SYS_32-1 downto 0);       -- imem data
            
            clk        : out std_logic;
            rst        : out std_logic);  
     
    -- Connect MIPS system (gut)
    gut : mips32sys
    generic map(
        SYS_32      => SYS_32,
        IA_LEN      => IA_LEN,
		DA_LEN      => DA_LEN,
		GPIO_LEN    => 8)
    port map(
	    ibus_d_i    => imem_d_o,
	    ibus_a_o    => ibus_a_o,
	    clk         => clk,
	    resetn      => resetn);

    -- Connect MIPS system (dut)
    
    -- Connect Comparator
	     


end architecture tb_arch;