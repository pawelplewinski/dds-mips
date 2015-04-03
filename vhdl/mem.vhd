library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity mem32 is
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
end entity mem32;