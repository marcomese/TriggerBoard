--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: trigger_logic_fsm.vhd
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
use IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;
library proasic3e;
use proasic3e.all;

entity TRIGGER_logic_FSM is
          port (
                reset           : in std_logic;
				clock           : in std_logic;  
				clock200k       : in std_logic;  
                debug           : in std_logic;
                trigger_in_1    : in  std_logic_vector(31 downto 0);
                trigger_in_2    : in  std_logic_vector(31 downto 0);
                PMT_mask_1      : in  std_logic_vector(31 downto 0);
                PMT_mask_2      : in  std_logic_vector(31 downto 0);
                generic_trigger_mask : in std_logic_vector(31 downto 0);	
                trigger_mask    : in  std_logic_vector(31 downto 0);
                apply_trigger_mask : in std_logic;
                apply_PMT_mask : in std_logic;
                start_readers   : in std_logic;
                SMPL_HOLD_N     : in std_logic;

                calibration_state : in std_logic;
                acquisition_state : in std_logic;
                --stop_run        : in std_logic;
                test_out        : out std_logic;
		
		        --mask_rate       : out std_logic_vector(287 downto 0);				
		        PMT_rate        : out std_logic_vector(575 downto 0);				

                trigger_flag_1  : out std_logic_vector(31 downto 0);			
                trigger_flag_2  : out std_logic_vector(31 downto 0);			
                trigger_mask_rate : out std_logic_vector(143 downto 0);

                debug_out : out std_logic;

				trg_to_DAQ_EASI : out std_logic  -- attivo alto
				);
attribute syn_preserve : boolean;
attribute syn_preserve of trg_to_DAQ_EASI : signal is true;
end TRIGGER_logic_FSM;

architecture Behavioral of TRIGGER_logic_FSM is


component trigger_extender_100ns is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           trigger_in : in  STD_LOGIC;
           trigger_out : out  STD_LOGIC);
end component;

component OR2 is
    port( A : in    std_logic := 'U';
          B : in    std_logic := 'U';
          Y : out   std_logic
        );
end component;

component AND2
    port( A : in    std_logic := 'U';
          B : in    std_logic := 'U';
          Y : out   std_logic
        );
end component;

  component MX2
    port( A : in    std_logic := 'U';
          B : in    std_logic := 'U';
          S : in    std_logic := 'U';
          Y : out   std_logic
        );
  end component;

component AND32 is

    port( Data   : in    std_logic_vector(31 downto 0);
          Result : out   std_logic
        );

end component;

component TRIGGER_selector is
          port (
                reset           : in std_logic;
				clock           : in std_logic;  
                plane           : in  std_logic_vector(31 downto 0);
                generic_trigger_mask : in std_logic_vector(31 downto 0);	
                trigger_mask    : in  std_logic_vector(31 downto 0);
                start_readers   : in std_logic;

                apply_trigger_mask : in std_logic;

                rate_time_sig	: in std_logic; --1 secondo	
		
		        --mask_rate_0 : out std_logic_vector(15 downto 0);
		        --mask_rate_1 : out std_logic_vector(15 downto 0);
		        --mask_rate_2 : out std_logic_vector(15 downto 0);
		        --mask_rate_3 : out std_logic_vector(15 downto 0);
		        --mask_rate_4 : out std_logic_vector(15 downto 0);
		        --mask_rate_5 : out std_logic_vector(15 downto 0);
		        --mask_rate_6 : out std_logic_vector(15 downto 0);
		        --mask_rate_7 : out std_logic_vector(15 downto 0);
		        --mask_rate_8 : out std_logic_vector(15 downto 0);

                debug : out std_logic;

				trg_int         : out std_logic  -- attivo alto
				);
end component;

type state_values is (       wait_state,   -- sistema in attesa
                             trg_state,    -- trg_state = '1'
                             idle_state    -- idle per 100 ns
							 );
signal pres_state, next_state: state_values;

signal trg_to_DAQ_EASI_i: std_logic := '0';
signal trigger_sincro_1, trigger_sincro_2, plane, trigger_PMTmasked_1, trigger_PMTmasked_2, PMT_mask_int_1, PMT_mask_int_2: std_logic_vector(31 downto 0);

constant TRG_LENGHT : integer := 9; -- Number of clock cycles
signal count : integer range 0 to TRG_LENGHT := 0;
signal idle, idle_i: std_logic := '0';
signal trigger: std_logic := '0';

constant RATE_TIME  : integer := 20000; -- 100 millisec a 200kHz
signal time_cnt : integer range 0 to RATE_TIME := 0;
signal rate_time_sig, rise_rate, reset_counter : std_logic := '0';--

signal mask_rate_0_sig, mask_rate_1_sig, mask_rate_2_sig, mask_rate_3_sig, mask_rate_4_sig, mask_rate_5_sig, mask_rate_6_sig, mask_rate_7_sig, mask_rate_8_sig: std_logic_vector(15 downto 0);

type count_array is array (0 to 31) of std_logic_vector(15 downto 0);
signal count_pmt_1, count_pmt_2, pmt_rate_1, pmt_rate_2: count_array;

signal rise_1, rise_2: std_logic_vector(31 downto 0);

begin

test_out <= trigger_sincro_1(0);

sincronizzatore1 : for i in 0 to 31 generate
        begin
        edge_trigger_i: process(clock, reset)
            variable resync_i : std_logic_vector(1 to 3);
                begin
                   if reset='1' then
                        rise_1(i) <= '0';
                   elsif clock'event and clock='1' then
                        rise_1(i) <= resync_i(2) and not resync_i(3);
                        resync_i := trigger_in_1(i) & resync_i(1 to 2);
                   end if;
        end process;
end generate sincronizzatore1;

sincronizzatore2 : for i in 0 to 31 generate
        begin
        edge_trigger_i: process(clock, reset)
            variable resync_i : std_logic_vector(1 to 3);
                begin
                   if reset='1' then
                        rise_2(i) <= '0';
                   elsif clock'event and clock='1' then
                        rise_2(i) <= resync_i(2) and not resync_i(3);
                        resync_i := trigger_in_2(i) & resync_i(1 to 2);
                   end if;
        end process;
end generate sincronizzatore2;


trigger_sampler_process_1 : for i in 0 to 31 generate
        begin
        trigger_i: trigger_extender_100ns 
                Port map(   clock => clock,
                            reset => reset, 
                            trigger_in => rise_1(i),
                            trigger_out  => trigger_sincro_1(i)
                         );
end generate trigger_sampler_process_1;

trigger_sampler_process_2 : for i in 0 to 31 generate
        begin
        trigger_i: trigger_extender_100ns 
                Port map(   clock => clock,
                            reset => reset, 
                            trigger_in => rise_2(i),
                            trigger_out  => trigger_sincro_2(i)
                         );
end generate trigger_sampler_process_2;

PMT_counter_process1 : for i in 0 to 31 generate
        begin
        counter1_trigger_i: process(clock, reset, reset_counter)
            begin
            if reset='1' or reset_counter = '1' then
                count_pmt_1(i) <= (others=> '0');
            elsif clock'event and clock='1' then
                if rise_1(i) ='1' then
                    count_pmt_1(i) <= count_pmt_1(i) +1;
                end if;
            end if;
            end process;
        end generate PMT_counter_process1;

PMT_counter_process2 : for i in 0 to 31 generate
        begin
        counter2_trigger_i: process(clock, reset, reset_counter)
            begin
            if reset='1' or reset_counter = '1' then
                count_pmt_2(i) <= (others=> '0');
            elsif clock'event and clock='1' then
                if rise_2(i) ='1' then
                    count_pmt_2(i) <= count_pmt_2(i) +1;
                end if;
            end if;
            end process;
        end generate PMT_counter_process2;

PMT_reg_process : for i in 0 to 31 generate
    begin
        reg_counter_trigger_i: process(clock, reset)
            begin
            if reset='1' then
                PMT_rate_1(i) <= (others => '0');
                PMT_rate_2(i) <= (others => '0');
            elsif clock'event and clock='1' then
                if rise_rate = '1' then
                    PMT_rate_1(i)(15 downto 0) <= count_pmt_1(i)(15 downto 0);
                    PMT_rate_2(i)(15 downto 0) <= count_pmt_2(i)(15 downto 0);--(others => '0'); --
                end if;
            end if;
            end process;
     end generate PMT_reg_process;

reset_counter_register: process(clock, reset)
                begin
                   if reset='1' then
                       reset_counter <= '1';
                   elsif clock'event and clock='1' then
                       reset_counter <= rise_rate;
                   end if;
        end process;

        PMT_rate <= X"1008" & PMT_rate_1(8) & X"1007" & PMT_rate_1(7) & X"1006" & PMT_rate_1(6)
                  & X"1005" & PMT_rate_1(5) & X"1004" & PMT_rate_1(4) & X"1003" & PMT_rate_1(3) 
                  & X"1002" & PMT_rate_1(2) & X"1001" & PMT_rate_1(1) & X"1000" & PMT_rate_1(0)
                  & X"2008" & PMT_rate_2(8) & X"2007" & PMT_rate_2(7) & X"2006" & PMT_rate_2(6)
                  & X"2005" & PMT_rate_2(5) & X"2004" & PMT_rate_2(4) & X"2003" & PMT_rate_2(3)
                  & X"2002" & PMT_rate_2(2) & X"2001" & PMT_rate_2(1) & X"2000" & PMT_rate_2(0);

--        PMT_rate <= X"201F" & PMT_rate_2(31) & X"201E" & PMT_rate_2(30) & X"201D" & PMT_rate_2(29) & X"201C" & PMT_rate_2(28) & X"201B" & PMT_rate_2(27) & X"201A"
--                    & PMT_rate_2(26) & X"2019" & PMT_rate_2(25) & X"2018" & PMT_rate_2(24) & X"2017" & PMT_rate_2(23) & X"2016" & PMT_rate_2(22) & X"2015" 
--                    & PMT_rate_2(21) & X"2014" & PMT_rate_2(20) & X"2013" & PMT_rate_2(19) & X"2012" & PMT_rate_2(18) & X"2011" & PMT_rate_2(17) & X"2010" 
--                    & PMT_rate_2(16) & X"200F" & PMT_rate_2(15) & X"200E" & PMT_rate_2(14) & X"200D" & PMT_rate_2(13) & X"200C" & PMT_rate_2(12) & X"200B" 
--                    & PMT_rate_2(11) & X"200A" & PMT_rate_2(10) & X"2009" & PMT_rate_2(9) & X"2008" & PMT_rate_2(8) & X"2007" & PMT_rate_2(7) & X"2006" 
--                    & PMT_rate_2(6) & X"2005" & PMT_rate_2(5) & X"2004" & PMT_rate_2(4) & X"2003" & PMT_rate_2(3) & X"2002" & PMT_rate_2(2) & X"2001" 
--                    & PMT_rate_2(1) & X"2000" & PMT_rate_2(0) & X"101F" 
--                    & PMT_rate_1(31) & X"101E" & PMT_rate_1(30) & X"101D" & PMT_rate_1(29) & X"101C" & PMT_rate_1(28) & X"101B" & PMT_rate_1(27) & X"101A"
--                    & PMT_rate_1(26) & X"1019" & PMT_rate_1(25) & X"1018" & PMT_rate_1(24) & X"1017" & PMT_rate_1(23) & X"1016" & PMT_rate_1(22) & X"1015" 
--                    & PMT_rate_1(21) & X"1014" & PMT_rate_1(20) & X"1013" & PMT_rate_1(19) & X"1012" & PMT_rate_1(18) & X"1011" & PMT_rate_1(17) & X"1010" 
--                    & PMT_rate_1(16) & X"100F" & PMT_rate_1(15) & X"100E" & PMT_rate_1(14) & X"100D" & PMT_rate_1(13) & X"100C" & PMT_rate_1(12) & X"100B" 
--                    & PMT_rate_1(11) & X"100A" & PMT_rate_1(10) & X"1009" & PMT_rate_1(9) & X"1008" & PMT_rate_1(8) & X"1007" & PMT_rate_1(7) & X"1006" 
--                    & PMT_rate_1(6) & X"1005" & PMT_rate_1(5) & X"1004" & PMT_rate_1(4) & X"1003" & PMT_rate_1(3) & X"1002" & PMT_rate_1(2) & X"1001" 
--                    & PMT_rate_1(1) & X"1000" & PMT_rate_1(0);


internal_values: process(clock, reset)
                begin
                   if reset='1' then
                        PMT_mask_int_1 <= (others => '1');
                        PMT_mask_int_2 <= (others => '1');
                   elsif clock'event and clock='1' then
                        if apply_PMT_mask = '1' then
                            PMT_mask_int_1 <= PMT_mask_1;
                            PMT_mask_int_2 <= PMT_mask_2;
                        end if;
                   end if;
        end process;


PMT_mask_process_1 : for i in 0 to 31 generate
        begin
        PMT_mask_i: AND2 
              port map( A=> trigger_sincro_1(i),
                        B=> PMT_mask_int_1(i),
                        Y => trigger_PMTmasked_1(i)
                       );
        end generate PMT_mask_process_1;

PMT_mask_process_2 : for i in 0 to 31 generate
        begin
        PMT_mask_i: AND2 
              port map( A=> trigger_sincro_2(i),
                        B=> PMT_mask_int_2(i),
                        Y => trigger_PMTmasked_2(i)
                       );
        end generate PMT_mask_process_2;


trigger_OR_process : for i in 0 to 31 generate
        begin
        OR_i: OR2
              port map( A =>trigger_PMTmasked_1(i),
                        B =>trigger_PMTmasked_2(i),
                        Y => plane(i)
                       );
        end generate trigger_OR_process;

trigger_selector_component : TRIGGER_selector 
       port map(
                clock => clock,
                reset => reset,
                plane  => plane,
                generic_trigger_mask => generic_trigger_mask,
                trigger_mask => trigger_mask,
                start_readers => start_readers,
                apply_trigger_mask => apply_trigger_mask,

                rate_time_sig	=> rise_rate,
		
--		        mask_rate_0 => mask_rate_0_sig,
--		        mask_rate_1 => mask_rate_1_sig,
--		        mask_rate_2 => mask_rate_2_sig,
--		        mask_rate_3 => mask_rate_3_sig,
--		        mask_rate_4  => mask_rate_4_sig,
--		        mask_rate_5  => mask_rate_5_sig,
--		        mask_rate_6  => mask_rate_6_sig,
--		        mask_rate_7  => mask_rate_7_sig,
--		        mask_rate_8  => mask_rate_8_sig,

                debug => debug_out,

				trg_int => trigger
				);



--mask_rate <=    X"0000" & mask_rate_0_sig & 
--                X"0001" & mask_rate_1_sig & 
--                X"0002" & mask_rate_2_sig & 
--                X"0003" & mask_rate_3_sig & 
--                X"0004" & mask_rate_4_sig & 
--                X"0005" & mask_rate_5_sig & 
--                X"0006" & mask_rate_6_sig & 
--                X"0007" & mask_rate_7_sig & 
--                X"0008" & mask_rate_8_sig;

--trigger_mask_rate <= mask_rate_8_sig & mask_rate_7_sig & mask_rate_6_sig & mask_rate_5_sig & mask_rate_4_sig 
--                                               & mask_rate_3_sig & mask_rate_2_sig & mask_rate_1_sig & mask_rate_0_sig;
                        

trigger_flag_register: process(clock, reset)
                 begin
                       if reset='1' then
                            trigger_flag_1 <= (others=> '0');
                            trigger_flag_2 <= (others=> '0');
                       elsif clock'event and clock='1' then
                            if acquisition_state = '1' or calibration_state = '1' then
                                if SMPL_HOLD_N = '1' then 
                                    if trigger = '1' then
                                        trigger_flag_1 <= trigger_PMTmasked_1;
                                        trigger_flag_2 <= trigger_PMTmasked_2;
                                    end if;
                                end if;
                            else
                                trigger_flag_1 <= (others=> '0');
                                trigger_flag_2 <= (others=> '0');                                
                            end if;
                       end if;
                 end process;
-- FSM register

SYNC_PROC: process (clock,reset)
   begin
    	if reset='1' then 

			pres_state <= wait_state;

            trg_to_DAQ_EASI    <= '0' ;
            idle <= '0' ;

		elsif clock'event and clock='1' then
            
            pres_state <= next_state;
			
            trg_to_DAQ_EASI    <= trg_to_DAQ_EASI_i;
            idle <= idle_i ;

        end if;
end process;
  
-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process (pres_state, start_readers, trigger, count, debug, SMPL_HOLD_N, calibration_state, acquisition_state) 
begin
	
next_state <= pres_state;

case pres_state is

when wait_state => -- sistema in attesa

        if debug = '1' then
                next_state <= trg_state;
		elsif start_readers= '1' then
            if ( calibration_state = '1' and trigger = '0' and SMPL_HOLD_N = '1' ) or debug = '1' then
                next_state <= trg_state;
            elsif ( acquisition_state = '1' and trigger = '1' and SMPL_HOLD_N = '1' ) or debug = '1' then
                next_state <= trg_state;
            else
                next_state <= wait_state;
            end if;
        else
			next_state <= wait_state;
		end if;

when trg_state => 
	next_state <= idle_state;

when idle_state => 
		if count = TRG_LENGHT then
			next_state <= wait_state;
        else
			next_state <= idle_state;
		end if;

when others =>
	next_state <= wait_state;

end case;

end process;

OUTPUT_DECODE: process (next_state)

begin

if next_state = wait_state then --  sistema in attesa

            trg_to_DAQ_EASI_i <= '0' ;
            idle_i <= '0' ;
           
elsif next_state = trg_state then 

            trg_to_DAQ_EASI_i <= '1' ;
            idle_i <= '0' ;

elsif next_state = idle_state then 

            trg_to_DAQ_EASI_i <= '0' ;
            idle_i <= '1' ;

else

            trg_to_DAQ_EASI_i <= '0' ;
            idle_i <= '0' ;

end if; 
end process;

-- contatore bit
process (clock, reset) 
begin
   if reset='1' then 
      count <= 0;
   elsif (clock = '1' and clock'event) then
			if (idle = '1') then -- il contatore è abilitato solo nello stato idle 
				if count < TRG_LENGHT  then
					count <= count + 1;
                else 
					count <= 0;                  
                end if;       
			end if;
	end if;
end process;


-- contatore 100 millisecondi
process (clock200k, reset) 
begin
   if reset= '1' then 
      time_cnt <= 0;
      rate_time_sig <= '0';
   elsif (clock200k = '1' and clock200k'event) then
        if (time_cnt < RATE_TIME) then 
            time_cnt <= time_cnt + 1;    
            rate_time_sig <= '0';
        elsif time_cnt = RATE_TIME then
            time_cnt <= 0;  
            rate_time_sig <= '1';
        else
            time_cnt <= 0;  
            rate_time_sig <= '0';
        end if;       
   end if;
end process;

sincronizzatore_rate : process(clock, reset)
            variable resync : std_logic_vector(1 to 3):=(others=> '0');
                begin
                   if reset='1' then
                        rise_rate <= '0';
                   elsif clock'event and clock='1' then
                        rise_rate <= resync(2) and not resync(3);
                        resync := rate_time_sig & resync(1 to 2);
                   end if;
        end process;

end Behavioral;