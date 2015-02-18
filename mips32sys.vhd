library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity mips32sys is 
	generic (IA_LEN : natural := 9;
		DA_LEN : natural := 5;
		GPIO_LEN : natural := 8);
	port(
	gpo0 : out std_logic_vector(GPIO_LEN-1 downto 0);
	
	ibus_a_o : out std_logic_vector(IA_LEN-1 downto 0);
	ibus_d_i : in std_logic_vector(31 downto 0);
	
	clk : in std_logic;
	resetn : in std_logic);
end entity mips32sys;
	
architecture struct of mips32sys is
	
	component mips32core is
	generic(
		IA_LEN : natural := 9;
		DA_LEN : natural := 6);
	port(
		ibus_a_o : out std_logic_vector(IA_LEN-1 downto 0);
		ibus_d_i : in std_logic_vector(31 downto 0);
	    
		dbus_a_o : out std_logic_vector(DA_LEN-1 downto 0);
		dbus_d_o : out std_logic_vector(31 downto 0);
		dbus_d_i : in std_logic_vector(31 downto 0);
		dbus_we_o : out std_logic;
	    
		clk : in std_logic;
		resetn : in std_logic);
	end component mips32core;
     
	component mem32 is
	generic(ADDR_LENGTH : natural := 9);
	port(
		-- wishbone interface
		wbs_addr_i : in std_logic_vector(ADDR_LENGTH-1 downto 0);
		wbs_dat_o : out std_logic_vector(31 downto 0);
		wbs_dat_i : in std_logic_vector(31 downto 0);
       
		wbs_we_i : in std_logic;	-- '1' -> enable write ; '0' -> disable write
          
		clk : in std_logic;
		resetn : in std_logic
	);
	end component mem32;
	
-- 	component gpio is
-- 	generic( GPIO_LEN : natural := 8 );
-- 	port(
-- 		       -- wishbone interface
-- 		wbs_addr_i : in std_logic_vector(1 downto 0);
-- 		wbs_dat_o : out std_logic_vector(31 downto 0);
-- 		wbs_dat_i : in std_logic_vector(31 downto 0);
-- 		
-- 		wbs_we_i : in std_logic;	-- '1' -> enable write ; '0' -> disable write
--        
-- 		io : inout std_logic_vector(GPIO_LEN-1 downto 0);
-- 		
-- 		
-- 		clk : in std_logic;
-- 		resetn : in std_logic
-- 	);
-- 	end component gpio;
	

	signal dbus_a : std_logic_vector(DA_LEN-1 downto 0);
	signal dbus_d_i : std_logic_vector(31 downto 0);
	signal dbus_d_o : std_logic_vector(31 downto 0);
	signal dbus_we : std_logic;
	
	-- Internal RAM related signals
	signal dram_d_o : std_logic_vector(31 downto 0);
	signal dram_a_i : std_logic_vector(DA_LEN-1 downto 0);
	signal dram_we_i : std_logic;
	
	signal dperiph_d_o : std_logic_vector(31 downto 0);
	signal dperiph_d_i : std_logic_vector(31 downto 0);
begin
	--No output from peripherals for now
	dperiph_d_o <= (others => '-');
	
	-- Map memory on addresses 256-512
	dram_a_i <= dbus_a(DA_LEN-2 downto 0);
	dram_we_i <= dbus_we and dbus_a(DA_LEN-1);
	dmem : mem32
	    generic map(ADDR_LENGTH => DA_LEN-1)
	    port map(wbs_addr_i => dram_a_i,
		     wbs_dat_o => dram_d_o,
		     wbs_dat_i => dbus_d_o,
		     wbs_we_i => dram_we_i,
		     
		     clk => clk,
		     resetn => resetn);
	
	-- Switch between RAM and peripherals
	with dbus_a(DA_LEN-1) select dbus_d_i <=
	    dram_d_o when '1',
	    dperiph_d_o when '0',
	    (others => '-') when others;
	    
		     
	cpu : mips32core
	generic map(IA_LEN => IA_LEN,
		    DA_LEN => DA_LEN)
	port map(ibus_a_o => ibus_a_o,
	     ibus_d_i => ibus_d_i,
	     
	     dbus_a_o => dbus_a,
	     dbus_d_i => dbus_d_i,
	     dbus_d_o => dbus_d_o,
	     dbus_we_o => dbus_we,
	    
	     clk => clk,
	     resetn => resetn);      
	    
	    
end architecture struct;