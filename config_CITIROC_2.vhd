--------------------------------------------------------------------------------
-- File: config_CITIROC_1.vhd
-- File history:
--      00 : 07/03/2018 : CREAZIONE FILE
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- BLOCCO DI CONFIGURAZIONE CITIROC, modificato a partire da quello per EASIROC
--
-- Targeted device: <Family::ProASIC3E> <Die::A3PE1500> <Package::208 PQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library proasic3e;
use proasic3e.all;


entity config_CITIROC_2 is
		port (  
                clock           : in std_logic;  -- clk di sistema: 48 MHz???
                reset           : in std_logic;
				
				clk200k         : in std_logic;
				configure_command : in std_logic;
                config_vector   : in std_logic_vector(1143 downto 0);

                holdDelayIN       : in std_logic_vector(7 downto 0);
                holdDelayOUT      : out std_logic_vector(7 downto 0);

				CLK_SR_reg_out   : out std_logic; -- debug
                idle             : out std_logic;

                load             : out std_logic;
						
				select_reg       : out std_logic;  
				
				SR_IN_SR         : out std_logic;  
				RST_B_SR         : out std_logic;  
				CLK_SR           : out std_logic
				
				);
end config_CITIROC_2 ;

architecture Behavioral of config_CITIROC_2 is

type state_values is (       power_off,
                             state0,
                             reset_select0,
							 reset_select1,
							 config_state,    
							 config_to_idle1, -- stato di transizione con clk200k abilitato
							 config_to_idle2, -- stato di transizione con clk200k non abilitato e load = '0'
							 load_state,      -- load = '1'
                             probe_state,
                             load_to_probe,
                             probe_to_idle,
                             idle_state
							 );
signal pres_state, next_state: state_values;


signal SR_IN_SR_i : std_logic := '1';
signal select_reg_i, RST_B_SR_i, CLK_SR_i, CLK_SR_sig, idle_i, load_i: std_logic := '0';
signal RST_B_SR_sig, select_reg_sig, state0_sig, state0_sig_i : std_logic := '0';---------------------

constant DATA_WIDTH : integer :=   1144; -- Width of command word
constant PROBE_WIDTH : integer :=   256; -- Width of probe word
constant RESET_LENGHT : integer :=   3; -- Lenght of the reset to CITIROC registers (number of 200 KHz clk200k cycles)

signal bit_nr : integer range 0 to DATA_WIDTH - 1 := 0;
signal probe_bit_nr : integer range 0 to PROBE_WIDTH - 1 := 0;
signal reset_cnt : integer range 0 to 2*RESET_LENGHT + 1 := 0;
signal state0_cnt : integer range 0 to 100003 := 0; -- 10003


------------------- Slow Control ------------------------
Constant holdDelay_const                    :std_logic_vector(7 downto 0) := X"00";
Constant DAC00_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC01_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC02_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC03_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC04_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC05_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC06_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC07_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC08_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC09_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC10_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC11_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC12_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC13_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC14_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC15_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC16_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC17_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC18_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC19_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC20_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC21_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC22_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC23_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC24_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC25_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC26_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC27_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC28_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC29_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC30_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000
Constant DAC31_t							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	_t from channel 0 to 31 - (DAC_t0-DAC_t3)	32 x 0000

Constant DAC00  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC01  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC02  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC03  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC04  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC05  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC06  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC07  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC08  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC09  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC10  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC11  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC12  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC13  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC14  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC15  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC16  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC17  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC18  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC19  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC20  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC21  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC22  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC23  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC24  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC25  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC26  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC27  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC28  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC29  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC30  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000
Constant DAC31  							:std_logic_vector(3 downto 0) :=  X"0";	--	Input 3-BIT DAC	 from channel 0 to 31 - (DAC0-DAC3)	32 x 0000

Constant EN_discri							:std_logic:='1';    --	Enable Discriminator	1 (discriminator Enabled)
Constant Discriminator						:std_logic:='0';    --	Disable trigger discriminator power pulsing mode (force ON)	0
Constant RS_or_discri						:std_logic:='0';    --	 Select latched (RS : 1) or direct output (trigger : 0)	0

Constant EN_discri_t						:std_logic:='1';    --	Enable Discriminator_t	1 (discriminator Enabled)
Constant Discriminator_t					:std_logic:='0';    --	Disable trigger discriminator power pulsing mode (force ON)	0

Constant EN_4b_dac						    :std_logic:='1';    --	Enable 4-BIT DAC charge - 0 disabled, force off   - 1 enabled - default 1         
Constant PP4b_dac						    :std_logic:='0';    --	4-BIT DAC charge power pulsing mode - 0 power pin - 1 force on - default 0

Constant EN_4b_dac_t						:std_logic:='1';    --	Enable 4-BIT DAC time - 0 disabled, force off   - 1 enabled - default 1         
Constant PP4b_dac_t				     		:std_logic:='0';    --	4-BIT DAC time power pulsing mode - 0 power pin - 1 force on - default 0

Constant Discri_Mask						:std_logic_vector(31 downto 0) :=  X"FFFFFFFF";	--	Discriminator Mask	Allows to Mask Discriminator (channel 0 to 31) [active low: 1 unmasked, 0 masked]	- 32 x 0 (masked)

Constant HG_TeH 						    :std_logic:='0'; --  Disable High Gain Track & Hold power pulsing mode (force ON) - 0
Constant EN_HG_TeH 						    :std_logic:='1'; --   Enable High Gain Track & Hold - 1

Constant LG_TeH 						    :std_logic:='0'; --  Disable low Gain Track & Hold power pulsing mode (force ON) - 0
Constant EN_LG_TeH 						    :std_logic:='1'; --   Enable low Gain Track & Hold - 1

Constant SCA_bias						    :std_logic:='0'; --  SCA bias ( 1 = weak bias, 0 = high bias 5MHz ReadOut Speed)	1 (weak bias)

Constant HG_Pdet 						    :std_logic:='0'; --  High Gain Peak detector power pulsing mode (force ON) - 0
Constant EN_HG_Pdet  					    :std_logic:='0'; --   Enable High Gain Peak detector - 1

Constant LG_Pdet						    :std_logic:='0'; -- low Gain Peak detector power pulsing mode (force ON) - 0
Constant EN_LG_Pdet 					    :std_logic:='0'; --   Enable low Gain Peak detector - 1

Constant Sel_SCA_or_PeakD_HG			    :std_logic:='1'; -- Select  - 1 (SCA HG)
Constant Sel_SCA_or_PeakD_LG				:std_logic:='1'; --   Enable low Gain Peak detector - 1 (SCA LG)

Constant bypass_PSC			                :std_logic:='1';  --  Bypass Peak Sensing Cell ( 0 cell active, 1 cell bypassed)
Constant Sel_Trig_Ext_PSC			        :std_logic:='0';  -- Select peak sensing cell trigger  ( 0 internal trigger - 1 external trigger)

Constant Fast_Shapers_Follower_PP	        :std_logic:='0';    --	Fast Shapers Follower PP	Disable fast shaper follower power pulsing mode (force ON)	1 (FSb follower ON)
Constant EN_Fast_Shaper					    :std_logic:='1';    --	EN_Fast Shaper	Enable fast shaper	1 (FSb Enabled)
Constant Fast_Shaper_PP				    	:std_logic:='0';    --	Fast Shaper PP	Disable fast shaper power pulsing mode (force ON)	1 (FSb ON)

Constant LG_sShaper_PP					    :std_logic:='1';    --	Low Gain Slow Shaper PP	Disable low gain slow shaper power pulsing mode (force ON)	1 (SS ON)
Constant EN_LG_sShaper	       				:std_logic:='1';    --	EN_Low_Gain_Slow Shaper	Enable Low Gain Slow Shaper	1 (SS Enabled)
Constant Tconst_LG_Shaper		    		:std_logic_vector(2 downto 0) :=  "000";    --	Time Constant LG Shaper	Low gain shaper time constant commands (2:0) active low	0
Constant HG_sShaper_PP				    	:std_logic:='1';    --	High Gain Slow Shaper PP	Disable high gain slow shaper power pulsing mode (force ON)	1 (SS ON)
Constant EN_HG_sShaper					    :std_logic:='1';    --	EN_High_Gain_Slow Shaper	Enable high gain Slow Shaper	1 (SS Enabled)
Constant Tconst_HG_Shaper				    :std_logic_vector(2 downto 0) :=  "000";    --	Time Constant HG Shaper	High gain shaper time constant commands (2?0)	0

Constant LG_PA_bias						    :std_logic:='0';    --	Low Gain PA bias	Low Gain PreAmp bias (weak bias = 1 , high bias = 0)	1 (weak bias)

Constant LG_PreAmpPP						:std_logic:='1';    --	Low Gain PreAmplifier PP	Disable Low Gain preamp power pulsing mode (force ON)	1 (PA ON)
Constant EN_LG_PA							:std_logic:='1';    --	EN_Low_Gain_PA	Enable Low Gain preamp	1 (PA Enabled)
Constant HG_PreAmpPP						:std_logic:='1';    --	High Gain PreAmplifier PP	Disable High Gain preamp power pulsing mode (force ON)	1 (PA ON)
Constant EN_HG_PA							:std_logic:='1';    --	EN_High_Gain_PA	Enable High Gain preamp	1 (PA Enabled)

Constant Fast_Shaper_LG						:std_logic:='0';    --	Select LG PreAmp to send to Fast Shaper ( 0 fast shaper on hg PreAmp , 1 fast shaper on LG PreAMP )

Constant EN_input_dac					    :std_logic:='0';    --	Enable 32 input 8-bit DACs	1 (DACs ON)
Constant DAC_ref							:std_logic:='1';    --	8-bit input DAC Voltage Reference (1 = external 4,5V , 0 = internal 2,5V)	1 (External Ref)
Constant DAC00_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC01_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC02_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC03_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC04_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC05_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC06_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC07_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC08_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC09_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC10_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC11_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC12_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC13_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC14_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC15_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC16_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC17_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC18_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC19_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC20_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC21_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC22_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC23_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC24_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC25_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC26_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC27_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC28_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC29_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC30_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant DAC31_in							:std_logic_vector(8 downto 0) :=  X"00"&'0';	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0

Constant PreAMP_config00                    :std_logic_vector(14 downto 0) :=   X"000"&"000";	--	Input 8-bit DAC Data from channel 0 to 31 - (DAC7 to DAC0+ DAC ON)	32 x 0000 0000 0
Constant PreAMP_config01                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config02                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config03                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config04                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config05                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config06                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config07                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config08                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config09                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config10                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config11                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config12                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config13                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config14                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config15                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config16                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config17                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config18                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config19                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config20                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config21                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config22                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config23                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config24                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config25                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config26                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config27                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config28                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config29                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config30                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000
Constant PreAMP_config31                    :std_logic_vector(14 downto 0) :=   X"000"&"000"; -- Channel 0 to 31 PreAmp config (HG gain[5..0], LG gain [5..0], CtestHG, CtestLG, PA disabled)	15 x 111000 111011 000


Constant Temp		        				:std_logic:='0';	-- Disable Temperature Sensor power pulsing mode (force ON)	1099	0
Constant EN_Temp							:std_logic:='1';    -- Enable Temperature Sensor	1100	1 (T° Enabled)

Constant BandGap_PP						    :std_logic:='0';    -- BandGap PP	Disable BandGap power pulsing mode (force ON)	1 (BandGap ON)
Constant EN_BandGap					    	:std_logic:='1';    -- EN_BandGap	Enable BandGap	1 (BandGap Enabled)
Constant EN_DAC_1							:std_logic:='1';    -- EN_DAC	Enable DAC	1 (DAC Enabled)
Constant DAC_PP_1							:std_logic:='1';    -- DAC PP	Disable DAC power pulsing mode (force ON)	1 (DAC ON)
Constant EN_DAC_2							:std_logic:='1';    -- EN_DAC	Enable DAC	1 (DAC Enabled)
Constant DAC_PP_2							:std_logic:='1';    -- DAC PP	Disable DAC power pulsing mode (force ON)	1 (DAC ON)
Constant DAC_code_1							:std_logic_vector(9 downto 0) := "0011100110";	--	DAC code	10-bit DAC (MSB-LSB) (arriva prima il LSB) ATTENZIONE: ordine invertito rispetto a EASIROC
Constant DAC_code_2							:std_logic_vector(9 downto 0) := "0011100110";	--	DAC code	10-bit DAC (MSB-LSB) (arriva prima il LSB) ATTENZIONE: ordine invertito rispetto a EASIROC

Constant EN_HG_OTAq	    					:std_logic:='1';    -- EN_High Gain OTAq	Enable High Gain OTA	0 (HG path Disabled)
Constant HG_OTAq_PP		    				:std_logic:='0';    -- High Gain OTAq PP	Disable High Gain OTA power pulsing mode (force ON)	0
Constant EN_LG_OTAq			    			:std_logic:='1';    -- EN_Low Gain OTAq	Enable Low Gain OTA	0 (LG path Disabled)
Constant LG_OTAq_PP				    		:std_logic:='0';    -- Low Gain OTAq PP	Disable Low Gain OTA power pulsing mode (force ON)	0
Constant EN_Probe_OTAq				    	:std_logic:='1';    -- Enable Probe OTA	0 (Probe Disabled)
Constant Probe_OTAq_PP					    :std_logic:='0';    -- disable Probe OTA power pulsing mode (force ON)	0

Constant Testb_Otaq				        	:std_logic:='1';    -- Otaq test bit
Constant EN_Val_Evt				        	:std_logic:='1';    -- Enable Val_Evt receiver
Constant Val_Evt				           	:std_logic:='0';    -- Disable Val_Evt receiver power pulsing mode (force ON)
Constant EN_Raz_Chn				        	:std_logic:='0';    -- Enable Raz_Chn receiver
Constant Raz_Chn					        :std_logic:='0';    -- Disable Raz Chn receiver power pulsing mode (force ON)
Constant EN_out_dig				    		:std_logic:='1';    -- Enable digital multiplexed output (Hit mux out)	0 (digital out disabled)
Constant EN_OR32							:std_logic:='1';    -- Enable digital OR32 output [active low]	0 (OR32 enabled)

Constant EN_NOR32_oc				       	:std_logic:='1';    -- Enable digital OR32 Open Collector output
Constant Trigger_Polarity			       	:std_logic:='0';    -- 0 RISING EDGE - 1 FALLING EDGE
Constant EN_NOR32T_oc			           	:std_logic:='1';    -- Enable digital OR32_T Open Collector output
Constant EN_32_trigg						:std_logic:='1';    -- Enable 32 channels triggers outputs [active low]	0 (Triggers enabled)
---------------------------------------------------------

------------------- Probe Register ----------------------
-- NB: è possibile mandare in uscita contemporaneamente solo un output 
-- ANALOGICO (un solo bit a 1 su Out_fs, Out_ssh_LG, Out_ssh_HG, Out_PA_HG, Out_PA_LG)
-- uno DIGITALE (PeakSensing_modeb_LG, PeakSensing_modeb_HG)
-- e un DAC (InputDAC)
Constant Out_fs               :std_logic_vector(31 downto 0) :=  X"00000000";	--	fast shaper output channel 0 to 31  ANALOG output on Out_probe  X"80000000" = pin IN_s32
Constant Out_ssh_LG           :std_logic_vector(31 downto 0) :=  X"00000000";	--	low gain slow shaper output channel 0 to 31  ANALOG output on Out_probe 
Constant PeakSensing_modeb_LG :std_logic_vector(31 downto 0) :=  X"00000000";	--	low gain peak detector status (follower or peak sensing) channel 0 to 31  DIGITAL output on Digital_probe 
Constant Out_ssh_HG           :std_logic_vector(31 downto 0) :=  X"00000000";	--	high gain slow shaper output channel 0 to 31  ANALOG output on Out_probe 
Constant PeakSensing_modeb_HG :std_logic_vector(31 downto 0) :=  X"00000000";	--	high gain peak detector status (follower or peak sensing) channel 0 to 31  DIGITAL output on Digital_probe 
Constant Out_PA_HG            :std_logic_vector(31 downto 0) :=  X"00000000";	--	high gain preAmp output channel 0 to 31  ANALOG output on Out_probe 
Constant Out_PA_LG            :std_logic_vector(31 downto 0) :=  X"00000000";	--	low gain preAmp output channel 0 to 31  ANALOG output on Out_probe 
Constant InputDAC             :std_logic_vector(31 downto 0) :=  X"00000000";	--	input DAC output channel 0 to 31  ANALOG output on Out_probe_dac_5V NB: solo uno per volta a 1
---------------------------------------------------------

signal Data_Conf: std_logic_vector(1143 downto 0) :=  (others => '0');
signal PROBE_reg: std_logic_vector(255 downto 0) :=  (others => '0');


COMPONENT output_DDR is

    port( DataR : in    std_logic;
          DataF : in    std_logic;
          CLR   : in    std_logic;
          CLK   : in    std_logic;
          PAD   : out   std_logic
        );

end COMPONENT;

begin

holdDelay_process: process(clock,reset)
begin
    if reset = '1' then
        holdDelayOUT <= holdDelay_const;
    elsif rising_edge(clock) then
        if configure_command = '1' then
            holdDelayOUT <= holdDelayIN;
        end if;
    end if;
end process;

config_vector_process: process (clock,reset)
   begin
    	if reset='1' then 
                Data_Conf(1143 downto 0) <= DAC00_t		& DAC01_t	& DAC02_t & DAC03_t & DAC04_t & DAC05_t & DAC06_t & DAC07_t & DAC08_t & 
                                            DAC09_t & DAC10_t & DAC11_t & DAC12_t& DAC13_t  & DAC14_t & DAC15_t & DAC16_t & DAC17_t  & DAC18_t 
                                            & DAC19_t & DAC20_t & DAC21_t & DAC22_t & DAC23_t & DAC24_t & DAC25_t & DAC26_t & DAC27_t & DAC28_t
                                            & DAC29_t & DAC30_t & DAC31_t & DAC00 & DAC01 & DAC02 & DAC03 & DAC04 & DAC05 & DAC06 & DAC07 & 
                                            DAC08 & DAC09 & DAC10 & DAC11 & DAC12 & DAC13 & DAC14 & DAC15 & DAC16 & DAC17 & DAC18 & DAC19 & 
                                            DAC20 & DAC21 & DAC22 & DAC23  & DAC24 & DAC25 & DAC26 & DAC27 & DAC28 & DAC29 & DAC30 & DAC31 & 
                                            EN_discri	& Discriminator	& RS_or_discri	 & EN_discri_t	& Discriminator_t	& EN_4b_dac	& 
                                            PP4b_dac	& EN_4b_dac_t	& PP4b_dac_t & Discri_Mask & HG_TeH & EN_HG_TeH & LG_TeH & EN_LG_TeH & 
                                            SCA_bias	& HG_Pdet & EN_HG_Pdet  & LG_Pdet & EN_LG_Pdet & Sel_SCA_or_PeakD_HG & Sel_SCA_or_PeakD_LG	
                                            & bypass_PSC & Sel_Trig_Ext_PSC	& Fast_Shapers_Follower_PP	& EN_Fast_Shaper & Fast_Shaper_PP	
                                            & LG_sShaper_PP	& EN_LG_sShaper	 & Tconst_LG_Shaper	& HG_sShaper_PP	& EN_HG_sShaper	& 
                                            Tconst_HG_Shaper	& LG_PA_bias & LG_PreAmpPP & EN_LG_PA & HG_PreAmpPP & EN_HG_PA	& 
                                            Fast_Shaper_LG & EN_input_dac & DAC_ref	& DAC00_in & DAC01_in & DAC02_in & DAC03_in & DAC04_in & 
                                            DAC05_in		 & DAC06_in		 & DAC07_in		 & DAC08_in		 & DAC09_in		 & DAC10_in		 
                                            & DAC11_in		 & DAC12_in		 & DAC13_in		 & DAC14_in		 & DAC15_in		 & DAC16_in		 
                                            & DAC17_in		 & DAC18_in		 & DAC19_in		 & DAC20_in		 & DAC21_in		 & DAC22_in		 
                                            & DAC23_in		 & DAC24_in		 & DAC25_in		 & DAC26_in		 & DAC27_in		 & DAC28_in		 
                                            & DAC29_in		 & DAC30_in		 & DAC31_in & PreAMP_config00 & PreAMP_config01  & PreAMP_config02 
                                            & PreAMP_config03  & PreAMP_config04  & PreAMP_config05  & PreAMP_config06  
                                            & PreAMP_config07  & PreAMP_config08  & PreAMP_config09  & PreAMP_config10  
                                            & PreAMP_config11  & PreAMP_config12  & PreAMP_config13  & PreAMP_config14  
                                            & PreAMP_config15  & PreAMP_config16  & PreAMP_config17  & PreAMP_config18  
                                            & PreAMP_config19  & PreAMP_config20  & PreAMP_config21  & PreAMP_config22  
                                            & PreAMP_config23   & PreAMP_config24 & PreAMP_config25  & PreAMP_config26 
                                            & PreAMP_config27 & PreAMP_config28   & PreAMP_config29 & PreAMP_config30 
                                            & PreAMP_config31  & Temp	& EN_Temp & BandGap_PP	& EN_BandGap	& EN_DAC_1	
                                            & DAC_PP_1 & EN_DAC_2	& DAC_PP_2	& DAC_code_1	& DAC_code_2	& EN_HG_OTAq	 
                                            & HG_OTAq_PP	& EN_LG_OTAq	& LG_OTAq_PP	& EN_Probe_OTAq	& Probe_OTAq_PP 
                                            & Testb_Otaq	& EN_Val_Evt	& Val_Evt	& EN_Raz_Chn	& Raz_Chn	
                                            & EN_out_dig	& EN_OR32	& EN_NOR32_oc & Trigger_Polarity & EN_NOR32T_oc & EN_32_trigg;	

elsif clock'event and clock='1' then        
                if configure_command = '1' then
                    Data_Conf <= config_vector;
                end if;
        end if;
   end process;


--La configurazione da mandare al probe deve essere invertita (PROBE_reg(0) equivale al bit 255, PROBE_reg(255) al bit 0 cioè CH0)

PROBE_reg(255 downto 0) <= Out_fs  & Out_ssh_LG& PeakSensing_modeb_LG & Out_ssh_HG  & PeakSensing_modeb_HG & Out_PA_HG & Out_PA_LG & InputDAC;

-- FSM register

SYNC_PROC: process (clk200k,reset)
   begin
    	if reset='1' then 
			pres_state <= power_off;
			select_reg_sig       <= '0'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR         <= '1'; 
			RST_B_SR_sig         <= '1'; -- attivo basso
			CLK_SR_sig           <= '0'; -- attivo sul fronte di salita 
            state0_sig <= '1';
            idle <= '0';

            load <= '0';
				
		elsif clk200k'event and clk200k='1' then
            
            pres_state <= next_state;
			SR_IN_SR <= SR_IN_SR_i;
			select_reg_sig <= select_reg_i;
			RST_B_SR_sig <= RST_B_SR_i;
			CLK_SR_sig <= CLK_SR_i;
            state0_sig <= state0_sig_i;
            idle <= idle_i;
            load <= load_i;

      end if;
   end process;

			RST_B_SR <= RST_B_SR_sig;

            select_reg <= select_reg_sig;

-- FSM combinational block(NEXT_STATE_DECODE)
	
fsm: process (pres_state, reset_cnt, bit_nr, configure_command, state0_cnt, probe_bit_nr) 
begin
	
next_state <= pres_state;

case pres_state is

when power_off =>
		next_state <= state0;

when state0 =>
		if state0_cnt < 100000 then 
            next_state <= state0;
		else
			next_state <= reset_select0;
		end if;

when reset_select0 =>
		if reset_cnt < RESET_LENGHT then
        next_state <= reset_select0;
		else
			next_state <= reset_select1;
		end if;

when reset_select1 =>
		if reset_cnt < 2*RESET_LENGHT then
          next_state <= reset_select1;
		else
		  next_state <= config_state;
        end if;
				
when config_state =>
        if bit_nr = DATA_WIDTH - 1 then
            next_state <= config_to_idle1;
        else
			next_state <= config_state; 
        end if;	

when config_to_idle1 =>
			next_state <= config_to_idle2;
		  
when config_to_idle2 =>
			next_state <= load_state;
			
when load_state =>
			next_state <= load_to_probe;

when load_to_probe =>
			next_state <= probe_state;

when probe_state =>
        if probe_bit_nr = PROBE_WIDTH -1 then
              next_state <= probe_to_idle;
        else
		      next_state <= probe_state; 
        end if;	

when probe_to_idle =>
			next_state <= idle_state;

when idle_state =>
    if ( configure_command = '1') then
        next_state <= state0;
	else 
	     next_state <= idle_state;
    end if;

when others =>
	next_state <= power_off;

end case;

end process;



OUTPUT_DECODE: process (next_state,bit_nr,probe_bit_nr)

begin

if next_state = power_off then

			select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '1';
            idle_i             <= '0';
            load_i             <= '0';

elsif next_state = state0 then

 			select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '1';
            idle_i             <= '0';
            load_i             <= '0';

elsif next_state = reset_select0 then

 			select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '0'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';

elsif next_state = reset_select1 then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '0'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';
			
elsif next_state = config_state then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= Data_Conf(bit_nr); ------------------------------------------------------------
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '1'; ---------------------------------------------------------------- -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';
			
elsif next_state = config_to_idle1 then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '1'; -- attivo sul fronte di salita ------------------------------------------------
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';
			
elsif next_state = config_to_idle2 then

             select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita ------------------------------------------------
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';
			
elsif next_state = load_state then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '1';

			
elsif next_state = probe_state then

 			select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg !!!!!!!!!!!!!!!!!!!!!!
			SR_IN_SR_i         <= PROBE_reg(probe_bit_nr); 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '1'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';

			
elsif next_state = load_to_probe then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg 
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita !!!!!!!!!!!!!!!!!!!!!! ancora abilitato
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';

elsif next_state = probe_to_idle then

 			select_reg_i       <= '0'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= PROBE_reg(probe_bit_nr); 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '1'; -- attivo sul fronte di salita ------------------------------------------------
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';

elsif next_state = idle_state then

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '1';
            load_i             <= '0';
				
else 			

 			select_reg_i       <= '1'; -- 0 probe reg, 1 slow control reg
			SR_IN_SR_i         <= '1'; 
			RST_B_SR_i         <= '1'; -- attivo basso
			CLK_SR_i           <= '0'; -- attivo sul fronte di salita 
			state0_sig_i       <= '0';
            idle_i             <= '0';
            load_i             <= '0';
end if;

end process;

-- contatore durata stato iniziale

process (clk200k, reset, idle_i) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
   if reset='1' or idle_i = '1' then 
      state0_cnt <= 0;
   elsif (clk200k = '1' and clk200k'event) then
			if state0_sig = '1' then -- il contatore è abilitato solo nello stato iniziale
				state0_cnt <= state0_cnt + 1;		
			end if;
	end if;
end process;

-- contatore durata reset

process (clk200k, reset, idle_i) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
   if reset='1' or idle_i = '1' then 
      reset_cnt <= 0;
   elsif (clk200k = '1' and clk200k'event) then
			if RST_B_SR_sig = '0' then -- il contatore è abilitato solo negli stati di reset (config_state)
				reset_cnt <= reset_cnt + 1;		
			end if;
	end if;
end process;

-- contatore bit di configurazione

process (clk200k, reset) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
   if reset='1' then 
      bit_nr <= 0;
   elsif (clk200k = '1' and clk200k'event) then
			if (RST_B_SR_sig = '0') then -- il contatore viene resettato ogni volta che si resettano i registri
				bit_nr <= 0;	
			elsif (CLK_SR_sig = '1' and select_reg_sig = '1') then -- il contatore è abilitato solo nello stato di configurazione e limitrofi (config_state, config_to_idle)
				if bit_nr < DATA_WIDTH - 1  then
					bit_nr <= bit_nr + 1;
				end if;
			end if;
	end if;
end process;

-- contatore bit di probe

process (clk200k, reset) -- usa come clk200k lo stesso clk200k usato dalla memoria e per la configurazione della easiroc
begin
   if reset='1' then 
      probe_bit_nr <= 0;
   elsif (clk200k = '1' and clk200k'event) then
			if (RST_B_SR_sig = '0') then -- il contatore viene resettato ogni volta che si resettano i registri
				probe_bit_nr <= 0;	
			elsif (CLK_SR_sig = '1' and select_reg_sig = '0') then -- il contatore è abilitato solo nello stato di probe (probe_state)
				if probe_bit_nr < PROBE_WIDTH - 1  then
					probe_bit_nr <= probe_bit_nr + 1;
				end if;
			end if;
	end if;
end process;

CompODDR: output_DDR

    port MAP( DataR  => '0',
            DataF  => '1',
            CLR    => CLK_SR_sig, 
            CLK    => clk200k,
            PAD    => CLK_SR
        );

CLK_SR_reg_out <= CLK_SR_sig;	

end Behavioral;



