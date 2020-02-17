-------------------------------------------------------------------------------
--
-- register_file
--
-- This module implement a register file.
--
-- @file: register_file.vhd
-- $Author: Filippo Giuliani NEAT S.r.l.
-- $Revision:$
-- $Date: 12/01/2015
--
-- History:
--
--  Version  Date        Author         Change Description
--
-- -  x.y.z   dd/mm/aaaa  NEAT S.r.l.    Release Alpha
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Library
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------

entity register_file is

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
    
    --PMT_rate              : in std_logic_vector(2047 downto 0);
    PMT_rate              : in std_logic_vector(575 downto 0);
    --mask_rate             : in std_logic_vector(287 downto 0);
    board_temp            : in std_logic_vector(31 downto 0)
      
  );
      
end register_file;

-------------------------------------------------------------------------------
-- Architecture Declaration
-------------------------------------------------------------------------------

architecture Behavioral of register_file is

-------------------------------------------------------------------------------
-- Type and constant Declaration
-------------------------------------------------------------------------------

    constant DATA_LENGHT        : integer := 32;
    constant ADDR_LENGHT        : integer := 32;

    -- define the memory array
    type mem_t is array (natural range <>) of std_logic_vector(DATA_LENGHT - 1 downto 0);

    -- define the register mode: RW = read/write, RO = read only
    type register_mode_t is (RW, RO);
    
    -- define the base type for the address vector that store the address map table
    type addr_t is 
        record
            addr : std_logic_vector(ADDR_LENGHT - 1 downto 0);
            mode : register_mode_t;
        end record;

    -- define the type for the address vector that store the address map table
    type addr_vector_t is array (natural range <>) of addr_t;
	
    -- control registers
    constant ID_REG_ADDR                  : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000000";
    constant CLK_REG_ADDR                 : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000001";
    constant RW_REG_ADDR                  : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000002";
    constant STATUS_REG_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000003";
    constant CMD_REG_ADDR                 : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000004";
    
    -- citiroc 1 configuration registers
    constant CONFIG_CITIROC_1_0_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000005";
    constant CONFIG_CITIROC_1_1_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000006";
    constant CONFIG_CITIROC_1_2_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000007";
    constant CONFIG_CITIROC_1_3_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000008";
    constant CONFIG_CITIROC_1_4_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000009";
    constant CONFIG_CITIROC_1_5_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000A";
    constant CONFIG_CITIROC_1_6_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000B";
    constant CONFIG_CITIROC_1_7_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000C";
    constant CONFIG_CITIROC_1_8_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000D";
    constant CONFIG_CITIROC_1_9_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000E";
    constant CONFIG_CITIROC_1_10_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000000F";
    constant CONFIG_CITIROC_1_11_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000010";
    constant CONFIG_CITIROC_1_12_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000011";
    constant CONFIG_CITIROC_1_13_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000012";
    constant CONFIG_CITIROC_1_14_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000013";
-- registri aggiuntivi per completare i 1144 bit di configurazione necessari per il citiroc1 (1144/32]=36 registri da 32bit)
    constant CONFIG_CITIROC_1_15_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000014";
    constant CONFIG_CITIROC_1_16_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000015";
    constant CONFIG_CITIROC_1_17_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000016";
    constant CONFIG_CITIROC_1_18_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000017";
    constant CONFIG_CITIROC_1_19_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000018";
    constant CONFIG_CITIROC_1_20_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000019";
    constant CONFIG_CITIROC_1_21_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001A";
    constant CONFIG_CITIROC_1_22_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001B";
    constant CONFIG_CITIROC_1_23_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001C";
    constant CONFIG_CITIROC_1_24_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001D";
    constant CONFIG_CITIROC_1_25_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001E";
    constant CONFIG_CITIROC_1_26_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000001F";
    constant CONFIG_CITIROC_1_27_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000020";
    constant CONFIG_CITIROC_1_28_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000021";
    constant CONFIG_CITIROC_1_29_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000022";
    constant CONFIG_CITIROC_1_30_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000023";
    constant CONFIG_CITIROC_1_31_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000024";
    constant CONFIG_CITIROC_1_32_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000025";
    constant CONFIG_CITIROC_1_33_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000026";
    constant CONFIG_CITIROC_1_34_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000027";
    constant CONFIG_CITIROC_1_35_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000028";

    -- citiroc 2 configuration registers
    constant CONFIG_CITIROC_2_0_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000029";
    constant CONFIG_CITIROC_2_1_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002A";
    constant CONFIG_CITIROC_2_2_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002B";
    constant CONFIG_CITIROC_2_3_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002C";
    constant CONFIG_CITIROC_2_4_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002D";
    constant CONFIG_CITIROC_2_5_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000002E";
    constant CONFIG_CITIROC_2_6_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003F";
    constant CONFIG_CITIROC_2_7_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000030";
    constant CONFIG_CITIROC_2_8_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000031";
    constant CONFIG_CITIROC_2_9_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000032";
    constant CONFIG_CITIROC_2_10_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000033";
    constant CONFIG_CITIROC_2_11_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000034";
    constant CONFIG_CITIROC_2_12_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000035";
    constant CONFIG_CITIROC_2_13_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000036";
    constant CONFIG_CITIROC_2_14_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000037";
-- registri aggiuntivi per completare i 1144 bit di configurazione necessari per il citiroc2 (1144/32]=36 registri da 32bit)
    constant CONFIG_CITIROC_2_15_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000038";
    constant CONFIG_CITIROC_2_16_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000039";
    constant CONFIG_CITIROC_2_17_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003A";
    constant CONFIG_CITIROC_2_18_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003B";
    constant CONFIG_CITIROC_2_19_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003C";
    constant CONFIG_CITIROC_2_20_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003D";
    constant CONFIG_CITIROC_2_21_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003E";
    constant CONFIG_CITIROC_2_22_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000003F";
    constant CONFIG_CITIROC_2_23_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000040";
    constant CONFIG_CITIROC_2_24_ADDR      : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000041";
    constant CONFIG_CITIROC_2_25_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000042";
    constant CONFIG_CITIROC_2_26_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000043";
    constant CONFIG_CITIROC_2_27_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000044";
    constant CONFIG_CITIROC_2_28_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000045";
    constant CONFIG_CITIROC_2_29_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000046";
    constant CONFIG_CITIROC_2_30_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000047";
    constant CONFIG_CITIROC_2_31_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000048";
    constant CONFIG_CITIROC_2_32_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000049";
    constant CONFIG_CITIROC_2_33_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000004A";
    constant CONFIG_CITIROC_2_34_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000004B";
    constant CONFIG_CITIROC_2_35_ADDR     : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000004C";

    -- trigger mask registers 
    constant TRIGGER_MASK_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000100";
    constant GENERIC_TRIGGER_MASK_ADDR    : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000101";
    constant PMT_1_MASK_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000102";
    constant PMT_2_MASK_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000103";
    constant CAL_FREQ_ADDR                : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000104";
    
    -- temperature sensors registers 
    constant BOARD_TEMP_ADDR              : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000200";
    
    -- PMT rate meter registers 
    constant PMT_RATE_00_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000300";
    constant PMT_RATE_01_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000301";
    constant PMT_RATE_02_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000302";
    constant PMT_RATE_03_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000303";
    constant PMT_RATE_04_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000304";
    constant PMT_RATE_05_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000305";
    constant PMT_RATE_06_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000306";
    constant PMT_RATE_07_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000307";
    constant PMT_RATE_08_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000308";
    constant PMT_RATE_09_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000309";
    constant PMT_RATE_10_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030A";
    constant PMT_RATE_11_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030B";
    constant PMT_RATE_12_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030C";
    constant PMT_RATE_13_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030D";
    constant PMT_RATE_14_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030E";
    constant PMT_RATE_15_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000030F";
    constant PMT_RATE_16_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000310";
    constant PMT_RATE_17_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000311";
    --constant PMT_RATE_18_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000312";
    --constant PMT_RATE_19_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000313";
    --constant PMT_RATE_20_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000314";
    --constant PMT_RATE_21_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000315";
    --constant PMT_RATE_22_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000316";
    --constant PMT_RATE_23_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000317";
    --constant PMT_RATE_24_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000318";
    --constant PMT_RATE_25_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000319";
    --constant PMT_RATE_26_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031A";
    --constant PMT_RATE_27_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031B";
    --constant PMT_RATE_28_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031C";
    --constant PMT_RATE_29_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031D";
    --constant PMT_RATE_30_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031E";
    --constant PMT_RATE_31_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000031F";
    --constant PMT_RATE_32_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000320";
    --constant PMT_RATE_33_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000321";
    --constant PMT_RATE_34_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000322";
    --constant PMT_RATE_35_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000323";
    --constant PMT_RATE_36_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000324";
    --constant PMT_RATE_37_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000325";
    --constant PMT_RATE_38_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000326";
    --constant PMT_RATE_39_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000327";
    --constant PMT_RATE_40_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000328";
    --constant PMT_RATE_41_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000329";
    --constant PMT_RATE_42_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032A";
    --constant PMT_RATE_43_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032B";
    --constant PMT_RATE_44_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032C";
    --constant PMT_RATE_45_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032D";
    --constant PMT_RATE_46_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032E";
    --constant PMT_RATE_47_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000032F";
    --constant PMT_RATE_48_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000330";
    --constant PMT_RATE_49_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000331";
    --constant PMT_RATE_50_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000332";
    --constant PMT_RATE_51_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000333";
    --constant PMT_RATE_52_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000334";
    --constant PMT_RATE_53_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000335";
    --constant PMT_RATE_54_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000336";
    --constant PMT_RATE_55_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000337";
    --constant PMT_RATE_56_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000338";
    --constant PMT_RATE_57_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000339";
    --constant PMT_RATE_58_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033A";
    --constant PMT_RATE_59_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033B";
    --constant PMT_RATE_60_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033C";
    --constant PMT_RATE_61_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033D";
    --constant PMT_RATE_62_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033E";
    --constant PMT_RATE_63_ADDR             : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"0000033F";
    
    -- mask rate registers 
    --constant MASK_RATE_00_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000400";
    --constant MASK_RATE_01_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000401";
    --constant MASK_RATE_02_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000402";
    --constant MASK_RATE_03_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000403";
    --constant MASK_RATE_04_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000404";
    --constant MASK_RATE_05_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000405";
    --constant MASK_RATE_06_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000406";
    --constant MASK_RATE_07_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000407";
    --constant MASK_RATE_08_ADDR            : std_logic_vector(ADDR_LENGHT - 1 downto 0) := x"00000408";
    
	
    -- define the length of the REGISTER_FILE
-- aumento la dimensione di questa costante per tener conto dei nuovi 42 registri che ho aggiunto (114+42=156)
-- aggiungo un altro registro per PMT_RATE_63
    --constant REGISTER_FILE_LENGTH    : integer := 157;
    constant REGISTER_FILE_LENGTH    : integer := 102;
	
    -- define the map of the address this is used to get the local address of the register
    constant address_vector : addr_vector_t(0 to REGISTER_FILE_LENGTH - 1) :=
    (
        -- control registers
        (addr => ID_REG_ADDR,               mode => RO),
        (addr => CLK_REG_ADDR,              mode => RO),
        (addr => RW_REG_ADDR,               mode => RW),
        (addr => STATUS_REG_ADDR,           mode => RO),
        (addr => CMD_REG_ADDR,              mode => RW),
-- modifico la mappatura degli indirizzi per tener conto dei nuovi registri
        -- citiroc 1 configuration registers
        (addr => CONFIG_CITIROC_1_0_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_1_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_2_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_3_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_4_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_5_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_6_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_7_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_8_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_9_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_10_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_11_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_12_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_13_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_14_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_15_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_16_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_17_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_18_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_19_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_20_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_21_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_22_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_23_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_24_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_25_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_26_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_27_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_28_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_29_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_1_30_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_31_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_32_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_33_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_34_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_1_35_ADDR,   mode => RW),
    
        -- citiroc 2 configuration registers  
        (addr => CONFIG_CITIROC_2_0_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_1_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_2_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_3_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_4_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_5_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_6_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_7_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_8_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_9_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_10_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_11_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_12_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_13_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_14_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_15_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_16_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_17_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_18_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_19_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_20_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_21_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_22_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_23_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_24_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_25_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_26_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_27_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_28_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_29_ADDR,  mode => RW),
        (addr => CONFIG_CITIROC_2_30_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_31_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_32_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_33_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_34_ADDR,   mode => RW),
        (addr => CONFIG_CITIROC_2_35_ADDR,   mode => RW), 
    
        -- trigger mask registers  
        (addr => TRIGGER_MASK_ADDR,         mode => RW),         
        (addr => GENERIC_TRIGGER_MASK_ADDR, mode => RW),     
        (addr => PMT_1_MASK_ADDR,           mode => RW),    
        (addr => PMT_2_MASK_ADDR,           mode => RW),    
        (addr => CAL_FREQ_ADDR,             mode => RW), 

        -- temperature sensors registers         
        (addr => BOARD_TEMP_ADDR,           mode => RO), 
    
        -- PMT rate meter registers           
        (addr => PMT_RATE_00_ADDR,          mode => RO),   
        (addr => PMT_RATE_01_ADDR,          mode => RO),   
        (addr => PMT_RATE_02_ADDR,          mode => RO),   
        (addr => PMT_RATE_03_ADDR,          mode => RO),   
        (addr => PMT_RATE_04_ADDR,          mode => RO),   
        (addr => PMT_RATE_05_ADDR,          mode => RO),   
        (addr => PMT_RATE_06_ADDR,          mode => RO),   
        (addr => PMT_RATE_07_ADDR,          mode => RO),   
        (addr => PMT_RATE_08_ADDR,          mode => RO),   
        (addr => PMT_RATE_09_ADDR,          mode => RO),   
        (addr => PMT_RATE_10_ADDR,          mode => RO),   
        (addr => PMT_RATE_11_ADDR,          mode => RO),   
        (addr => PMT_RATE_12_ADDR,          mode => RO),   
        (addr => PMT_RATE_13_ADDR,          mode => RO),   
        (addr => PMT_RATE_14_ADDR,          mode => RO),   
        (addr => PMT_RATE_15_ADDR,          mode => RO),   
        (addr => PMT_RATE_16_ADDR,          mode => RO),   
        (addr => PMT_RATE_17_ADDR,          mode => RO),   
        --(addr => PMT_RATE_18_ADDR,          mode => RO),   
        --(addr => PMT_RATE_19_ADDR,          mode => RO),   
        --(addr => PMT_RATE_20_ADDR,          mode => RO),   
        --(addr => PMT_RATE_21_ADDR,          mode => RO),   
        --(addr => PMT_RATE_22_ADDR,          mode => RO),   
        --(addr => PMT_RATE_23_ADDR,          mode => RO),   
        --(addr => PMT_RATE_24_ADDR,          mode => RO),   
        --(addr => PMT_RATE_25_ADDR,          mode => RO),   
        --(addr => PMT_RATE_26_ADDR,          mode => RO),   
        --(addr => PMT_RATE_27_ADDR,          mode => RO),   
        --(addr => PMT_RATE_28_ADDR,          mode => RO),   
        --(addr => PMT_RATE_29_ADDR,          mode => RO),   
        --(addr => PMT_RATE_30_ADDR,          mode => RO),   
        --(addr => PMT_RATE_31_ADDR,          mode => RO),   
        --(addr => PMT_RATE_32_ADDR,          mode => RO),   
        --(addr => PMT_RATE_33_ADDR,          mode => RO),   
        --(addr => PMT_RATE_34_ADDR,          mode => RO),   
        --(addr => PMT_RATE_35_ADDR,          mode => RO),   
        --(addr => PMT_RATE_36_ADDR,          mode => RO),   
        --(addr => PMT_RATE_37_ADDR,          mode => RO),   
        --(addr => PMT_RATE_38_ADDR,          mode => RO),   
        --(addr => PMT_RATE_39_ADDR,          mode => RO),   
        --(addr => PMT_RATE_40_ADDR,          mode => RO),   
        --(addr => PMT_RATE_41_ADDR,          mode => RO),   
        --(addr => PMT_RATE_42_ADDR,          mode => RO),   
        --(addr => PMT_RATE_43_ADDR,          mode => RO),   
        --(addr => PMT_RATE_44_ADDR,          mode => RO),   
        --(addr => PMT_RATE_45_ADDR,          mode => RO),   
        --(addr => PMT_RATE_46_ADDR,          mode => RO),   
        --(addr => PMT_RATE_47_ADDR,          mode => RO),   
        --(addr => PMT_RATE_48_ADDR,          mode => RO),   
        --(addr => PMT_RATE_49_ADDR,          mode => RO),   
        --(addr => PMT_RATE_50_ADDR,          mode => RO),   
        --(addr => PMT_RATE_51_ADDR,          mode => RO),   
        --(addr => PMT_RATE_52_ADDR,          mode => RO),   
        --(addr => PMT_RATE_53_ADDR,          mode => RO),   
        --(addr => PMT_RATE_54_ADDR,          mode => RO),   
        --(addr => PMT_RATE_55_ADDR,          mode => RO),   
        --(addr => PMT_RATE_56_ADDR,          mode => RO),   
        --(addr => PMT_RATE_57_ADDR,          mode => RO),   
        --(addr => PMT_RATE_58_ADDR,          mode => RO),   
        --(addr => PMT_RATE_59_ADDR,          mode => RO),   
        --(addr => PMT_RATE_60_ADDR,          mode => RO),   
        --(addr => PMT_RATE_61_ADDR,          mode => RO),   
        --(addr => PMT_RATE_62_ADDR,          mode => RO),
        --(addr => PMT_RATE_63_ADDR,          mode => RO),
    
        -- mask rate registers         
        --(addr => MASK_RATE_00_ADDR,        mode => RO),   
        --(addr => MASK_RATE_01_ADDR,        mode => RO),   
        --(addr => MASK_RATE_02_ADDR,        mode => RO),   
        --(addr => MASK_RATE_03_ADDR,        mode => RO),   
        --(addr => MASK_RATE_04_ADDR,        mode => RO),   
        --(addr => MASK_RATE_05_ADDR,        mode => RO),   
        --(addr => MASK_RATE_06_ADDR,        mode => RO),   
        --(addr => MASK_RATE_07_ADDR,        mode => RO),   
        --(addr => MASK_RATE_08_ADDR,        mode => RO),   
        (addr => x"00000000",              mode => RO)  -- defensive
    );
    
    constant register_vector_reset : mem_t(0 to REGISTER_FILE_LENGTH - 1) :=
    (
        -- control registers
        sysid,        -- ID_REG_ADDR
        x"00000000",  -- CLK_REG_ADDR
        x"A5A5A5A5",  -- RW_REG_ADDR                 
        x"00000000",  -- STATUS_REG_ADDR             
        x"00000000",  -- CMD_REG_ADDR 
 -- modifico la configurazione iniziale dei registri per renderla compatibile con i valori iniziali da impostare sui citiroc
        -- citiroc 1 configuration registers  
        x"31CD563B",  -- CONFIG_CITIROC_1_0_ADDR     (DAC_code_1(4 downto 0) | DAC_code_2(9 downto 0) -> EN_32_trigg)
        x"00000BE7",  -- CONFIG_CITIROC_1_1_ADDR     (PreAMP_config30(12 downto 0) | PreAMP_config31(14 downto 0) | Temp -> DAC_code_1(9 downto 5))
        x"00000000",  -- CONFIG_CITIROC_1_2_ADDR     (PreAMP_config28(15 downto 0) -> PreAMP_config30(14 downto 13))
        x"00000000",  -- CONFIG_CITIROC_1_3_ADDR     (PreAMP_config25(1 downto 0) -> PreAMP_config27(14 downto 0)) 
        x"00000000",  -- CONFIG_CITIROC_1_4_ADDR     (PreAMP_config23(3 downto 0) -> PreAMP_config25(14 downto 2))
        x"00000000",  -- CONFIG_CITIROC_1_5_ADDR     (PreAMP_config21(5 downto 0) -> PreAMP_config23(14 downto 4))
        x"00000000",  -- CONFIG_CITIROC_1_6_ADDR     (PreAMP_config19(7 downto 0) -> PreAMP_config21(14 downto 6))
        x"00000000",  -- CONFIG_CITIROC_1_7_ADDR     (PreAMP_config17(9 downto 0) -> PreAMP_config19(14 downto 8))
        x"00000000",  -- CONFIG_CITIROC_1_8_ADDR     (PreAMP_config15(11 downto 0) -> PreAMP_config17(14 downto 10))
        x"00000000",  -- CONFIG_CITIROC_1_9_ADDR     (PreAMP_config13(13 downto 0) -> PreAMP_config15(14 downto 12))     
        x"00000000",  -- CONFIG_CITIROC_1_10_ADDR    (PreAMP_config10(0) -> PreAMP_config13(14))
        x"00000000",  -- CONFIG_CITIROC_1_11_ADDR    (PreAMP_config08(2 downto 0) -> PreAMP_config10(14 downto 1)) 
        x"00000000",  -- CONFIG_CITIROC_1_12_ADDR    (PreAMP_config06(4 downto 0) -> PreAMP_config08(14 downto 3))
        x"00000000",  -- CONFIG_CITIROC_1_13_ADDR    (PreAMP_config04(6 downto 0) -> PreAMP_config06(14 downto 5))
        x"00000000",  -- CONFIG_CITIROC_1_14_ADDR    (PreAMP_config02(8 downto 0) -> PreAMP_config04(14 downto 7))
        x"00000000",  -- CONFIG_CITIROC_1_15_ADDR    (PreAMP_config00(10 downto 0) -> PreAMP_config02(14 downto 9))
        x"00000000",  -- CONFIG_CITIROC_1_16_ADDR    (DAC28_in(0) -> DAC31_in(8 downto 0) | PreAMP_config00(14 downto 11))
        x"00000000",  -- CONFIG_CITIROC_1_17_ADDR    (DAC26_in(5 downto 0) -> DAC28_in(8 downto 1))
        x"00000000",  -- CONFIG_CITIROC_1_18_ADDR    (DAC22_in(1 downto 0) -> DAC26_in(8 downto 6))
        x"00000000",  -- CONFIG_CITIROC_1_19_ADDR    (DAC19_in(6 downto 0) -> DAC22_in(8 downto 2))
        x"00000000",  -- CONFIG_CITIROC_1_20_ADDR    (DAC15_in(2 downto 0) -> DAC19_in(8 downto 7))
        x"00000000",  -- CONFIG_CITIROC_1_21_ADDR    (DAC12_in(7 downto 0) -> DAC15_in(8 downto 3))
        x"00000000",  -- CONFIG_CITIROC_1_22_ADDR    (DAC08_in(3 downto 0) -> DAC12_in(8))
        x"00000000",  -- CONFIG_CITIROC_1_23_ADDR    (DAC05_in(8 downto 0) -> DAC08_in(8 downto 4))
        x"00000000",  -- CONFIG_CITIROC_1_24_ADDR    (DAC01_in(4 downto 0) -> DAC04_in(8 downto 0))
        x"630F6000",  -- CONFIG_CITIROC_1_25_ADDR    (Fast_Shaper_PP -> DAC01_in(8 downto 5)
        x"FFFFA839",  -- CONFIG_CITIROC_1_26_ADDR    (discriMask(15 downto 0) | HG_TeH -> EN_Fast_Shaper )
        x"00957FFF",  -- CONFIG_CITIROC_1_27_ADDR    (DAC30 | DAC31 | EN_discri -> discriMask(31 downto 16))
        x"00000000",  -- CONFIG_CITIROC_1_28_ADDR    (DAC22 -> DAC29)
        x"00000000",  -- CONFIG_CITIROC_1_29_ADDR    (DAC14 -> DAC21)
        x"00000000",  -- CONFIG_CITIROC_1_30_ADDR    (DAC06 -> DAC13)
        x"00000000",  -- CONFIG_CITIROC_1_31_ADDR    (DAC30_t -> DAC31_t | DAC00 -> DAC05)
        x"00000000",  -- CONFIG_CITIROC_1_32_ADDR    (DAC22_t -> DAC29_t)
        x"00000000",  -- CONFIG_CITIROC_1_33_ADDR    (DAC14_t -> DAC21_t)
        x"00000000",  -- CONFIG_CITIROC_1_34_ADDR    (DAC06_t -> DAC13_t)
        x"00000000",  -- CONFIG_CITIROC_1_35_ADDR    (DAC00_t -> DAC05_t)  
    
        -- citiroc 2 configuration registers  -- l'ho configurato in modo da avere DAC_code_1 = "0011110000" e DAC_code_2 = "0011110000"
                                              -- così e' possibile riconoscere se viene configurato o meno
        x"31CD563B",  -- CONFIG_CITIROC_2_0_ADDR     (DAC_code_1(4 downto 0) | DAC_code_2(9 downto 0) -> EN_32_trigg)
        x"00000BE7",  -- CONFIG_CITIROC_2_1_ADDR     (PreAMP_config30(12 downto 0) | PreAMP_config31(14 downto 0) | Temp -> DAC_code_1(9 downto 5))
        x"00000000",  -- CONFIG_CITIROC_2_2_ADDR     (PreAMP_config28(15 downto 0) -> PreAMP_config30(14 downto 13))
        x"00000000",  -- CONFIG_CITIROC_2_3_ADDR     (PreAMP_config25(1 downto 0) -> PreAMP_config27(14 downto 0)) 
        x"00000000",  -- CONFIG_CITIROC_2_4_ADDR     (PreAMP_config23(3 downto 0) -> PreAMP_config25(14 downto 2))
        x"00000000",  -- CONFIG_CITIROC_2_5_ADDR     (PreAMP_config21(5 downto 0) -> PreAMP_config23(14 downto 4))
        x"00000000",  -- CONFIG_CITIROC_2_6_ADDR     (PreAMP_config19(7 downto 0) -> PreAMP_config21(14 downto 6))
        x"00000000",  -- CONFIG_CITIROC_2_7_ADDR     (PreAMP_config17(9 downto 0) -> PreAMP_config19(14 downto 8))
        x"00000000",  -- CONFIG_CITIROC_2_8_ADDR     (PreAMP_config15(11 downto 0) -> PreAMP_config17(14 downto 10))
        x"00000000",  -- CONFIG_CITIROC_2_9_ADDR     (PreAMP_config13(13 downto 0) -> PreAMP_config15(14 downto 12))     
        x"00000000",  -- CONFIG_CITIROC_2_10_ADDR    (PreAMP_config10(0) -> PreAMP_config13(14))
        x"00000000",  -- CONFIG_CITIROC_2_11_ADDR    (PreAMP_config08(2 downto 0) -> PreAMP_config10(14 downto 1)) 
        x"00000000",  -- CONFIG_CITIROC_2_12_ADDR    (PreAMP_config06(4 downto 0) -> PreAMP_config08(14 downto 3))
        x"00000000",  -- CONFIG_CITIROC_2_13_ADDR    (PreAMP_config04(6 downto 0) -> PreAMP_config06(14 downto 5))
        x"00000000",  -- CONFIG_CITIROC_2_14_ADDR    (PreAMP_config02(8 downto 0) -> PreAMP_config04(14 downto 7))
        x"00000000",  -- CONFIG_CITIROC_2_15_ADDR    (PreAMP_config00(10 downto 0) -> PreAMP_config02(14 downto 9))
        x"00000000",  -- CONFIG_CITIROC_2_16_ADDR    (DAC28_in(0) -> DAC31_in(8 downto 0) | PreAMP_config00(14 downto 11))
        x"00000000",  -- CONFIG_CITIROC_2_17_ADDR    (DAC26_in(5 downto 0) -> DAC28_in(8 downto 1))
        x"00000000",  -- CONFIG_CITIROC_2_18_ADDR    (DAC22_in(1 downto 0) -> DAC26_in(8 downto 6))
        x"00000000",  -- CONFIG_CITIROC_2_19_ADDR    (DAC19_in(6 downto 0) -> DAC22_in(8 downto 2))
        x"00000000",  -- CONFIG_CITIROC_2_20_ADDR    (DAC15_in(2 downto 0) -> DAC19_in(8 downto 7))
        x"00000000",  -- CONFIG_CITIROC_2_21_ADDR    (DAC12_in(7 downto 0) -> DAC15_in(8 downto 3))
        x"00000000",  -- CONFIG_CITIROC_2_22_ADDR    (DAC08_in(3 downto 0) -> DAC12_in(8))
        x"00000000",  -- CONFIG_CITIROC_2_23_ADDR    (DAC05_in(8 downto 0) -> DAC08_in(8 downto 4))
        x"00000000",  -- CONFIG_CITIROC_2_24_ADDR    (DAC01_in(4 downto 0) -> DAC04_in(8 downto 0))
        x"630F6000",  -- CONFIG_CITIROC_2_25_ADDR    (Fast_Shaper_PP -> DAC01_in(8 downto 5)
        x"FFFFA839",  -- CONFIG_CITIROC_2_26_ADDR    (discriMask(15 downto 0) | HG_TeH -> EN_Fast_Shaper )
        x"00957FFF",  -- CONFIG_CITIROC_2_27_ADDR    (DAC30 | DAC31 | EN_discri -> discriMask(31 downto 16))
        x"00000000",  -- CONFIG_CITIROC_2_28_ADDR    (DAC22 -> DAC29)
        x"00000000",  -- CONFIG_CITIROC_2_29_ADDR    (DAC14 -> DAC21)
        x"00000000",  -- CONFIG_CITIROC_2_30_ADDR    (DAC06 -> DAC13)
        x"00000000",  -- CONFIG_CITIROC_2_31_ADDR    (DAC30_t -> DAC31_t | DAC00 -> DAC05)
        x"00000000",  -- CONFIG_CITIROC_2_32_ADDR    (DAC22_t -> DAC29_t)
        x"00000000",  -- CONFIG_CITIROC_2_33_ADDR    (DAC14_t -> DAC21_t)
        x"00000000",  -- CONFIG_CITIROC_2_34_ADDR    (DAC06_t -> DAC13_t)
        x"00000000",  -- CONFIG_CITIROC_2_35_ADDR    (DAC00_t -> DAC05_t)
        
        -- trigger mask registers  
        x"00000000",  -- TRIGGER_MASK_ADDR            
        x"00000000",  -- GENERIC_TRIGGER_MASK_ADDR    
        x"FFFFFFFF",  -- PMT_1_MASK_ADDR              
        x"FFFFFFFF",  -- PMT_2_MASK_ADDR              
        x"00000001",  -- CAL_FREQ_ADDR     
        
        -- temperature sensors registers     
        x"00000000", --  BOARD_TEMP_ADDR           
    
        -- PMT rate meter registers           
        x"00000000",  -- PMT_RATE_00_ADDR             
        x"00000000",  -- PMT_RATE_01_ADDR             
        x"00000000",  -- PMT_RATE_02_ADDR             
        x"00000000",  -- PMT_RATE_03_ADDR             
        x"00000000",  -- PMT_RATE_04_ADDR             
        x"00000000",  -- PMT_RATE_05_ADDR             
        x"00000000",  -- PMT_RATE_06_ADDR             
        x"00000000",  -- PMT_RATE_07_ADDR             
        x"00000000",  -- PMT_RATE_08_ADDR             
        x"00000000",  -- PMT_RATE_09_ADDR             
        x"00000000",  -- PMT_RATE_10_ADDR             
        x"00000000",  -- PMT_RATE_11_ADDR             
        x"00000000",  -- PMT_RATE_12_ADDR             
        x"00000000",  -- PMT_RATE_13_ADDR             
        x"00000000",  -- PMT_RATE_14_ADDR             
        x"00000000",  -- PMT_RATE_15_ADDR             
        x"00000000",  -- PMT_RATE_16_ADDR             
        x"00000000",  -- PMT_RATE_17_ADDR             
        --x"00000000",  -- PMT_RATE_18_ADDR             
        --x"00000000",  -- PMT_RATE_19_ADDR             
        --x"00000000",  -- PMT_RATE_20_ADDR             
        --x"00000000",  -- PMT_RATE_21_ADDR             
        --x"00000000",  -- PMT_RATE_22_ADDR             
        --x"00000000",  -- PMT_RATE_23_ADDR             
        --x"00000000",  -- PMT_RATE_24_ADDR             
        --x"00000000",  -- PMT_RATE_25_ADDR             
        --x"00000000",  -- PMT_RATE_26_ADDR             
        --x"00000000",  -- PMT_RATE_27_ADDR             
        --x"00000000",  -- PMT_RATE_28_ADDR             
        --x"00000000",  -- PMT_RATE_29_ADDR             
        --x"00000000",  -- PMT_RATE_30_ADDR             
        --x"00000000",  -- PMT_RATE_31_ADDR             
--        x"00000000",  -- PMT_RATE_32_ADDR             
        --x"00000000",  -- PMT_RATE_33_ADDR             
        --x"00000000",  -- PMT_RATE_34_ADDR             
        --x"00000000",  -- PMT_RATE_35_ADDR             
        --x"00000000",  -- PMT_RATE_36_ADDR             
        --x"00000000",  -- PMT_RATE_37_ADDR             
        --x"00000000",  -- PMT_RATE_38_ADDR             
        --x"00000000",  -- PMT_RATE_39_ADDR             
        --x"00000000",  -- PMT_RATE_40_ADDR             
        --x"00000000",  -- PMT_RATE_41_ADDR             
        --x"00000000",  -- PMT_RATE_42_ADDR             
        --x"00000000",  -- PMT_RATE_43_ADDR             
        --x"00000000",  -- PMT_RATE_44_ADDR             
        --x"00000000",  -- PMT_RATE_45_ADDR             
        --x"00000000",  -- PMT_RATE_46_ADDR             
        --x"00000000",  -- PMT_RATE_47_ADDR             
        --x"00000000",  -- PMT_RATE_48_ADDR             
        --x"00000000",  -- PMT_RATE_49_ADDR             
        --x"00000000",  -- PMT_RATE_50_ADDR             
        --x"00000000",  -- PMT_RATE_51_ADDR             
        --x"00000000",  -- PMT_RATE_52_ADDR             
        --x"00000000",  -- PMT_RATE_53_ADDR             
        --x"00000000",  -- PMT_RATE_54_ADDR             
        --x"00000000",  -- PMT_RATE_55_ADDR             
        --x"00000000",  -- PMT_RATE_56_ADDR             
        --x"00000000",  -- PMT_RATE_57_ADDR             
        --x"00000000",  -- PMT_RATE_58_ADDR             
        --x"00000000",  -- PMT_RATE_59_ADDR             
        --x"00000000",  -- PMT_RATE_60_ADDR             
        --x"00000000",  -- PMT_RATE_61_ADDR             
        --x"00000000",  -- PMT_RATE_62_ADDR  
        --x"00000000",  -- PMT_RATE_63_ADDR  
        
        -- mask rate registers         
        --x"00000000",  -- MASK_RATE_00_ADDR            
        --x"00000000",  -- MASK_RATE_01_ADDR            
        --x"00000000",  -- MASK_RATE_02_ADDR            
        --x"00000000",  -- MASK_RATE_03_ADDR            
        --x"00000000",  -- MASK_RATE_04_ADDR            
        --x"00000000",  -- MASK_RATE_05_ADDR            
        --x"00000000",  -- MASK_RATE_06_ADDR            
        --x"00000000",  -- MASK_RATE_07_ADDR            
        --x"00000000",  -- MASK_RATE_08_ADDR            
        x"00000000"
    );
    
-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

    -- register declaration, each register has local address from 0 to REGISTER_FILE_LENGTH - 1. The address_vector map the remote address to local address.
    signal register_vector : mem_t(0 to REGISTER_FILE_LENGTH - 1);

    -- the signal local_address is the conversion of the remote address to local using the address_vector
    signal local_address        : integer;

    signal clk_counter : unsigned(31 downto 0) := (others => '0');
    
    signal start_config_1_pipe_0      : std_logic;
    signal start_config_1_pipe_1      : std_logic;

    signal start_config_2_pipe_0      : std_logic;
    signal start_config_2_pipe_1      : std_logic;

    signal start_debug_pipe_0         : std_logic;
    signal start_debug_pipe_1         : std_logic;
    
    signal apply_trigger_mask_pipe_0  : std_logic;
    signal apply_trigger_mask_pipe_1  : std_logic;
    
    signal apply_PMT_mask_pipe_0      : std_logic;
    signal apply_PMT_mask_pipe_1      : std_logic;
    
    signal start_ACQ_pipe_0           : std_logic;
    signal start_ACQ_pipe_1           : std_logic;
    
    signal stop_ACQ_pipe_0            : std_logic;
    signal stop_ACQ_pipe_1            : std_logic;
    
    signal start_cal_pipe_0           : std_logic;
    signal start_cal_pipe_1           : std_logic;
    
    signal stop_cal_pipe_0            : std_logic;
    signal stop_cal_pipe_1            : std_logic;
    
    signal FLG_RST_pipe_0            : std_logic;
    signal FLG_RST_pipe_1            : std_logic;    

-------------------------------------------------------------------------------
-- Function prototype
-------------------------------------------------------------------------------

    -- the get_local_addr function get the map of the address (address_vector) and convert the input address to an integer address from 0 to memory length
    -- last address shall be an address not mapped for this memory and must be RO it will be returned if the address is not found in the previous address
    function get_local_addr (address : std_logic_vector; address_vector : addr_vector_t) return integer is
    begin
    
        for I in address_vector'range loop
        
            if (address = address_vector(I).addr) then
                return I;
            end if;
        
        end loop;
        
        return address_vector'high; 
    
    end function;
        
begin

    -- configuration
-- aggiungo i registri mancanti
--(23 downto 0) perchè hai in totale 1152 bit (36 registri da 32 bit)
-- ma te ne bastano 1144 quindi dell'ultimo registro prendi solo gli ultimi 24 bit

    holdDelay_1 <= register_vector(get_local_addr(CONFIG_CITIROC_1_35_ADDR, address_vector))(31 downto 24);
    holdDelay_2 <= register_vector(get_local_addr(CONFIG_CITIROC_2_35_ADDR, address_vector))(31 downto 24);

    config_vector_1 <=  register_vector( get_local_addr(CONFIG_CITIROC_1_35_ADDR, address_vector) )(23 downto 0) &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_34_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_33_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_32_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_31_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_30_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_29_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_28_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_27_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_26_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_25_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_24_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_23_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_22_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_21_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_20_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_19_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_18_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_17_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_16_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_15_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_14_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_13_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_12_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_11_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_10_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_9_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_8_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_7_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_6_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_5_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_4_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_3_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_2_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_1_1_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_1_0_ADDR, address_vector) );

    config_vector_2 <=  register_vector( get_local_addr(CONFIG_CITIROC_2_35_ADDR, address_vector) )(23 downto 0) &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_34_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_33_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_32_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_31_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_30_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_29_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_28_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_27_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_26_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_25_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_24_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_23_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_22_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_21_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_20_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_19_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_18_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_17_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_16_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_15_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_14_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_13_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_12_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_11_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_10_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_9_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_8_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_7_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_6_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_5_ADDR, address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_4_ADDR,  address_vector) )             & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_3_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_2_ADDR, address_vector) )              &
                      register_vector( get_local_addr(CONFIG_CITIROC_2_1_ADDR, address_vector) )              & 
                      register_vector( get_local_addr(CONFIG_CITIROC_2_0_ADDR, address_vector) );

    trigger_mask           <= register_vector( get_local_addr(TRIGGER_MASK_ADDR, address_vector) ); 
    generic_trigger_mask   <= register_vector( get_local_addr(GENERIC_TRIGGER_MASK_ADDR, address_vector) ); 
    PMT_mask_1             <= register_vector( get_local_addr(PMT_1_MASK_ADDR, address_vector) ); 
    PMT_mask_2             <= register_vector( get_local_addr(PMT_2_MASK_ADDR, address_vector) ); 
    
    
    -- Commands
    start_config_1      <= start_config_1_pipe_0 and (not start_config_1_pipe_1);
    start_config_2      <= start_config_2_pipe_0 and (not start_config_2_pipe_1); 

    start_readers       <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(2); 
    sw_rst              <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(3); 
    pwr_on_citiroc1     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(4); 
    pwr_on_citiroc2     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(5); 
      
    start_debug         <= start_debug_pipe_0 and (not start_debug_pipe_1);


    apply_trigger_mask  <= apply_trigger_mask_pipe_0 and (not apply_trigger_mask_pipe_1);
    apply_PMT_mask      <= apply_PMT_mask_pipe_0 and (not apply_PMT_mask_pipe_1);
    start_ACQ           <= start_ACQ_pipe_0 and (not start_ACQ_pipe_1);
    stop_ACQ            <= stop_ACQ_pipe_0 and (not stop_ACQ_pipe_1);
    start_cal           <= start_cal_pipe_0 and (not start_cal_pipe_1);
    stop_cal            <= stop_cal_pipe_0 and (not stop_cal_pipe_1);
    
    iFLG_RST            <= FLG_RST_pipe_0 and (not FLG_RST_pipe_1);

    local_address <= get_local_addr(addr, address_vector);
    
    clk_counter_proc : process (clk, rst)
    begin
    
        if (rst = '1') then
            clk_counter <= (others => '0');
        elsif (rising_edge(clk)) then
            clk_counter <= clk_counter + 1;
        end if;
        
    end process clk_counter_proc;
    
    
    read_write_process : process(clk, rst)
    begin
    
        if (rst = '1') then
        
            -- reset to zero
            register_vector <= register_vector_reset;
            
            
            start_config_1_pipe_0     <= '0';
            start_config_1_pipe_1     <= '0';

            start_config_2_pipe_0     <= '0';
            start_config_2_pipe_1     <= '0';
                
            start_debug_pipe_0        <= '0';
            start_debug_pipe_1        <= '0';
            
            apply_trigger_mask_pipe_0 <= '0';
            apply_trigger_mask_pipe_1 <= '0';
            
            apply_PMT_mask_pipe_0     <= '0';
            apply_PMT_mask_pipe_1     <= '0';
            
            start_ACQ_pipe_0          <= '0';
            start_ACQ_pipe_1          <= '0';
            
            stop_ACQ_pipe_0           <= '0';
            stop_ACQ_pipe_1           <= '0';
            
            start_cal_pipe_0          <= '0';
            start_cal_pipe_1          <= '0';
            
            stop_cal_pipe_0           <= '0';
            stop_cal_pipe_1           <= '0';

            FLG_RST_pipe_0           <= '0';
            FLG_RST_pipe_1           <= '0';
            

        elsif (rising_edge(clk)) then
        
            start_config_1_pipe_0   <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(0);
            start_config_1_pipe_1   <= start_config_1_pipe_0;
            
            start_config_2_pipe_0   <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(1);
            start_config_2_pipe_1   <= start_config_2_pipe_0;
            
            start_debug_pipe_0      <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(6);
            start_debug_pipe_1      <= start_debug_pipe_0;
            
            apply_trigger_mask_pipe_0 <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(7);
            apply_trigger_mask_pipe_1 <= apply_trigger_mask_pipe_0;
            
            apply_PMT_mask_pipe_0     <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(8);
            apply_PMT_mask_pipe_1     <= apply_PMT_mask_pipe_0;
            
            start_ACQ_pipe_0          <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(9);
            start_ACQ_pipe_1          <= start_ACQ_pipe_0;
            
            stop_ACQ_pipe_0           <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(10);
            stop_ACQ_pipe_1           <= stop_ACQ_pipe_0;
            
            start_cal_pipe_0          <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(11);
            start_cal_pipe_1          <= start_cal_pipe_0;
            
            stop_cal_pipe_0           <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(12);
            stop_cal_pipe_1           <= stop_cal_pipe_0;
            
            FLG_RST_pipe_0           <= register_vector( get_local_addr(CMD_REG_ADDR, address_vector) )(13);
            FLG_RST_pipe_1           <= FLG_RST_pipe_0;


            do <= register_vector(local_address);

            -- update register vector
            register_vector(get_local_addr(CLK_REG_ADDR, address_vector))     <= std_logic_vector(clk_counter);
            
            register_vector(get_local_addr(STATUS_REG_ADDR, address_vector))  <=  (31 downto 14 => '0')  & -- bits [31:14]
                                                                                  DAQ_OK              & -- bit 13
                                                                                  RDY             & -- bit  12
                                                                                  DAQ_FIRST_LEVEL_N         & -- bit  11
                                                                                  DAQ_TRIGGER_N             & -- bit  10
                                                                                  DAQ_HOLD_N                  & -- bit  9
                                                                                  DAQ_BUSY_N                  & -- bit  8
                                                                                  error_state_ON_TRG    & -- bit  7
                                                                                  error_state_ON_INIT   & -- bit  6
                                                                                  calibration_state     & -- bit  5
                                                                                  acquisition_state     & -- bit  4
                                                                                  reader_status_2       & -- bit  3
                                                                                  config_status_2       & -- bit  2
                                                                                  reader_status_1       & -- bit  1
                                                                                  config_status_1       ; -- bit  0
            

            --register_vector(get_local_addr(PMT_RATE_63_ADDR, address_vector)) <= PMT_rate(2047 downto 2016);
            --register_vector(get_local_addr(PMT_RATE_62_ADDR, address_vector)) <= PMT_rate(2015 downto 1984);
            --register_vector(get_local_addr(PMT_RATE_61_ADDR, address_vector)) <= PMT_rate(1983 downto 1952);
            --register_vector(get_local_addr(PMT_RATE_60_ADDR, address_vector)) <= PMT_rate(1951 downto 1920);
            --register_vector(get_local_addr(PMT_RATE_59_ADDR, address_vector)) <= PMT_rate(1919 downto 1888);
            --register_vector(get_local_addr(PMT_RATE_58_ADDR, address_vector)) <= PMT_rate(1887 downto 1856);
            --register_vector(get_local_addr(PMT_RATE_57_ADDR, address_vector)) <= PMT_rate(1855 downto 1824);
            --register_vector(get_local_addr(PMT_RATE_56_ADDR, address_vector)) <= PMT_rate(1823 downto 1792);
            --register_vector(get_local_addr(PMT_RATE_55_ADDR, address_vector)) <= PMT_rate(1791 downto 1760);
            --register_vector(get_local_addr(PMT_RATE_54_ADDR, address_vector)) <= PMT_rate(1759 downto 1728);
            --register_vector(get_local_addr(PMT_RATE_53_ADDR, address_vector)) <= PMT_rate(1727 downto 1696);
            --register_vector(get_local_addr(PMT_RATE_52_ADDR, address_vector)) <= PMT_rate(1695 downto 1664);
            --register_vector(get_local_addr(PMT_RATE_51_ADDR, address_vector)) <= PMT_rate(1663 downto 1632);
            --register_vector(get_local_addr(PMT_RATE_50_ADDR, address_vector)) <= PMT_rate(1631 downto 1600);
            --register_vector(get_local_addr(PMT_RATE_49_ADDR, address_vector)) <= PMT_rate(1599 downto 1568);
            --register_vector(get_local_addr(PMT_RATE_48_ADDR, address_vector)) <= PMT_rate(1567 downto 1536);
            --register_vector(get_local_addr(PMT_RATE_47_ADDR, address_vector)) <= PMT_rate(1535 downto 1504);
            --register_vector(get_local_addr(PMT_RATE_46_ADDR, address_vector)) <= PMT_rate(1503 downto 1472);
            --register_vector(get_local_addr(PMT_RATE_45_ADDR, address_vector)) <= PMT_rate(1471 downto 1440);
            --register_vector(get_local_addr(PMT_RATE_44_ADDR, address_vector)) <= PMT_rate(1439 downto 1408);
            --register_vector(get_local_addr(PMT_RATE_43_ADDR, address_vector)) <= PMT_rate(1407 downto 1376);
            --register_vector(get_local_addr(PMT_RATE_42_ADDR, address_vector)) <= PMT_rate(1375 downto 1344);
            --register_vector(get_local_addr(PMT_RATE_41_ADDR, address_vector)) <= PMT_rate(1343 downto 1312);
            --register_vector(get_local_addr(PMT_RATE_40_ADDR, address_vector)) <= PMT_rate(1311 downto 1280);
            --register_vector(get_local_addr(PMT_RATE_39_ADDR, address_vector)) <= PMT_rate(1279 downto 1248);
            --register_vector(get_local_addr(PMT_RATE_38_ADDR, address_vector)) <= PMT_rate(1247 downto 1216);
            --register_vector(get_local_addr(PMT_RATE_37_ADDR, address_vector)) <= PMT_rate(1215 downto 1184);
            --register_vector(get_local_addr(PMT_RATE_36_ADDR, address_vector)) <= PMT_rate(1183 downto 1152);
            --register_vector(get_local_addr(PMT_RATE_35_ADDR, address_vector)) <= PMT_rate(1151 downto 1120);
            --register_vector(get_local_addr(PMT_RATE_34_ADDR, address_vector)) <= PMT_rate(1119 downto 1088);
            --register_vector(get_local_addr(PMT_RATE_33_ADDR, address_vector)) <= PMT_rate(1087 downto 1056);
            --register_vector(get_local_addr(PMT_RATE_32_ADDR, address_vector)) <= PMT_rate(1055 downto 1024);
            --register_vector(get_local_addr(PMT_RATE_31_ADDR, address_vector)) <= PMT_rate(1023 downto  992);
            --register_vector(get_local_addr(PMT_RATE_30_ADDR, address_vector)) <= PMT_rate( 991 downto  960);
            --register_vector(get_local_addr(PMT_RATE_29_ADDR, address_vector)) <= PMT_rate( 959 downto  928);
            --register_vector(get_local_addr(PMT_RATE_28_ADDR, address_vector)) <= PMT_rate( 927 downto  896);
            --register_vector(get_local_addr(PMT_RATE_27_ADDR, address_vector)) <= PMT_rate( 895 downto  864);
            --register_vector(get_local_addr(PMT_RATE_26_ADDR, address_vector)) <= PMT_rate( 863 downto  832);
            --register_vector(get_local_addr(PMT_RATE_25_ADDR, address_vector)) <= PMT_rate( 831 downto  800);
            --register_vector(get_local_addr(PMT_RATE_24_ADDR, address_vector)) <= PMT_rate( 799 downto  768);
            --register_vector(get_local_addr(PMT_RATE_23_ADDR, address_vector)) <= PMT_rate( 767 downto  736);
            --register_vector(get_local_addr(PMT_RATE_22_ADDR, address_vector)) <= PMT_rate( 735 downto  704);
            --register_vector(get_local_addr(PMT_RATE_21_ADDR, address_vector)) <= PMT_rate( 703 downto  672);
            --register_vector(get_local_addr(PMT_RATE_20_ADDR, address_vector)) <= PMT_rate( 671 downto  640);
            --register_vector(get_local_addr(PMT_RATE_19_ADDR, address_vector)) <= PMT_rate( 639 downto  608);
            --register_vector(get_local_addr(PMT_RATE_18_ADDR, address_vector)) <= PMT_rate( 607 downto  576);
            register_vector(get_local_addr(PMT_RATE_17_ADDR, address_vector)) <= PMT_rate( 575 downto  544);
            register_vector(get_local_addr(PMT_RATE_16_ADDR, address_vector)) <= PMT_rate( 543 downto  512);
            register_vector(get_local_addr(PMT_RATE_15_ADDR, address_vector)) <= PMT_rate( 511 downto  480);
            register_vector(get_local_addr(PMT_RATE_14_ADDR, address_vector)) <= PMT_rate( 479 downto  448);
            register_vector(get_local_addr(PMT_RATE_13_ADDR, address_vector)) <= PMT_rate( 447 downto  416);
            register_vector(get_local_addr(PMT_RATE_12_ADDR, address_vector)) <= PMT_rate( 415 downto  384);
            register_vector(get_local_addr(PMT_RATE_11_ADDR, address_vector)) <= PMT_rate( 383 downto  352);
            register_vector(get_local_addr(PMT_RATE_10_ADDR, address_vector)) <= PMT_rate( 351 downto  320);
            register_vector(get_local_addr(PMT_RATE_09_ADDR, address_vector)) <= PMT_rate( 319 downto  288);
            register_vector(get_local_addr(PMT_RATE_08_ADDR, address_vector)) <= PMT_rate( 287 downto  256);
            register_vector(get_local_addr(PMT_RATE_07_ADDR, address_vector)) <= PMT_rate( 255 downto  224);
            register_vector(get_local_addr(PMT_RATE_06_ADDR, address_vector)) <= PMT_rate( 223 downto  192);
            register_vector(get_local_addr(PMT_RATE_05_ADDR, address_vector)) <= PMT_rate( 191 downto  160);
            register_vector(get_local_addr(PMT_RATE_04_ADDR, address_vector)) <= PMT_rate( 159 downto  128);
            register_vector(get_local_addr(PMT_RATE_03_ADDR, address_vector)) <= PMT_rate( 127 downto   96);
            register_vector(get_local_addr(PMT_RATE_02_ADDR, address_vector)) <= PMT_rate(  95 downto   64);
            register_vector(get_local_addr(PMT_RATE_01_ADDR, address_vector)) <= PMT_rate(  63 downto   32);
            register_vector(get_local_addr(PMT_RATE_00_ADDR, address_vector)) <= PMT_rate(  31 downto    0);
            
            
            --register_vector(get_local_addr(MASK_RATE_00_ADDR, address_vector)) <= mask_rate( 287 downto  256);
            --register_vector(get_local_addr(MASK_RATE_01_ADDR, address_vector)) <= mask_rate( 255 downto  224);
            --register_vector(get_local_addr(MASK_RATE_02_ADDR, address_vector)) <= mask_rate( 223 downto  192);
            --register_vector(get_local_addr(MASK_RATE_03_ADDR, address_vector)) <= mask_rate( 191 downto  160);
            --register_vector(get_local_addr(MASK_RATE_04_ADDR, address_vector)) <= mask_rate( 159 downto  128);
            --register_vector(get_local_addr(MASK_RATE_05_ADDR, address_vector)) <= mask_rate( 127 downto   96);
            --register_vector(get_local_addr(MASK_RATE_06_ADDR, address_vector)) <= mask_rate(  95 downto   64);
            --register_vector(get_local_addr(MASK_RATE_07_ADDR, address_vector)) <= mask_rate(  63 downto   32);
            --register_vector(get_local_addr(MASK_RATE_08_ADDR, address_vector)) <= mask_rate(  31 downto    0);
            
                                                                                  
            register_vector(get_local_addr(BOARD_TEMP_ADDR, address_vector))     <= board_temp;
            
            
            
            
            
            if (we = '1') then                                                                                    
            
                -- on write request the local address is check whether it is writeable                            
                if (address_vector(local_address).mode = RW) then
                
                    -- local address writeable, write it
                    register_vector(local_address) <= di;

                end if;

            end if;
            
        end if;

    end process read_write_process;
    
end Behavioral;

