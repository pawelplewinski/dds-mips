library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_mips is
    generic(
	IA_LEN : natural := 20;
	DA_LEN : natural := 16);
end entity tb_mips;

architecture tb_arch of tb_mips is
    signal clk : std_logic := '0';
    signal resetn : std_logic;
    
    component mem32 is
    generic(ADDR_LENGTH : natural := 9);
    port(addr : in std_logic_vector(ADDR_LENGTH downto 0);
       data : inout std_logic_vector(31 downto 0);
       
       we : in std_logic;	-- '1' -> enable write ; '0' -> disalbe write
       wr : in std_logic;	-- '0' -> write ; '1' -> read
       
       
       clk : in std_logic;
       resetn : in std_logic);
    end component mem32;
    
    component mips32sys is 
	generic (IA_LEN : natural := 9;
		DA_LEN : natural := 6;
		GPIO_LEN : natural := 8);
	port(
	gpo0 : out std_logic_vector(GPIO_LEN-1 downto 0);
	
	ibus_a_o : out std_logic_vector(IA_LEN-1 downto 0);
	ibus_d_i : in std_logic_vector(31 downto 0);
	
	clk : in std_logic;
	resetn : in std_logic);
    end component mips32sys;
    
    signal gpo0 : std_logic_vector(7 downto 0);
    
    signal imem_a : std_logic_vector(IA_LEN-1 downto 0);
    signal imem_d : std_logic_vector(31 downto 0);
    signal imem_we : std_logic;
    signal imem_wr : std_logic;

    signal inst : std_logic_vector(31 downto 0) := (others => '0');
begin
    -- Connect memory
    imem : mem32
    generic map(ADDR_LENGTH => IA_LEN)
    port map(addr => imem_a,
	     data => imem_d,
	     we => imem_we,
	     wr => imem_wr,
	     clk => clk,
	     resetn => resetn);
	     
    -- Connect MIPS system
    gut : mips32sys
    generic map(IA_LEN => IA_LEN,
		DA_LEN => DA_LEN,
		GPIO_LEN => 8)
    port map(gpo0 => gpo0,
	     ibus_a_o => imem_a,
	     ibus_d_i => imem_d,
	     clk => clk,
	     resetn => resetn);

    clk <= not clk after 50 ns;
    
    rst : process begin
	resetn <= '0';
	wait for 50 ns;
	resetn <= '1';
	wait;
    end process;
    
    mem_access : process begin
	-- wait till the system is reset
	wait until resetn = '1';
	
	-- Writing ...
	imem_wr <= '0';
	-- First word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(0,IA_LEN));
	imem_d <= std_logic_vector(to_unsigned(1,32));
	imem_we <= '1';
	wait until clk = '1';
	imem_we <= '0';
	-- Second word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(1,IA_LEN));
	imem_d <= std_logic_vector(to_unsigned(5,32));
	imem_we <= '1';
	wait until clk = '1';
	imem_we <= '0';
	-- Third word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(2,IA_LEN));
	imem_d <= std_logic_vector(to_unsigned(2,32));
	imem_we <= '1';
	wait until clk = '1';
	imem_we <= '0';
	
	-- Reading
	imem_wr <= '1';
	imem_d <= (others => 'Z');
	-- Read first word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(0,IA_LEN));
	inst <= imem_d;
	wait until clk = '1';
	-- Read second word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(1,IA_LEN));
	inst <= imem_d;
	wait until clk = '1';
	-- Read third word
	wait until clk = '0';
	imem_a <= std_logic_vector(to_unsigned(2,IA_LEN));
	inst <= imem_d;
	wait until clk = '1';
	
	-- wait a few clock cycles more
	for i in 1 to 10 loop
	    wait until clk = '0';
	    wait until clk = '1';
	end loop;
	
	assert false report "End of simulation" severity failure;
	wait;
    end process;
	
end architecture tb_arch;