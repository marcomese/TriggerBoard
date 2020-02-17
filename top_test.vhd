library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library proasic3e;
use proasic3e.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.spwpkg.all;

entity top_test is
generic (

sysid           : std_logic_vector(31 downto 0) := x"02020202";
sysfreq         : real := 48.0e6

);
port (
    clock48M       : in std_logic;  -- clk di sistema: 48 MHz
    led            : inout std_logic;  --

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

    PS_global_trig_1 : out std_logic;
    PS_global_trig_2 : out std_logic;

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
    ha_rstb_psc     : out std_logic;    -- reset del peak detector (citiroc A)
    hb_rstb_psc     : out std_logic;    -- reset del peak detector (citiroc B)

    spw_di          : in  std_logic;
    spw_si          : in  std_logic;
    spw_do          : out std_logic;
    spw_so          : out std_logic

);
end top_test;

architecture architecture_top_test of top_test is

signal s_rst             : std_logic;


---------------------------------------------------
-- Segnali per test_file
---------------------------------------------------

signal clock48M_buffered : std_logic;

signal s_clock96M       : std_logic;
signal s_clock24M       : std_logic;
signal s_clock48M       : std_logic;

signal s_select_reg_1   : std_logic;
signal s_SR_IN_SR_1     : std_logic;
signal s_RST_B_SR_1     : std_logic;
signal s_CLK_SR_1       : std_logic;
signal s_load_1         : std_logic;
signal s_select_reg_2   : std_logic;
signal s_SR_IN_SR_2     : std_logic;
signal s_RST_B_SR_2     : std_logic;
signal s_CLK_SR_2       : std_logic;
signal s_load_2         : std_logic;

signal s_uscita_test    : std_logic;
signal s_test_2         : std_logic;

signal s_tx          : std_logic;
signal s_rx          : std_logic;

signal s_PWR_ON_1       : std_logic;
signal s_PWR_ON_2       : std_logic;

signal s_VAL_EVT_1       : std_logic;
signal s_VAL_EVT_2       : std_logic;

signal s_RAZ_CHN_1       : std_logic;
signal s_RAZ_CHN_2       : std_logic;

signal s_trigger_in_1    : std_logic_vector(31 downto 0);
signal s_trigger_in_2    : std_logic_vector(31 downto 0);
signal s_OR32_1          : std_logic;
signal s_OR32_2          : std_logic;

signal s_SDATA_hg_1        : std_logic;
signal s_SDATA_lg_1        : std_logic;
signal s_CS_1              : std_logic;
signal s_SCLK_1            : std_logic;
signal s_hold_hg_1         : std_logic;
signal s_hold_lg_1         : std_logic;

signal s_CLK_READ_1        : std_logic;
signal s_SR_IN_READ_1      : std_logic;

signal s_RST_B_READ_1      : std_logic;

signal s_SDATA_hg_2        : std_logic;
signal s_SDATA_lg_2        : std_logic;
signal s_CS_2              : std_logic;
signal s_SCLK_2            : std_logic;
signal s_hold_hg_2         : std_logic;
signal s_hold_lg_2         : std_logic;

signal s_CLK_READ_2        : std_logic;
signal s_SR_IN_READ_2      : std_logic;

signal s_RST_B_READ_2      : std_logic;

---------------------------------------------------
-- Segnali per cses_reg_file_manager
---------------------------------------------------

signal s_txrdy           : std_logic;
signal s_rxvalid         : std_logic;
signal s_rxflag          : std_logic;
signal s_rxdata          : std_logic_vector(7 downto 0);
signal s_rxread          : std_logic;
signal s_txwrite         : std_logic;
signal s_txflag          : std_logic;
signal s_txdata          : std_logic_vector(7 downto 0);

signal s_we              : std_logic;
signal s_addr            : std_logic_vector(31 downto 0);
signal s_di              : std_logic_vector(31 downto 0);
signal s_do              : std_logic_vector(31 downto 0);

---------------------------------------------------
-- Segnali per register_file
---------------------------------------------------

signal s_trigger_mask          : std_logic_vector(31 downto 0);
signal s_generic_trigger_mask  : std_logic_vector(31 downto 0);
signal s_PMT_mask_1            : std_logic_vector(31 downto 0);
signal s_PMT_mask_2            : std_logic_vector(31 downto 0);

signal s_start_config_1      : std_logic;
signal s_start_config_2      : std_logic;
signal s_start_readers       : std_logic;
signal s_sw_rst              : std_logic;
--signal s_pwr_on_citiroc1     : std_logic;
--signal s_pwr_on_citiroc2     : std_logic;
signal s_start_debug         : std_logic;
signal s_apply_trigger_mask  : std_logic;
signal s_apply_PMT_mask      : std_logic;
signal s_start_ACQ           : std_logic;
signal s_stop_ACQ            : std_logic;
signal s_start_cal           : std_logic;
signal s_stop_cal            : std_logic;
--signal s_iFLG_RST            : std_logic;


signal s_config_status_1   : std_logic;
signal s_reader_status_1   : std_logic;
signal s_config_status_2   : std_logic;
signal s_reader_status_2   : std_logic;
signal s_acquisition_state : std_logic;
signal s_calibration_state : std_logic;
--signal s_DAQ_FIRST_LEVEL_N     : std_logic;
--signal s_DAQ_TRIGGER_N         : std_logic;
--signal s_DAQ_HOLD_N              : std_logic;
--signal s_DAQ_BUSY_N              : std_logic;
--signal s_error_state_ON_INIT    : std_logic;
--signal s_error_state_ON_TRG     : std_logic;
--signal s_RDY              : std_logic;
--signal s_DAQ_OK              : std_logic;

--signal s_PMT_rate              : std_logic_vector(2047 downto 0);
signal s_PMT_rate              : std_logic_vector(575 downto 0);
--signal s_mask_rate             : std_logic_vector(287 downto 0);
--signal s_board_temp            : std_logic_vector(31 downto 0);

signal s_config_vector_1 : std_logic_vector(1143 downto 0);
signal s_config_vector_2 : std_logic_vector(1143 downto 0);

---------------------------------------------------
-- Segnali per spwstream
---------------------------------------------------

signal s_spw_di          : std_logic;
signal s_spw_si          : std_logic;
signal s_spw_do          : std_logic;
signal s_spw_so          : std_logic;
---- debug
signal s_started     : std_logic;
signal s_connecting  : std_logic;
signal s_running     : std_logic;
signal s_errdisc     : std_logic;
signal s_errpar      : std_logic;
signal s_erresc      : std_logic;
signal s_errcred     : std_logic;

signal s_holdDelay_1 : std_logic_vector(7 downto 0);
signal s_holdDelay_2 : std_logic_vector(7 downto 0);

signal trigger_interno_sig : std_logic;

component CLKINT is
port(
        A : in std_logic;
        Y : out std_logic
);
end component;

component pll96MHz is

    port( POWERDOWN : in    std_logic;
          CLKA      : in    std_logic;
          LOCK      : out   std_logic;
          GLA       : out   std_logic;
          GLB       : out   std_logic;
          GLC       : out   std_logic
        );

end component;

component test_file is
port (
    clock96M       : in std_logic;  -- clk di sistema: 48 MHz
    clock24M       : in std_logic;
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
----------
    debug_triggerIN   : in std_logic

);
end component;

component cses_reg_file_manager is

    port (
        clk             : in  std_logic;
        rst             : in  std_logic;

        txrdy           : in  std_logic;
        rxvalid         : in  std_logic;
        rxflag          : in  std_logic;
        rxdata          : in  std_logic_vector(7 downto 0);
        rxread          : out std_logic;
        txwrite         : out std_logic;
        txflag          : out std_logic;
        txdata          : out std_logic_vector(7 downto 0);

        we              : out std_logic;
        addr            : out std_logic_vector(31 downto 0);
        di              : out std_logic_vector(31 downto 0);
        do              : in  std_logic_vector(31 downto 0)
    );
end component;

component register_file is

  generic (

    sysid : std_logic_vector(31 downto 0) := x"00000000"

  );

  port (

    debugOUT : out std_logic;

    clk   : in std_logic;
    rst   : in std_logic;
    we    : in std_logic;
    en    : in std_logic;
    addr  : in std_logic_vector(31 downto 0);
    di    : in std_logic_vector(31 downto 0);
    do    : out std_logic_vector(31 downto 0);

    -- configuration
    config_vector_1         : out std_logic_vector(1143 downto 0);
    config_vector_2         : out std_logic_vector(1143 downto 0);

    holdDelay_1           : out std_logic_vector(7 downto 0);
    holdDelay_2           : out std_logic_vector(7 downto 0);

    trigger_mask          : out std_logic_vector(31 downto 0);
    generic_trigger_mask  : out std_logic_vector(31 downto 0);
    PMT_mask_1            : out std_logic_vector(31 downto 0);
    PMT_mask_2            : out std_logic_vector(31 downto 0);

    -- Commands
    start_config_1      : out std_logic;
    start_config_2      : out std_logic;
    start_readers       : out std_logic;
    sw_rst              : out std_logic;
    pwr_on_citiroc1     : out std_logic;
    pwr_on_citiroc2     : out std_logic;
    start_debug         : out std_logic;
    apply_trigger_mask  : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    apply_PMT_mask      : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    start_ACQ           : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    stop_ACQ            : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    start_cal           : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    stop_cal            : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)
    iFLG_RST            : out std_logic; -- attivo alto (impulso lungo almeno un colpo di clock)

    -- status register
    config_status_1   : in std_logic;
    reader_status_1   : in std_logic;
    config_status_2   : in std_logic;
    reader_status_2   : in std_logic;
    acquisition_state : in std_logic; -- = '1' quando il sistema Ã¨ in acquisizione
    calibration_state : in std_logic; -- = '1' quando il sistema Ã¨ in calibrazione
    DAQ_FIRST_LEVEL_N     : in std_logic; -- = '1' in caso di errore
    DAQ_TRIGGER_N         : in std_logic; -- = '1' in caso di errore
    DAQ_HOLD_N              : in std_logic; -- = '1' in caso di errore
    DAQ_BUSY_N              : in std_logic; -- = '1' in caso di errore
    error_state_ON_INIT    : in std_logic; -- = '1' in caso di errore
    error_state_ON_TRG     : in std_logic; -- = '1' in caso di errore
    RDY              : in std_logic;
    DAQ_OK              : in STD_LOGIC;

    --PMT_rate          : out std_logic_vector(2047 downto 0);
    PMT_rate          : out std_logic_vector(575 downto 0);
    --mask_rate             : in std_logic_vector(287 downto 0);
    board_temp            : in std_logic_vector(31 downto 0)

  );
end component;

component spwstream

generic (

  sysfreq:        real;
  txclkfreq:      real := 0.0;
  rximpl:         spw_implementation_type := impl_generic;
  rxchunk:        integer range 1 to 4 := 1;
  tximpl:         spw_implementation_type := impl_generic;
  rxfifosize_bits: integer range 6 to 14 := 11;
  txfifosize_bits: integer range 2 to 14 := 11

);

port (

  clk:        in  std_logic;
  rxclk:      in  std_logic;
  txclk:      in  std_logic;
  rst:        in  std_logic;
  autostart:  in  std_logic;
  linkstart:  in  std_logic;
  linkdis:    in  std_logic;
  txdivcnt:   in  std_logic_vector(7 downto 0);
  tick_in:    in  std_logic;
  ctrl_in:    in  std_logic_vector(1 downto 0);
  time_in:    in  std_logic_vector(5 downto 0);
  txwrite:    in  std_logic;
  txflag:     in  std_logic;
  txdata:     in  std_logic_vector(7 downto 0);
  txrdy:      out std_logic;
  txhalff:    out std_logic;
  tick_out:   out std_logic;
  ctrl_out:   out std_logic_vector(1 downto 0);
  time_out:   out std_logic_vector(5 downto 0);
  rxvalid:    out std_logic;
  rxhalff:    out std_logic;
  rxflag:     out std_logic;
  rxdata:     out std_logic_vector(7 downto 0);
  rxread:     in  std_logic;
  started:    out std_logic;
  connecting: out std_logic;
  running:    out std_logic;
  errdisc:    out std_logic;
  errpar:     out std_logic;
  erresc:     out std_logic;
  errcred:    out std_logic;
  spw_di:     in  std_logic;
  spw_si:     in  std_logic;
  spw_do:     out std_logic;
  spw_so:     out std_logic
  
);

end component;

begin

PS_global_trig_1 <= trigger_interno_sig;
PS_global_trig_2 <= trigger_interno_sig;

ha_rstb_psc <= not s_rst;
hb_rstb_psc <= not s_rst;

---------------------------------------------------
-- Gli ingressi e le uscite di top_test li 
-- collego ai segnali che vanno a test_file
---------------------------------------------------

select_reg_1 <= s_select_reg_1;
SR_IN_SR_1 <= s_SR_IN_SR_1;
RST_B_SR_1 <= s_RST_B_SR_1;
CLK_SR_1 <= s_CLK_SR_1;
load_1 <= s_load_1;
select_reg_2 <= s_select_reg_2;
SR_IN_SR_2 <= s_SR_IN_SR_2;
RST_B_SR_2 <= s_RST_B_SR_2;
CLK_SR_2 <= s_CLK_SR_2;
load_2 <= s_load_2;

uscita_test <= s_uscita_test or OR32_1 or OR32_2;
test_2 <= s_test_2;

tx <= s_tx;
s_rx <= rx;

PWR_ON_1 <= s_PWR_ON_1;
PWR_ON_2 <= s_PWR_ON_2;

VAL_EVT_1 <= s_VAL_EVT_1;
VAL_EVT_2 <= s_VAL_EVT_2;

RAZ_CHN_1 <= s_RAZ_CHN_1;
RAZ_CHN_2 <= s_RAZ_CHN_2;

s_trigger_in_1 <= trigger_in_1;
s_trigger_in_2 <= trigger_in_2;
s_OR32_1 <= OR32_1;
s_OR32_2 <= OR32_2;

s_SDATA_hg_1 <= SDATA_hg_1;
s_SDATA_lg_1 <= SDATA_lg_1;
CS_1 <= s_CS_1;
SCLK_1 <= s_SCLK_1;
hold_hg_1 <= s_hold_hg_1;
hold_lg_1 <= s_hold_lg_1;

CLK_READ_1 <= s_CLK_READ_1;
SR_IN_READ_1 <= s_SR_IN_READ_1;

RST_B_READ_1 <= s_RST_B_READ_1;

s_SDATA_hg_2 <= SDATA_hg_2;
s_SDATA_lg_2 <= SDATA_lg_2;
CS_2 <= s_CS_2;
SCLK_2 <= s_SCLK_2;
hold_hg_2 <= s_hold_hg_2;
hold_lg_2 <= s_hold_lg_2;

CLK_READ_2 <= s_CLK_READ_2;
SR_IN_READ_2 <= s_SR_IN_READ_2;

RST_B_READ_2 <= s_RST_B_READ_2;

---------------------------------------------------
-- Gli ingressi e le uscite di top_test 
-- legate a spwstream li collego ai segnali 
-- che vanno a spwstream
---------------------------------------------------

s_spw_di <= spw_di;
s_spw_si <= spw_si;
spw_do <= s_spw_do;
spw_so <= s_spw_so;

clk48MBuf: CLKINT
    port map(
        A => clock48M,
        Y => clock48M_buffered
    );

pll96_inst: pll96MHz
    port map( 
            POWERDOWN => '1',
            CLKA      => clock48M_buffered,
            LOCK      => open,
            GLA       => s_clock96M,
            GLB       => s_clock24M,
            GLC       => s_clock48M
        );


inst_test_file: test_file
    port map (
            clock96M => s_clock96M,
            clock24M => s_clock24M,
            led => led,

            rstOUT => s_rst,

            holdDelay_1 => s_holdDelay_1,
            holdDelay_2 => s_holdDelay_2,

            triggerOUT => trigger_interno_sig,

            PMT_mask_1           => s_PMT_mask_1,
            PMT_mask_2           => s_PMT_mask_2,
            generic_trigger_mask => s_generic_trigger_mask,
            trigger_mask         => s_trigger_mask,
            apply_trigger_mask   => s_apply_trigger_mask,
            apply_PMT_mask       => s_apply_PMT_mask,
            start_readers        => s_start_readers,
            start_ACQ            => s_start_ACQ,
            stop_ACQ             => s_stop_ACQ,
            start_cal            => s_start_cal,
            stop_cal             => s_stop_cal,
            acquisition_state    => s_acquisition_state,
            calibration_state    => s_calibration_state,
            PMT_rate => s_PMT_rate,
            --mask_rate => s_mask_rate,
            config_status_1 => s_config_status_1,
            config_status_2 => s_config_status_2,
            readers_status_1 => s_reader_status_1,
            readers_status_2 => s_reader_status_2,
            sw_rst => s_sw_rst,

            select_reg_1 => s_select_reg_1,
            SR_IN_SR_1 => s_SR_IN_SR_1,
            RST_B_SR_1 => s_RST_B_SR_1,
            CLK_SR_1 => s_CLK_SR_1,
            load_1 => s_load_1,
            select_reg_2 => s_select_reg_2,
            SR_IN_SR_2 => s_SR_IN_SR_2,
            RST_B_SR_2 => s_RST_B_SR_2,
            CLK_SR_2 => s_CLK_SR_2,
            load_2 => s_load_2,

            uscita_test => s_uscita_test,
            test_2 => s_test_2,

            config_vector_1 => s_config_vector_1,
            config_vector_2 => s_config_vector_2,
            configure_command_1 => s_start_config_1,
            configure_command_2 => s_start_config_2,

            tx => s_tx,
            rx => s_rx,

            PWR_ON_1 => s_PWR_ON_1,
            PWR_ON_2 => s_PWR_ON_2,

            VAL_EVT_1 => s_VAL_EVT_1,
            VAL_EVT_2 => s_VAL_EVT_2,

            RAZ_CHN_1 => s_RAZ_CHN_1,
            RAZ_CHN_2 => s_RAZ_CHN_2,

            trigger_in_1 => s_trigger_in_1,
            trigger_in_2 => s_trigger_in_2,
            OR32_1 => s_OR32_1,
            OR32_2 => s_OR32_2,

            SDATA_hg_1 => s_SDATA_hg_1,
            SDATA_lg_1 => s_SDATA_lg_1,
            CS_1 => s_CS_1,
            SCLK_1 => s_SCLK_1,
            hold_hg_1 => s_hold_hg_1,
            hold_lg_1 => s_hold_lg_1,

            CLK_READ_1 => s_CLK_READ_1,
            SR_IN_READ_1 => s_SR_IN_READ_1,

            RST_B_READ_1 => s_RST_B_READ_1,

            SDATA_hg_2 => s_SDATA_hg_2,
            SDATA_lg_2 => s_SDATA_lg_2,
            CS_2 => s_CS_2,
            SCLK_2 => s_SCLK_2,
            hold_hg_2 => s_hold_hg_2,
            hold_lg_2 => s_hold_lg_2,

            CLK_READ_2 => s_CLK_READ_2,
            SR_IN_READ_2 => s_SR_IN_READ_2,

            RST_B_READ_2 => s_RST_B_READ_2,

            debug_triggerIN => s_start_debug

);

inst_cses_reg_file_manager: cses_reg_file_manager
    port map (
        clk => s_clock48M,
        rst => s_rst,

        txrdy => s_txrdy,
        rxvalid => s_rxvalid,
        rxflag => s_rxflag,
        rxdata => s_rxdata,
        rxread => s_rxread,
        txwrite => s_txwrite,
        txflag => s_txflag,
        txdata => s_txdata,

        we => s_we,
        addr => s_addr,
        di => s_di,
        do => s_do
    );

inst_register_file: register_file
  generic map (

    sysid => sysid

  )

  port map (

        debugOUT => open,--s_test_2,

        clk => s_clock48M,
        rst => s_rst,
        we => s_we,
        en => '1',
        addr => s_addr,
        di => s_di,
        do => s_do,

        holdDelay_1 => s_holdDelay_1,
        holdDelay_2 => s_holdDelay_2,

        config_vector_1 => s_config_vector_1,
        config_vector_2 => s_config_vector_2,
        trigger_mask => s_trigger_mask,
        generic_trigger_mask => s_generic_trigger_mask,
        PMT_mask_1 => s_PMT_mask_1,
        PMT_mask_2 => s_PMT_mask_2,


        start_config_1 => s_start_config_1,
        start_config_2 => s_start_config_2,
        start_readers => s_start_readers,
        sw_rst => s_sw_rst,
        pwr_on_citiroc1 => open,--s_pwr_on_citiroc1,
        pwr_on_citiroc2 => open,--s_pwr_on_citiroc2,
        start_debug => s_start_debug,
        apply_trigger_mask => s_apply_trigger_mask,
        apply_PMT_mask => s_apply_PMT_mask,
        start_ACQ => s_start_ACQ,
        stop_ACQ => s_stop_ACQ,
        start_cal => s_start_cal,
        stop_cal => s_stop_cal,
        iFLG_RST => open,--s_iFLG_RST,


        config_status_1 => s_config_status_1,
        reader_status_1 => s_reader_status_1,
        config_status_2 => s_config_status_2,
        reader_status_2 => s_reader_status_2,
        acquisition_state => s_acquisition_state,
        calibration_state => s_calibration_state,
        DAQ_FIRST_LEVEL_N => open,--s_DAQ_FIRST_LEVEL_N,
        DAQ_TRIGGER_N => open,--s_DAQ_TRIGGER_N,
        DAQ_HOLD_N => open,--s_DAQ_HOLD_N,
        DAQ_BUSY_N => open,--s_DAQ_BUSY_N,
        error_state_ON_INIT => open,--s_error_state_ON_INIT,
        error_state_ON_TRG => open,--s_error_state_ON_TRG,
        RDY => open,--s_RDY,
        DAQ_OK => open,--s_DAQ_OK,

        PMT_rate => s_PMT_rate,
        --mask_rate => s_mask_rate,
        board_temp => open--s_board_temp

  );

-- spwstream instance
spwstream_inst: spwstream
    generic map (
        sysfreq         => sysfreq,
        txclkfreq       => sysfreq,
        rximpl          => impl_generic,
        rxchunk         => 1,
        tximpl          => impl_generic,
        rxfifosize_bits => 6,
        txfifosize_bits => 6 )
    port map (
        clk         => s_clock48M,
        rxclk       => s_clock48M,
        txclk       => s_clock48M,
        rst         => s_rst,
        autostart   => '0',
        linkstart   => '1',
        linkdis     => '0',
        txdivcnt    => "00011111",
        tick_in     => '0',
        ctrl_in     => (others => '0'),
        time_in     => (others => '0'),
        txwrite     => s_txwrite,
        txflag      => s_txflag,
        txdata      => s_txdata,
        txrdy       => s_txrdy,
        txhalff     => open,
        tick_out    => open,
        ctrl_out    => open,
        time_out    => open,
        rxvalid     => s_rxvalid,
        rxhalff     => open,
        rxflag      => s_rxflag,
        rxdata      => s_rxdata,
        rxread      => s_rxread,
        started     => s_started,
        connecting  => s_connecting,
        running     => s_running,
        errdisc     => s_errdisc,
        errpar      => s_errpar,
        erresc      => s_erresc,
        errcred     => s_errcred,
        spw_di      => s_spw_di,
        spw_si      => s_spw_si,
        spw_do      => s_spw_do,
        spw_so      => s_spw_so );

end architecture_top_test;
