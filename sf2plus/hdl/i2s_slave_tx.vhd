----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Company:  Arrow Electronics
-- Engineer: Keith D. Rowe
-- 
-- Create Date:    07/07/2015 
-- Design Name: 
-- Module Name:    I2S_Slave_TX - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 1.00 - File modifications to ensure BCK edges are before LR_CK (WS).
-- Additional Comments: 
--
-- Description:   
-- 
-- This module provides a parallel to serial bridge between an I2S Slave TX  
-- interface device (Audio DAC, Audio Codec, S/PDIF Decoded data, etc.) and  
-- a parallel device (microcontroller, IP block).
--
-- It's coded as a generic VHDL entity, proper signal width (8/16/24 bit) via genric.
--
-- Input takes:
-- -I2S_EN Interface enable control
-- -I2S Bit Clock
-- -I2S LR Clock (Left/Right channel indication)
-- -Parrallel Left & Right Data (DATA_L / DATA_R)
--
-- Output provides:
-- -DATA_L / DATA_R parallel inputs
-- -STROBE = RE indicates that both Left and Right Data are ready
-- 
--------------------------------------------------------------------------------
-- I2S Waveform summary
--
-- BIT_CK     __    __   __    __    __            __    __    __    __   
--           | 1|__| 2|_| 3|__| 4|__| 5|__... ... |32|__| 1|__| 2|__| 3| ...
--
-- LR_CK                                  ... ...      _________________
--           ____________R_Channel_Data______________|   L Channel Data ...
--
-- DATA      x< 00 ><D24><D22><D21><D20>  ... ...     < 00 ><D24><D23>  ...
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity i2s_slave_tx is 
-- width: How many bits (from MSB) are gathered from the serial I2S input
generic(width : integer := 16);
port(
	--  I2S Input ports
	-- Control ports
	RESET_N     : in std_logic; --Asynchronous Reset (Active Low)
	CLK         : in std_logic; --Board Clock
	I2S_EN      : in std_logic; --I2S Enable Port, '1' = enable
	LR_CK       : in std_logic; --Left/Right indicator clock ('0' = Left)
	BIT_CK      : in std_logic; --Bit clock
	DOUT        : out std_logic; --Serial I2S Data Output
	-- Parallel Output ports
	DATA_L : in std_logic_vector(width-1 downto 0);
	DATA_R : in std_logic_vector(width-1 downto 0);
	-- Output status ports
	STROBE : out std_logic;  --Rising edge means request for next LR Data
	STROBE_LR : out std_logic --Currently not using
    );

end i2s_slave_tx;
 
architecture Behavioral of i2s_slave_tx  is
----------------------------------------------
-- Start Signal / Constant Declarations:
----------------------------------------------

--    constant DATA_MSB : integer := 23;
--    constant ADDR_MSB : integer := 31;
-- Input registering signals
	signal inputregbusinput		: std_logic_vector(33 downto 0); 
	signal inputregbusoutput    : std_logic_vector(33 downto 0);
	signal BIT_CK_2d    : std_logic ;
	signal LR_CK_2d    : std_logic ;
	signal DATA_L_2d    : std_logic_vector(15 downto 0);
	signal DATA_R_2d    : std_logic_vector(15 downto 0);

-- Other signal declarations
	signal stopvalue    : std_logic := '0'; -- Value of serial data when shifting is over.
	signal channel_lr   : std_logic; -- channel indicator: 0=Left; 1=Right
	signal DATA_L_latched : std_logic_vector(width-1 downto 0); -- Latch of DATA in
	signal DATA_R_latched : std_logic_vector(width-1 downto 0); -- Latch of DATA in
	signal DATA_L_forshift : std_logic_vector(width-1 downto 0); -- Latch of DATA to shift
	signal DATA_R_forshift : std_logic_vector(width-1 downto 0); -- Latch of DATA to shift
	signal DATA4shift : std_logic_vector(width-1 downto 0); -- Data to "shift" L or R
	signal LR_CK_3d   : std_logic; -- 1 clock delay BIT_CK
	signal LR_CK_4d   : std_logic; -- 2 clock delay BIT_CK = ensures that FE of BIT_CK is before edge of LR_CK
	signal LR_CK_5d   : std_logic; -- 2 clock delay BIT_CK = ensures that FE of BIT_CK is before edge of LR_CK
	signal LR_CK_6d   : std_logic; -- 2 clock delay BIT_CK = ensures that FE of BIT_CK is before edge of LR_CK
	signal LR_CK_7d   : std_logic; -- 2 clock delay BIT_CK = ensures that FE of BIT_CK is before edge of LR_CK
	signal LR_CK_8d   : std_logic; -- 2 clock delay BIT_CK = ensures that FE of BIT_CK is before edge of LR_CK
	signal BIT_CK_re   : std_logic; -- rising edge of BIT_CK
	signal BIT_CK_fe   : std_logic; -- falling edge of BIT_CK
	signal LR_CK_re     : std_logic; -- rising edge of LR_CK
	signal LR_CK_fe     : std_logic; -- falling edge of LR_CK
--	signal strobe_L     : std_logic; -- one clock pulse indicating left data latched.
	signal shifting_L  : std_logic; -- '1' Indicates shifting in of data in process
	signal counter_L : integer range 0 to width+1; -- Bit counter for Left
	signal shifting_R  : std_logic; -- '1' Indicates shifting in of data in process

----------------------------------------------
-- End Signal / Constant Declarations:
----------------------------------------------

----------------------------------------------
-- Start Component declarations
----------------------------------------------

	COMPONENT rising_edge_sig
	PORT( 
		clk            : in std_logic ;
		reset_n        : in std_logic ;
		reg_signal     : in std_logic ;
		reg_signal_re  : out std_logic);
	END COMPONENT;

	COMPONENT falling_edge_sig
	PORT( 
		clk            : in std_logic ;
		reset_n        : in std_logic ;
		reg_signal     : in std_logic ;
		reg_signal_fe  : out std_logic);
	END COMPONENT;

	COMPONENT input_registration
	PORT( 
		CLK         : in  STD_LOGIC;
		BRDRESET_N  : in  STD_LOGIC;
		inputs      : in  STD_LOGIC_VECTOR (33 downto 0);
		inputs_2d   : out  STD_LOGIC_VECTOR (33 downto 0) );
	END COMPONENT;

----------------------------------------------
-- End Component declarations
----------------------------------------------
 
begin

-- Asynchronous signals

-- Assign inputs to input registering (2 clock registering for metastbility and synchronous design)
-- I use _xd where x represents the number of clock delays, so _2d is double clocked.

    inputregbusinput    <= BIT_CK & LR_CK & DATA_L & DATA_R;
    BIT_CK_2d   <= inputregbusoutput(33);
    LR_CK_2d   <= inputregbusoutput(32);
    DATA_L_2d   <= inputregbusoutput(31 downto 16);
    DATA_R_2d	<= inputregbusoutput(15 downto 0);

-- Synchronous Processes
   
    REGSIGNALS: process(RESET_N, CLK)
	begin
		if (CLK='1' and CLK'event) then
            if ((RESET_N = '0') or (I2S_EN = '0')) then
                STROBE_LR <= '0';
                STROBE <= '0';
                channel_lr <= '0'; 
                LR_CK_3d <= '0';
                LR_CK_4d <= '0';
            else
                STROBE_LR <= LR_CK_2d;
                STROBE <= (not LR_CK_2d); -- Might need to add delays to align with fe and re sgnals.
                channel_lr <= LR_CK_2d; -- Might need to add delays to align with fe and re sgnals.
                LR_CK_3d <= LR_CK_2d;
                LR_CK_4d <= LR_CK_3d;
                LR_CK_5d <= LR_CK_4d;
                LR_CK_6d <= LR_CK_5d;
                LR_CK_7d <= LR_CK_6d;
                LR_CK_8d <= LR_CK_7d;
            end if;
        end if;
    end process REGSIGNALS;

    DATA_PROC: process(RESET_N, CLK)
	begin
		if (CLK='1' and CLK'event) then
            if ((RESET_N = '0') or (I2S_EN = '0')) then
                DOUT <= stopvalue;
                DATA_L_latched <= (others => '0');
                DATA_R_latched <= (others => '0');
                DATA4shift <= (others => '0');
                shifting_L <= '0';
                counter_L <= 0;
            elsif (LR_CK_fe ='1') or (LR_CK_re ='1') then
                if (channel_lr = '0') then-- left channel
--                    DATA_L_latched <= "0000000000000000"; -- for test
--                    DATA_R_latched <= "0000000000100000"; -- 32 for test
                    DATA_L_latched <= DATA_L_2d; -- not really needed, since DATA_L is latched in to start below
                    DATA_R_latched <= DATA_R_2d;
                    DATA4shift <= DATA_L_2d;
                    shifting_R <= '0';
                    shifting_L <= '1';
                    counter_L <= width;
                else  -- right channel
                    DATA4shift <= DATA_R_latched;
                    shifting_R <= '1';
                    shifting_L <= '0';
                    counter_L <= width;
                end if;
            elsif ( (BIT_CK_fe = '1') and ((shifting_L = '1') XOR (shifting_R = '1')) ) then 
                -- Note: LRCK changes on the falling edge of BCK
                -- We notice of the first LRCK transition only on the
                -- next rising edge of BCK
                -- In this way we discard the first data bit as we start pushing
                -- data into the shift register only on the next BCK rising edge
                -- This is right for I2S standard (data starts on the 2nd clock)
                if ((counter_L <= width) and (counter_L > 1))   then
                    -- Shift Data Out
                    DOUT <= DATA4shift(width-1);
                    DATA4shift <= DATA4shift(width-2 downto 0) & stopvalue;
                    -- decrement counter
                    counter_L <= counter_L - 1;
                elsif (counter_L = 1) then -- last bit of channel shifted
                    -- Shift Data Out
                    DOUT <= DATA4shift(width-1);
                    DATA4shift <= DATA4shift(width-2 downto 0) & stopvalue;
                    -- set counter out of range
                    counter_L <= 0;
                    if (shifting_L = '1') then  
                        shifting_L <= '0';
                    elsif (shifting_R = '1') then 
                        shifting_R <= '0';
                    end if;
                end if;
            end if;
        end if;
 
    end process DATA_PROC;



----------------------------------------------
--Start Port Mapping
----------------------------------------------

  BITCLKRE: rising_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => BIT_CK_2d,
        reg_signal_re   => BIT_CK_re
    );

  BITCLKFE: falling_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => BIT_CK_2d,
        reg_signal_fe   => BIT_CK_fe
    );

  LRCKRE: rising_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => LR_CK_8d,
        reg_signal_re   => LR_CK_re
    );

  LRCKFE: falling_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => LR_CK_8d,
        reg_signal_fe   => LR_CK_fe
    );

  INPUTREGISTRATION: input_registration
    port map (
        CLK				=> CLK,
        BRDRESET_N		=> RESET_N,
        inputs			=> inputregbusinput,
        inputs_2d		=> inputregbusoutput
    );

----------------------------------------------
--End Port Mapping
----------------------------------------------

end Behavioral;
