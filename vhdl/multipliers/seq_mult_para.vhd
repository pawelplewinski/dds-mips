library   ieee;
use  ieee.std_logic_1164.all;
use  ieee.numeric_std.all;
--use  work.util_pkg.all ;

entity seq_mult_para is 
    generic (WIDTH: natural := 32);
    port ( 
        start : in   std_logic; 
        a_in  : in   std_logic_vector(WIDTH-1 downto 0);
        b_in  : in   std_logic_vector(WIDTH-1 downto 0);
        rdy   : out  std_logic;
        res   : out  std_logic_vector(2*WIDTH-1 downto 0);
        clk   : in   std_logic;
        reset : in   std_logic
    ); 
end seq_mult_para;

architecture shift_add_better_arch of seq_mult_para is 
    constant C_WIDTH : integer := 6; -- log2c(WIDTH)+l;
    constant C_INIT  : unsigned(C_WIDTH-1 downto 0) := to_unsigned(WIDTH,C_WIDTH);
    type  state_type is (idle, add_shift);
    
    signal state_reg     : state_type;
    signal state_next    : state_type;
    signal a_reg, a_next : unsigned(WIDTH-1   downto 0);
    signal n_reg, n_next : unsigned(C_WIDTH-1 downto 0);
    signal p_reg, p_next : unsigned(2*WIDTH   downto 0);
    -- alias for the upper part and lower parts of p_reg
        alias pu_next    : unsigned(WIDTH     downto 0) is p_next(2*WIDTH downto WIDTH); -- upper
        alias pu_reg     : unsigned(WIDTH     downto 0) is p_reg(2*WIDTH downto WIDTH);  -- upper
        alias pl_reg     : unsigned(WIDTH-1   downto 0) is p_reg(WIDTH-1 downto 0);      -- lower

begin
    -- state and data registers  
    process (clk, reset) 
    begin 
        if reset = '1' then 
            state_reg  <=  idle; 
            a_reg      <=  (others => '0');
            n_reg      <=  (others => '0');
            p_reg      <=  (others => '0');
        elsif (clk'event and clk = '1') then 
            state_reg  <=  state_next;
            a_reg      <=  a_next;
            n_reg      <=  n_next;
            p_reg      <=  p_next;
        end if; 
    end process;
    
    -- combinational  circuit  
    process (start, state_reg, a_reg, n_reg, p_reg, a_in, b_in, n_next, p_next)
    begin 
        a_next <= a_reg;
        n_next <= n_reg; 
        p_next <= p_reg; 
        rdy    <= '0';  
        case state_reg is  
            when idle => 
                rdy <= '1';
                if start='1' then 
                    p_next(WIDTH-1 downto 0)     <= unsigned(b_in); 
                    p_next(2*WIDTH downto WIDTH) <= (others => '0'); 
                    a_next                       <= unsigned(a_in); 
                    n_next                       <= C_INIT; 
                    state_next                   <= add_shift;
                else
                    state_next <= idle; 
                end if; 
            when add_shift  => 
                n_next <= n_reg-1;
                -- add if multiplier bit is 1
                if (p_reg(0)='1') then 
                    pu_next    <=  pu_reg + ('0' & a_reg);
                else 
                    pu_next    <=  pu_reg;
                end if;
                -- shift  
                p_next  <= '0' & pu_next & pl_reg(WIDTH-1 downto 1);
                if (n_next /= "000000") then 
                    state_next <= add_shift;
                else
                    state_next <= idle;
                end if;  
        end case; 
    end process; 

    res <= std_logic_vector(p_reg(2*WIDTH-1 downto  0)) ; 

end shift_add_better_arch;