library ieee;
use ieee.std_logic_1164.all;

entity boothtest is
end entity;

architecture test_arch of boothtest is
component boothmult is 
    port( 
        a_in  : in  std_logic_vector(31 downto 0);
        b_in  : in  std_logic_vector(31 downto 0);
        res   : out std_logic_vector(63 downto 0) ;
        start : in  std_logic;
		clk   : in  std_logic;
		done  : out std_logic);
end component;

    
    signal a_in, b_in : std_logic_vector(31 downto 0);
    signal res : std_logic_vector(63 downto 0);
    signal start : std_logic := '0';
	signal clk : std_logic := '0';
	signal done : std_logic;
begin
    inst: boothmult 
        port map (a_in, b_in, res, start, clk, done);
    clk <= not clk after 10 ns;
    process
    begin
        a_in <= "11111111111111111111111111111110";
        b_in <= "00000000000000000000000000000010";
        start <= '1';
        wait for 20 ns;
        start <= '0';
        wait for 1000 ns ;
        a_in <= "00000000000000000000000000000101";
        b_in <= "00000000000000000000000000000010";
        start <= '1';
        wait for 20 ns;
        start <= '0';
        wait for 1000 ns;
        assert false report "Stop sim." severity error;
    end process;
end test_arch ;