library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulseExpand is
    Port ( clkOrig : in  STD_LOGIC;
           clkDest : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           pulseIN : in  STD_LOGIC;
           pulseOUT : out  STD_LOGIC);
end pulseExpand;

architecture Behavioral of pulseExpand is

signal FFOrigS, FFOrigR, FFOrigQ : std_logic;
signal FFDestD, FFDestQ : std_logic;

begin

FFOrig: process(clkOrig)
begin
    if rst = '1' then
        FFOrigQ <= '0';
    elsif rising_edge(clkOrig) then
        if FFOrigS = '1' and FFOrigR = '0' then
            FFOrigQ <= '1';
        elsif FFOrigS = '0' and FFOrigR = '1' then
            FFOrigQ <= '0';
        else
            FFOrigQ <= FFOrigQ;
        end if;
    end if;
end process;

FFDest: process(clkDest)
begin
    if rst = '1' then
        FFDestQ <= '0';
    elsif rising_edge(clkDest) then
        FFDestQ <= FFDestD;
    end if;
end process;

-- Ingressi primo Flip-Flop (SR)
FFOrigS <= pulseIN;
FFOrigR <= FFDestQ;

-- Ingressi secondo Flip-Flop (D)
FFDestD <= FFOrigQ;

-- Uscite
pulseOUT <= FFDestQ;

end Behavioral;

