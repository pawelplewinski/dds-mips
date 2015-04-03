library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity mips32sys_dut is 
    generic (
	PGM_FILE : string := "pgm_mem.txt";
        SYS_32   : positive := 32;
        DMEM_LEN   : natural  :=  64;  --In bytes
        IMEM_LEN   : natural  :=  64  --In 32-bit words
	);
    port(
        clk      : in  std_logic;
        resetn   : in  std_logic;
        
        end_sim	 : out std_logic);
end entity mips32sys_dut;
    
architecture struct of mips32sys_dut is
    component mips32core is
    generic(
        SYS_32    : positive := 32);
    port(
        ibus_d_i  : in  std_logic_vector(SYS_32-1 downto 0) := (others => '0');
        ibus_a_o  : out std_logic_vector(SYS_32-1 downto 0) := (others => '0');
        
        dbus_a_o  : out std_logic_vector(SYS_32-1 downto 0) := (others => '0');
        dbus_d_i  : in  std_logic_vector(SYS_32-1 downto 0) := (others => '0');
        dbus_d_o  : out std_logic_vector(SYS_32-1 downto 0) := (others => '0');
        dbus_we_o : out std_logic := '0';
        
        int0	  : out std_logic := '0';
        
        clk       : in std_logic := '0';
        resetn    : in std_logic := '0');
    end component mips32core;
     
    component mem32 is
    generic(
	PGM_FILE 	: string := "none.txt";
        SYS_32      	: positive := 32;
        MEM_LEN 	: natural  :=  64);
    port(
        -- wishbone interface
        wbs_addr_i : in  std_logic_vector(SYS_32-1 downto 0);
        wbs_dat_i  : in  std_logic_vector(SYS_32-1 downto 0);
        wbs_dat_o  : out std_logic_vector(SYS_32-1 downto 0);
        
        wbs_we_i   : in  std_logic;	-- '1' -> enable write ; '0' -> disable write
          
        clk        : in  std_logic;
        resetn     : in  std_logic);
    end component mem32;

    signal dbus_a       : std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    signal dbus_d_i     : std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    signal dbus_d_o     : std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    signal dbus_we      : std_logic;
    
    signal ibus_d_i 	: std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    signal ibus_a_o 	: std_logic_vector(SYS_32-1 downto 0) := (others => '0');
begin
    -- Connect memory
    i_mem : entity work.mem32(imem)
        generic map(
	    PGM_FILE 	=> PGM_FILE,
            SYS_32      => SYS_32,
            MEM_LEN 	=> IMEM_LEN)
        port map(
            wbs_addr_i  => ibus_a_o,
            wbs_dat_i   => (others => '0'),
            wbs_dat_o   => ibus_d_i,
            wbs_we_i    => '0',	-- Always read
                 
            clk         => clk,
            resetn      => resetn);

    d_mem : entity work.mem32(dmem)
        generic map(
            SYS_32      => SYS_32,
            MEM_LEN 	=> DMEM_LEN)
        port map(
            wbs_addr_i  => dbus_a,
            wbs_dat_o   => dbus_d_i,
            wbs_dat_i   => dbus_d_o,
            wbs_we_i    => dbus_we,
             
            clk         => clk,
            resetn      => resetn);
             
    cpu : entity work.mips32core(structural)
    port map(
        ibus_a_o    => ibus_a_o,
        ibus_d_i    => ibus_d_i,
         
        dbus_a_o    => dbus_a,
        dbus_d_i    => dbus_d_i,
        dbus_d_o    => dbus_d_o,
        dbus_we_o   => dbus_we,
        
        int0	    => end_sim,
        
        clk         => clk,
        resetn      => resetn);
                
end architecture struct;