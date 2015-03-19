library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- add shift mult

entity mult32x32 is
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        start : in  std_logic;
        a_in  : in  std_logic_vector(31 downto 0);
        b_in  : in  std_logic_vector(31 downto 0);
        rdy   : out std_logic;
		  res_out : out unsigned(64 downto 0)
    );
end mult32x32;

architecture add_shft_behav of mult32x32 is
    type state_type is (init, add_shift, shift);
    signal state_cnt : integer range 0 to 99;
    signal state : state_type := init;
    signal res   : unsigned(64 downto 0);                    -- accumulator
        --alias m  : bit is res(0);                         -- m is bit 0 of res
begin    
    process(clk,reset)
    begin
        if reset = '1' then
            res   <= (others => '0');
            state <= init;
        elsif (clk'event and clk='1') then                      -- executes on rising edge of clock
            case state is
                when init =>                                    -- inital state
                -- when 0
                    if start = '1' then
                        res(64 downto 32) <= (others => '0');   -- begin cycle
                        res(31 downto  0) <= unsigned(a_in);    -- load the multiplier
                        state_cnt         <= 1;
                        state             <= add_shift;
                    end if;
                when add_shift =>                               -- add/shift state
                    -- when 1 | 3 | 5 | 7..
                    if res(0) = '1' then                        -- add multiplicand
                        res(64 downto 32) <= '0' & res(63 downto 32) + unsigned(b_in);
                        state_cnt         <= state_cnt + 1;
                        state             <= shift;
                    else
                        res <= '0' & res(64 downto 1);          -- shift accumulator right
                        state_cnt <= state_cnt + 2;
                        state <= add_shift;
                    end if;
                when shift =>                                   -- "shift" state
                    -- when 2 | 4 | 6 | 8 ..
                    res       <= '0' & res(64 downto 1);        -- right shift
                    state_cnt <= state_cnt + 1;
                    state     <= add_shift;
            end case;
            if state_cnt = 65 then
                state       <= init;
                state_cnt   <= 0; 
            end if; 
        end if;
    end process;
    
    rdy <= '1' when state_cnt = 65 else '0';
    res_out <= res;
end add_shft_behav;