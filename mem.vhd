library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

-- includes the imem and the dmem architecture (which share the same interface)

entity mem32 is
    generic(
        PGM_FILE 	: string  := "no.file";
        ADDR_LENGTH : natural :=  9
    );
    port(
        clk             : in  std_logic;
        resetn          : in  std_logic;
        
        -- COM bus interface
        bus_wren_inp    : in  std_logic;	                                   -- '1' -> enable write ; '0' -> disable write
        bus_addr_inp    : in  std_logic_vector(31 downto 0);
        bus_data_inp    : in  std_logic_vector(31 downto 0);
        bus_data_out    : out std_logic_vector(31 downto 0)
    );
end entity mem32;

----------
-- imem --
----------
-- models the data mem of the MIPS system

architecture ibehav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(31 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
    signal iaddr  : natural range 0 to ((2**ADDR_LENGTH)-1);
begin
	-- PSL default clock is rising_edge(clk);

	-- PSL mem_i_data: assert always (bus_addr_inp -> next (bus_data_out = memory(iaddr))) abort not resetn;
    mem_access : process(clk, resetn)
        --variable addr_ctr : unsigned(ADDR_LENGTH-1 downto 0) := (others => '0');
        variable rdline   : line;
        variable hexdata  : std_logic_vector(31 downto 0);
        file mips_pgm     : text open read_mode is PGM_FILE;
    begin
        if(resetn = '0') then
            -- if reset active then set all mem regs to 0 ..
            memory <= (others => (others => '0'));
            -- .. and load imem with instruction from file
            for addr_ctr in memory'range loop
                readline(mips_pgm,rdline);
                hread(rdline,hexdata);
                memory(addr_ctr) <= hexdata;
                exit when endfile(mips_pgm);
            end loop;
        elsif(rising_edge(clk)) then
            -- NO write enabled - only reading
            --if(bus_wren_inp = '1') then
            --    memory(to_integer(unsigned(wbs_addr_i))) <= bus_data_inp;
            --end if;
        end if;
    end process mem_access;
    
    -- addr chk : checks if the requested addr is within the limited range
    -- (since the mem is artificially kept small while the addr space allows to point to not allocated mem)
    -- [causes WARNING in sim due to illegal unsigned(U) conversion]
    with bus_addr_inp select iaddr <= 
        0                                                          when "--------------------------------",
        to_integer(unsigned(bus_addr_inp(ADDR_LENGTH-1 downto 0))) when others; -- DEBUG: just cut if out of range addr request

    --assert bus_addr_inp(31 downto ADDR_LENGTH) /= (31 downto ADDR_LENGTH => '0') report "imem: addr request out of range" severity ERROR;
    
    -- always keep the output updated
    bus_data_out <= memory(iaddr);
    
end architecture ibehav;

----------
-- dmem --
----------
-- models the instruction mem of the MIPS system

architecture dbehav of mem32 is
    type mem_type is array (natural range <>) of std_logic_vector(31 downto 0);
    signal memory : mem_type(0 to ((2**ADDR_LENGTH)-1));
    signal daddr  : natural range 0 to ((2**ADDR_LENGTH)-1);
begin
	-- PSL default clock is rising_edge(clk);

	-- PSL mem_o_data: assert always (bus_addr_inp -> next (bus_data_out = memory(daddr))) abort not resetn;

    mem_access : process(clk, resetn)
    begin
        if(resetn = '0') then
            -- if reset active then set all mem regs to 0 ..
            memory <= (others => (others => '0'));
            -- .. if necessary to pre-load mem: do here!
            -- PREDLOAD routine
        elsif(rising_edge(clk)) then
            -- check write enabled
            if(bus_wren_inp = '1') then
                memory(daddr) <= bus_data_inp;
            end if;
        end if;
    end process mem_access;
    
    -- addr chk : checks if the requested addr is within the limited range
    -- (since the mem is artificially kept small while the addr space allows to point to not allocated mem)
    -- [causes WARNING in sim due to illegal unsigned(U) conversion]
    with bus_addr_inp select daddr <= 
        0                                                          when "--------------------------------",
        0                                                          when "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        0                                                          when "00------------------------------",
        0                                                          when "00XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        to_integer(unsigned(bus_addr_inp(ADDR_LENGTH-1 downto 0))) when others; -- DEBUG: just cut if out of range addr request

    --assert bus_addr_inp(31 downto ADDR_LENGTH) /= (31 downto ADDR_LENGTH => '0') report "dmem: addr request out of range" severity ERROR;
    
    -- always keep the output updated
    bus_data_out <= memory(daddr);
    
end architecture dbehav;