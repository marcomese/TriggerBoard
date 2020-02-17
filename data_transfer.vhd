-------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: data_transfer.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::ProASIC3E> <Die::A3PE3000> <Package::208 PQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library proasic3e;
use proasic3e.all;

entity data_transfer is
port (
      reset       : in  std_logic; -- Reset active High
      clock       : in  std_logic; -- 48 MHz Clock
      
      HG_data_1  : in std_logic_vector(383 downto 0);
      LG_data_1  : in std_logic_vector(383 downto 0);
      HG_data_2  : in std_logic_vector(383 downto 0);
      LG_data_2  : in std_logic_vector(383 downto 0);
      data_ready  : in std_logic;
      data_to_daq : in std_logic_vector(319 downto 0);
      iRDY        : in std_logic; -- Ready when DAQ answered to trigger and the internal fifo is not full

      -- Internal Interface 
      oSOP        : out std_logic; -- Start of Packet
      oEOP        : out std_logic; -- End Of Packet
      oDATA       : out std_logic_vector(7 downto 0); -- Word Data to transfer
      oWE         : out std_logic -- 
);
end data_transfer;

architecture Behavioral of data_transfer is
type state_values is (       
                             wait_state,                -- in attesa che il dato sia completo
                             DEBUG1_STATE,
                             DEBUG2_STATE,
                             DEBUG3_STATE,
                             DEBUG4_STATE,
                             SOP_state,                 -- primi 16 bit trasferiti
                             HG_1_state,                -- trasferimento dato alla FIFO
                             LG_1_state,                -- trasferimento dato alla FIFO
                             HG_2_state,                -- trasferimento dato alla FIFO
                             LG_2_state,                -- trasferimento dato alla FIFO
                             counter_state,
                             EOP_state                  -- last packet
                    );
signal pres_state, next_state: state_values;

constant TOTAL_PACKET_NR   : integer := 47; -- Number of TOTAL_PACKET - 1 
constant COUNTER_PACKET_NR : integer := 39; -- Number of COUNTER_PACKET - 1

signal packet_cnt,reg_cnt : integer range 0 to TOTAL_PACKET_NR := 0;

signal pkt_nr : std_logic_vector(5 downto 0) := (others => '0') ;

signal wSOP, wEOP, wWE, WE_txrdy: std_logic := '0'; 
signal wDATA : std_logic_vector(7 downto 0) := (others => '0') ; 

begin

-- FSM register

SYNC_PROC: process (clock,reset)
   begin
    	if reset = '1' then 

			pres_state <= wait_state;

            oSOP  <= '0' ;   -- Start of Packet
            oEOP  <= '0' ;   -- End Of Packet
            oDATA <= (others => '0') ; -- Word Data to transfer
            WE_txrdy   <= '0' ;

		elsif clock'event and clock='1' then
            
            pres_state <= next_state;
			
            oSOP  <= wSOP ;   -- Start of Packet
            oEOP  <= wEOP ;   -- End Of Packet
            oDATA <= wDATA ; -- Word Data to transfer
            WE_txrdy   <= wWE;

        end if;
end process;


--WE_txrdy <= not (wWE and iRDY);
owe <= not (WE_txrdy and irdy); --<= not (wWE and iRDY);

-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process (pres_state, reg_cnt, data_ready, iRDY) 
begin
	
case pres_state is

when wait_state => -- in attesa che il dato sia completo
		if data_ready = '1' and  iRDY = '1' then
            next_state <= debug1_state;
		else
			next_state <= wait_state;
		end if;

--#####################################################################################################################################################################
when debug1_state => -- last packet
		if iRDY = '1' then
            next_state <= debug2_state;
		else
			next_state <= debug1_state;
		end if; 
when debug2_state => -- last packet
		if iRDY = '1' then
            next_state <= SOP_state;
		else
			next_state <= debug2_state;
		end if; 
when debug3_state => -- last packet
		if iRDY = '1' then
            next_state <= debug4_state;
		else
			next_state <= debug3_state;
		end if; 
when debug4_state => -- last packet
		if iRDY = '1' then
            next_state <= wait_state;
		else
			next_state <= debug4_state;
		end if;  
--#####################################################################################################################################################################

when SOP_state => -- primi 16 bit trasferiti  
		if iRDY = '1' then
            next_state <= HG_1_state;
		else
			next_state <= SOP_state;
		end if;  
                                           
 when HG_1_state => -- trasferimento dato alla FIFO 
		if iRDY = '1' then
            if reg_cnt = TOTAL_PACKET_NR then 
                next_state <= LG_1_state ;		
            else
                next_state <= HG_1_state;
            end if;
		else
			next_state <= HG_1_state;
		end if;  
    

 when LG_1_state => -- trasferimento dato alla FIFO 
		if iRDY = '1' then
            if reg_cnt = TOTAL_PACKET_NR then 
                next_state <= HG_2_state;		
            else
                next_state <= LG_1_state;
            end if;
		else
			next_state <= LG_1_state;
		end if;  

 when HG_2_state => -- trasferimento dato alla FIFO 
		if iRDY = '1' then
            if reg_cnt = TOTAL_PACKET_NR then 
                next_state <= LG_2_state;		
            else
                next_state <= HG_2_state;
            end if;
		else
			next_state <= HG_2_state;
		end if; 
 
 when LG_2_state => -- trasferimento dato alla FIFO 
		if iRDY = '1' then
            if reg_cnt = TOTAL_PACKET_NR then --------------------------------
                next_state <= counter_state;		-------------------------counter_state
            else
                next_state <= LG_2_state;
            end if;
		else
			next_state <= LG_2_state;
		end if;  

--#####################################################################################################################################################################
 when counter_state => -- trasferimento dato alla FIFO ------------NB: saltato x evitare fifofull
		if iRDY = '1' then
            if reg_cnt = COUNTER_PACKET_NR - 1 then 
                next_state <= EOP_state;		
            else
                next_state <= counter_state;
            end if;
		else
			next_state <= counter_state;
		end if;                              
--#####################################################################################################################################################################

when EOP_state => -- last packet
		if iRDY = '1' then
            next_state <= debug3_state;
		else
			next_state <= EOP_state;
		end if;  

when others =>
	next_state <= wait_state;

end case;

end process;

OUTPUT_DECODE: process (next_state, HG_data_1, LG_data_1, HG_data_2, LG_data_2,  packet_cnt, data_to_daq)

begin

if next_state = wait_state then -- in attesa che il dato sia completo

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA <= (others => '0') ; -- Word Data to transfer
            wWE   <= '0' ;

elsif next_state = debug1_state then -- primi 16 bit trasferiti

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= X"46"; -- Word Data to transfer  
            wWE   <= '1' ;

elsif next_state = debug2_state then -- primi 16 bit trasferiti

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= X"45"; -- Word Data to transfer  
            wWE   <= '1' ;

elsif next_state = debug3_state then -- primi 16 bit trasferiti

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= X"47"; -- Word Data to transfer  
            wWE   <= '1' ;

elsif next_state = debug4_state then -- primi 16 bit trasferiti

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= X"48"; -- Word Data to transfer  
            wWE   <= '1' ;

elsif next_state = SOP_state then -- primi 16 bit trasferiti

            wSOP  <= '1' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= HG_data_2(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer  --HG_data_1(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer  
            wWE   <= '1' ;

elsif next_state = HG_1_state then -- trasferimento dato alla FIFO

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= HG_data_2(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer --HG_data_1(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer
            wWE   <= '1' ;

elsif next_state = LG_1_state then -- trasferimento dato alla FIFO

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= LG_data_2(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer --LG_data_1(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer
            wWE   <= '1' ;

elsif next_state = HG_2_state then -- trasferimento dato alla FIFO

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= HG_data_1(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer--HG_data_2(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer
            wWE   <= '1' ;

elsif next_state = LG_2_state then -- trasferimento dato alla FIFO

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= LG_data_1(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer-- LG_data_2(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer
            wWE   <= '1' ;

elsif next_state = counter_state then -- trasferimento dato alla FIFO

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA(7 downto 0) <= "001" & pkt_nr(4 downto 0) ; --data_to_daq(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- Word Data to transfer
            wWE   <= '1' ;

elsif next_state = EOP_state then -- last packet 

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '1' ;   -- End Of Packet
--#####################################################################################################################################################################
            wDATA(7 downto 0) <=  X"35" ; --data_to_daq(packet_cnt*8 + 7 downto 0+packet_cnt*8); -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--#####################################################################################################################################################################
            wWE   <= '1' ;                                        

else

            wSOP  <= '0' ;   -- Start of Packet
            wEOP  <= '0' ;   -- End Of Packet
            wDATA <= (others => '0') ; -- Word Data to transfer
            wWE   <= '0' ;

end if; 
end process;

process (clock, reset) 
begin
   if reset = '1' then 
      packet_cnt <= 0;
      reg_cnt <= 0;
   elsif (clock = '1' and clock'event) then
			if (wWE = '0') then -- 
				packet_cnt <= 0;
            elsif ( pres_state= debug1_state or pres_state= debug2_state) then
                packet_cnt <= 0;
			elsif (wWE = '1' and iRDY = '1' ) and ( pres_state= EOP_state or next_state = EOP_state) then   --			
				if packet_cnt = COUNTER_PACKET_NR then
					packet_cnt <= 0;   
                else
                    packet_cnt <= packet_cnt + 1;
				end if;				
			elsif (wWE = '1' and iRDY = '1' ) then   -- 		
				if packet_cnt = TOTAL_PACKET_NR then
					packet_cnt <= 0;   
                else
                    packet_cnt <= packet_cnt + 1;
				end if;
            end if;
      reg_cnt <= packet_cnt;
	end if;
end process;


pkt_nr <= conv_std_logic_vector(packet_cnt,6);------------------


end Behavioral;