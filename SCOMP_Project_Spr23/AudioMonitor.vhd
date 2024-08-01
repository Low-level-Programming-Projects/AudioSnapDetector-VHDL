-- AudioMonitor.vhd
-- Created 2023
--
-- This SCOMP peripheral passes data from an input bus to SCOMP's I/O bus.

library IEEE;
library lpm;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use lpm.lpm_components.all;

entity AudioMonitor is
port(
	CS          : in std_logic;
	IO_WRITE    : in std_logic;
	SYS_CLK     : in std_logic;  -- SCOMP's clock
	RESETN      : in std_logic;
	AUD_DATA    : in std_logic_vector(15 downto 0);
	AUD_NEW     : in std_logic;
	IO_DATA     : inout std_logic_vector(15 downto 0);
	COUNT_CLK   : in std_logic   -- 10 Hz timer clock
);
end AudioMonitor;

architecture a of AudioMonitor is
	
	-- Timer
	signal ticks                : integer := 0; 
	signal ticks_final          : integer := 0;
	
	-- Moving Average/Max Magnitude Processor
	constant shift_reg_depth    : integer := 32; -- Number of samples to use in moving average, must be power of 2 and if changed must be changed below	
	constant shift_reg_width    : integer := 21;
	type shift_reg_type is array (shift_reg_depth - 2 downto 0) of std_logic_vector(shift_reg_width - 1 downto 0);
	signal shift_reg : shift_reg_type;
	signal audio_average        : std_logic_vector(15 downto 0);
	
	-- Configurable Threshold
	signal input_data           : std_logic_vector(15 downto 0);
	signal in_en                : std_logic;
	
	-- State Machine
	signal is_clap              : std_logic;
	signal count_en             : std_logic;
	signal clap_count           : integer;
	signal out_en               : std_logic;
	signal loud_threshold       : std_logic_vector(15 downto 0);
	signal quiet_threshold      : std_logic_vector(15 downto 0) := "0000000001000000"; -- Audio magnitude threshold to become quiet again
	constant max_snap_duration  : integer := 2; -- Two ticks of the 10 Hz counter clock is equivalent to 0.2 seconds
	TYPE STATE_TYPE IS (listening, noise_detected, clap_check);
	signal state : STATE_TYPE;
	
	-- Output Signals
	signal parsed_data          : std_logic_vector(15 downto 0);
	signal output_data          : std_logic_vector(15 downto 0);
	
begin

	----------------------------------------   Development Notes   -----------------------------------------
	
	-- We have a few assembly programs that can be used to debug the code. They are in the SCOMP VHDL file, and one is commented out.
	-- The init file "AudioTest.mif" outputs all 16 bits to the LEDs, so that can be used to debug audio data by having parsed_data hold some
	-- audio. The other file "audio_peri_output1.mif" turns on all the LEDs when the LSB is 1, and it uses the rest of the parsed_data bits
	-- by displaying their value to the hex displays. The value on the 7-segment displays is hex and not decimal (a displayed value of 64 is
	-- actually 100 in decimal). At the bottom of this VHDL file is where the parsed_data signal is defined, so what SCOMP outputs can be changed in
	-- conjunction with what mif file is used to debug different things.
	
	
	----------------------------------------          Timer         ----------------------------------------
	
	-- Notes:
	--	The COUNT_CLK is a 10 Hz clock fed in from SCOMP's clock divider. This allows us to count independently of the state machine.
	--	The ticks signal stores the integer number of 10 Hz ticks that have elapsed. It only counts when count_en is enabled.
	--	The signal count_en is controlled from the main state machine so that we can control when to start and stop counting.
	-- We use the ticks_final variable to output the time that the noise was detected as being loud. Ticks holds its value temporarily.
	
	process (COUNT_CLK, RESETN) begin
		if resetn = '0' then
			ticks <= 0;
			ticks_final <= 0;
		elsif count_en = '1' then
			if rising_edge(COUNT_CLK) then
				ticks <= ticks + 1;
			end if;
		else
			if ticks > 0 then
				ticks_final <= ticks;
			end if;
			ticks <= 0;
		end if;
	end process;
	
	
	---------------------------------------             Moving Average             ---------------------------------------
	
	-- Notes:
	-- Every time we get a new sample of AUD_DATA (which is when rising edge of AUD_NEW happens), shift that into the shift register.
	-- At the same time, shift out the highest AUD_DATA stored in the shift register. Then, use a for loop to sum all the AUD_DATA.
	-- Finally, shift the sum right by 5 to divide by 32, which is the number of AUD_DATA values we have in the shift register.
	-- This average noise value is outputted to the audio_average signal which is then used in the state machine.
	
	process (AUD_NEW, RESETN)
		variable sum : std_logic_vector(20 downto 0);
	begin
		if resetn = '0' then
			audio_average <= x"0000";
		elsif rising_edge(AUD_NEW) then
			sum := (others => '0');
			
			-- 1. Subtract last value and add latest value
			shift_reg <= shift_reg(shift_reg'high - 1 downto shift_reg'low) & std_logic_vector(to_signed(abs(to_integer(signed(AUD_DATA))), shift_reg_width)); --ChatGPT replacement

			-- 2. Sum all array values
			for n in shift_reg'range loop
				sum := std_logic_vector(signed(sum) + signed(shift_reg(n)));
			end loop;
			
			-- 3. Divide by num of array values
			audio_average <= std_logic_vector(shift_right(signed(sum), 5))(15 downto 0); -- Divide by 32 same same as shift right by 5
		end if;
	end process;
	
	
	------------------------------------     Adjustable Threshold Data Collection     ------------------------------------
	
	-- Notes:
	-- This block is constantly formatting the input data from SCOMP to the format we need for our audio threshold. SCOMP sends in
	-- the switch data on the LSBs but we need them on the MSBs for the bit to be high enough to be an effective threshold. So, we
	-- shift the bits to the left and fill in with zeros.
	
	process (SYS_CLK) 
	begin
		if rising_edge(SYS_CLK) then
			loud_threshold <= input_data(9 downto 0) & "000000";
		end if;
	end process;
	
	
	-----------------------------------------------     State Machine     ------------------------------------------------
	
	-- Notes:
	-- This state machine has three states: listening, noise_detected, and clap_check. While the audio input (audio_average from above)
	-- is less than our loud threshold, just wait, as there is no clap or snap to be detected. If the input does go above the
	-- threshold, then transition to the noise_detected state. Stay there while the noise level is above the quiet threshold and begin counting.
	-- The counting happens in the timer above. When the noise drops below the quiet threshold, stop counting and transition to the final state.
	-- The final state does a one-time check of whether the noise was short enough to be a snap or clap, and if it is, add one to the clap_count
	-- signal and flash the is_clap signal bit. This signal bit allows SCOMP to not constantly poll the peripheral to determine whether a clap
	-- has occurred, as the bit carries that information.
	
	process (SYS_CLK, RESETN) begin
		if resetn = '0' then
			is_clap <= '0';
			count_en <= '0';
			clap_count <= 0;
			state <= listening;
		elsif rising_edge(SYS_CLK) then
			case state is
				when listening =>		-- Listening state where there is no loud noise
					if (unsigned(audio_average)) > unsigned(loud_threshold) then -- Using the less-than operator means that the left-most switch acts as a lock
						state <= noise_detected;
					else
						state <= listening;
					end if;
				when noise_detected =>	-- Counting state where duration of loud noise is found
					count_en <= '1';     -- TIMER begins
					if (unsigned(audio_average)) < unsigned(quiet_threshold) then
						count_en <= '0';  --Latches ticks_final
						state <= clap_check;
					else
						state <= noise_detected;
					end if;
				when clap_check =>	-- Decision state where we decide whether it was a clap or not
					if (ticks_final < max_snap_duration) then
						clap_count <= clap_count + 1;
						is_clap <= not is_clap;
					end if;
					state <= listening;
			end case;
		end if;
	end process;
	
	
	-----------------------------------------------   Output Management   ------------------------------------------------
	
	-- Notes:	
	-- This is our definition of our peripheral's API below.
	-- 15 | 1 (bits) --> Counter | SnapDetected (signals)
	parsed_data <= std_logic_vector(to_unsigned(clap_count, 15)) & is_clap;

	-- Latch data on rising edge of CS to keep it stable during IN
	process (CS) begin
		if rising_edge(CS) then
			output_data <= parsed_data;
		end if;
	end process;
   
	-- Drive IO_DATA when needed.
	out_en <= CS AND ( NOT IO_WRITE );  --when it doesn't write, it reads the output_data
	with out_en select IO_DATA <=
		output_data        when '1',
		"ZZZZZZZZZZZZZZZZ" when others;
	
	in_en <= CS AND (IO_WRITE);
	with in_en select input_data <=
		IO_DATA            when '1',
		input_data when others;
end a;
