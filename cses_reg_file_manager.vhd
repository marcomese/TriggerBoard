-------------------------------------------------------------------------------
--
-- cses_reg_file_manager
--
-- This module handle the communication over SpaceWire Ligth for a slave module.
--
-- @file: cses_reg_file_manager.vhd
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
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------

entity cses_reg_file_manager is

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


end cses_reg_file_manager;

-------------------------------------------------------------------------------
-- Architecture Declaration
-------------------------------------------------------------------------------

architecture Behavioral of cses_reg_file_manager is

-------------------------------------------------------------------------------
-- Type Declaration
-------------------------------------------------------------------------------

  type incom_state_t is (IDLE, GET_ADDRESS, GET_DATA, WAIT_EOP, EXECUTE_COMMAND);
  type outcom_state_t is (NONE, READY, SENDING_ADDR, SENDING_DATA, CLOSING, CLOSED);

  type com_data_t is array (natural range <>) of std_logic_vector(7 downto 0);

  constant SPACEWIRE_FREE_CMD       : std_logic_vector(7 downto 0) := x"00";
  constant SPACEWIRE_READ_CMD       : std_logic_vector(7 downto 0) := x"03";
  constant SPACEWIRE_WRITE_CMD      : std_logic_vector(7 downto 0) := x"0C";
  constant SPACEWIRE_POST_WRITE_CMD : std_logic_vector(7 downto 0) := x"30";
  constant SPACEWIRE_UNDEF_CMD      : std_logic_vector(7 downto 0) := x"FF";

  type incom_t is record

    address         : com_data_t(3 downto 0);
    data            : com_data_t(3 downto 0);
    command         : std_logic_vector(7 downto 0);
    state           : incom_state_t;
    counter         : integer;
    
  end record;

  type outcom_t is record

    address         : com_data_t(3 downto 0);
    data            : com_data_t(3 downto 0);
    command         : std_logic_vector(7 downto 0);
    state           : outcom_state_t;
    counter         : integer;

  end record;

-------------------------------------------------------------------------------
-- Constant Declaration
-------------------------------------------------------------------------------

  constant incom_reset  : incom_t :=
    (
      address         => (others => (others => '0')),
      data            => (others => (others => '0')),
      command         => SPACEWIRE_UNDEF_CMD,
      state           => IDLE,
      counter         => 0
      );

  constant incom_undef_seq_handler : incom_t :=
    (
      address         => (others => (others => '0')),
      data            => (others => (others => '0')),
      command         => SPACEWIRE_UNDEF_CMD,
      state           => EXECUTE_COMMAND,
      counter         => 0
      );
  
  constant outcom_reset : outcom_t :=
    (
      address         => (others => (others => '0')),
      data            => (others => (others => '0')),
      command         => SPACEWIRE_UNDEF_CMD,
      state           => NONE,
      counter         => 0
      );

  constant EOP : std_logic_vector(7 downto 0) := x"00";
  constant EEP : std_logic_vector(7 downto 0) := x"01";

-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

  signal incom          : incom_t := incom_reset;
  signal outcom         : outcom_t := outcom_reset;

  signal r_addr         : std_logic_vector(31 downto 0);
  signal r_data         : std_logic_vector(31 downto 0);
  
begin

  main : process(clk, rst)
  begin

    if (rst = '1') then

      incom   <= incom_reset;
      outcom  <= outcom_reset;
      txwrite <= '0';
      we      <= '0';
	  r_addr  <= (others => '0');
	  r_data  <= (others => '0');
	  
    elsif (rising_edge(clk)) then
		
      r_data  <= incom.data(3) & incom.data(2) & incom.data(1) & incom.data(0);            
      r_addr  <= incom.address(3) & incom.address(2) & incom.address(1) & incom.address(0);	   
	
      ----------------------------------------------
      -- Receive FSM
      ----------------------------------------------
      case (incom.state) is

        when IDLE => 

          rxread  <= '1';
          we      <= '0';

          if ((rxvalid = '1') and (rxflag = '1')) then

            -- Invalid data received
            incom               <= incom_undef_seq_handler;
            
          elsif (rxvalid = '1') then

            -- Valid data received, get the command and start to acquire address
            incom.command       <= rxdata;
            incom.state         <= GET_ADDRESS;
            incom.counter       <= 0;
            
          end if;

        when GET_ADDRESS =>

          -- Acquire the next 4 data byte as address
          
          rxread <= '1';

          if ( (rxvalid = '1') and (rxflag = '0') ) then

            -- Acquire address
            incom.address(incom.counter) <= rxdata;
            incom.counter                <= incom.counter + 1; 
            
            if (incom.counter = 3) then

              -- Last address byte received
              incom.state    <= GET_DATA;
              incom.counter  <= 0;

            end if;
            
          elsif ( rxvalid = '1' ) then

            -- Wrong data sequence
            incom <= incom_undef_seq_handler;
            
          end if;
          
        when GET_DATA =>

          -- Acquire the next 4 data byte as data
          
          rxread <= '1';

          if ( (rxvalid = '1') and (rxflag = '0') ) then

            -- Acquire data
            incom.data(incom.counter) <= rxdata;
            incom.counter             <= incom.counter + 1; 
            
            if (incom.counter = 3) then

              -- Last data byte received
              incom.state    <= WAIT_EOP;
              incom.counter  <= 0;

            end if;
            
          elsif ( rxvalid = '1' ) then

            -- Wrong data sequence
            incom <= incom_undef_seq_handler;
            
          end if;

        when WAIT_EOP =>

          -- Complete the communication with EOP
          rxread <= '0';
          
          if ( (rxvalid = '1') and (rxflag = '1') and (rxdata = EOP) ) then

            incom.state <= EXECUTE_COMMAND;

          elsif (rxvalid = '1') then

            -- Wrong data sequence
            incom <= incom_undef_seq_handler;

          end if;
          
        when EXECUTE_COMMAND =>

          -- Execute command
          incom <= incom_reset;
          rxread <= '1';
            
          case (incom.command) is
            
            when SPACEWIRE_READ_CMD =>

              -- check the output state to send a feedback of the command (if
              -- busy discard the packet)
              if outcom.state = NONE then

                outcom.command             <= incom.command;
                outcom.address(3 downto 0) <= incom.address(3 downto 0);
                outcom.data(3 downto 0)    <= (do(31 downto 24), do(23 downto 16), do(15 downto 8), do(7 downto 0));
                outcom.counter             <= 0;
                outcom.state               <= READY;
                
              end if;
              
            when SPACEWIRE_WRITE_CMD =>

              we <= '1';
              
              -- check the output state to send a feedback of the command (if
              -- busy discard the packet)
              if outcom.state = NONE then

                outcom.command          <= incom.command;	
				outcom.address          <= incom.address;
                outcom.data             <= incom.data;
                outcom.counter          <= 0;
                outcom.state            <= READY;
                
              end if;
              
            when SPACEWIRE_POST_WRITE_CMD =>
              
              we <= '1';

              -- no feedback for post write request
              
            when others => 
              
          end case;
          
        when others =>

          -- something wrong, reset.
          incom <= incom_reset;

      end case;

      ----------------------------------------------
      -- Send FSM
      ----------------------------------------------
      case (outcom.state) is

        when READY =>

          -- start to send
          if (txrdy = '1') then
            
            txwrite        <= '1';
            txflag         <= '0';
            txdata         <= outcom.command;
            outcom.state   <= SENDING_ADDR;
            outcom.counter <= 0;

          end if;

        when SENDING_ADDR =>

          -- send the address
          if (txrdy = '1') then

            txdata(7 downto 0)  <= outcom.address(outcom.counter);

            outcom.counter <= outcom.counter + 1;
            
            if (outcom.counter = 3) then

              outcom.state      <= SENDING_DATA;
              outcom.counter    <= 0;

            end if;
            
          end if;
          
        when SENDING_DATA =>

          -- send the data
          if (txrdy = '1') then

            txdata(7 downto 0)  <= outcom.data(outcom.counter);

            outcom.counter <= outcom.counter + 1;
            
            if (outcom.counter = 3) then

              outcom.state        <= CLOSING;
              outcom.counter      <= 0;

            end if;
            
          end if;
          
        when CLOSING =>

          -- close connection sending a EOP
          if (txrdy = '1') then

            txflag <= '1';
            txdata <= EOP;
            
            outcom.state <= CLOSED;
            
          end if;
          
        when CLOSED =>

          -- closed
          if (txrdy = '1') then

            txwrite <= '0';
            txflag  <= '0';
            outcom.state <= NONE;
            
          end if;

        when others =>

          txwrite <= '0';
          txflag  <= '0';
         
      end case;

    end if;
        
  end process;

  di          <= r_data;
  addr        <= r_addr;

end Behavioral;

