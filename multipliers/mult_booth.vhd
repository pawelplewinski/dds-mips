library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- uses booth algorithm

entity mult_booth is
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        start : in  std_logic;
        a_in  : in  std_logic_vector(31 downto 0);
        b_in  : in  std_logic_vector(31 downto 0);
        res   : out std_logic_vector(63 downto 0);
        rdy   : out std_logic
    );
end mult_booth;

architecture booth_behav of mult_booth is
    --Multiplies multiplicand by multiplier
    --Uses Booth's algorithm
    FUNCTION mult_fcn(
        multiplicand : std_logic_vector(31 downto 0);
        multiplier   : std_logic_vector(31 downto 0)
    ) RETURN std_logic_vector IS
        VARIABLE x,x2,y     : signed (31 DOWNTO 0);
        VARIABLE res        : signed (63 DOWNTO 0);
        VARIABLE A,S,P      : signed (64 DOWNTO 0);
        VARIABLE Ah,Sh,Ph   : signed (65 DOWNTO 0);
        VARIABLE lsb,plsb   : std_logic;
        VARIABLE found,temp : integer;
    BEGIN
        temp  := to_integer(signed (multiplicand));
        x     := to_signed(temp,32);
        x2    := to_signed(temp,32);
        found := -1;
        FOR i IN 0 TO 31 LOOP --Two's complement
            IF found /= -1 THEN
                x2(i) := not x2(i);
            ELSIF x2(i) = '1' THEN
                found := i;
            END IF;
        END LOOP;
        temp := to_integer(signed(multiplier));
        y := to_signed(temp,32);
        IF found = 31 THEN --Multiplicand equal to highest negative number
            Ah := '1' & x & "000000000000000000000000000000000";
            Sh := '0' & x2 & "000000000000000000000000000000000";
            Ph := "000000000000000000000000000000000" & y & '0';
            FOR i IN 0 to 31 LOOP
                lsb := Ph(0);
                plsb := Ph(1);
                CASE plsb IS
                    WHEN '0' =>
                        IF lsb = '1' THEN
                            Ph := Ph + Ah; --Overflow is ignored automatically
                        END IF;
                    WHEN '1' => 
                        IF lsb = '0' THEN
                            Ph := Ph + Sh; --overflow is ignored automatically
                        END IF;
                    WHEN OTHERS =>  Ph := (OTHERS => '0'); --Shift to right conserving sign bit
                END CASE;
                Ph := Ph(65) & Ph(65) & Ph(64 DOWNTO 1); --Shift to right conserving sign bit
            END LOOP;
            res := Ph(64 DOWNTO 1);
        ELSE --Multiplicand different from highest negative number
              
            A := x & "000000000000000000000000000000000";
            S := x2 & "000000000000000000000000000000000";
            P := "00000000000000000000000000000000" & y & '0';
                
            FOR i IN 0 to 31 LOOP
                lsb := P(0);
                plsb := P(1);
                CASE plsb IS
                    WHEN '0' => 
                        IF lsb = '1' THEN
                            P := P + A; --Overflow is ignored automatically
                        END IF;
                    WHEN '1' => 
                        IF lsb = '0' THEN
                            P := P + S; --overflow is ignored automatically
                        END IF;
                    WHEN OTHERS =>  
                        P := (OTHERS => '0'); --Shift to right conserving sign bit
                END CASE;
                P := P(64) & P(64) & P(63 DOWNTO 1); --Shift to right conserving sign bit
            END LOOP;
            res := P(64 DOWNTO 1);
        END IF;
        temp := to_integer (res);
        RETURN std_logic_vector(to_signed(temp,64));
    END mult_fcn;
begin
    
    process(clk,reset)
    begin
        if reset = '1' then
        elsif (clk'event and clk='1') then
            res <= mult_fcn(a_in,b_in);
        end if;
    end process;    
    
end booth_behav;