--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: read_FSM.vhd
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity read_FSM is
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
                                                  -- ATTENZIONE: � diverso da EASIROC
				CLK_READ        : out std_logic;  -- attivo sul fronte di salita
                SR_IN_READ      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                                  -- quando SR_IN_READ � alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
				RST_B_READ      : out std_logic;  -- attivo basso 
                                                  -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
                
                data_ready      : out std_logic;
                
                controllo : out std_logic
);
end read_FSM;

architecture Behavioral of read_FSM is

component ADC_lg_hg_FSM is
          port (
                reset           : in std_logic;
				clock           : in std_logic;   -- clock a 200 kHz
				enable_ADC      : in std_logic;
                ext_channels_nr : in std_logic_vector(4 downto 0);
                RST_B_READ      : in std_logic; 

                SDATA_hg        : in std_logic;    -- 2 leading '0' + 12 dati
                SDATA_lg        : in std_logic;    -- 2 leading '0' + 12 dati	
					
				CS              : out std_logic;  -- attivo sul fronte di discesa
				SCLK            : out std_logic;  -- il dato cambia sul fronte di discesa

                hg_data_out         : out std_logic_vector(383 downto 0);
                lg_data_out         : out std_logic_vector(383 downto 0);
                fineconv             : out std_logic;
                adc_data_out_test    : out std_logic
				);
end component;

component READ_CHANNELS_FSM is
          port (
                reset           : in std_logic;
				clock           : in std_logic;   
                clock200        : in std_logic;   -- clock a 200 kHz
				read_command    : in std_logic;
                fineconv       : in std_logic;

                hold_B          : out std_logic;  -- attivo ALTO
                                                  -- ATTENZIONE: � diverso da EASIROC

				CLK_READ        : out std_logic;  -- attivo sul fronte di salita
                SR_IN_READ      : out std_logic;  -- deve andare a '1' per un colpo di clock dopo il reset per avviare l'acquisizione 
                                                  -- quando SR_IN_READ � alto sul fronte di salita di CLK_READ, il primo canale (CH_0) va sull'output
				RST_B_READ      : out std_logic;  -- attivo basso 
                                                  -- deve essere inviato appena hold_B va a '1', prima di iniziare la lettura
                
                data_ready      : out std_logic;
                enable_ADC      : out std_logic;
                ext_channels_nr : out std_logic_vector(4 downto 0)
				);
end component;

signal RST_B_READ_sig, enable_adc_sig, fineconv_sig: std_logic := '0';
signal ext_channels_nr_sig : std_logic_vector(4 downto 0) := (others => '0');

begin

U1: READ_CHANNELS_FSM 
       port map (
                reset => reset,
				clock  => clock, -- ATTENZIONE  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                clock200  => clock200,
				read_command  => trigger_int, --read_easi,

                hold_B    => hold_B,
				CLK_READ    => CLK_READ,
                SR_IN_READ    => SR_IN_READ,
				RST_B_READ    => RST_B_READ_sig,

                data_ready    => data_ready,
                enable_ADC    => enable_ADC_sig,
                ext_channels_nr => ext_channels_nr_sig,
                fineconv=> fineconv_sig
				);

RST_B_READ  <= RST_B_READ_sig;

U2: ADC_lg_hg_FSM 
      port map (
                reset => reset,
				clock => clock24M,
				enable_ADC    => enable_ADC_sig,
                ext_channels_nr  => ext_channels_nr_sig,
                RST_B_READ       => RST_B_READ_sig,

                SDATA_hg        => SDATA_hg,
                SDATA_lg        => SDATA_lg,
				CS              => CS,
				SCLK             => SCLK,

                hg_data_out  => HG_data,
                lg_data_out  => LG_data,
                adc_data_out_test => controllo,
                fineconv=> fineconv_sig
				);



end Behavioral;

