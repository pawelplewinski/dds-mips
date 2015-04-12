library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32core is
generic(
        SYS_32    	: positive := 32);
port(
	ibus_a_o  	: out std_logic_vector(SYS_32-1 downto 0);
	ibus_d_i  	: in  std_logic_vector(SYS_32-1 downto 0);
           
	dbus_a_o  	: out std_logic_vector(SYS_32-1 downto 0);
	dbus_d_o  	: out std_logic_vector(SYS_32-1 downto 0);
	dbus_d_i  	: in  std_logic_vector(SYS_32-1 downto 0);
	dbus_we_o 	: out std_logic;
        
	int0	  	: out std_logic;
            
	clk       	: in  std_logic;
	resetn    	: in  std_logic
	);
end entity mips32core;
