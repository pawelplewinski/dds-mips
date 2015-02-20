library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;


entity mem32 is
    generic(
        SYS_32      : positive := 32;
        ADDR_LENGTH : natural  :=  9
    );
    port(
        clk             : in  std_logic;
        resetn          : in  std_logic;
        
        -- COM bus interface
        bus_wren_inp    : in  std_logic;	                                   -- '1' -> enable write ; '0' -> disable write
        bus_addr_inp    : in  std_logic_vector(ADDR_LENGTH-1 downto 0);
        bus_data_inp    : in  std_logic_vector(SYS_32-1      downto 0);
        bus_data_out    : out std_logic_vector(SYS_32-1      downto 0)
    );
end entity mem32;

----------
-- imem --
----------
-- models the data mem of the MIPS system

architecture ibehav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(SYS_32-1 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
begin

    mem_access : process(clk, resetn)
        --variable addr_ctr : unsigned(ADDR_LENGTH-1 downto 0) := (others => '0');
        variable rdline   : line;
        variable hexdata  : std_logic_vector(SYS_32-1 downto 0);
        file mips_pgm     : text open read_mode is "gcd.txt";
    begin
        if(resetn = '0') then
            -- if reset load imem with instruction from file
            for addr_ctr in memory'range loop
                readline(mips_pgm,rdline);
                hread(rdline,hexdata);
                memory(addr_ctr) <= hexdata;
                exit when endfile(mips_pgm);
            end loop;
        elsif(rising_edge(clk)) then
            -- NO write enabled - only reading
        end if;
    end process mem_access;
    
    -- always keep the output updated
    -- [causes WARNING in sim due to illegal unsigned(U) conversion]
    bus_data_out <= memory(to_integer(unsigned(bus_addr_inp)));
    
end architecture ibehav;

----------
-- dmem --
----------
-- models the instruction mem of the MIPS system

architecture dbehav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(SYS_32-1 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
begin
    mem_access : process(clk, resetn)
    begin
        if(resetn = '0') then
            for i in 0 to ((2**ADDR_LENGTH)-1) loop
                memory(i) <= (others => '0');
            end loop;
        elsif(rising_edge(clk)) then
            -- check write enabled
            if(bus_wren_inp = '1') then
                memory(to_integer(unsigned(bus_addr_inp))) <= bus_data_inp;
            end if;
        end if;
    end process mem_access;
    
    -- always keep the output updated
    -- [causes WARNING in sim due to illegal unsigned(U) conversion]
    bus_data_out <= memory(to_integer(unsigned(bus_addr_inp)));
    
end architecture dbehav;