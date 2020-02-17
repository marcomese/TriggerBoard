--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: trigger_extender_100ns.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity trigger_extender_100ns is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           trigger_in : in  STD_LOGIC;
           trigger_out : out  STD_LOGIC);
attribute syn_preserve : boolean;
attribute syn_preserve of trigger_out : signal is true;
end trigger_extender_100ns;

architecture Behavioral of trigger_extender_100ns is

constant TRG_LENGHT : integer := 10; -- Number of clock cycles

signal count : integer range 0 to TRG_LENGHT := 0;

--signal Q1, Q2, Q3, out_FDC1, out_FDC2,: std_logic:='0';
signal  trg_i : std_logic:='0';

type state_values is (       wait_state,   -- sistema in attesa
                             trg_state     -- trg_state = '1'
							 );
signal pres_state, next_state: state_values;

begin


--process (clock, trigger_in)
--begin
   --if trigger_in = '1' then   
		 --out_FDC1 <= '0';
         --out_FDC2 <= '0';
   --elsif (clock'event and clock='1') then 
         --out_FDC1 <= '1';
         --out_FDC2 <= out_FDC1;
      --end if;
--end process;


--process (clock, reset)
--begin
   --if reset='1' then   
		 --Q1 <= '0';
         --Q2 <= '0';
         --Q3 <= '0';
   --elsif (clock'event and clock='1') then 
         --Q1 <= NOT out_FDC2;
         --Q2 <= Q1;
         --Q3 <= Q2;
      --end if;
--end process;
--
--pulse <= Q1 and Q2 and (not Q3);

-- FSM 

SYNC_PROC: process (clock,reset)
   begin
    	if reset='1' then 
			pres_state <= wait_state;
            trigger_OUT    <= '0' ;
		elsif clock'event and clock='1' then
            pres_state <= next_state;
            trigger_OUT    <= trg_i;
        end if;
end process;
  	
fsm: process (pres_state, trigger_in, count) 
begin
case pres_state is
when wait_state => -- sistema in attesa
		if trigger_in = '1' then
			next_state <= trg_state;
        else
			next_state <= wait_state;
		end if;
when trg_state => 
		if count = TRG_LENGHT then
			next_state <= wait_state;
        else
			next_state <= trg_state;
		end if;

when others =>
	next_state <= wait_state;
end case;
end process;

OUTPUT_DECODE: process (next_state)
begin
if next_state = wait_state then --  sistema in attesa
            trg_i <= '0' ;
elsif next_state = trg_state then 
            trg_i <= '1' ;
else
            trg_i <= '0' ;
end if; 
end process;


-- contatore durata trigger
process (clock, reset) 
begin
   if reset='1' then 
      count <= 0;
   elsif (clock = '1' and clock'event) then
			if (trg_i = '1') then -- il contatore è abilitato solo nello stato trg 
				if count < TRG_LENGHT  then
					count <= count + 1;
                end if;
            else 
					count <= 0;                        
			end if;
	end if;
end process;

end Behavioral;

