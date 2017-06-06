----------------------------------------------------------------------------------
-- Company:  Arrow Electronics
-- Engineer: Keith D. Rowe
-- 
-- Create Date:    08/14/2005 
-- Design Name: 
-- Module Name:    ADC_I2StoPar - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 1.00 - 150704 Completely re-vamped original ADC interface to 
--                  be I2S Slave RX.
-- Revision 2.00 - 150826 Added latch of both DATA_L/_R on LR_CK_re.  Also,
--                  changed STROBE to (not LR_CK) to avoid data transition conflicts.
-- Revision 3.00 - 150826 near total overhaul to incorporate in one function..
--
-- Additional Comments: 
--
-- Description:   
-- 
-- This module provides a serial to parallel bridge between an I2S Slave RX  
-- interface device (Audio ADC, Audio Codec, S/PDIF Decoded data, etc.) and  
-- a parallel device (microcontroller, IP block).
--
-- It's coded as a generic VHDL entity, proper signal width (8/16/24 bit) via genric.
--
-- Input takes:
-- -I2S_EN Interface enable control
-- -I2S Bit Clock
-- -I2S LR Clock (Left/Right channel indication)
-- -I2S Data
--
-- Output provides:
-- -DATA_L / DATA_R parallel outputs
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


entity i2s_slave_rx is 
-- width: # of bits gathered from the serial I2S input and width of output bus.
generic(width : integer := 16);
port(
	--  I2S Input ports
	-- Control ports
	RESET_N     : in std_logic; --Asynchronous Reset (Active Low)
	CLK         : in std_logic; --Board Clock
	I2S_EN      : in std_logic; --I2S Enable Port, '1' = enable
	LR_CK       : in std_logic; --Left/Right indicator clock ('0' = Left)
	BIT_CK      : in std_logic; --Bit clock
	DIN         : in std_logic; --Data Input
	-- Parallel Output ports
	DATA_L : out std_logic_vector(width-1 downto 0);
	DATA_R : out std_logic_vector(width-1 downto 0);
	-- Output status ports
	STROBE : out std_logic;  --Rising edge means data is ready
	STROBE_LR : out std_logic
    );

end i2s_slave_rx;
 
architecture Behavioral of i2s_slave_rx  is
----------------------------------------------
-- Start Signal / Constant Declarations:
----------------------------------------------

--    constant DATA_MSB : integer := 23;
--    constant ADDR_MSB : integer := 31;
-- Input registering signals
	signal inputregbusinput		: std_logic_vector(33 downto 0); 
	signal inputregbusoutput    : std_logic_vector(33 downto 0);
	signal BIT_CK_2d    : std_logic ;
	signal LR_CK_2d     : std_logic ;
	signal DIN_2d       : std_logic;

-- Other signal declarations
	signal BIT_CK_re    : std_logic; -- rising edge of BIT_CK
	signal LR_CK_re     : std_logic; -- rising edge of LR_CK
	signal LR_CK_fe     : std_logic; -- falling edge of LR_CK
	signal DATA_R_int   : std_logic_vector(width-1 downto 0); -- internal DATA bus
	signal DATA_L_int   : std_logic_vector(width-1 downto 0); -- internal DATA bus
	signal strobe_L     : std_logic; -- one clock pulse indicating left data latched.
	signal shifting_L   : std_logic; -- '1' Indicates shifting in of data in process
	signal counter_L    : integer range 0 to width+1; -- Bit counter for Left
	signal shift_reg_L  : std_logic_vector(width-1 downto 0); -- Shift Reg for Left
	signal counter_R    : integer range 0 to width; -- Bit counter for Right
	signal shift_reg_R  : std_logic_vector(width-1 downto 0); -- Shift Reg for Right
	signal strobe_R     : std_logic; -- one clock pulse indicating right data latched.
	signal shifting_R   : std_logic; -- '1' Indicates shifting in of data in process

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

    inputregbusinput    <= "0000000000000000000000000000000" & BIT_CK & LR_CK & DIN;
    BIT_CK_2d   <= inputregbusoutput(2);
    LR_CK_2d    <= inputregbusoutput(1);
    DIN_2d      <= inputregbusoutput(0);

-- Synchronous Processes
    
    REGSIGNALS: process(RESET_N, CLK)
	begin
		if (CLK='1' and CLK'event) then
            if ((RESET_N = '0') or (I2S_EN = '0')) then
                STROBE_LR <= '0'; 
                STROBE <= '1';
                DATA_L <= (others => '0');
                DATA_R <= (others => '0');
            else
                if (LR_CK_re ='1') then
                    -- Latch full frame
                    DATA_L <= DATA_L_int;
                    DATA_R <= DATA_R_int;
                end if;
                STROBE_LR <= LR_CK_2d; -- for now...tbd behavior
                STROBE <= not LR_CK_2d; -- Might need to add delays to align with fe and re sgnals...Also not really a "strobe" correct later.
            end if;
        end if;
    end process REGSIGNALS;


    DATAL_PROC: process(RESET_N, CLK)
	begin
		if (CLK='1' and CLK'event) then
            if ((RESET_N = '0') or (I2S_EN = '0')) then
                DATA_L_int <= (others => '0');
                strobe_L <= '0';
                shift_reg_L <= (others => '0');
                shifting_L <= '0';
                counter_L <= 0;
            elsif (LR_CK_fe ='1') then
--                DATA_L_int <= (others => '0');
                strobe_L <= '0';
                shift_reg_L <= (others => '0');
                shifting_L <= '1';
                counter_L <= 0;
                strobe_L <= '0';
            elsif ((BIT_CK_re = '1') and (shifting_L = '1')) then
                -- Note: LRCK changes on the falling edge of BCK
                -- We notice of the first LRCK transition only on the
                -- next rising edge of BCK
                -- In this way we discard the first data bit as we start pushing
                -- data into the shift register only on the next BCK rising edge
                -- This is right for I2S standard (data starts on the 2nd clock)
                if(counter_L = 0) then
                    -- Get ready during Null Bit
                    shift_reg_L <= (others => '0');
                    counter_L <= counter_L + 1;
                elsif(counter_L < width) then
                    -- Push data into the shift register
                    shift_reg_L <= shift_reg_L(width-2 downto 0) & DIN_2d;
                    -- Increment counter
                    counter_L <= counter_L + 1;		
                elsif(counter_L = width) then
                    -- Push last bit of data into DATA out and reset signals to wait for next LR_CK_fe 
                    DATA_L_int <= shift_reg_L(width-2 downto 0) & DIN_2d;
                    shifting_L <= '0';
                    strobe_L <= '1';
                    counter_L <= 0;
                end if;
            end if;
        end if;
 
    end process DATAL_PROC;

    DATAR_PROC: process(RESET_N, CLK)
	begin
		if (CLK='1' and CLK'event) then
            if ((RESET_N = '0') or (I2S_EN = '0')) then
--                DATA_R_int <= (others => '0');
                DATA_R_int <= "0000000000001000";
                strobe_R <= '0';
                shift_reg_R <= (others => '0');
                shifting_R <= '0';
                counter_R <= 0;
            elsif (LR_CK_re ='1') then
--                DATA_R_int <= (others => '0');
                strobe_R <= '0';
                shift_reg_R <= (others => '0');
                shifting_R <= '1';
                counter_R <= 0;
            elsif ((BIT_CK_re = '1') and (shifting_R = '1')) then
                -- Note: LRCK changes on the falling edge of BCK
                -- We notice of the first LRCK transition only on the
                -- next rising edge of BCK
                -- In this way we discard the first data bit as we start pushing
                -- data into the shift register only on the next BCK rising edge
                -- This is right for I2S standard (data starts on the 2nd clock)
                if(counter_R = 0) then
                    -- Get ready during Null Bit
                    shift_reg_R <= (others => '0');
                    counter_R <= counter_R + 1;
                elsif(counter_R < width) then
                    -- Push data into the shift register
                    shift_reg_R <= shift_reg_R(width-2 downto 0) & DIN_2d;
                    -- Increment counter
                    counter_R <= counter_R + 1;		
                elsif(counter_R = width) then
                    -- Push last bit of data into DATA out and reset signals to wait for next LR_CK_fe 
                    DATA_R_int <= shift_reg_R(width-2 downto 0) & DIN_2d;
                    shifting_R <= '0';
                    strobe_R <= '1';
                    counter_R <= 0;
                end if;
            end if;
        end if;
 
    end process DATAR_PROC;



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
  LRCKRE: rising_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => LR_CK_2d,
        reg_signal_re   => LR_CK_re
    );
  LRCKFE: falling_edge_sig
    port map (
        clk             => CLK,
        reset_n         => RESET_N,
        reg_signal      => LR_CK_2d,
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
