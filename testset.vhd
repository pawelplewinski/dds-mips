library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- the testset will besides clock and reset generation provide the 
-- loading data read from a file to the instruction memory of the MIPS system

entity testset is
    generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9);
    port(
        -- Wishbone bus interface (with imem)
        wbs_addr_o : out std_logic_vector(ADDR_LENGTH-1 downto 0);  -- imem address 
        wbs_dat_o  : out std_logic_vector(SYS_32-1 downto 0);       -- imem data
        
        clk        : out std_logic;
        rst        : out std_logic;
        rstn       : out std_logic);
end entity testset

architecture behav of testset is
    -----------
    -- CLOCK --
    -----------
    component clk_gen is
    generic(
        period      : time := 10 ns);
    port(
        reset       : in  std_logic;
        clk         : out std_logic);
    end component clk_gen;
    
begin

    ------------------------------------------------
    ------------------ Components ------------------
    ------------------------------------------------

    -- Clock generation (reset sensitive)
    
    reset <= not resetn;
    
    clkgen : clk_gen
        generic map(
            period  => 10 ns)
        port map(
            reset   => resetn,
            clk     => clk);
    
    
    ---------------------------------------------
    ----------------- Processes -----------------
    ---------------------------------------------

    -- Reset generation --
    rst  <= rst_internal;
    rstn <= not rst_internal;
    
    rst : process
    begin
        wait for 10 ns;
        rst_internal <= '1';
        wait for 50 ns;
        rst_internal <= '0';
        wait;
    end process rst;
    
    -- Memory instantiation --
    mem_preload : process 
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
    end process mem_preload;
    
end architecture behav;

