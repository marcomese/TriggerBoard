--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: top_data_transfer.vhd
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
use work.usb_uart_usb_uart_0_coreuart_pkg.all;

entity top_data_transfer is
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

      tx          : out std_logic; -- Start of Packet
      rx          : in std_logic; -- End Of Packet
      receivedDATA       : out std_logic_vector(7 downto 0)
);
end top_data_transfer;

architecture Behavioral of top_data_transfer is

signal       sDATA       :  std_logic_vector(7 downto 0); -- Word Data to transfer
signal       sWE, TXRDY_sig         :  std_logic := '0'; -- 

component data_transfer is
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
end component;

component usb_uart IS
    port(
        -- Inputs
        BAUD_VAL    : in  std_logic_vector(12 downto 0);
        BIT8        : in  std_logic;
        CLK         : in  std_logic;
        CSN         : in  std_logic;
        DATA_IN     : in  std_logic_vector(7 downto 0);
        ODD_N_EVEN  : in  std_logic;
        OEN         : in  std_logic;
        PARITY_EN   : in  std_logic;
        RESET_N     : in  std_logic;
        RX          : in  std_logic;
        WEN         : in  std_logic;
        -- Outputs
        DATA_OUT    : out std_logic_vector(7 downto 0);
        FRAMING_ERR : out std_logic;
        OVERFLOW    : out std_logic;
        PARITY_ERR  : out std_logic;
        RXRDY       : out std_logic;
        TX          : out std_logic;
        TXRDY       : out std_logic
        );
end component;


begin

UART: usb_uart 
 PORT map (
      BAUD_VAL        => "0000000110011",
      BIT8   => '1',   --   IF SET TO ONE 8 DATA BITS OTHERWISE 7 DATA BITS
      CLK      => clock,
      CSN             => '0',
      DATA_IN         => sDATA,
      ODD_N_EVEN  => '0',    --   IF SET TO ONE ODD PARITY OTHERWISE EVEN PARITY
      OEN             => '0',
      PARITY_EN  => '0',    --   IF SET TO ONE PARITY IS ENABLED OTHERWISE DISABLED
      RESET_N  => '1', 
      RX              => rx, 
      WEN             => sWe,

      DATA_OUT      => receivedDATA, 
      FRAMING_ERR    => open,
      OVERFLOW     => open,  --   RECEIVER OVERFLOW
      PARITY_ERR  => open, 
      RXRDY      => open,    --   RECEIVER HAS A BYTE READY
      TX            => tx,
      TXRDY        => TXRDY_sig    --   TRANSMIT READY FOR ANOTHER BYTE
);


fsm: data_transfer 
port map(
      reset      => reset,
      clock      => clock,
      
      HG_data_1   => hG_data_1,
      LG_data_1   => LG_data_1,
      HG_data_2   => hG_data_2,
      LG_data_2   => LG_data_2,
      data_ready   => data_ready,
      data_to_daq => data_to_daq,
      iRDY        => TXRDY_sig,

      -- Internal Interface 
      oSOP        => open, 
      oEOP        => open,
      oDATA       => sDATA,
      oWE          => sWe
);

end Behavioral;