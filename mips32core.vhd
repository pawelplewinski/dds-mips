library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32core is
	generic(
        IA_LEN    : natural  :=  9
    );
	port(
        clk             : in  std_logic;
        resetn          : in  std_logic;
        
        -- COM with instruction memory (imem)
        ibus_data_inp   : in  std_logic_vector(31 downto 0);      -- instructions
        ibus_addr_out   : out std_logic_vector(31 downto 0);      -- address for new instructions
        
        -- COM with data memory (dmem)
        dbus_data_inp   : in  std_logic_vector(31 downto 0);      -- write data
        dbus_addr_out   : out std_logic_vector(31 downto 0);      -- address to store data to
        dbus_data_out   : out std_logic_vector(31 downto 0);      -- read data
        dbus_wren_out   : out std_logic                                 -- write enable
        
        -- [optional] COM with peripherals (perX)
        --pbus_data_inp   : in  std_logic_vector(SYS_32-1 downto 0);
        --pbus_addr_out   : out std_logic_vector(DA_LEN-1 downto 0);
        --pbus_data_out   : out std_logic_vector(SYS_32-1 downto 0);
        --pbus_wren_out   : out std_logic;
        --pbus__sel_out   : out std_logic_vector(SYS_32-1 downto 0);
    );
end entity mips32core;
