library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library proasic3e;
use proasic3e.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity test_file is
port (
    clock96M       : in std_logic;  -- clk di sistema: 48 MHz
    clock24M       : in std_logic;  -- per gli ADC
    led            : inout std_logic;  -- 

    rstOUT         : out std_logic;

    holdDelay_1    : in std_logic_vector(7 downto 0);
    holdDelay_2    : in std_logic_vector(7 downto 0);

    triggerOUT : out std_logic;

    PMT_mask_1      : in  std_logic_vector(31 downto 0);
    PMT_mask_2      : in  std_logic_vector(31 downto 0);
    generic_trigger_mask : in std_logic_vector(31 downto 0);	
    trigger_mask    : in  std_logic_vector(31 downto 0);
    apply_trigger_mask : in std_logic;
    apply_PMT_mask : in std_logic; 
    start_readers  : in std_logic; 
    start_ACQ      : in std_logic; 
    stop_ACQ       : in std_logic; 
    start_cal      : in std_logic;
    stop_cal       : in std_logic;
    acquisition_state : out std_logic;
    calibration_state : out std_logic;
    --PMT_rate          : out std_logic_vector(2047 downto 0);
    PMT_rate          : out std_logic_vector(575 downto 0);
    --mask_rate         : out std_logic_vector(287 downto 0);
    config_status_1 : out std_logic;
    config_status_2 : out std_logic;
    readers_status_1 : out std_logic;
    readers_status_2 : out std_logic;
    sw_rst         : in std_logic;

    select_reg_1   : out std_logic;
	SR_IN_SR_1     : out std_logic; 
	RST_B_SR_1     : out std_logic; 
	CLK_SR_1       : out std_logic;
    load_1         : out std_logic;
    select_reg_2   : out std_logic;
	SR_IN_SR_2     : out std_logic; 
	RST_B_SR_2     : out std_logic; 
	CLK_SR_2       : out std_logic;
    load_2         : out std_logic;

    uscita_test    : out std_logic;
    test_2         : out std_logic;

    config_vector_1 : in std_logic_vector(1143 downto 0);
    config_vector_2 : in std_logic_vector(1143 downto 0);
    configure_command_1 : in std_logic;
    configure_command_2 : in std_logic;

    tx          : out std_logic; 
    rx          : in std_logic; 

    PWR_ON_1       : out std_logic;
    PWR_ON_2       : out std_logic;

    VAL_EVT_1       : out std_logic;
    VAL_EVT_2       : out std_logic;

    RAZ_CHN_1       : out std_logic;
    RAZ_CHN_2       : out std_logic;

    --trigger_int    : in std_logic;

    trigger_in_1    : in std_logic_vector(31 downto 0);
    trigger_in_2    : in std_logic_vector(31 downto 0);    
    OR32_1          : in std_logic;
    OR32_2          : in std_logic;

    SDATA_hg_1        : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_1        : in std_logic;    -- 2 leading '0' + 12 dati
    CS_1              : out std_logic;  -- attivo sul fronte di discesa
    SCLK_1            : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_1         : out std_logic;  -- attivo ALTO
    hold_lg_1         : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_1        : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_1      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_1      : out std_logic;  -- attivo basso 
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
    SDATA_hg_2        : in std_logic;    -- 2 leading '0' + 12 dati
    SDATA_lg_2        : in std_logic;    -- 2 leading '0' + 12 dati
    CS_2              : out std_logic;  -- attivo sul fronte di discesa
    SCLK_2            : out std_logic;  -- il dato cambia sul fronte di discesa
    hold_hg_2         : out std_logic;  -- attivo ALTO
    hold_lg_2         : out std_logic;  -- attivo ALTO
                                        -- ATTENZIONE: è diverso da EASIROC
    CLK_READ_2        : out std_logic;  -- attivo sul fronte di salita
    SR_IN_READ_2      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                        -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
    RST_B_READ_2      : out std_logic;  -- attivo basso 
                                        -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
-----
    debug_triggerIN   : in std_logic

);
end test_file;


architecture Behavioral of test_file is

component pulseExpand is
    Port ( clkOrig : in  STD_LOGIC;
           clkDest : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           pulseIN : in  STD_LOGIC;
           pulseOUT : out  STD_LOGIC);
end component;

component CLKINT is
    port (A : in std_logic;
          Y : out std_logic);
end component;


component BIBUF 
    port ( 

      D : in std_logic;
      E : std_logic;
      PAD: inout std_logic;
      Y : out std_logic
    );
    
  end component;

COMPONENT output_DDR is
    port( DataR : in    std_logic;
          DataF : in    std_logic;
          CLR   : in    std_logic;
          CLK   : in    std_logic;
          PAD   : out   std_logic
        );
end COMPONENT;

component delayLine is
    Generic(
        ffNum        : integer := 8
    );
    Port(
        signalIN    : in  std_logic;
        signalOUT   : out std_logic;
        delayVal    : in  std_logic_vector;
        clk         : in  std_logic;
        rst         : in  std_logic
        );
end component;

component config_CITIROC_1 is
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
end component;

component config_CITIROC_2 is
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
end component;


component read_FSM is
   port (
                reset           : in std_logic;
				clock           : in std_logic;   
                clock200        : in std_logic;   -- clock a 200 kHz
                clock24M        : in std_logic;   -- clock a 24 MHz

                SDATA_hg        : in std_logic;    -- 2 leading '0' + 12 dati
                SDATA_lg        : in std_logic;    -- 2 leading '0' + 12 dati

                trigger_int     : in std_logic;

                CS              : out std_logic;  -- attivo sul fronte di discesa
				SCLK            : out std_logic;  -- il dato cambia sul fronte di discesa

                LG_data         : out std_logic_vector(383 downto 0);
                HG_data         : out std_logic_vector(383 downto 0);

                hold_B          : out std_logic;  -- attivo ALTO
                                                  -- ATTENZIONE: è diverso da EASIROC
				CLK_READ        : out std_logic;  -- attivo sul fronte di salita
                SR_IN_READ      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                                  -- quando SR_IN_READ è alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
				RST_B_READ      : out std_logic;  -- attivo basso 
                                                  -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
                
                data_ready      : out std_logic;
                
                controllo : out std_logic
);
end component;

component TRIGGER_logic_FSM is
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
		
		        --mask_rate       : out std_logic_vector(287 downto 0);				
		        --PMT_rate        : out std_logic_vector(2047 downto 0);				
                PMT_rate        : out std_logic_vector(575 downto 0);				

                trigger_flag_1  : out std_logic_vector(31 downto 0);			
                trigger_flag_2  : out std_logic_vector(31 downto 0);			
                trigger_mask_rate : out std_logic_vector(143 downto 0);

                debug_out : out std_logic;
                test_out : out std_logic;

				trg_to_DAQ_EASI : out std_logic  -- attivo alto
				);
end component;

component top_data_transfer is
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

      tx          : out std_logic; 
      rx          : in std_logic; 
      receivedDATA       : out std_logic_vector(7 downto 0)
);
end component;

-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

  signal s_rst                  : std_logic; 
  signal s_global_rst           : std_logic; 
  signal r_rst_n_0              : std_logic;
  signal r_rst_n_1              : std_logic;
  signal r_rst_n_2              : std_logic;
  signal r_rst_n_3              : std_logic;
  signal rst                    : std_logic;
  signal clk                    : std_logic;
  signal idle_1_sig             : std_logic;
  signal idle_2_sig             : std_logic;
  signal clk200k_sig            : std_logic;

signal CLK_READ_1_sig, CLK_READ_2_sig : std_logic := '0';

signal hg_data_1_sig, hg_data_2_sig : std_logic_vector(383 downto 0);
signal lg_data_1_sig, lg_data_2_sig : std_logic_vector(383 downto 0);

signal SCLK_1_sig, SCLK_2_sig: std_logic := '0';
signal controllo1, controllo2: std_logic := '0';
signal hold_1_sig, hold_2_sig: std_logic := '0';

signal data_ready_2_sig, data_ready_1_sig, trigger_int_sig : std_logic := '0';

signal trigger_or, trigger_interno_sig, debug : std_logic := '0';

signal trigger_flag_1, trigger_flag_2 : std_logic_vector(31 downto 0);
--signal s_pmt_rate : std_logic_vector(2047 downto 0);
signal s_pmt_rate : std_logic_vector(575 downto 0);
--signal s_mask_rate : std_logic_vector(287 downto 0);


signal DATA_OUT : std_logic := '0';
signal sDATA  : std_logic_vector(7 downto 0);

--signal clock24M : std_logic := '0';

--signal NOR32_1, OR32_1_sig, NOR32_2, OR32_2_sig : std_logic;

	type my_state is (s0,s1);
	signal state, next_state: my_state;
	
	signal clk200k_int_i, clk200k_int : STD_LOGIC;

	signal count : integer range 0 to 120 := 0;

signal s_config_vector_1 : std_logic_vector(1143 downto 0);
signal s_config_vector_2 : std_logic_vector(1143 downto 0);

signal conf_comm_200k_1, conf_comm_200k_2 : std_logic;

signal holdSignal_1 : std_logic;
signal holdSignal_2 : std_logic;
signal holdDelayVal_1 : std_logic_vector(7 downto 0);
signal holdDelayVal_2 : std_logic_vector(7 downto 0);

signal acquisition_state_sig : std_logic;
signal calibration_state_sig : std_logic;
signal start_readers_sig     : std_logic;

signal rise_test : std_logic;

begin

clk <= clock96M;

rstOUT <= rst;

s_config_vector_1 <= config_vector_1;
s_config_vector_2 <= config_vector_2;

triggerOUT <= trigger_interno_sig;

PMT_rate <= s_PMT_rate;
--mask_rate <= s_mask_rate;

calibration_state <= calibration_state_sig;
acquisition_state <= acquisition_state_sig;

config_status_1 <= idle_1_sig;
config_status_2 <= idle_2_sig;

readers_status_1 <=  start_readers_sig and idle_1_sig;
readers_status_2 <=  start_readers_sig and idle_2_sig;

pulseExpand_inst1: pulseExpand
  port map (
    clkOrig  => clk,
    clkDest  => clk200k_sig,
    rst      => rst,
    pulseIN  => configure_command_1,
    pulseOUT => conf_comm_200k_1);

pulseExpand_inst2: pulseExpand
  port map (
    clkOrig  => clk,
    clkDest  => clk200k_sig,
    rst      => rst,
    pulseIN  => configure_command_2,
    pulseOUT => conf_comm_200k_2);

--buf_CLK48M: CLKINT
--  
--    port map (
--    
--      Y => clk,     -- Clock buffer output
--      A => clock96M  -- Clock buffer input
--      
--    );

BUFclk200: CLKINT--BUFG
port map (
           Y => clk200k_sig,     -- Clock buffer output
           A => clk200k_int  -- Clock buffer input
          );

SYNC_PROC: process (clock24M,s_global_rst)
   begin
    	if s_global_rst='1' then 
			state<=s0;
			clk200k_int<='0';
		elsif clock24M'event and clock24M='1' then
         state <= next_state;
			clk200k_int <= clk200k_int_i;
      end if;
   end process;
	
OUTPUT_DECODE: process (next_state)
   begin

      if next_state = s1 then
         clk200k_int_i <= '1';
      elsif next_state=s0 then
         clk200k_int_i <= '0';
		else 
			clk200k_int_i<= '0';
		end if;

	end process;

NEXT_STATE_DECODE: process(state,count)
	begin	 
	next_state <= state;
		case state is 
		
			when s0 => 
				--if count=124 then
                if count=60 then
					next_state<= s1;
				else 
					next_state <= s0;
				end if;
			
			 when s1 => 
				--if count=249 then
                if count=120 then
					next_state<= s0;
				else 
					next_state <= s1;
				end if;
				
			when others =>
				next_state <= s0;
				
		end case;
	end process;

-- contatore durata segnale

process (clock24M, s_global_rst) -- usa come clock lo stesso clock usato dalla memoria e per la configurazione della easiroc
begin
   if s_global_rst = '1' then 
      count <= 0;
   elsif (clock24M = '1' and clock24M'event) then
		if count = 120 then
			count <= 0;
		else
			count <= count + 1;
		end if;
	end if;
end process;

  BIBUF_instance: BIBUF
    port map ( 
    
      D   => '0',
      E   => '1',
      PAD => led,
      Y   => rst
      
    );
        
  power_on_reset_process: process(clk, rst)
	begin
			if (rst = '1') then
            r_rst_n_0 <= '0';
			r_rst_n_1 <= '0';
			r_rst_n_2 <= '0';
			r_rst_n_3 <= '0';
			elsif ( clk'event and clk = '1' ) then
            r_rst_n_0 <= '1';
			r_rst_n_1 <= r_rst_n_0;
			r_rst_n_2 <= r_rst_n_1;
			r_rst_n_3 <= r_rst_n_2;			
      
		end if;
			end process;	

  -- global reset signal assignment (active high)
  s_rst         <= (not r_rst_n_3); -- or s_sw_rst 

  global_reset_buffer_instance: CLKINT
    port map(
          A => s_rst,
      Y => s_global_rst
        );


--uscita_test <= data_out or controllo1 or controllo2 or trigger_flag_1(31) or trigger_flag_1(1) or trigger_flag_1(26) or s_pmt_rate(26) or trigger_flag_2(26) or debug or s_pmt_rate(226) or s_pmt_rate(1226) or 
--                s_pmt_rate(1216) or s_pmt_rate(2) or s_pmt_rate(2000) or s_pmt_rate(216) or s_pmt_rate(232) or s_pmt_rate(22) or LG_data_1_sig(1) or LG_data_2_sig(1) or trigger_int_sig;

uscita_test <= data_out or controllo1 or controllo2 or trigger_flag_1(31) or trigger_flag_1(1) or trigger_flag_1(26) or trigger_flag_2(26) or debug or
                LG_data_1_sig(1) or LG_data_2_sig(1) or trigger_int_sig;


test_2 <= rise_test;--trigger_interno_sig;--trigger_int_sig

holdDelay_1_inst: delayLine
    Generic map(
        ffNum => 14
        )
    Port map(
        signalIN  => hold_1_sig,
        signalOUT => holdSignal_1,
        delayVal  => holdDelayVal_1(3 downto 0),
        clk  => clk,
        rst => rst
        );

u1_CONFIG1: config_CITIROC_1
	port map(  
                clock  => clk,--clock,
                reset => rst,
				
				clk200k => clk200k_sig,
				configure_command => conf_comm_200k_1, 
                config_vector => s_config_vector_1,
				
                holdDelayIN  => holdDelay_1,
                holdDelayOUT => holdDelayVal_1,

				CLK_SR_reg_out => open, --LED3
                idle => idle_1_sig,
                load => load_1,
				
				select_reg => select_reg_1 ,
				
				SR_IN_SR  =>    SR_IN_SR_1  , 
				RST_B_SR    =>  RST_B_SR_1  , 
				CLK_SR      => CLK_SR_1  
				);

holdDelay_2_inst: delayLine
    Generic map(
        ffNum => 14
        )
    Port map(
        signalIN  => hold_2_sig,
        signalOUT => holdSignal_2,
        delayVal  => holdDelayVal_2(3 downto 0),
        clk  => clk,
        rst => rst
        );

u2_CONFIG2: config_CITIROC_2 
	port map(  
                clock  => clk,--clock,
                reset => rst,
				
				clk200k => clk200k_sig,
				configure_command => conf_comm_200k_2, 
                config_vector => s_config_vector_2,
				
                holdDelayIN  => holdDelay_2,
                holdDelayOUT => holdDelayVal_2,

				CLK_SR_reg_out => open, --LED3
                idle => idle_2_sig,
                load => load_2,

				
				select_reg => select_reg_2 ,
				
				SR_IN_SR  =>    SR_IN_SR_2  , 
				RST_B_SR    =>  RST_B_SR_2  , 
				CLK_SR      => CLK_SR_2  
				);

u3: READ_FSM
port map(
                clock  => clk,
                reset => rst,
				clock200 => clk200k_sig,
                clock24M => clock24M,

                SDATA_hg       => SDATA_hg_1,
                SDATA_lg       => SDATA_lg_1,

                trigger_int => trigger_interno_sig,

                CS             => CS_1,
				SCLK           => SCLK_1_sig,

                HG_data    => HG_data_1_sig,
                LG_data    => LG_data_1_sig,

                hold_B          => hold_1_sig,
				CLK_READ        => CLK_READ_1_sig,
                SR_IN_READ      => SR_IN_READ_1,
				RST_B_READ      => RST_B_READ_1,
                data_ready      => data_ready_1_sig,
                controllo => controllo1
);

u4: READ_FSM
port map(
                clock  => clk,
                reset => rst,
				clock200 => clk200k_sig,
                clock24M => clock24M,

                SDATA_hg       => SDATA_hg_2,
                SDATA_lg       => SDATA_lg_2,

                trigger_int => trigger_interno_sig,

                CS             => CS_2,
				SCLK           => SCLK_2_sig,

                HG_data    => HG_data_2_sig,
                LG_data    => LG_data_2_sig,

                hold_B          => hold_2_sig,
				CLK_READ        => CLK_READ_2_sig,
                SR_IN_READ      => SR_IN_READ_2,
				RST_B_READ      => RST_B_READ_2,
                data_ready      => data_ready_2_sig,
                controllo => controllo2
);

hold_hg_1 <= holdSignal_1;--hold_1_sig;
hold_lg_1 <= holdSignal_1;--hold_1_sig;
hold_hg_2 <= holdSignal_2;--hold_2_sig;
hold_lg_2 <= holdSignal_2;--hold_2_sig;

ACQ_REGISTER: process(clk, rst)
                begin
                   if rst='1' then
                        acquisition_state_sig <= '0';
                   elsif clk'event and clk='1' then
                        if start_ACQ = '1' then
                            acquisition_state_sig <= '1';
                        elsif stop_ACQ = '1' then
                            acquisition_state_sig <= '0';
                        end if;
                   end if;
        end process;

CAL_REGISTER: process(clk, rst)
                begin
                   if rst='1' then
                        calibration_state_sig <= '0';
                   elsif clk'event and clk='1' then
                        if start_cal = '1' then
                            calibration_state_sig <= '1';
                        elsif stop_cal = '1' then
                            calibration_state_sig <= '0';
                        end if;
                   end if;
        end process;

start_readers_sig <= start_readers or acquisition_state_sig or calibration_state_sig;

u5: TRIGGER_logic_FSM 
      port map (
                reset      => rst,
				clock      => clk,
				clock200k  => clk200k_sig,
                debug => trigger_int_sig,
                trigger_in_1   => trigger_in_1,
                trigger_in_2   => trigger_in_2,
                PMT_mask_1     => PMT_mask_1,
                PMT_mask_2     => PMT_mask_2,
                generic_trigger_mask => generic_trigger_mask,
                trigger_mask    => trigger_mask,
                apply_trigger_mask => apply_trigger_mask,
                apply_PMT_mask => apply_PMT_mask,
                start_readers   => start_readers_sig,
 
                calibration_state => calibration_state_sig,
                acquisition_state => acquisition_state_sig,
                SMPL_HOLD_N       => '1',
		
		        --mask_rate       => s_mask_rate,				
		        PMT_rate        => s_PMT_rate,				

                trigger_flag_1  => trigger_flag_1,		
                trigger_flag_2  => trigger_flag_2,			
                trigger_mask_rate => open,

                debug_out => debug,

                test_out => rise_test,

				trg_to_DAQ_EASI => trigger_interno_sig
				);

u6: top_data_transfer 
port map (
      reset   => rst,
      clock     => clk,
      
      HG_data_1  => HG_data_1_sig,
      LG_data_1  => LG_data_1_sig,
      HG_data_2  => HG_data_2_sig,
      LG_data_2  => LG_data_2_sig,
      data_ready  => data_ready_1_sig,
      data_to_daq => (others => '1'),
      iRDY       => '1', -- Ready when DAQ answered to trigger and the internal fifo is not full

      tx          => tx,
      rx          => rx, 
      receivedDATA       => sDATA
);

data_transfer_process: process(sdata)
    begin
        if sDATA = X"31" then 
             data_out <= '1';
        else
             data_out <= '0';
        end if;
    end process;



edge_trigger: process(clk, rst)
            variable resync : std_logic_vector(1 to 3);
                begin
                   if rst='1' then
                        trigger_int_sig <= '0';
                   elsif clk'event and clk='1' then
                        trigger_int_sig <= resync(2) and not resync(3);
                        resync := trigger_or & resync(1 to 2);
                   end if;
        end process;

trigger_or <= debug_triggerIN;--OR32_1 or OR32_2 or data_out or debug_triggerIN; -- lasciare solo debug_triggerIN

--NOR32_1 <= OR32_1_sig;
--NOR32_2 <= OR32_2_sig;

--or1_trigger: process(clk, rst)
            --variable resync : std_logic_vector(1 to 3);
                --begin
                   --if rst='1' then
                        --OR32_1_sig <= '0';
                   --elsif clk'event and clk='1' then
                        --OR32_1_sig <= resync(2) and not resync(3);
                        --resync := OR32_1 & resync(1 to 2);
                   --end if;
        --end process;
--or2_trigger: process(clk, rst)
            --variable resync : std_logic_vector(1 to 3);
                --begin
                   --if rst='1' then
                        --OR32_2_sig <= '0';
                   --elsif clk'event and clk='1' then
                        --OR32_2_sig <= resync(2) and not resync(3);
                        --resync := OR32_2 & resync(1 to 2);
                   --end if;
        --end process;

ODDR_CLK_READ_1: output_DDR
    port MAP( DataR  => '0',
            DataF  => '1',
            CLR    => CLK_READ_1_sig, 
            CLK    => clk200k_sig,
            PAD    => CLK_READ_1
        );

ODDR_CLK_READ_2: output_DDR
    port MAP( DataR  => '0',
            DataF  => '1',
            CLR    => CLK_READ_2_sig, 
            CLK    => clk200k_sig,
            PAD    => CLK_READ_2
        );

ODDR_SCLK_1: output_DDR
  port MAP( DataR  => '0',
            DataF  => '1',
            CLR    => SCLK_1_sig, -- attivo basso
            CLK    => clock24M,--clk,
            PAD    => SCLK_1
        );


ODDR_SCLK_2: output_DDR
  port MAP( DataR  => '0',
            DataF  => '1',
            CLR    => SCLK_2_sig, -- attivo basso
            CLK    => clock24M,--clk,
            PAD    => SCLK_2
        );

    PWR_ON_1  <= '1';
    PWR_ON_2  <= '1';
    VAL_EVT_1  <= '1';
    VAL_EVT_2  <= '1';    
    RAZ_CHN_1  <= '0';
    RAZ_CHN_2  <= '0';

end Behavioral;
