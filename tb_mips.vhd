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
    signal clk      : std_logic := '0';
    signal resetn   : std_logic;
    
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
	    resetn      => resetn);
	     
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
	-- wait til the system is reset
    begin
        wait until resetn = '1';
        -- Give control of the memory address to the test bench
        ia_sel <= '0';

        -- Writing ...
        -- First word
            imem_d_i    <= (others => '0');
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(0,IA_LEN));
        imem_d_i    <= std_logic_vector(to_unsigned(0,32));
        imem_we     <= '1';
        wait until clk = '1';
        imem_we     <= '0';
        
        -- Second word
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(1,IA_LEN));
        imem_d_i    <= std_logic_vector(to_unsigned(1,32));
        imem_we     <= '1';
        wait until clk = '1';
        imem_we     <= '0';
        
        -- Third word
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(2,IA_LEN));
        imem_d_i    <= std_logic_vector(to_unsigned(2,32));
        imem_we     <= '1';
        wait until clk = '1';
        imem_we     <= '0';
        
        -- Reading
        -- Read first word
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(0,IA_LEN));
        inst        <= imem_d_o;
        wait until clk = '1';
        
        -- Read second word
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(1,IA_LEN));
        inst        <= imem_d_o;
        wait until clk = '1';
        
        -- Read third word
        wait until clk = '0';
        iaddr       <= std_logic_vector(to_unsigned(2,IA_LEN));
        inst        <= imem_d_o;
        wait until clk = '1';
        
        -- Switch memory address control to CPU
        ia_sel <= '1';
        
        -- wait a few clock cycles more
        for i in 1 to 10 loop
            wait until clk = '0';
            wait until clk = '1';
        end loop;
        
        assert false report "End of simulation" severity warning;
        wait;
    end process;
	
end architecture tb_arch;