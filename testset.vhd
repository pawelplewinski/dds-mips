library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- the testset will besides clock and reset generation provide the 
-- loading data read from a file to the instruction memory of the MIPS system

entity testset is
    generic(
        PGM_FILE : string    := "no.file";
        IA_LEN   : natural   :=  9;
        DA_LEN   : natural   :=  6);
    port(
        clk      : out std_logic;
        rst      : out std_logic;
        rstn     : out std_logic);
end entity testset;

architecture behav of testset is

    ------------------------------------------------
    ------------------ Components ------------------
    ------------------------------------------------

    -----------
    -- CLOCK --
    -----------
    component clock_gen is
    generic(
        period      : time := 10 ns);
    port(
        reset       : in  std_logic;
        clk         : out std_logic);
    end component clock_gen;
    
    ---------------------------------------------
    ------------------ Signals ------------------
    ---------------------------------------------
    
    signal ts_reset  : std_logic;
    signal ts_resetn : std_logic;
    signal ts_clk    : std_logic;
    
begin

    ------------------------------------------------
    ------------------ Components ------------------
    ------------------------------------------------

    -- Clock generation (reset sensitive)
    
    clk <= ts_clk;
    
    clkgen : clock_gen
        generic map(
            period  => 10 ns)
        port map(
            reset   => ts_reset,
            clk     => ts_clk);

    ---------------------------------------------
    ----------------- Processes -----------------
    ---------------------------------------------

    -- Reset generation --
    rst  <= ts_reset;
    rstn <= not ts_reset;
    
    rst_gen : process
    begin
        wait for 10 ns;
        ts_reset <= '1';
        wait for 50 ns;
        ts_reset <= '0';
        wait;
    end process rst_gen;
   
end architecture behav;

