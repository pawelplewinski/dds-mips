library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity tb_mips is
    generic(
        IA_LEN   : natural  := 8;
        DA_LEN   : natural  := 4;
        SYS_32   : positive := 32);
end entity tb_mips;

architecture tb_arch of tb_mips is
    signal clk      : std_logic := '0';
    signal resetn   : std_logic;
    signal resetp : std_logic := '0';
    
    component mem32 is
	generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9);
	port(
		-- wishbone interface
		wbs_addr_i  : in  std_logic_vector(ADDR_LENGTH-1 downto 0);
		wbs_dat_i   : in  std_logic_vector(SYS_32-1 downto 0);
		wbs_dat_o   : out std_logic_vector(SYS_32-1 downto 0);
        
		wbs_we_i    : in std_logic;	-- '1' -> enable write ; '0' -> disable write
          
		clk         : in std_logic;
		resetn      : in std_logic
	);
    end component mem32;
    
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
    
    signal imem_a_i : std_logic_vector(IA_LEN-1 downto 0);
    signal imem_d_o : std_logic_vector(SYS_32-1 downto 0);
    signal imem_d_i : std_logic_vector(SYS_32-1 downto 0);
    signal imem_we  : std_logic;

    signal inst     : std_logic_vector(SYS_32-1 downto 0) := (others => '0');
    
    signal ibus_a_o : std_logic_vector(IA_LEN-1 downto 0);
    signal iaddr    : std_logic_vector(IA_LEN-1 downto 0);
    signal ia_sel   : std_logic;
    
    file mips_pgm : text open read_mode is "gcd.txt";
begin
    -- Connect memory
    imem : mem32
        generic map(
            SYS_32      => SYS_32,
            ADDR_LENGTH => IA_LEN)
        port map(
            wbs_addr_i  => imem_a_i,
            wbs_dat_i   => imem_d_i,
            wbs_dat_o   => imem_d_o,
            wbs_we_i    => imem_we,
                 
            clk         => clk,
            resetn      => resetn);
	     
    -- Connect MIPS system
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
	    resetn      => resetp);
	     
	-- switch between cpu and program loader
	imem_a_i <=  ibus_a_o when ia_sel = '0' else
	             iaddr;

    -- clock generation
    clk <= not clk after 50 ns;
    
    -- reset generation
    rst : process
        begin
            resetn      <= '0';
            wait for 50 ns;
            resetn      <= '1';
            wait;
        end process;
    
    mem_access : process 
	     variable rdline : line;
	     variable hexdata : std_logic_vector(SYS_32-1 downto 0);
	     variable addr_ctr : unsigned(IA_LEN-1 downto 0) := (others => '0');
    begin
        -- wait til the system is reset
        wait until resetn = '1';
        
        -- Give control of the memory address to the test bench
        ia_sel <= '1';
        imem_we <= '1';
        addr_ctr := (others => '0');
        while not endfile(mips_pgm) loop
            iaddr <= std_logic_vector(addr_ctr);
            addr_ctr := addr_ctr + 1;
            readline(mips_pgm,rdline);
            hread(rdline,hexdata);
            imem_d_i <= hexdata;
            wait until clk = '1';
            wait until clk = '0';
        end loop;
        imem_we <= '0';
        ia_sel <= '0';
        resetp <= '0';
        resetp <= '1';
        
        assert false report "End of simulation" severity warning;
        wait;
    end process;
	
end architecture tb_arch;