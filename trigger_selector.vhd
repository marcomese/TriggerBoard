--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: trigger_selector.vhd
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

entity TRIGGER_selector is
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
end TRIGGER_selector;

architecture Behavioral of TRIGGER_selector is

signal trigger, rise: std_logic_vector(8 downto 0) := (others=> '0');
signal plane_masked: std_logic_vector(15 downto 0) := (others=> '0');
--signal count_0 :  std_logic_vector(15 downto 0);
--signal count_1 :  std_logic_vector(15 downto 0);
--signal count_2 :  std_logic_vector(15 downto 0);
--signal count_3 :  std_logic_vector(15 downto 0);
--signal count_4 :  std_logic_vector(15 downto 0);
--signal count_5 :  std_logic_vector(15 downto 0);
--signal count_6 :  std_logic_vector(15 downto 0);
--signal count_7 :  std_logic_vector(15 downto 0);
--signal count_8 :  std_logic_vector(15 downto 0);
signal reset_counter : std_logic;
signal lyso, lyso_masked, trigger0_masked : std_logic;


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

signal generic_trigger_mask_int :  std_logic_vector(31 downto 0);	
signal trigger_mask_int    :   std_logic_vector(31 downto 0);

signal trigger_int, veto_lateral, veto_bottom : std_logic;

begin

debug <= trigger(7);
 
internal_values: process(clock, reset)
                begin
                   if reset='1' then
                        generic_trigger_mask_int <= (others=> '0');
                        trigger_mask_int <= X"00000000";
                   elsif clock'event and clock='1' then
                        if apply_trigger_mask = '1' then
                            generic_trigger_mask_int <= generic_trigger_mask;
                            trigger_mask_int <= trigger_mask;
                        end if;
                   end if;
        end process;
-------------------- Costruzione delle configurazioni di trigger --------------------------------
trigger(0) <= plane(0) or plane(1) or plane(2) or plane(3) or plane(4) or plane(5);
trigger(1) <= (plane(0) or plane(1)) and (plane(2) or plane(3));--trigger(0) and  plane(6);
trigger(2) <= trigger(0) and  (plane(6) or plane(7));
trigger(3) <= (plane(2) or plane(3)) and  (plane(6) or plane(7));
trigger(4) <= trigger(0) and  plane(6) and plane(7);
trigger(5) <= trigger(0) and  plane(6) and plane(7) and plane(8);
trigger(6) <= trigger(2) and  (plane(20) or plane(21));
trigger(7) <= trigger(2) and  lyso;

veto_lateral <= plane(22) or plane(23) or plane(24) or plane(25);
veto_bottom <= plane(26);

lyso <= plane(27) or plane(28) or plane(29) or plane(30) or plane(31);

mux_16_piani : for i in 0 to 15  generate
        begin
        generic_trigger_i: MX2
        port map( A => '1',
                  B => plane(i+6),
                  S => generic_trigger_mask_int(i+1),
                  Y => plane_masked(i)
                );
        end generate mux_16_piani;

mux_trigger0: MX2
        port map( A => '1',
                  B => trigger(0),
                  S => generic_trigger_mask_int(0),
                  Y => trigger0_masked
                );

mux_lyso: MX2
        port map( A => '1',
                  B => lyso,
                  S => generic_trigger_mask_int(17),
                  Y => lyso_masked
                );

trigger(8) <= trigger0_masked and lyso_masked and plane_masked(0) and plane_masked(1) and plane_masked(2) and plane_masked(3) and plane_masked(4) 
                and plane_masked(5) and plane_masked(6) and plane_masked(7) and plane_masked(8) and plane_masked(9) and plane_masked(10) 
                and plane_masked(11) and plane_masked(12) and plane_masked(13) and plane_masked(14) and plane_masked(15);

sincronizzatore : for i in 0 to 8 generate
        begin
        edge_trigger_i: process(clock, reset)
            variable resync_i : std_logic_vector(1 to 3);
                begin
                   if reset='1' then
                        rise(i) <= '0';
                   elsif clock'event and clock='1' then
                    -- detect rising and falling edges.
                        rise(i) <= resync_i(2) and not resync_i(3);
                    -- update history shifter.
                        resync_i := trigger(i) & resync_i(1 to 2);
                   end if;
        end process;
end generate sincronizzatore;

reset_counter_register: process(clock, reset)
                begin
                   if reset='1' then
                       reset_counter <= '1';
                   elsif clock'event and clock='1' then
                       reset_counter <= rate_time_sig;
                   end if;
        end process;

--counter_trigger_0: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_0 <= (others=> '0');
        --elsif clock'event and clock='1' then
            --if start_readers = '1' then
                --if rise(0) ='1' then
                    --count_0 <= count_0 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_1: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_1 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(1) ='1' then
                --count_1 <= count_1 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_2: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_2 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(2) ='1' then
                --count_2 <= count_2 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_3: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_3 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(3) ='1' then
                --count_3 <= count_3 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_4: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_4 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(4) ='1' then
                --count_4 <= count_4 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_5: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_5 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(5) ='1' then
                --count_5 <= count_5 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_6: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_6 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(6) ='1' then
                --count_6 <= count_6 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_7: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_7 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(7) ='1' then
                --count_7 <= count_7 +1;
                --end if;
            --end if;
        --end if;
--end process;
--
--counter_trigger_8: process(clock, reset_counter)
    --begin
        --if reset_counter='1' then
            --count_8 <= (others=> '0');
        --elsif clock'event and clock='1' then
           --if start_readers = '1' then
                --if rise(8) ='1' then
                --count_8 <= count_8 +1;
                --end if;
            --end if;
        --end if;
--end process;

--time_register: process(clock, reset)
                --begin
                   --if reset='1' then
                        --mask_rate_0 <= (others=> '0');
                        --mask_rate_1 <= (others=> '0');
                        --mask_rate_2 <= (others=> '0');
                        --mask_rate_3 <= (others=> '0');
                        --mask_rate_4 <= (others=> '0');
                        --mask_rate_5 <= (others=> '0');
                        --mask_rate_6 <= (others=> '0');
                        --mask_rate_7 <= (others=> '0');
                        --mask_rate_8 <= (others=> '0');
                   --elsif clock'event and clock='1' then
                        --if rate_time_sig = '1' then
                            --mask_rate_0 <= count_0;
                            --mask_rate_1 <= count_1;
                            --mask_rate_2 <= count_2;
                            --mask_rate_3 <= count_3;
                            --mask_rate_4 <= count_4;
                            --mask_rate_5 <= count_5;
                            --mask_rate_6 <= count_6;
                            --mask_rate_7 <= count_7;
                            --mask_rate_8 <= count_8;
                        --end if;
                   --end if;
        --end process;

-----------------------------------------------------------------------------------------------------------

mux_trigger : process (trigger_mask_int(7 downto 0), trigger(8 downto 0)) is
   begin
      case trigger_mask_int(7 downto 0) is
         when X"00"  => trigger_int <= trigger(0);
         when X"01"  => trigger_int <= trigger(1);
         when X"02"  => trigger_int <= trigger(2);
         when X"03"  => trigger_int <= trigger(3);
         when X"04"  => trigger_int <= trigger(4);
         when X"05"  => trigger_int <= trigger(5);
         when X"06"  => trigger_int <= trigger(6);
         when X"07"  => trigger_int <= trigger(7);
         when X"08"  => trigger_int <= trigger(8);
         when others => trigger_int <= trigger(1);
      end case;
   end process;

mux_veto : process (trigger_mask_int(15 downto 8), trigger_int, veto_bottom, veto_lateral) is
   begin
      case trigger_mask_int(15 downto 8) is
         when X"00"  => trg_int <= trigger_int;
         when X"01"  => trg_int <= trigger_int and not veto_lateral;
         when X"02"  => trg_int <= trigger_int and not veto_bottom;
         when X"03"  => trg_int <= trigger_int and not(veto_lateral or veto_bottom);
         when others => trg_int <= trigger_int;
      end case;
   end process;

end Behavioral;